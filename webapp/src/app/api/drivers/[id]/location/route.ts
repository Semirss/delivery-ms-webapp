import { NextResponse } from 'next/server';
import { supabaseAdmin as supabase } from '@/lib/supabase-admin';

export async function PATCH(request: Request, context: { params: Promise<{ id: string }> }) {
    try {
        const { id } = await context.params;
        const body = await request.json();
        const { lat, lng } = body;

        if (typeof lat !== 'number' || typeof lng !== 'number') {
            return NextResponse.json({ error: "Invalid coordinates provided" }, { status: 400 });
        }

        const { data, error } = await supabase
            .from('drivers')
            .update({
                current_lat: lat,
                current_lng: lng,
                last_location_update: new Date().toISOString()
            })
            .eq('id', id)
            .select('id, current_lat, current_lng, last_location_update')
            .single();

        if (error) throw error;
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
    } catch (err: any) {
        return NextResponse.json({ error: err.message }, { status: 500 });
    }
}
