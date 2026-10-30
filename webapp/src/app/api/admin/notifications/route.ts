import { isAdminRequest } from '@/lib/admin-auth';
import { getSupabaseAdmin } from '@/lib/supabase-admin';
import { OperationsError, textValue } from '@/lib/driver-operations';
import { operationsFailure, operationsJson } from '@/lib/operations-response';

export const dynamic = 'force-dynamic';

export async function GET() {
  try {
    if (!await isAdminRequest()) throw new OperationsError('Admin sign-in required.', 401);
    const db = await getSupabaseAdmin();
    const { data, error } = await db.from('app_notifications').select('*')
      .eq('app', 'admin').eq('type', 'wallet_credit_request')
      .order('created_at', { ascending: false }).limit(100);
    if (error) throw error;
    return operationsJson(data ?? []);
  } catch (error) { return operationsFailure(error); }
}

export async function POST(request: Request) {
  try {
    if (!await isAdminRequest()) throw new OperationsError('Admin sign-in required.', 401);
    const origin = request.headers.get('origin');
    if (origin && origin !== new URL(request.url).origin) throw new OperationsError('Invalid request origin.', 403);
    const body = await request.json();
    const title = textValue(body.title, 100);
    const message = textValue(body.message, 1000);
    if (!title || !message) throw new OperationsError('Enter a title and message.');
    const audience = textValue(body.audience, 20);
    if (!['driver', 'client', 'both'].includes(audience)) throw new OperationsError('Choose an app audience.');
    const db = await getSupabaseAdmin();
    const apps = audience === 'both' ? ['driver', 'client'] : [audience];
    const { error } = await db.from('app_notifications').insert(apps.map(app => ({
      app, title, body: message, type: 'admin_message',
    })));
    if (error) throw error;
    return operationsJson({ sent: apps.length }, 201);
  } catch (error) { return operationsFailure(error); }
}

export async function PATCH(request: Request) {
  try {
    if (!await isAdminRequest()) throw new OperationsError('Admin sign-in required.', 401);
    const origin = request.headers.get('origin');
    if (origin && origin !== new URL(request.url).origin) throw new OperationsError('Invalid request origin.', 403);
    const db = await getSupabaseAdmin();
    const { error } = await db.from('app_notifications').update({ read_at: new Date().toISOString() })
      .eq('app', 'admin').eq('type', 'wallet_credit_request').is('read_at', null);
    if (error) throw error;
    return operationsJson({ success: true });
  } catch (error) { return operationsFailure(error); }
}
