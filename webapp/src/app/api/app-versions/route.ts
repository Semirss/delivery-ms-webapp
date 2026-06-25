import { NextResponse } from 'next/server';
import { parse } from 'cookie';
import jwt from 'jsonwebtoken';
import { supabaseAdmin as supabase } from '@/lib/supabase-admin';

export const dynamic = 'force-dynamic';
export const fetchCache = 'force-no-store';

const JWT_SECRET = process.env.JWT_SECRET || 'fallback_secret_change_me_in_production_123';
const APPS = new Set(['client', 'driver']);
const PLATFORMS = new Set(['android', 'ios']);

type VersionPayload = {
    app: string;
    platform: string;
    minimum_build: number;
    latest_build: number;
    latest_version: string;
    force_update: boolean;
    update_url: string;
    release_notes: string;
    maintenance_mode: boolean;
    maintenance_message: string;
};

function isAdminRequest(request: Request) {
    const cookieHeader = request.headers.get('cookie') || '';
    const token = parse(cookieHeader).admin_token;
    if (!token) return false;

    try {
        jwt.verify(token, JWT_SECRET);
        return true;
    } catch {
        return false;
    }
}

function toPositiveInteger(value: unknown, field: string) {
    const parsed = typeof value === 'number' ? value : Number(value);
    if (!Number.isInteger(parsed) || parsed < 1) {
        throw new Error(`${field} must be a positive integer`);
    }
    return parsed;
}

function toStringValue(value: unknown, maxLength: number) {
    const text = typeof value === 'string' ? value.trim() : '';
    return text.slice(0, maxLength);
}

function toRecord(value: unknown): Record<string, unknown> {
    return typeof value === 'object' && value !== null ? value as Record<string, unknown> : {};
}

function errorMessage(error: unknown, fallback: string) {
    return error instanceof Error ? error.message : fallback;
}

function validatePayload(body: unknown): VersionPayload {
    const input = toRecord(body);
    const app = toStringValue(input.app, 20);
    const platform = toStringValue(input.platform, 20);

    if (!APPS.has(app)) {
        throw new Error('app must be either client or driver');
    }
    if (!PLATFORMS.has(platform)) {
        throw new Error('platform must be either android or ios');
    }

    const minimumBuild = toPositiveInteger(input.minimum_build, 'minimum_build');
    const latestBuild = toPositiveInteger(input.latest_build, 'latest_build');

    if (latestBuild < minimumBuild) {
        throw new Error('latest_build must be greater than or equal to minimum_build');
    }

    return {
        app,
        platform,
        minimum_build: minimumBuild,
        latest_build: latestBuild,
        latest_version: toStringValue(input.latest_version, 40) || '1.0.0',
        force_update: Boolean(input.force_update),
        update_url: toStringValue(input.update_url, 2048),
        release_notes: toStringValue(input.release_notes, 1000),
        maintenance_mode: Boolean(input.maintenance_mode),
        maintenance_message: toStringValue(input.maintenance_message, 500),
    };
}

export async function GET(request: Request) {
    const { searchParams } = new URL(request.url);
    const app = searchParams.get('app');
    const platform = searchParams.get('platform');

    let query = supabase
        .from('app_versions')
        .select('*')
        .order('app', { ascending: true })
        .order('platform', { ascending: true });

    if (app) query = query.eq('app', app);
    if (platform) query = query.eq('platform', platform);

    const { data, error } = await query;

    if (error) {
        console.error('[GET /api/app-versions] Supabase error:', error);
        return NextResponse.json({ error: error.message }, { status: 500 });
    }

    return NextResponse.json(data || []);
}

export async function PATCH(request: Request) {
    if (!isAdminRequest(request)) {
        return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    try {
        const payload = validatePayload(await request.json());
        const now = new Date().toISOString();

        const { data, error } = await supabase
            .from('app_versions')
            .upsert({ ...payload, updated_at: now }, { onConflict: 'app,platform' })
            .select()
            .single();

        if (error) {
            console.error('[PATCH /api/app-versions] Supabase error:', error);
            throw error;
        }

        return NextResponse.json(data);
    } catch (err: unknown) {
        return NextResponse.json({ error: errorMessage(err, 'Invalid app version payload') }, { status: 400 });
    }
}
