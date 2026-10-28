import { getSupabaseAdmin } from '@/lib/supabase-admin';
import { signDriverSession } from '@/lib/driver-session';
import { OperationsError } from '@/lib/driver-operations';
import { operationsFailure, operationsJson, operationsOptions } from '@/lib/operations-response';

export const OPTIONS = operationsOptions;
export async function POST(request: Request) {
  try {
    const token = request.headers.get('authorization')?.replace(/^Bearer\s+/i,'');
    if (!token) throw new OperationsError('Google sign-in required.',401);
    const db = await getSupabaseAdmin();
    const { data: { user }, error: authError } = await db.auth.getUser(token);
    if (authError || !user?.email || !user.email_confirmed_at) throw new OperationsError('Google session could not be verified.',401);
    const { data: driver, error } = await db.from('drivers').select('*').ilike('email',user.email).maybeSingle();
    if (error) throw error;
    if (!driver || driver.approval_status !== 'Approved' || driver.is_active === false) throw new OperationsError('An approved, active driver account is required.',403);
    delete driver.password;
    return operationsJson({ ...driver, access_token: signDriverSession(driver) });
  } catch (error) { return operationsFailure(error); }
}
