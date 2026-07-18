import { NextResponse } from 'next/server'
import {
  getAdminBackendConfig,
  maskSecret,
  updateAdminBackendConfig,
} from '@/lib/backend-config'

const BACKEND_PASS = process.env.ADMIN_BACKEND_PASS || '1212'

function isAuthorized(request: Request, bodyPass?: string) {
  const headerPass = request.headers.get('x-backend-pass')?.trim()
  const queryPass = new URL(request.url).searchParams.get('pass')?.trim()
  return (bodyPass || headerPass || queryPass) === BACKEND_PASS
}

export async function GET(request: Request) {
  if (!isAuthorized(request)) {
    return NextResponse.json({ error: 'Backend section locked.' }, { status: 401 })
  }

  try {
    const config = await getAdminBackendConfig()
    return NextResponse.json({
      label: config.label,
      supabaseUrl: config.supabaseUrl,
      supabaseAnonKey: config.supabaseAnonKey,
      maskedAnonKey: maskSecret(config.supabaseAnonKey),
      hasServiceRoleKey: Boolean(config.supabaseServiceRoleKey),
      maskedServiceRoleKey: maskSecret(config.supabaseServiceRoleKey),
      updatedAt: config.updatedAt,
      source: config.source,
    })
  } catch (error: unknown) {
    return NextResponse.json(
      {
        error:
          error instanceof Error
            ? error.message
            : 'Could not load backend config.',
      },
      { status: 500 },
    )
  }
}

export async function PATCH(request: Request) {
  const body = await request.json().catch(() => ({}))

  if (!isAuthorized(request, body.pass?.toString())) {
    return NextResponse.json({ error: 'Backend section locked.' }, { status: 401 })
  }

  try {
    await updateAdminBackendConfig({
      label: body.label?.toString() || 'production',
      supabaseUrl: body.supabaseUrl?.toString() || '',
      supabaseAnonKey: body.supabaseAnonKey?.toString() || '',
      supabaseServiceRoleKey: body.supabaseServiceRoleKey?.toString() || '',
      updatedBy: 'admin-dashboard',
    })

    return NextResponse.json({ ok: true })
  } catch (error: unknown) {
    return NextResponse.json(
      {
        error:
          error instanceof Error
            ? error.message
            : 'Could not save backend config.',
      },
      { status: 400 },
    )
  }
}
