import { createClient } from '@supabase/supabase-js'

const SUPABASE_URL = 'https://vfcivewnqefnkyicklcn.supabase.co'
const SUPABASE_ANON_KEY =
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZmY2l2ZXducWVmbmt5aWNrbGNuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjYzMzk5MzIsImV4cCI6MjA0MTkxNTkzMn0.TomJW4YjfyqtnushHZsxuPvvCtGdsb1a5IkN7rQlEoI'

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY)
