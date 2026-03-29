import { NextResponse } from 'next/server';
import { supabaseAdmin as supabase } from '@/lib/supabase-admin';

export async function PATCH(request: Request, context: { params: Promise<{ id: string }> }) {
    try {
        const { id } = await context.params;
        const { status, cancelled_by, cancellation_reason } = await request.json();

        const updatePayload: Record<string, any> = { status };

        // Track who/what caused a cancellation or re-pending
        if (cancelled_by) updatePayload.cancelled_by = cancelled_by;
        if (cancellation_reason) updatePayload.cancellation_reason = cancellation_reason;

        // When reverting to Pending, unassign the driver
        if (status === 'Pending') {
            updatePayload.driver_id = null;
            updatePayload.assigned_at = null;
        }

        const { data, error } = await supabase
            .from('deliveries')
            .update(updatePayload)
            .eq('id', id)
            .select()
            .single();

        if (error) throw error;
        try {
            await supabase.channel('deliveries-sync').send({
                type: 'broadcast',
                event: 'delivery_status_updated',
                payload: {
                    delivery_id: data.id,
                    driver_id: data.driver_id,
                    status: data.status
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
