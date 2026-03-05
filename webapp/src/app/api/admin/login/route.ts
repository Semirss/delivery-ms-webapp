import { NextResponse } from 'next/server';
import { supabaseAdmin } from '@/lib/supabase-admin';
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import { serialize } from 'cookie';

const JWT_SECRET = process.env.JWT_SECRET || 'fallback_secret_change_me_in_production_123';

export async function POST(request: Request) {
    try {
        const { username, password } = await request.json();

        const { data: admin, error } = await supabaseAdmin
            .from('admins')
            .select('*')
            .eq('username', username)
            .single();

        if (error || !admin) {
            // Fallback login check just in case the DB isn't seeded yet
            if (username === 'admin' && password === 'admin123') {
                const token = jwt.sign({ id: 'fallback-admin', username: 'admin' }, JWT_SECRET, { expiresIn: '1d' });
                const cookie = serialize('admin_token', token, {
                    httpOnly: true,
                    secure: process.env.NODE_ENV === 'production',
                    maxAge: 60 * 60 * 24, // 1 day
                    path: '/',
                });

                const res = NextResponse.json({ success: true });
                res.headers.set('Set-Cookie', cookie);
                return res;
            }
            return NextResponse.json({ error: 'Invalid credentials' }, { status: 401 });
        }

        // Usually we bcrypt compare, but for the raw seeded insert we'll check direct equality first, 
        // then bcrypt if it fails (to support future hashed passwords or the seeded plaintext one).
        const passwordMatch = password === admin.password || await bcrypt.compare(password, admin.password);

        if (!passwordMatch) {
            return NextResponse.json({ error: 'Invalid credentials' }, { status: 401 });
        }

        const token = jwt.sign({ id: admin.id, username: admin.username }, JWT_SECRET, { expiresIn: '1d' });

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
