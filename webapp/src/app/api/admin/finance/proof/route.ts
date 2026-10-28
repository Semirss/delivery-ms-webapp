import { isAdminRequest } from '@/lib/admin-auth';
import { getSupabaseAdmin } from '@/lib/supabase-admin';
import { OperationsError, uuid } from '@/lib/driver-operations';
import { operationsFailure } from '@/lib/operations-response';

export const dynamic = 'force-dynamic';
export async function GET(request: Request) {
  try {
    if (!await isAdminRequest()) throw new OperationsError('Admin sign-in required.', 401);
    const id = uuid(new URL(request.url).searchParams.get('request_id'));
    const db = await getSupabaseAdmin();
    const { data: row, error } = await db.from('driver_wallet_requests')
      .select('proof_path,proof_mime_type').eq('id', id).eq('kind', 'topup').single();
    if (error || !row?.proof_path) throw new OperationsError('Payment screenshot is unavailable.', 404);
    const { data: file, error: downloadError } = await db.storage.from('driver_topup_proofs').download(row.proof_path);
    if (downloadError || !file) throw new OperationsError('Payment screenshot is unavailable.', 404);
    return new Response(file, { headers: { 'Content-Type': row.proof_mime_type || 'application/octet-stream',
      'Cache-Control': 'private, no-store', 'Content-Disposition': 'inline' } });
  } catch (error) { return operationsFailure(error); }
}
