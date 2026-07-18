import { NextResponse } from 'next/server';
import { getSupabaseAdmin } from '@/lib/supabase-admin';
import { errorMessage, isAdminRequest, slugify, toBoolean, toNullableText, toNullableUuid, toNumber, toRecord, toText } from '../../_utils';

export async function PATCH(request: Request, context: { params: Promise<{ id: string }> }) {
    const supabase = await getSupabaseAdmin();
    if (!isAdminRequest(request)) {
        return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    try {
        const { id } = await context.params;
        const input = toRecord(await request.json());
        const name = toText(input.name, 120);
        const payload: Record<string, unknown> = {
            description: toNullableText(input.description, 500),
            parent_id: toNullableUuid(input.parent_id),
            icon_name: toNullableText(input.icon_name, 80),
            sort_order: Math.trunc(toNumber(input.sort_order, 0)),
            is_active: toBoolean(input.is_active, true),
        };
        if (name) {
            payload.name = name;
            payload.slug = toText(input.slug, 100) || slugify(name);
        }

        const { data, error } = await supabase
            .from('food_categories')
            .update(payload)
            .eq('id', id)
            .select()
            .single();

        if (error) throw error;
        return NextResponse.json(data);
    } catch (err: unknown) {
        return NextResponse.json({ error: errorMessage(err, 'Invalid category update') }, { status: 400 });
    }
}

export async function DELETE(request: Request, context: { params: Promise<{ id: string }> }) {
    const supabase = await getSupabaseAdmin();
    if (!isAdminRequest(request)) {
        return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { id } = await context.params;
    const { error } = await supabase.from('food_categories').delete().eq('id', id);
    if (error) return NextResponse.json({ error: error.message }, { status: 500 });
    return NextResponse.json({ success: true });
}
