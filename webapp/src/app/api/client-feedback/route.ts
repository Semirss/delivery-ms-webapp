import { NextResponse } from 'next/server';
import { getSupabaseAdmin } from '@/lib/supabase-admin';

export const dynamic = 'force-dynamic';
export const fetchCache = 'force-no-store';

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};

export async function OPTIONS() {
    return new NextResponse(null, { status: 204, headers: corsHeaders });
}

export async function POST(request: Request) {
    const supabase = await getSupabaseAdmin();
    try {
        const body = await request.json();
        const feedback = typeof body.feedback === 'string' ? body.feedback.trim() : '';

        if (!feedback) {
            return NextResponse.json(
                { error: 'Feedback is required.' },
                { status: 400, headers: corsHeaders },
            );
        }

        const userName = cleanText(body.user_name) || 'Guest';
        const phone = cleanText(body.phone);
        const email = cleanText(body.email);
        const lines = [
            `User: ${userName}`,
            phone ? `Phone: ${phone}` : null,
            email ? `Email: ${email}` : null,
            `Feedback: ${feedback}`,
        ].filter(Boolean);

        const { error } = await supabase.from('app_notifications').insert({
            app: 'admin',
            title: 'Client app feedback',
            body: lines.join('\n'),
            type: 'client_feedback',
        });

        if (error) {
            console.error('[POST /api/client-feedback] Supabase error:', JSON.stringify(error));
            return NextResponse.json(
                { error: error.message },
                { status: 500, headers: corsHeaders },
            );
        }

        return NextResponse.json({ ok: true }, { status: 201, headers: corsHeaders });
    } catch (err: unknown) {
        const message = err instanceof Error ? err.message : 'Unknown error';
        console.error('[POST /api/client-feedback] Error:', message);
        return NextResponse.json(
            { error: message },
            { status: 500, headers: corsHeaders },
        );
    }
}

function cleanText(value: unknown): string {
    return typeof value === 'string' ? value.trim() : '';
}
