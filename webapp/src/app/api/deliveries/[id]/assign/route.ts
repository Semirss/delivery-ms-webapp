import { NextResponse } from 'next/server';
import { supabaseAdmin as supabase } from '@/lib/supabase-admin';

// A dynamic params API route in Next.js App Router
export async function POST(request: Request, context: { params: Promise<{ id: string }> }) {
    try {
        const { id } = await context.params;
        const { driver_id } = await request.json();

        const { data, error } = await supabase
            .from('deliveries')
            .update({ driver_id, status: 'Assigned' })
            .eq('id', id)
            .select('*, driver:drivers(*)')
            .single();

        if (error) throw error;

        // Webhook call to notify the Telegram Bot
        const TELEGRAM_BOT_URL = process.env.TELEGRAM_BOT_URL; // e.g., your python bot URL on Render
        if (TELEGRAM_BOT_URL) {
            try {
                await fetch(`${TELEGRAM_BOT_URL}/webhook/notify`, {
                    method: 'POST',
                    body: JSON.stringify(data),
                    headers: { 'Content-Type': 'application/json' }
                });
            } catch (e) {
                console.error("Failed to notify telegram webhook:", e);
            }
        }

        return NextResponse.json({ success: true, data });
    } catch (err: any) {
        return NextResponse.json({ error: err.message }, { status: 500 });
    }
}
