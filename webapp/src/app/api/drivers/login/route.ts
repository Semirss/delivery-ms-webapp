import { NextResponse } from 'next/server';
import { getSupabaseAdmin } from '@/lib/supabase-admin';

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};

export async function OPTIONS() {
    return new NextResponse(null, { status: 204, headers: corsHeaders });
}

export async function POST(request: Request) {
    const supabase = await getSupabaseAdmin();
    try {
        const { name, password } = await request.json();

        const { data, error } = await supabase
            .from('drivers')
            .select('*')
            .eq('name', name)
            .eq('password', password)
            .single();

        if (error || !data) {
            return NextResponse.json({ error: 'Invalid credentials' }, { status: 401, headers: corsHeaders });
        }

        return NextResponse.json(data, { headers: corsHeaders });
    } catch (err: unknown) {
        const message = err instanceof Error ? err.message : 'Unknown error';
        return NextResponse.json({ error: message }, { status: 500, headers: corsHeaders });
    }
}
