import { NextResponse } from 'next/server';
import { supabaseAdmin as supabase } from '@/lib/supabase-admin';

export async function PATCH(request: Request, context: { params: Promise<{ id: string }> }) {
    try {
        const { id } = await context.params;
        const body = await request.json();

        const { data, error } = await supabase
            .from('drivers')
            .update(body)
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
