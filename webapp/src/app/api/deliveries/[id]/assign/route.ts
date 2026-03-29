import { NextResponse } from 'next/server';
import { supabaseAdmin as supabase } from '@/lib/supabase-admin';

export async function POST(request: Request, context: { params: Promise<{ id: string }> }) {
    try {
        const { id } = await context.params;
        const { driver_id } = await request.json();

        const now = new Date().toISOString();

        const { data, error } = await supabase
            .from('deliveries')
            .update({ 
                driver_id, 
                status: 'Assigned',
                assigned_at: now,
                // Clear any previous cancellation record
                cancelled_by: null,
                cancellation_reason: null,
            })
            .eq('id', id)
            .select('*, driver:drivers(*)')
            .single();

        if (error) throw error;

        // Webhook call to notify the Telegram Bot
        const TELEGRAM_BOT_URL = process.env.TELEGRAM_BOT_URL;
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
        // Broadcast to all active driver/admin dashboards to re-fetch data
        try {
            await supabase.channel('deliveries-sync').send({
                type: 'broadcast',
                event: 'delivery_assigned',
                payload: {
                    delivery_id: data.id,
                    driver_id: data.driver_id,
                    status: data.status
                }
            });
        } catch (e) {
            console.error('Broadcast failed', e);
        }

        return NextResponse.json({ success: true, data });
    } catch (err: any) {
        return NextResponse.json({ error: err.message }, { status: 500 });
    }
}
