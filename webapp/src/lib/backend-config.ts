import { createClient } from '@supabase/supabase-js'

export type BackendRuntimeConfig = {
  label: string
  supabaseUrl: string
  supabaseAnonKey: string
  supabaseServiceRoleKey?: string
  updatedAt?: string
  source: 'master' | 'env'
}

const MASTER_TABLE =
  process.env.MASTER_BACKEND_CONFIG_TABLE || 'backend_runtime_config'
const MASTER_VIEW =
  process.env.MASTER_BACKEND_CONFIG_VIEW || 'public_backend_runtime_config'

function clean(value: string | undefined) {
  return value?.trim() || ''
}

function fallbackConfig(): BackendRuntimeConfig {
  return {
    label: 'env-fallback',
    supabaseUrl:
      clean(process.env.NEXT_PUBLIC_SUPABASE_URL) ||
      clean(process.env.SUPABASE_URL) ||
      'http://localhost:54321',
    supabaseAnonKey:
      clean(process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY) ||
      clean(process.env.SUPABASE_ANON_KEY) ||
      'your-anon-key',
    supabaseServiceRoleKey: clean(process.env.SUPABASE_SERVICE_ROLE_KEY),
    source: 'env',
  }
}

function masterClient({ serviceRole = false } = {}) {
  const url = clean(process.env.MASTER_SUPABASE_URL)
  const key = serviceRole
    ? clean(process.env.MASTER_SUPABASE_SERVICE_ROLE_KEY)
    : clean(process.env.MASTER_SUPABASE_ANON_KEY)

  if (!url || !key) return null

  return createClient(url, key, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
    global: {
      fetch: (input, init) =>
        fetch(input, {
          ...init,
          signal: AbortSignal.timeout(10000),
        }),
    },
  })
}

function normalizeRow(
  row: Record<string, unknown> | null | undefined,
  source: 'master' | 'env',
): BackendRuntimeConfig {
  return {
    label: row?.label?.toString() || 'production',
    supabaseUrl: row?.supabase_url?.toString() || '',
    supabaseAnonKey: row?.supabase_anon_key?.toString() || '',
    supabaseServiceRoleKey: row?.supabase_service_role_key?.toString() || '',
    updatedAt: row?.updated_at?.toString(),
    source,
  }
}

export function maskSecret(value?: string) {
  const cleanValue = clean(value)
  if (!cleanValue) return ''
  if (cleanValue.length <= 12) return '••••'
  return `${cleanValue.slice(0, 6)}••••${cleanValue.slice(-6)}`
}

export async function getPublicBackendConfig(): Promise<BackendRuntimeConfig> {
  const master = masterClient()
  if (!master) return fallbackConfig()

  try {
    const { data, error } = await master
      .from(MASTER_VIEW)
      .select('supabase_url,supabase_anon_key,updated_at')
      .limit(1)
      .maybeSingle()

    if (error || !data) return fallbackConfig()
    const config = normalizeRow(data, 'master')
    if (!config.supabaseUrl || !config.supabaseAnonKey) return fallbackConfig()
    return config
  } catch {
    return fallbackConfig()
  }
}

export async function getAdminBackendConfig(): Promise<BackendRuntimeConfig> {
  const master = masterClient({ serviceRole: true })
  if (!master) return fallbackConfig()

  const { data, error } = await master
    .from(MASTER_TABLE)
    .select(
      'label,supabase_url,supabase_anon_key,supabase_service_role_key,is_active,updated_at',
    )
    .eq('is_active', true)
    .order('updated_at', { ascending: false })
    .limit(1)
    .maybeSingle()

  if (error) throw error
  if (!data) return fallbackConfig()
  return normalizeRow(data, 'master')
}

export async function updateAdminBackendConfig(input: {
  label: string
  supabaseUrl: string
  supabaseAnonKey: string
  supabaseServiceRoleKey?: string
  updatedBy?: string
}) {
  const master = masterClient({ serviceRole: true })
  if (!master) {
    throw new Error(
      'Missing MASTER_SUPABASE_URL or MASTER_SUPABASE_SERVICE_ROLE_KEY.',
    )
  }

  const supabaseUrl = clean(input.supabaseUrl)
  const supabaseAnonKey = clean(input.supabaseAnonKey)
  const supabaseServiceRoleKey = clean(input.supabaseServiceRoleKey)

  if (!/^https?:\/\/\S+$/.test(supabaseUrl)) {
    throw new Error('Enter a valid Supabase URL.')
  }

  if (supabaseAnonKey.length <= 20) {
    throw new Error('Enter a valid Supabase anon key.')
  }

  const { error: deactivateError } = await master
    .from(MASTER_TABLE)
    .update({ is_active: false })
    .eq('is_active', true)

  if (deactivateError) throw deactivateError

  const { error: insertError } = await master.from(MASTER_TABLE).insert({
    label: clean(input.label) || 'production',
    supabase_url: supabaseUrl,
    supabase_anon_key: supabaseAnonKey,
    supabase_service_role_key: supabaseServiceRoleKey || null,
    is_active: true,
    updated_by: clean(input.updatedBy) || 'admin',
  })

  if (insertError) throw insertError
}
