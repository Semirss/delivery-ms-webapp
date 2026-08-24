import { NextResponse } from 'next/server';
import { getSupabaseAdmin } from '@/lib/supabase-admin';
import { normalizeEthiopianPhone } from '@/lib/phone';

export const dynamic = 'force-dynamic';
export const fetchCache = 'force-no-store';

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'PATCH, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Motobike-Account-Email, X-Motobike-Account-Phone',
};

export async function OPTIONS() {
    return new NextResponse(null, { status: 204, headers: corsHeaders });
}

export async function PATCH(request: Request, context: { params: Promise<{ id: string }> }) {
    const supabase = await getSupabaseAdmin();
    try {
        const { id } = await context.params;
        const body = await request.json();
        const updates = { ...body };

        if (typeof updates.email === 'string') {
            updates.email = updates.email.trim().toLowerCase();
        }
        if (typeof updates.phone === 'string') {
            updates.phone = normalizeEthiopianPhone(updates.phone);
        }
        if (typeof updates.name === 'string') {
            updates.name = updates.name.trim();
        }

        if (updates.email) {
            const { data: existingEmail, error: existingEmailError } = await supabase
                .from('drivers')
                .select('id')
                .ilike('email', updates.email)
                .neq('id', id)
                .maybeSingle();

            if (existingEmailError) throw existingEmailError;
            if (existingEmail) {
                return NextResponse.json(
                    { error: 'A driver account already exists for this email' },
                    { status: 409, headers: corsHeaders }
                );
            }
        }

        if (updates.phone) {
            const { data: existingPhone, error: existingPhoneError } = await supabase
                .from('drivers')
                .select('id, phone')
                .neq('id', id)
                .not('phone', 'is', null);

            if (existingPhoneError) throw existingPhoneError;
            if ((existingPhone ?? []).some((driver) => normalizeEthiopianPhone(driver.phone) === updates.phone)) {
                return NextResponse.json(
                    { error: 'A driver account already exists for this phone number' },
                    { status: 409, headers: corsHeaders }
                );
            }
        }

        const { data, error } = await supabase
            .from('drivers')
            .update(updates)
            .eq('id', id)
            .select()
            .single();

        if (error) throw error;
        try {
            await supabase.channel('deliveries-sync').send({
                type: 'broadcast',
                event: 'driver_updated',
                payload: {
                    driver_id: data.id,
                    status: data.status,
                    approval_status: data.approval_status,
                    is_active: data.is_active
                }
            });
        } catch (e) {
            console.error('Broadcast failed', e);
        }
        return NextResponse.json(data, { headers: corsHeaders });
    } catch (err: unknown) {
        const message = err instanceof Error ? err.message : 'Unknown error';
        return NextResponse.json({ error: message }, { status: 500, headers: corsHeaders });
    }
}

export async function DELETE(request: Request, context: { params: Promise<{ id: string }> }) {
    const supabase = await getSupabaseAdmin();
    try {
        const { id } = await context.params;
        const accountEmail = request.headers.get('x-motobike-account-email')?.trim().toLowerCase() ?? '';
        const accountPhone = normalizeEthiopianPhone(request.headers.get('x-motobike-account-phone'));

        if (accountEmail || accountPhone) {
            const { data: driver, error: lookupError } = await supabase
                .from('drivers')
                .select('id,email,phone')
                .eq('id', id)
                .maybeSingle();

            if (lookupError) throw lookupError;
            if (!driver) {
                return NextResponse.json({ error: 'Driver account not found' }, { status: 404, headers: corsHeaders });
            }

            const emailMatches = accountEmail && driver.email?.toString().trim().toLowerCase() === accountEmail;
            const phoneMatches = accountPhone && normalizeEthiopianPhone(driver.phone) === accountPhone;
            if ((accountEmail && !emailMatches) || (accountPhone && !phoneMatches)) {
                return NextResponse.json({ error: 'Account verification failed' }, { status: 403, headers: corsHeaders });
            }
        }

        await supabase
            .from('app_notifications')
            .delete()
            .eq('app', 'driver')
            .eq('recipient_id', id);

        await supabase
            .from('delivery_ratings')
            .delete()
            .or(`and(rater_type.eq.driver,rater_id.eq.${id}),and(ratee_type.eq.driver,ratee_id.eq.${id})`);

        // First, nullify driver_id in deliveries to preserve history
        await supabase.from('deliveries').update({ driver_id: null }).eq('driver_id', id);

        const { error } = await supabase
            .from('drivers')
            .delete()
            .eq('id', id);

        if (error) throw error;
        try {
            await supabase.channel('deliveries-sync').send({
                type: 'broadcast',
                event: 'driver_deleted',
                payload: {
                    driver_id: id
                }
            });
        } catch (e) {
            console.error('Broadcast failed', e);
        }
        return NextResponse.json({ success: true }, { headers: corsHeaders });
    } catch (err: unknown) {
        const message = err instanceof Error ? err.message : 'Unknown error';
        return NextResponse.json({ error: message }, { status: 500, headers: corsHeaders });
    }
}
