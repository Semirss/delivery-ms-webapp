import { NextResponse } from 'next/server';
import { getSupabaseAdmin } from '@/lib/supabase-admin';
import { normalizeEthiopianPhone } from '@/lib/phone';

export const dynamic = 'force-dynamic';
export const fetchCache = 'force-no-store';

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Motobike-Account-Email, X-Motobike-Account-Phone',
};

export async function OPTIONS() {
    return new NextResponse(null, { status: 204, headers: corsHeaders });
}

export async function DELETE(request: Request, context: { params: Promise<{ id: string }> }) {
    const supabase = await getSupabaseAdmin();

    try {
        const { id } = await context.params;
        const accountEmail = request.headers.get('x-motobike-account-email')?.trim().toLowerCase() ?? '';
        const accountPhone = normalizeEthiopianPhone(request.headers.get('x-motobike-account-phone'));

        const { data: client, error: lookupError } = await supabase
            .from('clients')
            .select('id,email,phone')
            .eq('id', id)
            .maybeSingle();

        if (lookupError) throw lookupError;
        if (!client) {
            return NextResponse.json({ error: 'Client account not found' }, { status: 404, headers: corsHeaders });
        }

        const emailMatches = accountEmail && client.email?.toString().trim().toLowerCase() === accountEmail;
        const phoneMatches = accountPhone && normalizeEthiopianPhone(client.phone) === accountPhone;
        if ((accountEmail && !emailMatches) || (accountPhone && !phoneMatches)) {
            return NextResponse.json({ error: 'Account verification failed' }, { status: 403, headers: corsHeaders });
        }

        await supabase
            .from('app_notifications')
            .delete()
            .eq('app', 'client')
            .eq('recipient_id', id);

        await supabase
            .from('delivery_ratings')
            .delete()
            .or(`and(rater_type.eq.client,rater_id.eq.${id}),and(ratee_type.eq.client,ratee_id.eq.${id})`);

        const { error: deleteError } = await supabase
            .from('clients')
            .delete()
            .eq('id', id);

        if (deleteError) throw deleteError;

        return NextResponse.json({ success: true }, { headers: corsHeaders });
    } catch (err: unknown) {
        const message = err instanceof Error ? err.message : 'Unknown error';
        return NextResponse.json({ error: message }, { status: 500, headers: corsHeaders });
    }
}
