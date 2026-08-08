import { NextResponse } from 'next/server';
import { getSupabaseAdmin } from '@/lib/supabase-admin';
import { normalizeEthiopianPhone } from '@/lib/phone';

export const dynamic = 'force-dynamic';
export const fetchCache = 'force-no-store';

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};

export async function OPTIONS() {
    return new NextResponse(null, { status: 204, headers: corsHeaders });
}

export async function GET() {
    const supabase = await getSupabaseAdmin();
    const { data, error } = await supabase
        .from('drivers')
        .select('*')
        .order('name', { ascending: true });

    if (error) {
        console.error('[GET /api/drivers] Supabase error:', error);
        return NextResponse.json({ error: error.message, details: error.details, hint: error.hint }, { status: 500, headers: corsHeaders });
    }
    return NextResponse.json(data, { headers: corsHeaders });
}

export async function POST(request: Request) {
    const supabase = await getSupabaseAdmin();
    try {
        let name, email, phone, password, telegram_username, plate_number, telegram_id, status, vehicle_type;
        let file: File | null = null;
        let personal_id_url = null;

        const contentType = request.headers.get("content-type") || "";

        if (contentType.includes("multipart/form-data")) {
            const formData = await request.formData();
            name = formData.get('name') as string;
            email = formData.get('email') as string;
            phone = formData.get('phone') as string;
            password = formData.get('password') as string;
            telegram_username = formData.get('telegram_username') as string;
            plate_number = formData.get('plate_number') as string;
            vehicle_type = formData.get('vehicle_type') as string;
            file = formData.get('personal_id') as File | null;
            telegram_id = formData.get('telegram_id') as string;
            status = formData.get('status') as string;
        } else {
            // Fallback for json logic (e.g. from existing bot if any)
            const body = await request.json();
            name = body.name;
            email = body.email;
            phone = body.phone;
            password = body.password;
            telegram_username = body.telegram_username;
            plate_number = body.plate_number;
            vehicle_type = body.vehicle_type;
            telegram_id = body.telegram_id;
            status = body.status;
        }

        const normalizedName = typeof name === 'string' ? name.trim() : '';
        const normalizedEmail = typeof email === 'string' ? email.trim().toLowerCase() : '';
        const normalizedPhone = normalizeEthiopianPhone(phone);
        const normalizedPassword = typeof password === 'string' ? password : '';

        if (!normalizedName || !normalizedEmail || !normalizedPhone || !normalizedPassword) {
            return NextResponse.json(
                { error: 'Name, email, phone, and password are required' },
                { status: 400, headers: corsHeaders }
            );
        }

        const { data: existingEmail, error: existingEmailError } = await supabase
            .from('drivers')
            .select('id')
            .ilike('email', normalizedEmail)
            .maybeSingle();

        if (existingEmailError) {
            return NextResponse.json({ error: existingEmailError.message }, { status: 500, headers: corsHeaders });
        }

        if (existingEmail) {
            return NextResponse.json(
                { error: 'A driver account already exists for this email' },
                { status: 409, headers: corsHeaders }
            );
        }

        const { data: existingPhone, error: existingPhoneError } = await supabase
            .from('drivers')
            .select('id, phone')
            .not('phone', 'is', null);

        if (existingPhoneError) {
            return NextResponse.json({ error: existingPhoneError.message }, { status: 500, headers: corsHeaders });
        }

        if ((existingPhone ?? []).some((driver) => normalizeEthiopianPhone(driver.phone) === normalizedPhone)) {
            return NextResponse.json(
                { error: 'A driver account already exists for this phone number' },
                { status: 409, headers: corsHeaders }
            );
        }

        if (file && file.size > 0) {
            if (file.size > 5 * 1024 * 1024) {
                return NextResponse.json({ error: "Image must be under 5MB" }, { status: 400, headers: corsHeaders });
            }

            const fileExt = file.name.split('.').pop();
            const fileName = `${Date.now()}_${Math.random().toString(36).substring(7)}.${fileExt}`;
            const filePath = `ids/${fileName}`;

            const arrayBuffer = await file.arrayBuffer();
            const buffer = Buffer.from(arrayBuffer);

            const { error: uploadError } = await supabase.storage
                .from('driver_ids')
                .upload(filePath, buffer, { contentType: file.type });

            if (uploadError) {
                console.error('[POST /api/drivers] Upload error:', uploadError);
                return NextResponse.json({ error: `Upload error: ${uploadError.message}` }, { status: 500, headers: corsHeaders });
            }

            const { data: publicUrlData } = supabase.storage.from('driver_ids').getPublicUrl(filePath);
            personal_id_url = publicUrlData.publicUrl;
        }

        const { data, error } = await supabase
            .from('drivers')
            .insert([{
                name: normalizedName,
                email: normalizedEmail,
                phone: normalizedPhone,
                password: normalizedPassword,
                telegram_id: telegram_id || null,
                status: status || 'Offline',
                telegram_username: typeof telegram_username === 'string' ? telegram_username.trim() || null : null,
                plate_number: typeof plate_number === 'string' ? plate_number.trim() || null : null,
                vehicle_type: typeof vehicle_type === 'string' ? vehicle_type.trim() || 'Bike' : 'Bike',
                personal_id_url: personal_id_url || null
            }])
            .select()
            .single();

        if (error) {
            console.error('[POST /api/drivers] Supabase insert error:', JSON.stringify(error, null, 2));
            return NextResponse.json({
                error: error.message,
                details: error.details,
                hint: error.hint,
                code: error.code
            }, { status: 500, headers: corsHeaders });
        }

        try {
            await supabase.channel('deliveries-sync').send({
                type: 'broadcast',
                event: 'driver_created',
                payload: {
                    driver_id: data.id,
                    approval_status: data.approval_status
                }
            });
        } catch (e) {
            console.error('Broadcast failed', e);
        }

        return NextResponse.json(data, { status: 201, headers: corsHeaders });
    } catch (err: unknown) {
        const message = err instanceof Error ? err.message : 'Unknown error';
        console.error('[POST /api/drivers] Caught exception:', message);
        return NextResponse.json({ error: message }, { status: 500, headers: corsHeaders });
    }
}
