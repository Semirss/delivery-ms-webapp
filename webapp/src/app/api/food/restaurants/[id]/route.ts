import { NextResponse } from 'next/server';
import { findAddisNeighborhood } from '@/lib/addis-locations';
import { getSupabaseAdmin } from '@/lib/supabase-admin';
import { errorMessage, isAdminRequest, slugify, toBoolean, toNullableText, toNumber, toRecord, toText } from '../../_utils';

export async function PATCH(request: Request, context: { params: Promise<{ id: string }> }) {
    const supabase = await getSupabaseAdmin();
    if (!isAdminRequest(request)) {
        return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    try {
        const { id } = await context.params;
        const input = toRecord(await request.json());
        const name = toText(input.name, 140);
        const pickupLocation = toNullableText(input.pickup_location, 500);
        const resolvedLocation = findAddisNeighborhood(pickupLocation || name);
        const hasPickupLat = input.pickup_lat !== null && input.pickup_lat !== '' && input.pickup_lat !== undefined;
        const hasPickupLng = input.pickup_lng !== null && input.pickup_lng !== '' && input.pickup_lng !== undefined;
        const payload: Record<string, unknown> = {
            subtitle: toNullableText(input.subtitle, 240),
            phone: toNullableText(input.phone, 80),
            image_url: toNullableText(input.image_url, 2048),
            pickup_location: pickupLocation || resolvedLocation?.name || null,
            pickup_lat: hasPickupLat ? toNumber(input.pickup_lat, 0) : resolvedLocation?.lat ?? null,
            pickup_lng: hasPickupLng ? toNumber(input.pickup_lng, 0) : resolvedLocation?.lng ?? null,
            is_featured: toBoolean(input.is_featured, false),
            is_active: toBoolean(input.is_active, true),
            sort_order: Math.trunc(toNumber(input.sort_order, 0)),
        };
        if (name) {
            payload.name = name;
            payload.slug = toText(input.slug, 120) || slugify(name);
        }

        const { data, error } = await supabase
            .from('food_restaurants')
            .update(payload)
            .eq('id', id)
            .select()
            .single();

        if (error) throw error;
        return NextResponse.json(data);
    } catch (err: unknown) {
        return NextResponse.json({ error: errorMessage(err, 'Invalid restaurant update') }, { status: 400 });
    }
}

export async function DELETE(request: Request, context: { params: Promise<{ id: string }> }) {
    const supabase = await getSupabaseAdmin();
    if (!isAdminRequest(request)) {
        return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { id } = await context.params;
    const { error } = await supabase.from('food_restaurants').delete().eq('id', id);
    if (error) return NextResponse.json({ error: error.message }, { status: 500 });
    return NextResponse.json({ success: true });
}
