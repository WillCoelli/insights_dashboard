-- =============================================
-- SCHEMA DO BANCO DE DADOS - Meta Ads Dashboard SaaS
-- Execute este SQL no Supabase SQL Editor
-- =============================================

-- Tabela de perfis de usuarios (extende auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  nome TEXT,
  telefone TEXT,
  telefone_verificado BOOLEAN DEFAULT FALSE,
  plano TEXT DEFAULT 'free',
  criado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  atualizado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela de codigos de verificacao WhatsApp
CREATE TABLE IF NOT EXISTS public.verification_codes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  telefone TEXT NOT NULL,
  codigo TEXT NOT NULL,
  email TEXT NOT NULL,
  usado BOOLEAN DEFAULT FALSE,
  expira_em TIMESTAMP WITH TIME ZONE NOT NULL,
  criado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela de tokens Meta Ads (cada usuario pode ter varios)
CREATE TABLE IF NOT EXISTS public.meta_tokens (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  nome TEXT NOT NULL,
  token_criptografado TEXT NOT NULL,
  contas_vinculadas JSONB DEFAULT '[]',
  ativo BOOLEAN DEFAULT TRUE,
  criado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  atualizado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela de uso/metricas
CREATE TABLE IF NOT EXISTS public.usage_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  acao TEXT NOT NULL,
  detalhes JSONB DEFAULT '{}',
  criado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indices para performance
CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);
CREATE INDEX IF NOT EXISTS idx_verification_codes_telefone ON public.verification_codes(telefone);
CREATE INDEX IF NOT EXISTS idx_verification_codes_email ON public.verification_codes(email);
CREATE INDEX IF NOT EXISTS idx_meta_tokens_user_id ON public.meta_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_usage_logs_user_id ON public.usage_logs(user_id);

-- RLS (Row Level Security) - Seguranca
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.verification_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meta_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.usage_logs ENABLE ROW LEVEL SECURITY;

-- Policies para profiles
CREATE POLICY "Users can view own profile" ON public.profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.profiles
  FOR UPDATE USING (auth.uid() = id);

-- Policies para meta_tokens
CREATE POLICY "Users can view own tokens" ON public.meta_tokens
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own tokens" ON public.meta_tokens
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own tokens" ON public.meta_tokens
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own tokens" ON public.meta_tokens
  FOR DELETE USING (auth.uid() = user_id);

-- Policies para usage_logs
CREATE POLICY "Users can view own logs" ON public.usage_logs
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own logs" ON public.usage_logs
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Funcao para criar profile automaticamente quando usuario se registra
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email)
  VALUES (NEW.id, NEW.email);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger para criar profile automaticamente
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Funcao para atualizar timestamp
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.atualizado_em = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers para atualizar timestamp
CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER update_meta_tokens_updated_at
  BEFORE UPDATE ON public.meta_tokens
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
