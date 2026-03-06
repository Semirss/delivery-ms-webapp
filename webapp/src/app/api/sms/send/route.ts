import { NextResponse } from 'next/server';

export async function POST(request: Request) {
    try {
        const body = await request.json();
        const { phone, message } = body;

        console.log(`[SMS Gateway] Sending SMS to ${phone} with message: "${message}"`);

        // This is a placeholder for your Android SMS Gateway logic.
        // You would typically make a fetch call here to your actual Android Gateway endpoint.
        // Example:
        // const response = await fetch('http://your-android-gateway-ip:8080/v1/sms/send', {
        //     method: 'POST',
        //     headers: { 'Content-Type': 'application/json' },
        //     body: JSON.stringify({ to: phone, message })
        // });
        // if (!response.ok) throw new Error("Gateway failed to send");

        return NextResponse.json({ success: true, message: "SMS dispatched to gateway" });
    } catch (error: any) {
        console.error('[POST /api/sms/send] Error:', error);
        return NextResponse.json({ error: error.message }, { status: 500 });
    }
}
