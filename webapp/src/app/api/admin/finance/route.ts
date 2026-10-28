import { isAdminRequest } from '@/lib/admin-auth';
import { getSupabaseAdmin } from '@/lib/supabase-admin';
import { moneyAmount, OperationsError, textValue, uuid } from '@/lib/driver-operations';
import { operationsFailure, operationsJson } from '@/lib/operations-response';

export const dynamic = 'force-dynamic';
export async function GET() {
  try {
    if (!await isAdminRequest()) throw new OperationsError('Admin sign-in required.', 401);
    const db = await getSupabaseAdmin();
    const results = await Promise.all([
      db.from('driver_operations_settings').select('*').eq('id', true).single(),
      db.from('driver_wallets').select('*,driver:drivers(name,phone)').order('updated_at', { ascending: false }).limit(200),
      db.from('driver_wallet_requests').select('*,driver:drivers(name,phone)').eq('status','pending').order('created_at', { ascending: true }).limit(200),
      db.from('driver_wallet_ledger').select('*,driver:drivers(name)').order('created_at', { ascending: false }).limit(100),
      db.from('driver_wallet_requests').select('*,driver:drivers(name,phone)').neq('status','pending').order('created_at', { ascending: false }).limit(100),
    ]);
    for (const result of results) if (result.error) throw result.error;
    // Aggregate in SQL to avoid a truncated ledger silently understating revenue.
    const { data: totals, error } = await db.rpc('driver_finance_totals');
    if (error) throw error;
    return operationsJson({ settings: results[0].data, wallets: results[1].data, requests: [...(results[2].data ?? []),...(results[4].data ?? [])],
      ledger: results[3].data, totals, automatic_transfers_enabled: false });
  } catch (error) { return operationsFailure(error); }
}
export async function POST(request: Request) {
  try {
    if (!await isAdminRequest()) throw new OperationsError('Admin sign-in required.', 401);
    // Cookie-authenticated financial mutations must be same-origin.
    const origin = request.headers.get('origin');
    if (origin && origin !== new URL(request.url).origin) throw new OperationsError('Invalid request origin.', 403);
    const db = await getSupabaseAdmin();
    const body = await request.json();
    if (body.action === 'legacy_delivery') {
      if (body.confirmed !== true || !['reoffer','preserve_cash_earnings'].includes(body.mode)) throw new OperationsError('Explicit per-delivery review confirmation is required.');
      const { data, error } = await db.rpc('review_legacy_driver_delivery', { p_delivery_id: uuid(body.delivery_id), p_action: body.mode });
      if (error) throw new OperationsError(error.message,409);
      return operationsJson(data);
    }
    if (body.action === 'commission') {
      const rate = body.commission_percent;
      if (typeof rate !== 'number' || !Number.isFinite(rate) || rate < 0 || rate > 100 ||
        Math.abs(rate * 100 - Math.round(rate * 100)) > 0.000001) throw new OperationsError('Commission must be from 0 to 100%, with at most two decimal places.');
      const note = textValue(body.rate_note, 300);
      if (!note) throw new OperationsError('Add a note explaining this rate.');
      const { data, error } = await db.from('driver_operations_settings').update({ commission_percent: rate, rate_note: note, updated_at: new Date().toISOString() }).eq('id', true).select().single();
      if (error) throw error;
      return operationsJson(data);
    }
    if (body.action === 'review') {
      if (typeof body.approve !== 'boolean') throw new OperationsError('Choose approval or rejection.');
      const { data, error } = await db.rpc('review_driver_wallet_request', {
        p_request_id: uuid(body.request_id), p_approve: body.approve,
        p_reference: textValue(body.external_reference, 150), p_note: textValue(body.review_note, 500),
      });
      if (error) throw new OperationsError(error.message, 409);
      return operationsJson(data);
    }
    if (body.action === 'delivery_fee') {
      if (!['cash','platform'].includes(body.fee_collection_method)) throw new OperationsError('Choose cash or platform collection.');
      const { data, error } = await db.from('deliveries').update({ delivery_fee: moneyAmount(body.delivery_fee),
        fee_collection_method: body.fee_collection_method }).eq('id', uuid(body.delivery_id)).eq('status','Pending').select().maybeSingle();
      if (error) throw error;
      if (!data) throw new OperationsError('Only a pending delivery can be repriced.', 409);
      return operationsJson(data);
    }
    if (body.action === 'verify_payment') {
      const reference = textValue(body.external_reference, 150);
      if (reference.length < 5 || body.confirmed !== true) throw new OperationsError('Confirm receipt of the full delivery fee and enter its actual payment reference.');
      const { data, error } = await db.rpc('confirm_delivery_payment', { p_delivery_id: uuid(body.delivery_id), p_reference: reference });
      if (error) throw new OperationsError(error.message, 409);
      return operationsJson(data);
    }
    throw new OperationsError('Unknown finance action.');
  } catch (error) { return operationsFailure(error); }
}
