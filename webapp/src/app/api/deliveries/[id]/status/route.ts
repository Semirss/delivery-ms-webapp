import { getSupabaseAdmin } from '@/lib/supabase-admin';
import { isAdminRequest } from '@/lib/admin-auth';
import { requireDriver } from '@/lib/driver-session';
import { OperationsError, uuid } from '@/lib/driver-operations';
import { operationsFailure, operationsJson } from '@/lib/operations-response';

export async function PATCH(request: Request, context: { params: Promise<{ id: string }> }) {
    const supabase = await getSupabaseAdmin();
    try {
        const { id } = await context.params;
        const { status, cancelled_by, cancellation_reason } = await request.json();

        if (!await isAdminRequest()) {
            const { driver } = await requireDriver(request);
            const action = status === 'Accepted' ? 'accept' : status === 'Picked Up' ? 'pickup' : status === 'Delivered' ? 'complete' : status === 'Pending' ? 'reject' : null;
            if (!action) throw new OperationsError('Unsupported driver delivery action.');
            const { data, error } = await supabase.rpc('driver_delivery_action', { p_delivery_id: uuid(id), p_driver_id: driver.id, p_action: action });
            if (error) throw new OperationsError(error.message, 409);
            return operationsJson(data);
        }
        if (status === 'Cancelled' || (status === 'Pending' && cancelled_by === 'timeout')) {
            const { data, error } = await supabase.rpc('cancel_delivery_offer', { p_delivery_id: uuid(id),
                p_reason: typeof cancellation_reason === 'string' ? cancellation_reason : 'Offer timed out', p_timeout: status === 'Pending' });
            if (error) throw new OperationsError(error.message, 409);
            return operationsJson(data);
        }
        throw new OperationsError('Use driver acceptance, pickup and completion actions; admin can cancel or expire offers.');
    } catch (err: unknown) {
        return operationsFailure(err);
    }
}
