import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

// Validacao de credenciais obrigatorias
if (!supabaseUrl || !supabaseAnonKey) {
  if (typeof window !== 'undefined') {
    console.error('ERRO: Credenciais Supabase nao configuradas. Verifique .env.local');
  }
}

// Cliente publico para autenticacao
export const supabase = createClient(
  supabaseUrl || 'https://placeholder.supabase.co',
  supabaseAnonKey || 'placeholder-key',
  {
    auth: {
      persistSession: true,
      autoRefreshToken: true,
    },
  }
);

// Cliente com service role para operacoes administrativas (apenas server-side)
export const createServiceClient = () => {
  const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

  // Verificar se esta no servidor
  if (typeof window !== 'undefined') {
    throw new Error('createServiceClient so pode ser usado no servidor');
  }

  if (!serviceRoleKey || serviceRoleKey === 'sua_service_role_key_aqui') {
    console.error('SUPABASE_SERVICE_ROLE_KEY nao configurada ou usando valor padrao');
    throw new Error('SUPABASE_SERVICE_ROLE_KEY nao configurada corretamente');
  }

  return createClient(supabaseUrl || '', serviceRoleKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  });
};

// Cliente admin para criar usuarios (apenas server-side)
export const createAdminClient = () => {
  const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

  // Verificar se esta no servidor
  if (typeof window !== 'undefined') {
    throw new Error('createAdminClient so pode ser usado no servidor');
  }

  if (!serviceRoleKey || serviceRoleKey === 'sua_service_role_key_aqui') {
    console.error('SUPABASE_SERVICE_ROLE_KEY nao configurada ou usando valor padrao');
    throw new Error('SUPABASE_SERVICE_ROLE_KEY nao configurada corretamente');
  }

  return createClient(supabaseUrl || '', serviceRoleKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  });
};
