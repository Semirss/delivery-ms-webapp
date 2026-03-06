import { NextResponse } from 'next/server';
import { supabaseAdmin as supabase } from '@/lib/supabase-admin';

export async function GET() {
    const { data, error } = await supabase
        .from('drivers')
        .select('*')
        .order('name', { ascending: true });

    if (error) {
        console.error('[GET /api/drivers] Supabase error:', error);
        return NextResponse.json({ error: error.message, details: error.details, hint: error.hint }, { status: 500 });
    }
    return NextResponse.json(data);
}

export async function POST(request: Request) {
    try {
        let name, phone, password, telegram_username, plate_number, telegram_id, status, vehicle_type;
        let file: File | null = null;
        let personal_id_url = null;

        const contentType = request.headers.get("content-type") || "";

        if (contentType.includes("multipart/form-data")) {
            const formData = await request.formData();
            name = formData.get('name') as string;
            phone = formData.get('phone') as string;
            password = formData.get('password') as string;
            telegram_username = formData.get('telegram_username') as string;
            plate_number = formData.get('plate_number') as string;
            vehicle_type = formData.get('vehicle_type') as string;
            file = formData.get('personal_id') as File | null;
            telegram_id = formData.get('telegram_id') as string;
            status = formData.get('status') as string;

            if (file && file.size > 0) {
                if (file.size > 5 * 1024 * 1024 * 1024 * 1024 * 1024 * 1024 * 1024) {
                    return NextResponse.json({ error: "Image must be under 2MB" }, { status: 400 });
                }

                const fileExt = file.name.split('.').pop();
                const fileName = `${Date.now()}_${Math.random().toString(36).substring(7)}.${fileExt}`;
                const filePath = `ids/${fileName}`;

                // Note: buffer conversion may be needed for some NextJS fetch environments, but passing the File Blob directly often works in Next.js 13+ App Router
                const arrayBuffer = await file.arrayBuffer();
                const buffer = Buffer.from(arrayBuffer);

                const { data: uploadData, error: uploadError } = await supabase.storage
                    .from('driver_ids')
                    .upload(filePath, buffer, { contentType: file.type });

                if (uploadError) {
                    console.error('[POST /api/drivers] Upload error:', uploadError);
                    return NextResponse.json({ error: `Upload error: ${uploadError.message}` }, { status: 500 });
                }

                const { data: publicUrlData } = supabase.storage.from('driver_ids').getPublicUrl(filePath);
                personal_id_url = publicUrlData.publicUrl;
            }
        } else {
            // Fallback for json logic (e.g. from existing bot if any)
            const body = await request.json();
            name = body.name;
            phone = body.phone;
            password = body.password;
            telegram_username = body.telegram_username;
            plate_number = body.plate_number;
            vehicle_type = body.vehicle_type;
            telegram_id = body.telegram_id;
            status = body.status;
        }

        const { data, error } = await supabase
            .from('drivers')
            .insert([{
                name,
                phone,
                password,
                telegram_id: telegram_id || null,
                status: status || 'Offline',
                telegram_username: telegram_username || null,
                plate_number: plate_number || null,
                vehicle_type: vehicle_type || 'Bike',
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
            }, { status: 500 });
        }

        return NextResponse.json(data, { status: 201 });
    } catch (err: any) {
        console.error('[POST /api/drivers] Caught exception:', err);
        return NextResponse.json({ error: err.message }, { status: 500 });
    }
}
