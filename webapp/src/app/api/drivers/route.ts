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
        const body = await request.json();
        console.log('[POST /api/drivers] Request body:', body);

        const { name, phone, password, telegram_id, status } = body;

        const { data, error } = await supabase
            .from('drivers')
            .insert([{ name, phone, password, telegram_id: telegram_id || null, status: status || 'Offline' }])
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
