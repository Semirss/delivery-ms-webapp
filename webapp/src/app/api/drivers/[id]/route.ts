import { NextResponse } from 'next/server';
import { getSupabaseAdmin } from '@/lib/supabase-admin';
import { normalizeEthiopianPhone } from '@/lib/phone';

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
                .eq('email', updates.email)
                .neq('id', id)
                .maybeSingle();

            if (existingEmailError) throw existingEmailError;
            if (existingEmail) {
                return NextResponse.json(
                    { error: 'A driver account already exists for this email' },
                    { status: 409 }
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
                    { status: 409 }
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
        return NextResponse.json(data);
    } catch (err: any) {
        return NextResponse.json({ error: err.message }, { status: 500 });
    }
}

export async function DELETE(request: Request, context: { params: Promise<{ id: string }> }) {
    const supabase = await getSupabaseAdmin();
    try {
        const { id } = await context.params;

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
        return NextResponse.json({ success: true });
    } catch (err: any) {
        return NextResponse.json({ error: err.message }, { status: 500 });
    }
}
