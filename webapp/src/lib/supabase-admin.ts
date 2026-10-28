import { createClient } from '@supabase/supabase-js'
import { assertSupabaseEnvironment } from './supabase-environment'

// Server-side only: uses service role key to bypass RLS. Never expose this to the browser.
const supabaseUrl = process.env.SUPABASE_URL
const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY

if (!supabaseUrl) {
    throw new Error('Missing SUPABASE_URL.')
}

if (!serviceRoleKey) {
    throw new Error('Missing SUPABASE_SERVICE_ROLE_KEY.')
}

if (process.env.NEXT_PUBLIC_SUPABASE_URL !== supabaseUrl) {
    throw new Error('Public and server Supabase URLs must match.')
}
assertSupabaseEnvironment(supabaseUrl, process.env.NEXT_PUBLIC_APP_ENV)

export const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey, {
    global: {
        fetch: (url, options) => {
            // Extended timeout (30s) to handle Supabase free tier cold starts
            return fetch(url, { ...options, signal: AbortSignal.timeout(30000) })
        }
    }
})

export async function getSupabaseAdmin() {
    return supabaseAdmin
}
