import { NextResponse } from 'next/server';
import { getSupabaseAdmin } from '@/lib/supabase-admin';

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};

const approvalRequiredMessage =
    'Approval required first. Your driver application is still waiting for admin approval. If this takes too long, contact admin at +251 931 323 328 or support@motobike.app.';

type SupabaseAdmin = Awaited<ReturnType<typeof getSupabaseAdmin>>;
type DriverRow = Record<string, unknown>;

export async function OPTIONS() {
    return new NextResponse(null, { status: 204, headers: corsHeaders });
}

function isEmailIdentifier(value: string) {
    return value.includes('@');
}

function normalizeEthiopianPhone(value: unknown) {
    const digits = String(value ?? '').replace(/\D/g, '');

    if (digits.length === 12 && digits.startsWith('251') && digits[3] === '9') {
        return `0${digits.slice(3)}`;
    }

    if (digits.length === 9 && digits[0] === '9') {
        return `0${digits}`;
    }

    if (digits.length === 10 && digits.startsWith('09')) {
        return digits;
    }

    return digits;
}

async function findDriverByIdentifier(supabase: SupabaseAdmin, identifier: string) {
    if (isEmailIdentifier(identifier)) {
        const normalizedEmail = identifier.trim().toLowerCase();
        return supabase
            .from('drivers')
            .select('*')
            .ilike('email', normalizedEmail)
            .limit(1);
    }

    const normalizedPhone = normalizeEthiopianPhone(identifier);
    const { data: rows, error } = await supabase
        .from('drivers')
        .select('*')
        .not('phone', 'is', null);

    if (error) return { data: null, error };

    const driver = (rows ?? []).find(
        (row: DriverRow) => normalizeEthiopianPhone(row.phone) === normalizedPhone
    );

    return { data: driver ? [driver] : [], error: null };
}

export async function POST(request: Request) {
    const supabase = await getSupabaseAdmin();
    try {
        const body = await request.json();
        const rawIdentifier =
            typeof body.identifier === 'string'
                ? body.identifier
                : typeof body.email === 'string'
                    ? body.email
                    : '';
        const identifier = rawIdentifier.trim();
        const password = typeof body.password === 'string' ? body.password : '';

        if (!identifier || !password) {
            return NextResponse.json({ error: 'Email or phone and password are required' }, { status: 400, headers: corsHeaders });
        }

        if (!isEmailIdentifier(identifier) && !/^09\d{8}$/.test(identifier.replace(/\D/g, ''))) {
            return NextResponse.json(
                { error: 'Use an Ethiopian phone number starting with 09, for example 0912345678' },
                { status: 400, headers: corsHeaders }
            );
        }

        const { data: rows, error } = await findDriverByIdentifier(supabase, identifier);

        if (error) {
            return NextResponse.json({ error: error.message }, { status: 500, headers: corsHeaders });
        }

        const data = rows?.[0] || null;
        if (!data) {
            return NextResponse.json(
                { error: 'No driver account found with this email or phone. Ask admin to add it to your driver profile.' },
                { status: 401, headers: corsHeaders }
            );
        }

        if (data.password !== password) {
            return NextResponse.json({ error: 'Invalid email/phone or password' }, { status: 401, headers: corsHeaders });
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
