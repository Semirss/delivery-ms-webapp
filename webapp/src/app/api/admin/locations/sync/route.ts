import { NextRequest, NextResponse } from 'next/server';
import { isAdminRequest } from '@/lib/admin-auth';
import { getSupabaseAdmin } from '@/lib/supabase-admin';

type OverpassElement = {
  id: number;
  type: 'node' | 'way' | 'relation';
  lat?: number;
  lon?: number;
  center?: { lat?: number; lon?: number };
  tags?: Record<string, string>;
};

type SyncedLocation = {
  id: string;
  name: string;
  google_place_id: string | null;
};

const OVERPASS_QUERY = `
[out:json][timeout:90];
(
  nwr["place"~"^(neighbourhood|suburb|quarter|locality|village)$"]["name"](8.75,38.55,9.18,39.02);
  nwr["boundary"="administrative"]["admin_level"~"^(9|10|11)$"]["name"](8.75,38.55,9.18,39.02);
);
out center tags;
`;

function chunk<T>(items: T[], size: number) {
  const output: T[][] = [];
  for (let index = 0; index < items.length; index += size) {
    output.push(items.slice(index, index + size));
  }
  return output;
}

function osmRows(elements: OverpassElement[]) {
  const seen = new Set<string>();
  return elements.flatMap((element) => {
    const tags = element.tags ?? {};
    const name = (tags['name:en'] || tags.name || '').trim();
    const latitude = element.lat ?? element.center?.lat;
    const longitude = element.lon ?? element.center?.lon;
    const externalId = `osm:${element.type}:${element.id}`;
    if (!name || latitude == null || longitude == null || seen.has(externalId)) return [];
    seen.add(externalId);
    const aliases = [tags.name, tags['name:am'], tags['alt_name'], tags['short_name']]
      .filter((value): value is string => Boolean(value?.trim()))
      .filter((value, index, values) =>
        value.toLowerCase() !== name.toLowerCase() && values.indexOf(value) === index,
      );
    return [{
      name,
      aliases,
      latitude,
      longitude,
      location_type: tags.place || `admin_level_${tags.admin_level || 'unknown'}`,
      source: 'openstreetmap',
      source_license: 'ODbL 1.0 © OpenStreetMap contributors',
      external_id: externalId,
      source_updated_at: new Date().toISOString(),
      metadata: {
        osm_type: element.type,
        osm_id: element.id,
        wikidata: tags.wikidata || null,
      },
      is_active: true,
    }];
  });
}

async function googlePlaceId(name: string, apiKey: string) {
  try {
    const response = await fetch('https://places.googleapis.com/v1/places:searchText', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': apiKey,
        // Place IDs are the only Google Places field persisted by this app.
        'X-Goog-FieldMask': 'places.id',
      },
      body: JSON.stringify({
        textQuery: `${name}, Addis Ababa, Ethiopia`,
        pageSize: 1,
        locationBias: {
          rectangle: {
            low: { latitude: 8.75, longitude: 38.55 },
            high: { latitude: 9.18, longitude: 39.02 },
          },
        },
      }),
      signal: AbortSignal.timeout(7000),
    });
    if (!response.ok) return null;
    const payload = await response.json() as { places?: Array<{ id?: string }> };
    return payload.places?.[0]?.id?.trim() || null;
  } catch {
    return null;
  }
}

export async function POST(request: NextRequest) {
  if (!await isAdminRequest()) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }

  const body = await request.json().catch(() => ({})) as Record<string, unknown>;
  const validateGoogle = body.validate_google === true;
  const googleLimit = Math.min(Math.max(Number(body.google_limit) || 25, 1), 100);

  const overpassResponse = await fetch('https://overpass-api.de/api/interpreter', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8',
      'User-Agent': 'MotoBikeDelivery/1.0 (motobikedeliveryservice.com)',
    },
    body: new URLSearchParams({ data: OVERPASS_QUERY }),
    signal: AbortSignal.timeout(100000),
    cache: 'no-store',
  });
  if (!overpassResponse.ok) {
    return NextResponse.json(
      { error: `OpenStreetMap sync failed (${overpassResponse.status}). Try again shortly.` },
      { status: 502 },
    );
  }

  const payload = await overpassResponse.json() as { elements?: OverpassElement[] };
  const rows = osmRows(payload.elements ?? []);
  const supabase = await getSupabaseAdmin();
  const synced: SyncedLocation[] = [];

  for (const rowsChunk of chunk(rows, 250)) {
    const { data, error } = await supabase
      .from('addis_locations')
      .upsert(rowsChunk, { onConflict: 'external_id' })
      .select('id,name,google_place_id');
    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 });
    }
    synced.push(...((data ?? []) as SyncedLocation[]));
  }

  // Prefer newly synced OSM records over starter rows with the same name.
  for (const nameChunk of chunk(rows.map((row) => row.name), 100)) {
    await supabase
      .from('addis_locations')
      .update({ is_active: false })
      .eq('source', 'curated')
      .in('name', nameChunk);
  }

  let googleValidated = 0;
  const googleApiKey = process.env.GOOGLE_MAPS_API_KEY?.trim() ?? '';
  if (validateGoogle && googleApiKey) {
    const candidates = synced
      .filter((location) => !location.google_place_id)
      .slice(0, googleLimit);
    for (const candidateChunk of chunk(candidates, 5)) {
      await Promise.all(candidateChunk.map(async (location) => {
        const placeId = await googlePlaceId(location.name, googleApiKey);
        if (!placeId) return;
        const { error } = await supabase
          .from('addis_locations')
          .update({ google_place_id: placeId })
          .eq('id', location.id);
        if (!error) googleValidated += 1;
      }));
    }
  }

  return NextResponse.json({
    discovered: rows.length,
    synced: synced.length,
    google_validated: googleValidated,
    google_validation_available: Boolean(googleApiKey),
    attribution: 'Location data © OpenStreetMap contributors (ODbL 1.0)',
  });
}
