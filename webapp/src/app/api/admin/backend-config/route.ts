import { NextResponse } from 'next/server'
import { isAdminRequest } from '@/lib/admin-auth'
import { adminSessionSecret } from '@/lib/admin-session-secret'

export const dynamic = 'force-dynamic'

export async function GET() {
  if (!await isAdminRequest()) {
    return NextResponse.json({ error: 'Admin sign-in required.' }, { status: 401 })
  }

  const serverUrl = process.env.SUPABASE_URL ?? ''
  const publicUrl = process.env.NEXT_PUBLIC_SUPABASE_URL ?? ''
  return NextResponse.json({
    source: 'env',
    environment: process.env.NEXT_PUBLIC_APP_ENV ?? 'unknown',
    supabaseUrl: serverUrl,
    publicSupabaseUrl: publicUrl,
    urlsMatch: Boolean(serverUrl && publicUrl && serverUrl === publicUrl),
    serviceRoleConfigured: Boolean(process.env.SUPABASE_SERVICE_ROLE_KEY),
    sessionSecretConfigured: Boolean(adminSessionSecret()),
    deploymentCommit: process.env.VERCEL_GIT_COMMIT_SHA?.slice(0, 7) ?? null,
  }, { headers: { 'Cache-Control': 'no-store' } })
}

export async function PATCH() {
  return NextResponse.json({ error: 'Backend switching is disabled for current releases.' }, { status: 410 })
}
