import { NextResponse } from 'next/server';
import { getSupabaseAdmin } from '@/lib/supabase-admin';
import { errorMessage, isAdminRequest } from '../_utils';

export const dynamic = 'force-dynamic';
export const fetchCache = 'force-no-store';

const MAX_IMAGE_SIZE = 6 * 1024 * 1024;
const ALLOWED_TYPES = new Set(['image/jpeg', 'image/png', 'image/webp']);

export async function POST(request: Request) {
    const supabase = await getSupabaseAdmin();
    if (!isAdminRequest(request)) {
        return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    try {
        const formData = await request.formData();
        const file = formData.get('image');
        if (!(file instanceof File) || file.size === 0) {
            throw new Error('Image file is required');
        }
        if (file.size > MAX_IMAGE_SIZE) {
            throw new Error('Image must be under 6MB');
        }
        if (!ALLOWED_TYPES.has(file.type)) {
            throw new Error('Use a JPG, PNG, or WebP image');
        }

        const extension = extensionFor(file.type);
        const fileName = `${Date.now()}_${crypto.randomUUID()}.${extension}`;
        const filePath = `admin/${fileName}`;
        const buffer = Buffer.from(await file.arrayBuffer());
        const { error: uploadError } = await supabase.storage
            .from('food_images')
            .upload(filePath, buffer, {
                contentType: file.type,
                cacheControl: '3600',
                upsert: false,
            });

        if (uploadError) throw uploadError;

        const { data } = supabase.storage.from('food_images').getPublicUrl(filePath);
        return NextResponse.json({ url: data.publicUrl });
    } catch (err: unknown) {
        return NextResponse.json({ error: errorMessage(err, 'Could not upload image') }, { status: 400 });
    }
}

function extensionFor(contentType: string) {
    if (contentType === 'image/png') return 'png';
    if (contentType === 'image/webp') return 'webp';
    return 'jpg';
}
