import jwt, { JwtPayload } from 'jsonwebtoken';
import { getSupabaseAdmin } from './supabase-admin';
import { OperationsError } from './driver-operations';

function sessionSecret() {
  const secret = process.env.DRIVER_SESSION_SECRET || process.env.JWT_SECRET;
  if (!secret || secret.length < 32) {
    console.error('[driver session] Set DRIVER_SESSION_SECRET or JWT_SECRET to at least 32 characters.');
    throw new OperationsError('Sign-in is temporarily unavailable. Please try again later or contact support.', 503);
  }
  return secret;
}

export function signDriverSession(driver: Record<string, unknown>) {
  return jwt.sign({ version: driver.auth_version, role: 'driver' }, sessionSecret(), {
    subject: String(driver.id), issuer: 'motobike-driver', audience: 'driver-operations',
    algorithm: 'HS256', expiresIn: '7d',
  });
}

export async function requireDriver(request: Request) {
  const token = request.headers.get('authorization')?.replace(/^Bearer\s+/i, '');
  if (!token) throw new OperationsError('Please sign in again to continue.', 401);
  let claims: JwtPayload;
  const secret = sessionSecret();
  try {
    const decoded = jwt.verify(token, secret, { algorithms: ['HS256'], issuer: 'motobike-driver', audience: 'driver-operations' });
    if (typeof decoded === 'string' || decoded.role !== 'driver' || !decoded.sub) throw new Error();
    claims = decoded;
  } catch { throw new OperationsError('Your sign-in has expired. Please sign in again.', 401); }
  const db = await getSupabaseAdmin();
  const { data, error } = await db.from('drivers').select('*').eq('id', claims.sub).maybeSingle();
  if (error) {
    console.error('[driver session] Could not load driver account:', error);
    throw new OperationsError('Your account is temporarily unavailable. Please try again later or contact support.', 503);
  }
  if (!data || data.auth_version !== claims.version) throw new OperationsError('Please sign in again to continue.', 401);
  if (data.is_active === false || data.approval_status !== 'Approved') throw new OperationsError('An approved, active driver account is required.', 403);
  delete data.password;
  return { db, driver: data };
}
