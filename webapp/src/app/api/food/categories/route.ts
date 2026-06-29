import { NextResponse } from 'next/server';
import { supabaseAdmin as supabase } from '@/lib/supabase-admin';
import { errorMessage, isAdminRequest, slugify, toBoolean, toNullableText, toNullableUuid, toNumber, toRecord, toText } from '../_utils';

export const dynamic = 'force-dynamic';
export const fetchCache = 'force-no-store';

export async function GET() {
    const { data, error } = await supabase
        .from('food_categories')
        .select('*')
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
        const name = toText(input.name, 120);
        if (!name) throw new Error('Category name is required');

        const payload = {
            name,
            slug: toText(input.slug, 100) || slugify(name),
            description: toNullableText(input.description, 500),
            parent_id: toNullableUuid(input.parent_id),
            icon_name: toNullableText(input.icon_name, 80),
            sort_order: Math.trunc(toNumber(input.sort_order, 0)),
            is_active: toBoolean(input.is_active, true),
        };

        const { data, error } = await supabase
            .from('food_categories')
            .insert(payload)
            .select()
            .single();

        if (error) throw error;
        return NextResponse.json(data);
    } catch (err: unknown) {
        return NextResponse.json({ error: errorMessage(err, 'Invalid category payload') }, { status: 400 });
    }
}
