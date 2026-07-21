import { NextResponse } from 'next/server';
import { getSupabaseAdmin } from '@/lib/supabase-admin';

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};

const approvalRequiredMessage =
    'Approval required first. Your driver application is still waiting for admin approval. If this takes too long, contact admin at +251 931 323 328 or support@motobike.app.';

export async function OPTIONS() {
    return new NextResponse(null, { status: 204, headers: corsHeaders });
}

export async function POST(request: Request) {
    const supabase = await getSupabaseAdmin();
    try {
        const { email, password } = await request.json();
        const normalizedEmail = typeof email === 'string' ? email.trim().toLowerCase() : '';

        if (!normalizedEmail || !password) {
            return NextResponse.json({ error: 'Email and password are required' }, { status: 400, headers: corsHeaders });
        }

        const { data: rows, error } = await supabase
            .from('drivers')
            .select('*')
            .ilike('email', normalizedEmail)
            .limit(1);

        if (error) {
            return NextResponse.json({ error: error.message }, { status: 500, headers: corsHeaders });
        }

        const data = rows?.[0] || null;
        if (!data) {
            return NextResponse.json(
                { error: 'No driver account found with this email. Ask admin to add this email to your driver profile.' },
                { status: 401, headers: corsHeaders }
            );
        }

        if (data.password !== password) {
            return NextResponse.json({ error: 'Invalid email or password' }, { status: 401, headers: corsHeaders });
        }

        const approvalStatus = typeof data.approval_status === 'string'
            ? data.approval_status.trim().toLowerCase()
            : 'pending';
        if (approvalStatus !== 'approved') {
            return NextResponse.json({ error: approvalRequiredMessage }, { status: 403, headers: corsHeaders });
        }

        return NextResponse.json(data, { headers: corsHeaders });
    } catch (err: unknown) {
        const message = err instanceof Error ? err.message : 'Unknown error';
        return NextResponse.json({ error: message }, { status: 500, headers: corsHeaders });
    }
}
