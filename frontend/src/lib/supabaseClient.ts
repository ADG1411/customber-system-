import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL || 'https://lrbmqfirkfogougzbvty.supabase.co';
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY || 'mock_anon_key_for_dev_mode';

export const supabase = createClient(supabaseUrl, supabaseAnonKey);
