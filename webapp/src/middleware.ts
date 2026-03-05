import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
    const adminToken = request.cookies.get('admin_token');
    const isLoginPage = request.nextUrl.pathname.startsWith('/admin/login');

    // Protect all /admin routes except /admin/login
    if (request.nextUrl.pathname.startsWith('/admin') && !isLoginPage) {
        if (!adminToken) {
            return NextResponse.redirect(new URL('/admin/login', request.url));
        }
    }

    // Redirect away from login if already logged in
    if (isLoginPage && adminToken) {
        return NextResponse.redirect(new URL('/admin', request.url));
    }

    return NextResponse.next();
}

export const config = {
    matcher: '/admin/:path*',
};
