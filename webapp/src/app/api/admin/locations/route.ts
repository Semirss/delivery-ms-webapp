import { NextRequest, NextResponse } from 'next/server';
import { isAdminRequest } from '@/lib/admin-auth';
import { getSupabaseAdmin } from '@/lib/supabase-admin';

function aliasesFrom(value: unknown) {
  if (Array.isArray(value)) {
    return value.map(String).map((item) => item.trim()).filter(Boolean);
  }
  return String(value ?? '').split(',').map((item) => item.trim()).filter(Boolean);
}

function coordinate(value: unknown, min: number, max: number) {
  const parsed = Number(value);
  return Number.isFinite(parsed) && parsed >= min && parsed <= max ? parsed : null;
}

export async function GET(request: NextRequest) {
  if (!await isAdminRequest()) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }
  const query = request.nextUrl.searchParams.get('q')?.trim() ?? '';
  const supabase = await getSupabaseAdmin();
  let builder = supabase
    .from('addis_locations')
    .select('*')
    .order('is_active', { ascending: false })
    .order('search_priority', { ascending: false })
    .order('name', { ascending: true })
    .limit(2000);
  if (query) builder = builder.ilike('search_text', `%${query}%`);
  const { data, error } = await builder;
  if (error) return NextResponse.json({ error: error.message }, { status: 500 });
  return NextResponse.json({ locations: data ?? [] });
}

export async function POST(request: NextRequest) {
  if (!await isAdminRequest()) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }
  const body = await request.json();
  const name = String(body.name ?? '').trim();
  const latitude = coordinate(body.latitude, 8.75, 9.18);
  const longitude = coordinate(body.longitude, 38.55, 39.02);
  if (!name || latitude == null || longitude == null) {
    return NextResponse.json(
      { error: 'A name and valid Addis Ababa coordinates are required.' },
      { status: 400 },
    );
  }

  const supabase = await getSupabaseAdmin();
  const { data, error } = await supabase.from('addis_locations').insert({
    name,
    aliases: aliasesFrom(body.aliases),
    latitude,
    longitude,
    location_type: String(body.location_type ?? 'neighbourhood'),
    source: 'manual',
    source_license: 'Owner supplied',
    google_place_id: String(body.google_place_id ?? '').trim() || null,
    search_priority: Number.parseInt(String(body.search_priority ?? '50'), 10) || 0,
    is_active: body.is_active !== false,
  }).select().single();
  if (error) return NextResponse.json({ error: error.message }, { status: 500 });
  return NextResponse.json({ location: data }, { status: 201 });
}
