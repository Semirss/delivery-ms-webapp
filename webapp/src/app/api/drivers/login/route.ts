import { NextResponse } from 'next/server';
import { supabaseAdmin as supabase } from '@/lib/supabase-admin';

export async function POST(request: Request) {
    try {
        const { name, password } = await request.json();

        const { data, error } = await supabase
            .from('drivers')
            .select('*')
            .eq('name', name)
            .eq('password', password)
            .single();

        if (error || !data) {
            return NextResponse.json({ error: 'Invalid credentials' }, { status: 401 });
        }

        return NextResponse.json(data);
    } catch (err: any) {
        return NextResponse.json({ error: err.message }, { status: 500 });
    }
}
