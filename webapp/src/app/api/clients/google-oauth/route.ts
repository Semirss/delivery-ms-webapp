import { NextRequest, NextResponse } from 'next/server'
import { getSupabaseAdmin } from '@/lib/supabase-admin'

function clean(value: unknown) {
  return value?.toString().trim() || ''
}

function splitName(metadata: Record<string, unknown>) {
  const givenName = clean(metadata.given_name || metadata.first_name)
  const familyName = clean(metadata.family_name || metadata.last_name)
  if (givenName || familyName) {
    return { firstName: givenName, lastName: familyName }
  }

  const fullName = clean(metadata.full_name || metadata.name)
  const [firstName, ...rest] = fullName.split(/\s+/).filter(Boolean)
  return {
    firstName: firstName || '',
    lastName: rest.join(' '),
  }
}

function clientPayload(row: Record<string, unknown>) {
  return {
    id: row.id,
    email: row.email,
    phone: row.phone,
    first_name: row.first_name,
    last_name: row.last_name,
    is_email_verified: row.is_email_verified,
    is_phone_verified: row.is_phone_verified,
    created_at: row.created_at,
  }
}

export async function POST(request: NextRequest) {
  const authHeader = request.headers.get('authorization') || ''
  const token = authHeader.match(/^Bearer\s+(.+)$/i)?.[1]?.trim()
  if (!token) {
    return NextResponse.json({ error: 'Google sign-in expired. Please try again.' }, { status: 401 })
  }

  const supabase = await getSupabaseAdmin()
  const { data: authData, error: authError } = await supabase.auth.getUser(token)
  const authUser = authData.user
  if (authError || !authUser?.email) {
    return NextResponse.json({ error: 'Google sign-in could not be verified.' }, { status: 401 })
  }

  const email = authUser.email.trim().toLowerCase()
  const metadata = (authUser.user_metadata || {}) as Record<string, unknown>
  const { firstName, lastName } = splitName(metadata)

  const { data: existing, error: lookupError } = await supabase
    .from('clients')
    .select('id,email,phone,first_name,last_name,status,is_active,is_email_verified,is_phone_verified,created_at')
    .ilike('email', email)
    .limit(1)
    .maybeSingle()

  if (lookupError) {
    return NextResponse.json({ error: 'Could not prepare your client account.' }, { status: 500 })
  }

  if (existing && (!existing.is_active || existing.status !== 'Active')) {
    return NextResponse.json({ error: 'This client account is not active.' }, { status: 403 })
  }

  if (existing) {
    const { data, error } = await supabase
      .from('clients')
      .update({
        first_name: existing.first_name || firstName || null,
        last_name: existing.last_name || lastName || null,
        is_email_verified: true,
        last_login_at: new Date().toISOString(),
      })
      .eq('id', existing.id)
      .select('id,email,phone,first_name,last_name,is_email_verified,is_phone_verified,created_at')
      .single()

    if (error || !data) {
      return NextResponse.json({ error: 'Could not complete Google sign-in.' }, { status: 500 })
    }
    return NextResponse.json(clientPayload(data))
  }

  const { data, error } = await supabase
    .from('clients')
    .insert({
      email,
      first_name: firstName || null,
      last_name: lastName || null,
      password_hash: `google_oauth:${crypto.randomUUID()}`,
      is_email_verified: true,
      is_phone_verified: false,
      last_login_at: new Date().toISOString(),
    })
    .select('id,email,phone,first_name,last_name,is_email_verified,is_phone_verified,created_at')
    .single()

  if (error || !data) {
    return NextResponse.json({ error: 'Could not create your client account.' }, { status: 500 })
  }

  return NextResponse.json(clientPayload(data))
}
