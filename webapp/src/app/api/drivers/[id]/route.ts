import { NextResponse } from 'next/server';
import { getSupabaseAdmin } from '@/lib/supabase-admin';
import { normalizeEthiopianPhone } from '@/lib/phone';
import { isAdminRequest } from '@/lib/admin-auth';
import { requireDriver } from '@/lib/driver-session';
import { OperationsError, gpsQuality } from '@/lib/driver-operations';
import { operationsFailure } from '@/lib/operations-response';

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
        const admin = await isAdminRequest();
        const session = admin ? null : await requireDriver(request);
        if (session && session.driver.id !== id) throw new OperationsError('Driver account mismatch.', 403);
        const allowed = admin
            ? ['name','email','phone','plate_number','vehicle_type','telegram_username','approval_status','is_active','password']
            : ['name','plate_number','vehicle_type','telegram_username'];
        const updates: Record<string, any> = Object.fromEntries(Object.entries(body).filter(([key]) => allowed.includes(key)));
        if (!admin && body.status !== undefined) {
            if (body.status === 'Online') {
                if (gpsQuality({ ...session!.driver, status: 'Online' }) !== 'live') throw new OperationsError('Share a fresh GPS fix before going online.',409);
                updates.status = 'Online';
            } else if (body.status === 'Offline') {
                const { data, error } = await supabase.rpc('driver_set_offline', { p_driver_id: id });
                if (error) throw new OperationsError(error.message,409);
                return NextResponse.json(data, { headers: corsHeaders });
            } else throw new OperationsError('Invalid driver status.');
        }
        if (!Object.keys(updates).length) throw new OperationsError('No permitted driver changes supplied.');

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
        delete data.password;
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
        return operationsFailure(err);
    }
}

export async function DELETE(request: Request, context: { params: Promise<{ id: string }> }) {
    const supabase = await getSupabaseAdmin();
    try {
        const { id } = await context.params;
        if (!await isAdminRequest()) {
            const { driver } = await requireDriver(request);
            if (driver.id !== id) throw new OperationsError('Driver account mismatch.', 403);
        }
        const { error } = await supabase.rpc('close_driver_account', { p_driver_id: id });
        if (error) throw new OperationsError(error.message, 409);
        await supabase.from('app_notifications').delete().eq('app','driver').eq('recipient_id',id);

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
        return operationsFailure(err);
    }
}
