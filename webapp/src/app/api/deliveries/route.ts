import { NextResponse } from 'next/server';
import { supabaseAdmin as supabase } from '@/lib/supabase-admin';

export const dynamic = 'force-dynamic';
export const fetchCache = 'force-no-store';

export async function GET(request: Request) {
    const { searchParams } = new URL(request.url);
    const driver_id = searchParams.get('driver_id');
    const customer_phone = searchParams.get('customer_phone');

    let query = supabase
        .from('deliveries')
        .select('*, driver:drivers(name, phone, telegram_id, vehicle_type, current_lat, current_lng)')
        .order('created_at', { ascending: false });

    if (driver_id) query = query.eq('driver_id', driver_id);
    if (customer_phone) query = query.eq('customer_phone', customer_phone);

    const { data, error } = await query;

    if (error) return NextResponse.json({ error: error.message }, { status: 500 });
    return NextResponse.json(data);
}

export async function POST(request: Request) {
    try {
        const body = await request.json();
        const {
            customer_name,
            customer_phone,
            pickup_location,
            dropoff_location,
            package_type,
            delivery_fee,
            vehicle_category,
            pickup_lat,
            pickup_lng,
            dropoff_lat,
            dropoff_lng,
        } = body;

        const insertPayload = {
            customer_name,
            customer_phone,
            pickup_location,
            dropoff_location,
            package_type,
            delivery_fee: delivery_fee ?? null,
            vehicle_category: vehicle_category ?? null,
            pickup_lat: pickup_lat ?? null,
            pickup_lng: pickup_lng ?? null,
            dropoff_lat: dropoff_lat ?? null,
            dropoff_lng: dropoff_lng ?? null,
        };

        const { data, error } = await supabase
            .from('deliveries')
            .insert([insertPayload])
            .select()
            .single();

        if (error) {
            console.error('[POST /api/deliveries] Supabase error:', JSON.stringify(error));
            throw new Error(error.message);
        }

        // Broadcast so drivers re-fetch immediately
        try {
            await supabase.channel('deliveries-sync').send({
                type: 'broadcast',
                event: 'delivery_created',
                payload: {
                    delivery_id: data.id,
                    customer_name: data.customer_name,
                    created_at: data.created_at,
                },
            });
        } catch (e) {
            console.error('Broadcast failed', e);
        }

        return NextResponse.json(data, { status: 201 });
    } catch (err: any) {
        console.error('[POST /api/deliveries] Error:', err?.message ?? err);
        return NextResponse.json({ error: err?.message ?? 'Unknown error' }, { status: 500 });
    }
}
