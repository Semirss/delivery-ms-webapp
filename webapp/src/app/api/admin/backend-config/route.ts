import { NextResponse } from 'next/server'
export async function GET() {
  return NextResponse.json({ error: 'Backend switching is disabled.' }, { status: 410 })
}

export async function PATCH() {
  return NextResponse.json({ error: 'Backend switching is disabled.' }, { status: 410 })
}
