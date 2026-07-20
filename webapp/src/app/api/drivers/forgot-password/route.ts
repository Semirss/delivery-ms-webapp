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

async function sendSms(request: Request, phone: string, message: string) {
    const response = await fetch(new URL('/api/sms/send', request.url), {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ phone, message }),
    });

    if (!response.ok) {
        const body = await response.json().catch(() => null);
        const detail = body && typeof body.error === 'string' ? body.error : 'SMS gateway failed';
        throw new Error(detail);
    }
}

export async function POST(request: Request) {
    const supabase = await getSupabaseAdmin();

    try {
        const { phone } = await request.json();
        const normalizedPhone = normalizeEthiopianPhone(phone);

        if (!normalizedPhone) {
            return NextResponse.json({ error: 'Phone number is required' }, { status: 400, headers: corsHeaders });
        }

        const { data, error } = await supabase
            .from('drivers')
            .select('name, phone, password')
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

        await sendSms(
            request,
            driver.phone,
            `Your MotoBike Driver password is: ${driver.password}. Contact support if this was not requested.`
        );

        return NextResponse.json({ success: true }, { headers: corsHeaders });
    } catch (err: unknown) {
        const message = err instanceof Error ? err.message : 'Unknown error';
        return NextResponse.json({ error: message }, { status: 500, headers: corsHeaders });
    }
}
