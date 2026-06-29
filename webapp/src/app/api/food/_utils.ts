import { parse } from 'cookie';
import jwt from 'jsonwebtoken';

const JWT_SECRET = process.env.JWT_SECRET || 'fallback_secret_change_me_in_production_123';

export function isAdminRequest(request: Request) {
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

export function toRecord(value: unknown): Record<string, unknown> {
    return typeof value === 'object' && value !== null ? value as Record<string, unknown> : {};
}

export function toText(value: unknown, maxLength = 500) {
    return typeof value === 'string' ? value.trim().slice(0, maxLength) : '';
}

export function toNullableText(value: unknown, maxLength = 500) {
    const text = toText(value, maxLength);
    return text.length > 0 ? text : null;
}

export function toNullableUuid(value: unknown) {
    const text = toText(value, 80);
    return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(text)
        ? text
        : null;
}

export function toBoolean(value: unknown, fallback = false) {
    return typeof value === 'boolean' ? value : fallback;
}

export function toNumber(value: unknown, fallback = 0) {
    const parsed = typeof value === 'number' ? value : Number(value);
    return Number.isFinite(parsed) ? parsed : fallback;
}

export function slugify(value: string) {
    return value
        .toLowerCase()
        .replace(/[^a-z0-9]+/g, '-')
        .replace(/^-+|-+$/g, '')
        .slice(0, 80);
}

export function errorMessage(error: unknown, fallback: string) {
    return error instanceof Error ? error.message : fallback;
}

export function isMissingColumnError(error: unknown, column: string) {
    const message = errorMessage(error, '');
    return message.toLowerCase().includes(column.toLowerCase());
}
