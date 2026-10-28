import { NextResponse } from 'next/server';
import { OperationsError } from './driver-operations';

export const operationsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PATCH, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  'Cache-Control': 'no-store',
};
export function operationsJson(data: unknown, status = 200) {
  return NextResponse.json(data, { status, headers: operationsHeaders });
}
export function operationsFailure(error: unknown, fallback = 'Driver operations are unavailable. Try again or contact dispatch.') {
  if (error instanceof OperationsError) return operationsJson({ error: error.message }, error.status);
  console.error('[driver operations]', error);
  return operationsJson({ error: fallback }, 500);
}
export function operationsOptions() { return new NextResponse(null, { status: 204, headers: operationsHeaders }); }
