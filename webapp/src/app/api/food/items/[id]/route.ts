import { NextResponse } from 'next/server';
import { getSupabaseAdmin } from '@/lib/supabase-admin';
import { errorMessage, isAdminRequest, isMissingColumnError, toBoolean, toNullableText, toNullableUuid, toNumber, toRecord, toText } from '../../_utils';

export async function PATCH(request: Request, context: { params: Promise<{ id: string }> }) {
    const supabase = await getSupabaseAdmin();
    if (!isAdminRequest(request)) {
        return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    try {
        const { id } = await context.params;
        const input = toRecord(await request.json());
        const payload = {
            title: toText(input.title, 180),
            description: toNullableText(input.description, 1000),
            price: toNumber(input.price, 0),
            image_url: toNullableText(input.image_url, 2048),
            seller_name: toText(input.seller_name, 140),
            seller_phone: toText(input.seller_phone, 80),
            pickup_location: toNullableText(input.pickup_location, 500),
            pickup_lat: input.pickup_lat === null || input.pickup_lat === '' ? null : toNumber(input.pickup_lat, 0),
            pickup_lng: input.pickup_lng === null || input.pickup_lng === '' ? null : toNumber(input.pickup_lng, 0),
            category_id: toNullableUuid(input.category_id),
            restaurant_id: toNullableUuid(input.restaurant_id),
            restaurant_name: toNullableText(input.restaurant_name, 140),
            source_type: toText(input.source_type, 40) || 'admin',
            is_featured: toBoolean(input.is_featured, false),
            is_active: toBoolean(input.is_active, true),
            sort_order: Math.trunc(toNumber(input.sort_order, 0)),
        };

        let { data, error } = await supabase
            .from('food_marketplace_items')
            .update(payload)
            .eq('id', id)
            .select('*, category:food_categories(name), restaurant:food_restaurants(name)')
            .single();

        if (error && isMissingColumnError(error, 'restaurant_name')) {
            const fallbackPayload = Object.fromEntries(
                Object.entries(payload).filter(([key]) => key !== 'restaurant_name')
            );
            const fallback = await supabase
                .from('food_marketplace_items')
                .update(fallbackPayload)
                .eq('id', id)
                .select('*, category:food_categories(name), restaurant:food_restaurants(name)')
                .single();
            data = fallback.data;
            error = fallback.error;
        }

        if (error) throw error;
        return NextResponse.json(data);
    } catch (err: unknown) {
        return NextResponse.json({ error: errorMessage(err, 'Invalid food item update') }, { status: 400 });
    }
}

export async function DELETE(request: Request, context: { params: Promise<{ id: string }> }) {
    const supabase = await getSupabaseAdmin();
    if (!isAdminRequest(request)) {
        return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { id } = await context.params;
    const { error } = await supabase.from('food_marketplace_items').delete().eq('id', id);
    if (error) return NextResponse.json({ error: error.message }, { status: 500 });
    return NextResponse.json({ success: true });
}
