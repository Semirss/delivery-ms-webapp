import { NextResponse } from 'next/server';
import { getSupabaseAdmin } from '@/lib/supabase-admin';
import { normalizeEthiopianPhone } from '@/lib/phone';

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};

export async function OPTIONS() {
    return new NextResponse(null, { status: 204, headers: corsHeaders });
}

type ClientLookup = {
    id: string;
    phone: string | null;
    is_active: boolean | null;
    status: string | null;
};

function clientRecoveryError(message: string) {
    if (
        message.includes('reset_client_password_by_phone') ||
        message.includes('Could not find the function')
    ) {
        return 'Client password recovery database is not installed. Run supabase/schema_v9_phone_password_recovery.sql in Supabase.';
    }
    return message;
}

async function findClientByPhone(supabase: Awaited<ReturnType<typeof getSupabaseAdmin>>, phone: string) {
    const normalizedPhone = normalizeEthiopianPhone(phone);

    const { data, error } = await supabase
        .from('clients')
        .select('id, phone, is_active, status')
        .not('phone', 'is', null);

    if (error) throw error;

    return ((data ?? []) as ClientLookup[]).find(
        (client) => normalizeEthiopianPhone(client.phone) === normalizedPhone
    ) ?? null;
}

export async function POST(request: Request) {
    const supabase = await getSupabaseAdmin();

    try {
        const { phone, newPassword } = await request.json();
        const normalizedPhone = normalizeEthiopianPhone(phone);
        const password = typeof newPassword === 'string' ? newPassword : '';

        if (!normalizedPhone) {
            return NextResponse.json({ error: 'Phone number is required' }, { status: 400, headers: corsHeaders });
        }

        const client = await findClientByPhone(supabase, phone);

        if (!client) {
            return NextResponse.json(
                { error: 'No client account found for this phone number' },
                { status: 404, headers: corsHeaders }
            );
        }

        if (client.is_active === false || client.status === 'Blocked' || client.status === 'Deleted') {
            return NextResponse.json({ error: 'This client account is not active' }, { status: 403, headers: corsHeaders });
        }

        if (!password) {
            return NextResponse.json({ success: true, next: 'new_password' }, { headers: corsHeaders });
        }

        if (password.length < 6) {
            return NextResponse.json({ error: 'Password must be at least 6 characters' }, { status: 400, headers: corsHeaders });
        }

        const { error } = await supabase.rpc('reset_client_password_by_phone', {
            p_phone: client.phone ?? normalizedPhone,
            p_new_password: password,
        });

        if (error) {
            const status = error.message.includes('No client account') ? 404 : 500;
            return NextResponse.json({ error: clientRecoveryError(error.message) }, { status, headers: corsHeaders });
        }

        return NextResponse.json({ success: true, next: 'login' }, { headers: corsHeaders });
    } catch (err: unknown) {
        const message = err instanceof Error ? err.message : 'Unknown error';
        return NextResponse.json({ error: message }, { status: 500, headers: corsHeaders });
    }
}
