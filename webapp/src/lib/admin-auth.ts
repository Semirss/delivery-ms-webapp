import { cookies } from 'next/headers';
import jwt from 'jsonwebtoken';

const JWT_SECRET = process.env.JWT_SECRET;

export async function isAdminRequest() {
  const token = (await cookies()).get('admin_token')?.value;
  if (!token || !JWT_SECRET || JWT_SECRET.length < 32) return false;
  try {
    const claims = jwt.verify(token, JWT_SECRET, { algorithms: ['HS256'] });
    return typeof claims !== 'string' && Boolean(claims.id) && claims.id !== 'fallback-admin';
  } catch {
    return false;
  }
}
