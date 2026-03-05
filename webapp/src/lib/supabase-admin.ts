import { createClient } from '@supabase/supabase-js'

// ⚠️ Server-side only: uses service role key to bypass RLS. Never expose this to the browser.
const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!
const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY!

export const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey, {
    global: {
        fetch: (url, options) => {
            // Extended timeout (30s) to handle Supabase free tier cold starts
            return fetch(url, { ...options, signal: AbortSignal.timeout(30000) })
        }
    }
})
