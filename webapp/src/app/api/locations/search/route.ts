import { NextRequest, NextResponse } from 'next/server';
import { getSupabaseAdmin } from '@/lib/supabase-admin';

type LocationResult = {
  id?: string;
  name: string;
  aliases: string[];
  latitude: number;
  longitude: number;
  location_type: string;
  source: string;
  google_place_id?: string | null;
};

const ADDIS_VIEWBOX = '38.62,9.12,38.92,8.82';

function resultLimit(value: string | null) {
  const parsed = Number.parseInt(value ?? '12', 10);
  return Math.min(Math.max(Number.isFinite(parsed) ? parsed : 12, 1), 30);
}

function validCoordinate(latitude: number, longitude: number) {
  return Number.isFinite(latitude) && Number.isFinite(longitude) &&
    latitude >= 8.75 && latitude <= 9.18 &&
    longitude >= 38.55 && longitude <= 39.02;
}

function dedupe(results: LocationResult[], limit: number) {
  const seen = new Set<string>();
  return results.filter((location) => {
    const key = `${location.latitude.toFixed(5)},${location.longitude.toFixed(5)}`;
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  }).slice(0, limit);
}

async function searchNominatim(query: string, limit: number): Promise<LocationResult[]> {
  if (!query) return [];
  try {
    const url = new URL('https://nominatim.openstreetmap.org/search');
    url.searchParams.set('q', `${query}, Addis Ababa, Ethiopia`);
    url.searchParams.set('format', 'jsonv2');
    url.searchParams.set('addressdetails', '1');
    url.searchParams.set('countrycodes', 'et');
    url.searchParams.set('bounded', '1');
    url.searchParams.set('viewbox', ADDIS_VIEWBOX);
    url.searchParams.set('limit', String(limit));

    const response = await fetch(url, {
      headers: {
        'User-Agent': 'MotoBikeDelivery/1.0 (motobikedeliveryservice.com)',
        Accept: 'application/json',
      },
      signal: AbortSignal.timeout(4500),
      next: { revalidate: 3600 },
    });
    if (!response.ok) return [];
    const rows = await response.json() as Array<Record<string, unknown>>;
    return rows.flatMap((row) => {
      const latitude = Number.parseFloat(String(row.lat ?? ''));
      const longitude = Number.parseFloat(String(row.lon ?? ''));
      if (!validCoordinate(latitude, longitude)) return [];
      const address = row.address && typeof row.address === 'object'
        ? row.address as Record<string, unknown>
        : {};
      const name = String(
        address.neighbourhood ?? address.suburb ?? address.quarter ??
        address.city_district ?? row.name ?? row.display_name ?? query,
      ).trim();
      return [{
        name,
        aliases: [],
        latitude,
        longitude,
        location_type: String(row.type ?? 'place'),
        source: 'osm_live',
      }];
    });
  } catch {
    return [];
  }
}

export async function GET(request: NextRequest) {
  const query = request.nextUrl.searchParams.get('q')?.trim() ?? '';
  const limit = resultLimit(request.nextUrl.searchParams.get('limit'));
  let databaseResults: LocationResult[] = [];

  try {
    const supabase = await getSupabaseAdmin();
    const { data, error } = await supabase.rpc('search_addis_locations', {
      search_query: query,
      result_limit: limit,
    });
    if (error) throw error;
    databaseResults = (data ?? []) as LocationResult[];
  } catch {
    // Keep the endpoint useful before/while the location migration is applied.
    try {
      const supabase = await getSupabaseAdmin();
      let requestBuilder = supabase
        .from('addis_locations')
        .select('id,name,aliases,latitude,longitude,location_type,source,google_place_id')
        .eq('is_active', true)
        .order('search_priority', { ascending: false })
        .limit(limit);
      if (query) requestBuilder = requestBuilder.ilike('name', `%${query}%`);
      const { data } = await requestBuilder;
      databaseResults = (data ?? []) as LocationResult[];
    } catch {
      databaseResults = [];
    }
  }

  const onlineResults = databaseResults.length >= limit
    ? []
    : await searchNominatim(query, limit - databaseResults.length);
  const locations = dedupe([...databaseResults, ...onlineResults], limit);

  return NextResponse.json(
    { locations, attribution: 'Location data © OpenStreetMap contributors' },
    { headers: { 'Cache-Control': 'public, max-age=60, stale-while-revalidate=3600' } },
  );
}
