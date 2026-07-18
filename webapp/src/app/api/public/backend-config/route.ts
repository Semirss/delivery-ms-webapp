import { NextResponse } from 'next/server'
import { getPublicBackendConfig } from '@/lib/backend-config'

export async function GET() {
  const config = await getPublicBackendConfig()

  return NextResponse.json(
    {
      supabaseUrl: config.supabaseUrl,
      supabaseAnonKey: config.supabaseAnonKey,
      updatedAt: config.updatedAt,
      source: config.source,
    },
    {
      headers: {
        'Cache-Control': 'no-store',
      },
    },
  )
}
