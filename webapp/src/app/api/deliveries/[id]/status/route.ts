import { NextResponse } from 'next/server';
import { getSupabaseAdmin } from '@/lib/supabase-admin';

const ASSIGN_TIMEOUT_MS = 2 * 60 * 1000;

function errorMessage(error: unknown): string {
    return error instanceof Error ? error.message : 'Unknown error';
}

export async function PATCH(request: Request, context: { params: Promise<{ id: string }> }) {
    const supabase = await getSupabaseAdmin();
    try {
        const { id } = await context.params;
        const { status, cancelled_by, cancellation_reason } = await request.json();

        if (status === 'Pending' && cancelled_by === 'timeout') {
            const { data: current, error: currentError } = await supabase
                .from('deliveries')
                .select('id,status,assigned_at,driver_id,cancelled_by,cancellation_reason')
                .eq('id', id)
                .single();

            if (currentError) throw currentError;

            const assignedTime = current.assigned_at
                ? new Date(current.assigned_at).getTime()
                : Number.NaN;
            const isExpired =
                Number.isFinite(assignedTime) &&
                Date.now() - assignedTime > ASSIGN_TIMEOUT_MS;

            if (current.status !== 'Assigned' || !isExpired) {
                return NextResponse.json(current);
            }
        }

        const updatePayload: Record<string, unknown> = { status };

        // Track who/what caused a cancellation or re-pending. Once a delivery
        // moves forward, clear stale timeout/reject metadata so admin cards do
        // not keep showing "no accept" after the driver accepted.
        if (cancelled_by) updatePayload.cancelled_by = cancelled_by;
        if (cancellation_reason) updatePayload.cancellation_reason = cancellation_reason;
        if (status !== 'Pending' && status !== 'Cancelled') {
            updatePayload.cancelled_by = null;
            updatePayload.cancellation_reason = null;
        }

        if (status === 'Pending' || status === 'Cancelled') {
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
    } catch (err: unknown) {
        return NextResponse.json({ error: errorMessage(err) }, { status: 500 });
    }
}
