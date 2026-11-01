import { requireDriver } from '@/lib/driver-session';
import { OperationsError, textValue, validatedLocation } from '@/lib/driver-operations';
import { operationsFailure, operationsJson, operationsOptions } from '@/lib/operations-response';

export const dynamic = 'force-dynamic';
export const OPTIONS = operationsOptions;
const historyPageSize = 10;

function historyPage(value: string | null) {
  if (!value || !/^[1-9][0-9]*$/.test(value)) return 1;
  const page = Number(value);
  return Number.isSafeInteger(page) ? Math.min(page, 100000) : 1;
}

export async function GET(request: Request) {
  try {
    const { db, driver } = await requireDriver(request);
    const params = new URL(request.url).searchParams;
    const requestsPage = historyPage(params.get('requests_page'));
    const ledgerPage = historyPage(params.get('ledger_page'));
    const { error: expiryError } = await db.rpc('expire_driver_offers', { p_driver_id: driver.id });
    if (expiryError) throw expiryError;
    const { error: walletError } = await db.from('driver_wallets').upsert({ driver_id: driver.id }, { onConflict: 'driver_id', ignoreDuplicates: true });
    if (walletError) throw walletError;
    const results = await Promise.all([
      db.from('driver_wallets').select('*').eq('driver_id', driver.id).single(),
      db.from('driver_wallet_requests').select('*', { count: 'exact' }).eq('driver_id', driver.id)
        .order('created_at', { ascending: false }).order('id', { ascending: false })
        .range((requestsPage - 1) * historyPageSize, requestsPage * historyPageSize - 1),
      db.from('driver_wallet_ledger').select('*', { count: 'exact' }).eq('driver_id', driver.id)
        .order('created_at', { ascending: false }).order('id', { ascending: false })
        .range((ledgerPage - 1) * historyPageSize, ledgerPage * historyPageSize - 1),
      db.from('driver_operations_settings').select('*').eq('id', true).single(),
      db.from('driver_wallet_requests').select('id', { count: 'exact', head: true })
        .eq('driver_id', driver.id).eq('status', 'pending'),
    ]);
    for (const result of results) if (result.error) throw result.error;
    return operationsJson({ driver, wallet: results[0].data, requests: results[1].data, ledger: results[2].data,
      requests_total: results[1].count ?? 0, ledger_total: results[2].count ?? 0,
      pending_requests_count: results[4].count ?? 0,
      requests_page: requestsPage, ledger_page: ledgerPage, history_page_size: historyPageSize,
      settings: results[3].data, payment_mode: 'manual_reconciliation', automatic_transfers_enabled: false });
  } catch (error) { return operationsFailure(error); }
}

export async function PATCH(request: Request) {
  try {
    const { db, driver } = await requireDriver(request);
    const body = await request.json();
    const updates: Record<string, unknown> = {};
    const hasPauseColumn = Object.prototype.hasOwnProperty.call(driver, 'availability_paused');
    if (body.action === 'location') {
      if (driver.availability_paused === true) return operationsJson(driver);
      Object.assign(updates, validatedLocation(body));
      if (driver.last_location_update && Date.parse(String(driver.last_location_update)) >= Date.parse(String(updates.last_location_update))) {
        return operationsJson(driver); // An older delayed GPS fix must never overwrite a newer one.
      }
    } else if (body.action === 'online') {
      // Availability is a driver preference. Dispatch still checks a fresh GPS fix.
      updates.status = 'Online';
      if (hasPauseColumn) updates.availability_paused = false;
    } else if (body.action === 'offline') {
      const { data, error } = await db.rpc('driver_set_offline', { p_driver_id: driver.id });
      if (error) throw error;
      if (data) delete data.password;
      return operationsJson(data);
    } else if (body.action === 'settings') {
      if (body.working_radius_km !== undefined) {
        if (typeof body.working_radius_km !== 'number' || !Number.isFinite(body.working_radius_km) || body.working_radius_km < 1 || body.working_radius_km > 50) {
          throw new OperationsError('Working radius must be between 1 and 50 km.');
        }
        updates.working_radius_km = Math.round(body.working_radius_km * 10) / 10;
      }
      if (typeof body.notifications_enabled === 'boolean') updates.notifications_enabled = body.notifications_enabled;
    } else if (body.action === 'profile') {
      for (const key of ['name', 'plate_number', 'telegram_username', 'vehicle_type']) {
        if (typeof body[key] === 'string') updates[key] = textValue(body[key]);
      }
    } else throw new OperationsError('Unknown driver action.');
    if (!Object.keys(updates).length) throw new OperationsError('No valid changes supplied.');
    let query = db.from('drivers').update(updates).eq('id', driver.id);
    if (body.action === 'location') {
      query = query.or(`last_location_update.is.null,last_location_update.lt.${updates.last_location_update}`);
      if (hasPauseColumn) query = query.eq('availability_paused', false);
    }
    const { data, error } = await query.select('*').maybeSingle();
    if (error) throw error;
    if (data) delete data.password;
    return operationsJson(data ?? driver);
  } catch (error) { return operationsFailure(error); }
}
