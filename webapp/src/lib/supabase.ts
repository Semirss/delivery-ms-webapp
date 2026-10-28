import { createClient } from '@supabase/supabase-js'
import { assertSupabaseEnvironment } from './supabase-environment'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || 'http://localhost:54321'
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || 'your-anon-key'
assertSupabaseEnvironment(supabaseUrl, process.env.NEXT_PUBLIC_APP_ENV)

export const supabase = createClient(supabaseUrl, supabaseAnonKey)

export async function resolveSupabaseClient() {
    return supabase
}

