import { NextResponse } from 'next/server';

const TELEGRAM_BOT_TOKEN = process.env.TELEGRAM_BOT_TOKEN;

export async function POST(request: Request) {
    try {
        const { telegram_id, message } = await request.json();

        if (!telegram_id) {
            return NextResponse.json({ error: 'Missing telegram_id' }, { status: 400 });
        }

        // Call Telegram API directly to send the message
        const telegramUrl = `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage`;
        const res = await fetch(telegramUrl, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
                chat_id: telegram_id.replace('@', ''), // Handle raw chat IDs
                text: message
            })
        });

        if (!res.ok) {
            let errResponse;
            try {
                errResponse = await res.json();
            } catch (e) {
                errResponse = await res.text();
            }
            console.error("Telegram Webhook Error:", errResponse);
            return NextResponse.json({ error: 'Failed to send telegram message', details: errResponse }, { status: 500 });
        }

        return NextResponse.json({ success: true });
    } catch (err: any) {
        return NextResponse.json({ error: err.message }, { status: 500 });
    }
}
