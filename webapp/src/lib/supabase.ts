import { createClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || 'http://localhost:54321'
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || 'your-anon-key'

let activeRuntimeKey = `${supabaseUrl}|${supabaseAnonKey}`

export let supabase = createClient(supabaseUrl, supabaseAnonKey)

export async function resolveSupabaseClient() {
    if (typeof window === 'undefined') return supabase

    try {
        const response = await fetch('/api/public/backend-config', {
            cache: 'no-store',
        })
        if (!response.ok) return supabase

        const config = await response.json()
        const nextUrl = config.supabaseUrl?.toString().trim()
        const nextAnonKey = config.supabaseAnonKey?.toString().trim()

        if (!nextUrl || !nextAnonKey) return supabase

        const nextRuntimeKey = `${nextUrl}|${nextAnonKey}`
        if (nextRuntimeKey !== activeRuntimeKey) {
            activeRuntimeKey = nextRuntimeKey
            supabase = createClient(nextUrl, nextAnonKey)
        }
    } catch {
        // Keep the bundled env client when the runtime config endpoint is down.
    }

    return supabase
}

