import { NextResponse } from 'next/server';
import { getSupabaseAdmin } from '@/lib/supabase-admin';
import { requireDriver } from '@/lib/driver-session';
import { OperationsError, validatedLocation } from '@/lib/driver-operations';
import { operationsFailure } from '@/lib/operations-response';

export async function PATCH(request: Request, context: { params: Promise<{ id: string }> }) {
    const supabase = await getSupabaseAdmin();
    try {
        const { id } = await context.params;
        const { driver } = await requireDriver(request);
        if (driver.id !== id) throw new OperationsError('Driver account mismatch.',403);
        const body = await request.json();
        const fix = validatedLocation(body);

        const { data, error } = await supabase
            .from('drivers')
            .update(fix)
            .eq('id', id)
            .or(`last_location_update.is.null,last_location_update.lt.${fix.last_location_update}`)
            .select('id, current_lat, current_lng, last_location_update, location_accuracy_m')
            .maybeSingle();

        if (error) throw error;
        if (!data) return NextResponse.json({ id, ignored: true });
        try {
            await supabase.channel('deliveries-sync').send({
                type: 'broadcast',
                event: 'driver_location_updated',
                payload: {
                    driver_id: data.id,
                    current_lat: data.current_lat,
                    current_lng: data.current_lng
                }
            });
        } catch (e) {
            console.error('Broadcast failed', e);
        }
        return NextResponse.json(data);
    } catch (err: unknown) {
        return operationsFailure(err);
    }
}
