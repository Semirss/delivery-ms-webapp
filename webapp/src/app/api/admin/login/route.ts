import { NextResponse } from 'next/server';
import { getSupabaseAdmin } from '@/lib/supabase-admin';
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import { serialize } from 'cookie';
import { adminSessionSecret } from '@/lib/admin-session-secret';

export async function POST(request: Request) {
    const secret = adminSessionSecret();
    if (!secret) {
        console.error('[admin login] Set JWT_SECRET or DRIVER_SESSION_SECRET to at least 32 characters.');
        return NextResponse.json({ error: 'Admin sign-in is temporarily unavailable. Please contact support.' }, { status: 503 });
    }
    const supabaseAdmin = await getSupabaseAdmin();
    try {
        const { username, password } = await request.json();

        const { data: admin, error } = await supabaseAdmin
            .from('admins')
            .select('*')
            .eq('username', username)
            .single();

        if (error || !admin) {
            return NextResponse.json({ error: 'Invalid credentials' }, { status: 401 });
        }

        if (admin.password === 'admin123') {
            return NextResponse.json({ error: 'Replace the seeded admin password before enabling financial operations.' }, { status: 403 });
        }
        // Usually we bcrypt compare, but for the raw seeded insert we'll check direct equality first, 
        // then bcrypt if it fails (to support future hashed passwords or the seeded plaintext one).
        const passwordMatch = password === admin.password || await bcrypt.compare(password, admin.password);

        if (!passwordMatch) {
            return NextResponse.json({ error: 'Invalid credentials' }, { status: 401 });
        }

        const token = jwt.sign({ id: admin.id, username: admin.username }, secret, { expiresIn: '1d' });

        const cookie = serialize('admin_token', token, {
            httpOnly: true,
            secure: process.env.NODE_ENV === 'production',
            maxAge: 60 * 60 * 24, // 1 day
            path: '/',
        });

        const response = NextResponse.json({ success: true });
        response.headers.set('Set-Cookie', cookie);
        return response;

    } catch (error: any) {
        return NextResponse.json({ error: error.message }, { status: 500 });
    }
}
