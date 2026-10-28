import { NextResponse } from 'next/server';
import { getSupabaseAdmin } from '@/lib/supabase-admin';
import { isAdminRequest } from '@/lib/admin-auth';
import { OperationsError, uuid } from '@/lib/driver-operations';
import { operationsFailure } from '@/lib/operations-response';

export async function POST(request: Request, context: { params: Promise<{ id: string }> }) {
    const supabase = await getSupabaseAdmin();
    try {
        if (!await isAdminRequest()) throw new OperationsError('Admin sign-in required.', 401);
        const { id } = await context.params;
        const { driver_id } = await request.json();

        const { data, error } = await supabase.rpc('assign_delivery_offer', {
            p_delivery_id: uuid(id), p_driver_id: uuid(driver_id),
        });

        if (error) throw new OperationsError(error.message, 409);

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
    } catch (err: unknown) {
        return operationsFailure(err);
    }
}
