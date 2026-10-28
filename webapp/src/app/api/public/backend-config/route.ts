import { NextResponse } from 'next/server'
import { assertSupabaseEnvironment } from '@/lib/supabase-environment'

export async function GET() {
  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
  const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY
  if (!supabaseUrl || !supabaseAnonKey || supabaseUrl !== process.env.SUPABASE_URL) {
    return NextResponse.json({ error: 'Supabase environment is not configured.' }, { status: 503 })
  }
  assertSupabaseEnvironment(supabaseUrl, process.env.NEXT_PUBLIC_APP_ENV)

  return NextResponse.json(
    {
      supabaseUrl,
      supabaseAnonKey,
      source: 'env',
    },
    {
      headers: {
        'Cache-Control': 'no-store',
      },
    },
  )
}
