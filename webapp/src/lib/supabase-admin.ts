import { createClient } from '@supabase/supabase-js'
import { getAdminBackendConfig } from './backend-config'

// Server-side only: uses service role key to bypass RLS. Never expose this to the browser.
const supabaseUrl =
    process.env.NEXT_PUBLIC_SUPABASE_URL ||
    process.env.SUPABASE_URL ||
    process.env.MASTER_SUPABASE_URL
const serviceRoleKey =
    process.env.SUPABASE_SERVICE_ROLE_KEY ||
    process.env.MASTER_SUPABASE_SERVICE_ROLE_KEY

if (!supabaseUrl) {
    throw new Error('Missing Supabase URL. Set SUPABASE_URL or MASTER_SUPABASE_URL in webapp/.env.')
}

if (!serviceRoleKey) {
    throw new Error('Missing Supabase service role key. Set SUPABASE_SERVICE_ROLE_KEY or MASTER_SUPABASE_SERVICE_ROLE_KEY in webapp/.env.')
}

export const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey, {
    global: {
        fetch: (url, options) => {
            // Extended timeout (30s) to handle Supabase free tier cold starts
            return fetch(url, { ...options, signal: AbortSignal.timeout(30000) })
        }
    }
})

let cachedRuntimeKey = `${supabaseUrl}|${serviceRoleKey}`
let cachedRuntimeClient = supabaseAdmin

export async function getSupabaseAdmin() {
    try {
        const runtime = await getAdminBackendConfig()
        const runtimeServiceRole = runtime.supabaseServiceRoleKey?.trim()

        if (!runtime.supabaseUrl || !runtimeServiceRole) {
            return supabaseAdmin
        }

        const nextRuntimeKey = `${runtime.supabaseUrl}|${runtimeServiceRole}`
        if (nextRuntimeKey !== cachedRuntimeKey) {
            cachedRuntimeKey = nextRuntimeKey
            cachedRuntimeClient = createClient(runtime.supabaseUrl, runtimeServiceRole, {
                auth: {
                    persistSession: false,
                    autoRefreshToken: false,
                },
                global: {
                    fetch: (url, options) => {
                        return fetch(url, {
                            ...options,
                            signal: AbortSignal.timeout(30000),
                        })
                    },
                },
            })
        }

        return cachedRuntimeClient
    } catch {
        return supabaseAdmin
    }
}
