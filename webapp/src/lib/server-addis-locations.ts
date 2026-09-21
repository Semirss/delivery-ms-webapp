import { getSupabaseAdmin } from '@/lib/supabase-admin';

export async function findAddisLocation(value: unknown) {
  const query = typeof value === 'string' ? value.trim() : '';
  if (!query) return null;
  try {
    const supabase = await getSupabaseAdmin();
    const { data, error } = await supabase.rpc('search_addis_locations', {
      search_query: query,
      result_limit: 1,
    });
    if (error || !data?.[0]) return null;
    const row = data[0];
    return {
      name: String(row.name),
      lat: Number(row.latitude),
      lng: Number(row.longitude),
    };
  } catch {
    return null;
  }
}
