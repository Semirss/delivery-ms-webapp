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

export async function POST(request: Request) {
    const supabase = await getSupabaseAdmin();

    try {
        const { phone, newPassword } = await request.json();
        const normalizedPhone = normalizeEthiopianPhone(phone);
        const password = typeof newPassword === 'string' ? newPassword : '';

        if (!normalizedPhone) {
            return NextResponse.json({ error: 'Phone number is required' }, { status: 400, headers: corsHeaders });
        }

        const { data, error } = await supabase
            .from('drivers')
            .select('id, name, phone, password')
            .not('phone', 'is', null);

        if (error) {
            return NextResponse.json({ error: error.message }, { status: 500, headers: corsHeaders });
        }

        const driver = (data ?? []).find(
            (row) => normalizeEthiopianPhone(row.phone) === normalizedPhone
        );

        if (!driver) {
            return NextResponse.json(
                { error: 'No driver account found for this phone number' },
                { status: 404, headers: corsHeaders }
            );
        }

        if (!password) {
            return NextResponse.json({ success: true, next: 'new_password' }, { headers: corsHeaders });
        }

        if (password.length < 6) {
            return NextResponse.json({ error: 'Password must be at least 6 characters' }, { status: 400, headers: corsHeaders });
        }

        const { error: updateError } = await supabase
            .from('drivers')
            .update({ password })
            .eq('id', driver.id);

        if (updateError) {
            return NextResponse.json({ error: updateError.message }, { status: 500, headers: corsHeaders });
        }

        return NextResponse.json({ success: true, next: 'login' }, { headers: corsHeaders });
    } catch (err: unknown) {
        const message = err instanceof Error ? err.message : 'Unknown error';
        return NextResponse.json({ error: message }, { status: 500, headers: corsHeaders });
    }
}
