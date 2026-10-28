// The project currently holding real data. A test deployment must never use it.
const productionHost = 'smkfvvblyudecimcfman.supabase.co'
const testHost = 'mtbqqharhxijulpaqdrm.supabase.co'

export function assertSupabaseEnvironment(url: string, environment: string | undefined) {
  const parsed = new URL(url)
  if (parsed.protocol !== 'https:') {
    throw new Error('Supabase deployments must use HTTPS.')
  }
  const host = parsed.host.toLowerCase()

  if (environment === 'production' && host !== productionHost) {
    throw new Error('Production is configured with the wrong Supabase project.')
  }
  if (environment === 'test' && host !== testHost) {
    throw new Error('Test is configured with the wrong Supabase project.')
  }
  if (environment !== 'production' && environment !== 'test') {
    throw new Error('Set NEXT_PUBLIC_APP_ENV to production or test.')
  }
}
