import { cookies } from 'next/headers';
import jwt from 'jsonwebtoken';
import { adminSessionSecret } from './admin-session-secret';

export async function isAdminRequest() {
  const token = (await cookies()).get('admin_token')?.value;
  const secret = adminSessionSecret();
  if (!token || !secret) return false;
  try {
    const claims = jwt.verify(token, secret, { algorithms: ['HS256'] });
    return typeof claims !== 'string' && Boolean(claims.id) && claims.id !== 'fallback-admin';
  } catch {
    return false;
  }
}
