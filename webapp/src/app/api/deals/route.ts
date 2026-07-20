import { NextResponse } from 'next/server';
import { getSupabaseAdmin } from '@/lib/supabase-admin';
import { errorMessage, isAdminRequest, toBoolean, toNullableText, toNumber, toRecord, toText } from '../food/_utils';

export const dynamic = 'force-dynamic';
export const fetchCache = 'force-no-store';

const CARD_TYPES = new Set(['hero', 'grid']);

export async function GET(request: Request) {
    const supabase = await getSupabaseAdmin();
    const { searchParams } = new URL(request.url);
    const includeInactive = searchParams.get('includeInactive') === '1' && isAdminRequest(request);

    let query = supabase
        .from('app_deals')
        .select('*')
        .order('sort_order', { ascending: true })
        .order('created_at', { ascending: false });

    if (!includeInactive) query = query.eq('is_active', true);

    const { data, error } = await query;
    if (error) return NextResponse.json({ error: error.message }, { status: 500 });

    const now = Date.now();
    const rows = includeInactive ? data || [] : (data || []).filter((deal) => {
        const startsAt = deal.starts_at ? new Date(deal.starts_at).getTime() : null;
        const endsAt = deal.ends_at ? new Date(deal.ends_at).getTime() : null;
        return (startsAt == null || startsAt <= now) && (endsAt == null || endsAt >= now);
    });

    return NextResponse.json(rows);
}

export async function POST(request: Request) {
    const supabase = await getSupabaseAdmin();
    if (!isAdminRequest(request)) {
        return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    try {
        const input = toRecord(await request.json());
        const title = toText(input.title, 140);
        if (!title) throw new Error('Deal title is required');

        const payload = dealPayload(input, title);
        const { data, error } = await supabase
            .from('app_deals')
            .insert(payload)
            .select()
            .single();

        if (error) throw error;
        return NextResponse.json(data);
    } catch (err: unknown) {
        return NextResponse.json({ error: errorMessage(err, 'Invalid deal payload') }, { status: 400 });
    }
}

function dealPayload(input: Record<string, unknown>, title: string) {
    const cardType = toText(input.card_type, 20);
    return {
        title,
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
