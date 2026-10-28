// The project currently holding real data. A test deployment must never use it.
const productionHost = 'smkfvvblyudecimcfman.supabase.co'

export function assertSupabaseEnvironment(url: string, environment: string | undefined) {
  const host = new URL(url).host.toLowerCase()

  if (environment === 'production' && host !== productionHost) {
    throw new Error('Production is configured with the wrong Supabase project.')
  }
  if (environment === 'test' && host === productionHost) {
    throw new Error('Test cannot connect to the production Supabase project.')
  }
  if (environment !== 'production' && environment !== 'test') {
    throw new Error('Set NEXT_PUBLIC_APP_ENV to production or test.')
  }
}
