import { NextResponse } from 'next/server';
import { supabaseAdmin as supabase } from '@/lib/supabase-admin';
import { errorMessage, isAdminRequest, isMissingColumnError, toBoolean, toNullableText, toNullableUuid, toNumber, toRecord, toText } from '../_utils';

export const dynamic = 'force-dynamic';
export const fetchCache = 'force-no-store';

export async function GET(request: Request) {
    const { searchParams } = new URL(request.url);
    const hasPagination = searchParams.has('page') || searchParams.has('pageSize') || searchParams.has('restaurant_id');
    const page = Math.max(1, Number(searchParams.get('page') || '1') || 1);
    const pageSize = Math.min(50, Math.max(1, Number(searchParams.get('pageSize') || '12') || 12));
    const restaurantId = searchParams.get('restaurant_id')?.trim();

    let query = supabase
        .from('food_marketplace_items')
        .select('*, category:food_categories(name), restaurant:food_restaurants(name)', hasPagination ? { count: 'exact' } : undefined)
        .order('is_featured', { ascending: false })
        .order('sort_order', { ascending: true })
        .order('created_at', { ascending: false });

    if (restaurantId) query = query.eq('restaurant_id', restaurantId);
    if (hasPagination) {
        const from = (page - 1) * pageSize;
        query = query.range(from, from + pageSize - 1);
    }

    const { data, error, count } = await query;

    if (error) return NextResponse.json({ error: error.message }, { status: 500 });
    if (!hasPagination) return NextResponse.json(data || []);

    const { data: countRows } = await supabase
        .from('food_marketplace_items')
        .select('restaurant_id');
    const countsByRestaurant: Record<string, number> = {};
    for (const row of countRows || []) {
        const id = row.restaurant_id;
        if (!id) continue;
        countsByRestaurant[id] = (countsByRestaurant[id] || 0) + 1;
    }

    const total = count || 0;
    return NextResponse.json({
        data: data || [],
        page,
        pageSize,
        total,
        totalPages: Math.max(1, Math.ceil(total / pageSize)),
        countsByRestaurant,
    });
}

export async function POST(request: Request) {
    if (!isAdminRequest(request)) {
        return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    try {
        const input = toRecord(await request.json());
        const title = toText(input.title, 180);
        const sellerName = toText(input.seller_name, 140);
        const sellerPhone = toText(input.seller_phone, 80);
        if (!title) throw new Error('Food title is required');
        if (!sellerName || !sellerPhone) throw new Error('Seller name and phone are required');

        const payload = {
            title,
            description: toNullableText(input.description, 1000),
            price: toNumber(input.price, 0),
            image_url: toNullableText(input.image_url, 2048),
            seller_name: sellerName,
            seller_phone: sellerPhone,
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
            .insert(payload)
            .select('*, category:food_categories(name), restaurant:food_restaurants(name)')
            .single();

        if (error && isMissingColumnError(error, 'restaurant_name')) {
            const fallbackPayload = Object.fromEntries(
                Object.entries(payload).filter(([key]) => key !== 'restaurant_name')
            );
            const fallback = await supabase
                .from('food_marketplace_items')
                .insert(fallbackPayload)
                .select('*, category:food_categories(name), restaurant:food_restaurants(name)')
                .single();
            data = fallback.data;
            error = fallback.error;
        }

        if (error) throw error;
        return NextResponse.json(data);
    } catch (err: unknown) {
        return NextResponse.json({ error: errorMessage(err, 'Invalid food item payload') }, { status: 400 });
    }
}
