import { NextResponse } from 'next/server';
import { supabaseAdmin as supabase } from '@/lib/supabase-admin';
import { errorMessage, isAdminRequest, slugify, toBoolean, toNullableText, toNumber, toRecord, toText } from '../_utils';

export const dynamic = 'force-dynamic';
export const fetchCache = 'force-no-store';

export async function GET() {
    const { data, error } = await supabase
        .from('food_restaurants')
        .select('*')
        .order('is_featured', { ascending: false })
        .order('sort_order', { ascending: true })
        .order('name', { ascending: true });

    if (error) return NextResponse.json({ error: error.message }, { status: 500 });
    return NextResponse.json(data || []);
}

export async function POST(request: Request) {
    if (!isAdminRequest(request)) {
        return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    try {
        const input = toRecord(await request.json());
        const name = toText(input.name, 140);
        if (!name) throw new Error('Restaurant name is required');

        const payload = {
            name,
            slug: toText(input.slug, 120) || slugify(name),
            subtitle: toNullableText(input.subtitle, 240),
            phone: toNullableText(input.phone, 80),
            image_url: toNullableText(input.image_url, 2048),
            pickup_location: toNullableText(input.pickup_location, 500),
            pickup_lat: input.pickup_lat === null || input.pickup_lat === '' ? null : toNumber(input.pickup_lat, 0),
            pickup_lng: input.pickup_lng === null || input.pickup_lng === '' ? null : toNumber(input.pickup_lng, 0),
            is_featured: toBoolean(input.is_featured, false),
            is_active: toBoolean(input.is_active, true),
            sort_order: Math.trunc(toNumber(input.sort_order, 0)),
        };

        const { data, error } = await supabase
            .from('food_restaurants')
            .insert(payload)
            .select()
            .single();

        if (error) throw error;
        return NextResponse.json(data);
    } catch (err: unknown) {
        return NextResponse.json({ error: errorMessage(err, 'Invalid restaurant payload') }, { status: 400 });
    }
}
