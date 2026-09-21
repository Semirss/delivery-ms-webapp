import { NextRequest, NextResponse } from 'next/server';
import { isAdminRequest } from '@/lib/admin-auth';
import { getSupabaseAdmin } from '@/lib/supabase-admin';

export async function PATCH(
  request: NextRequest,
  context: { params: Promise<{ id: string }> },
) {
  if (!await isAdminRequest()) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }
  const { id } = await context.params;
  const body = await request.json();
  const update: Record<string, unknown> = {};
  if (body.name != null) update.name = String(body.name).trim();
  if (body.aliases != null) update.aliases = Array.isArray(body.aliases)
    ? body.aliases.map(String).map((item: string) => item.trim()).filter(Boolean)
    : String(body.aliases).split(',').map((item) => item.trim()).filter(Boolean);
  if (body.latitude != null) update.latitude = Number(body.latitude);
  if (body.longitude != null) update.longitude = Number(body.longitude);
  if (body.location_type != null) update.location_type = String(body.location_type);
  if (body.google_place_id !== undefined) {
    update.google_place_id = String(body.google_place_id ?? '').trim() || null;
  }
  if (body.search_priority != null) update.search_priority = Number(body.search_priority);
  if (body.is_active != null) update.is_active = Boolean(body.is_active);

  const supabase = await getSupabaseAdmin();
  const { data, error } = await supabase
    .from('addis_locations')
    .update(update)
    .eq('id', id)
    .select()
    .single();
  if (error) return NextResponse.json({ error: error.message }, { status: 500 });
  return NextResponse.json({ location: data });
}

export async function DELETE(
  _request: NextRequest,
  context: { params: Promise<{ id: string }> },
) {
  if (!await isAdminRequest()) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }
  const { id } = await context.params;
  const supabase = await getSupabaseAdmin();
  const { error } = await supabase
    .from('addis_locations')
    .update({ is_active: false })
    .eq('id', id);
  if (error) return NextResponse.json({ error: error.message }, { status: 500 });
  return NextResponse.json({ success: true });
}
