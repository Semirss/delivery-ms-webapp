import { NextResponse } from 'next/server';

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};

const recoveryDisabledMessage =
    'Password reset is handled by support after account ownership is verified.';

export async function OPTIONS() {
    return new NextResponse(null, { status: 204, headers: corsHeaders });
}

export async function POST() {
    return NextResponse.json(
        { error: recoveryDisabledMessage },
        { status: 403, headers: corsHeaders }
    );
}
