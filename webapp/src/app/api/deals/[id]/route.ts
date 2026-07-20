import { NextResponse } from 'next/server';
import { getSupabaseAdmin } from '@/lib/supabase-admin';
import { errorMessage, isAdminRequest, toBoolean, toNullableText, toNumber, toRecord, toText } from '../../food/_utils';

const CARD_TYPES = new Set(['hero', 'grid']);

export async function PATCH(request: Request, context: { params: Promise<{ id: string }> }) {
    const supabase = await getSupabaseAdmin();
    if (!isAdminRequest(request)) {
        return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    try {
        const { id } = await context.params;
        const input = toRecord(await request.json());
        const title = toText(input.title, 140);
        const payload = dealPayload(input);
        if (title) payload.title = title;

        const { data, error } = await supabase
            .from('app_deals')
            .update(payload)
            .eq('id', id)
            .select()
            .single();

        if (error) throw error;
        return NextResponse.json(data);
    } catch (err: unknown) {
        return NextResponse.json({ error: errorMessage(err, 'Invalid deal update') }, { status: 400 });
    }
}

export async function DELETE(request: Request, context: { params: Promise<{ id: string }> }) {
    const supabase = await getSupabaseAdmin();
    if (!isAdminRequest(request)) {
        return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { id } = await context.params;
    const { error } = await supabase.from('app_deals').delete().eq('id', id);
    if (error) return NextResponse.json({ error: error.message }, { status: 500 });
    return NextResponse.json({ success: true });
}

function dealPayload(input: Record<string, unknown>): Record<string, unknown> {
    const cardType = toText(input.card_type, 20);
    return {
        subtitle: toNullableText(input.subtitle, 220),
        body: toNullableText(input.body, 700),
        image_url: toNullableText(input.image_url, 2048),
        card_type: CARD_TYPES.has(cardType) ? cardType : 'grid',
        accent_color: colorValue(input.accent_color, '#f2644d'),
        text_color: colorValue(input.text_color, '#ffffff'),
        overlay_opacity: opacityValue(input.overlay_opacity),
        badge_text: toNullableText(input.badge_text, 80),
        cta_label: toNullableText(input.cta_label, 80),
        cta_url: toNullableText(input.cta_url, 2048),
        sort_order: Math.trunc(toNumber(input.sort_order, 0)),
        is_active: toBoolean(input.is_active, true),
        starts_at: dateValue(input.starts_at),
        ends_at: dateValue(input.ends_at),
    };
}

function colorValue(value: unknown, fallback: string) {
    const text = toText(value, 24);
    return /^#[0-9a-f]{6}$/i.test(text) ? text : fallback;
}

function opacityValue(value: unknown) {
    const parsed = toNumber(value, 0.55);
    return Math.min(0.95, Math.max(0, parsed));
}

function dateValue(value: unknown) {
    const text = toText(value, 80);
    if (!text) return null;
    const date = new Date(text);
    return Number.isNaN(date.getTime()) ? null : date.toISOString();
}
