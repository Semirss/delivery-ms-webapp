import { createHash } from 'node:crypto';
import { NextRequest, NextResponse } from 'next/server';
import { isAdminRequest } from '@/lib/admin-auth';
import { getSupabaseAdmin } from '@/lib/supabase-admin';

const maxFileBytes = 256 * 1024;
const maxLocations = 1000;

type ImportRow = {
  name: string;
  aliases: string[];
  latitude: number;
  longitude: number;
  location_type: string;
  source: string;
  source_license: string;
  external_id: string;
  search_priority: number;
  is_active: boolean;
};

function parseRow(line: string, lineNumber: number): ImportRow {
  const separator = line.includes('|') ? '|' : line.includes('\t') ? '\t' : ',';
  const parts = line.split(separator).map((part) => part.trim());
  const name = parts[0] ?? '';
  const latitude = Number(parts[1]);
  const longitude = Number(parts[2]);
  if (
    parts.length < 3 || !name || name.length > 150 ||
    !Number.isFinite(latitude) || latitude < 8.75 || latitude > 9.18 ||
    !Number.isFinite(longitude) || longitude < 38.55 || longitude > 39.02
  ) {
    throw new Error(`Line ${lineNumber}: use name | latitude | longitude | aliases with valid Addis Ababa coordinates.`);
  }
  const aliases = parts.slice(3).join(separator).split(/[,;]/)
    .map((alias) => alias.trim()).filter(Boolean);
  if (aliases.length > 20 || aliases.some((alias) => alias.length > 150)) {
    throw new Error(`Line ${lineNumber}: use at most 20 aliases of 150 characters each.`);
  }
  const identity = `${name.toLowerCase()}|${latitude}|${longitude}`;
  return {
    name,
    aliases: [...new Set(aliases)],
    latitude,
    longitude,
    location_type: 'neighbourhood',
    source: 'manual',
    source_license: 'Owner supplied',
    external_id: `admin-txt:${createHash('sha256').update(identity).digest('hex')}`,
    search_priority: 50,
    is_active: true,
  };
}

export async function POST(request: NextRequest) {
  if (!await isAdminRequest()) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }

  const text = await request.text();
  if (Buffer.byteLength(text, 'utf8') > maxFileBytes) {
    return NextResponse.json({ error: 'TXT file must be 256 KB or smaller.' }, { status: 413 });
  }

  const rows = new Map<string, ImportRow>();
  try {
    const lines = text.replace(/^\uFEFF/, '').split(/\r?\n/);
    for (const [index, rawLine] of lines.entries()) {
      const line = rawLine.trim();
      if (!line || line.startsWith('#')) continue;
      if (/^name\s*[,|\t]\s*(latitude|lat)\s*[,|\t]\s*(longitude|lng|lon)/i.test(line)) continue;
      const row = parseRow(line, index + 1);
      rows.set(row.external_id, row);
      if (rows.size > maxLocations) {
        throw new Error(`Import at most ${maxLocations} locations per file.`);
      }
    }
  } catch (error) {
    return NextResponse.json(
      { error: error instanceof Error ? error.message : 'Invalid TXT file.' },
      { status: 400 },
    );
  }
  if (rows.size === 0) {
    return NextResponse.json({ error: 'The TXT file has no locations.' }, { status: 400 });
  }

  const supabase = await getSupabaseAdmin();
  const { error } = await supabase.from('addis_locations')
    .upsert([...rows.values()], { onConflict: 'external_id' });
  if (error) return NextResponse.json({ error: error.message }, { status: 500 });
  return NextResponse.json({ imported: rows.size });
}
