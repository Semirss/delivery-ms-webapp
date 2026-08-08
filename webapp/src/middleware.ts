import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

const CLIENT_APP_ROUTE = '/motobikeiphoneapp';
const PUBLIC_FILE = /\.[^/]+$/;

export function middleware(request: NextRequest) {
    const pathname = request.nextUrl.pathname;

    if (
        (pathname === CLIENT_APP_ROUTE || pathname.startsWith(`${CLIENT_APP_ROUTE}/`)) &&
        !PUBLIC_FILE.test(pathname)
    ) {
        const url = request.nextUrl.clone();
        url.pathname = `${CLIENT_APP_ROUTE}/index.html`;
        return NextResponse.rewrite(url);
    }

    const adminToken = request.cookies.get('admin_token');
    const isLoginPage = pathname.startsWith('/admin/login');

    // Protect all /admin routes except /admin/login
    if (pathname.startsWith('/admin') && !isLoginPage) {
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
    matcher: ['/admin/:path*', '/motobikeiphoneapp/:path*'],
};
