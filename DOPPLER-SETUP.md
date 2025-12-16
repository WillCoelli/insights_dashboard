# 🔐 Configurar Doppler - Guia Completo

## Passo 1: Criar Conta no Doppler (5 minutos)

1. Acesse: **https://www.doppler.com/**
2. Clique em **"Start for Free"** ou **"Sign Up"**
3. Use sua conta Google/GitHub ou email
4. Confirme o email
5. **Plano Free** já está selecionado (não precisa pagar nada)

---

## Passo 2: Criar Projeto

1. No dashboard do Doppler, clique em **"Create Project"**
2. Nome do projeto: `insights-dashboard`
3. Clique em **"Create Project"**

Você verá 3 ambientes padrão:
- `dev` (desenvolvimento)
- `stg` (staging)
- `prd` (produção)

**Vamos usar o ambiente `prd` (produção)**

---

## Passo 3: Adicionar Secrets (pelo navegador)

1. Clique no ambiente **`prd`**
2. Você verá uma tela vazia de secrets
3. Clique em **"Add First Secret"** ou **"Add Secret"**

Agora adicione esses secrets **um por um**:

### Secrets para adicionar:

```
Nome: NEXT_PUBLIC_SUPABASE_URL
Valor: https://ixenaufwnyqlkzpgwzoe.supabase.co
```

```
Nome: NEXT_PUBLIC_SUPABASE_ANON_KEY
Valor: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml4ZW5hdWZ3bnlxbGt6cGd3em9lIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUyNDk5MTgsImV4cCI6MjA4MDgyNTkxOH0.lWgy29Jez6Vb3Ct5iIHUlPcLYklk4Bc7zKuEiCauqfo
```

```
Nome: SUPABASE_SERVICE_ROLE_KEY
Valor: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml4ZW5hdWZ3bnlxbGt6cGd3em9lIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NTI0OTkxOCwiZXhwIjoyMDgwODI1OTE4fQ.1nz0jTCqiu2pV04sELV1-bDTR5E2XF3mn-Yhji6i47U
```

```
Nome: GRAPH_API_VERSION
Valor: v21.0
```

```
Nome: GRAPH_API_URL
Valor: https://graph.facebook.com/v21.0
```

```
Nome: NEXT_PUBLIC_BACKEND_URL
Valor: https://gestor.disparazap.com
```

**Copie os valores do seu arquivo `.env.production` real!**

---

## Passo 4: Gerar Service Token (para a VPS acessar)

1. No Doppler, vá em **Settings** (ícone de engrenagem) do projeto
2. Ou clique em **"Access"** no menu lateral
3. Clique em **"Service Tokens"**
4. Clique em **"Generate"**
5. Configurações:
   - **Name**: `vps-production`
   - **Environment**: `prd`
   - **Access**: `Read`
6. Clique em **"Generate Service Token"**

7. **COPIE O TOKEN!** Vai ser algo como:
   ```
   dp.st.prd.xxxxxxxxxxxxxxxxxxxxxxxxxxxx
   ```

**⚠️ IMPORTANTE:** Copie agora! Você não conseguirá ver de novo!

---

## Passo 5: Testar (Opcional - na VPS depois)

Na VPS, você vai usar assim:

```bash
# Instalar Doppler CLI
curl -Ls https://cli.doppler.com/install.sh | sh

# Configurar token
echo "dp.st.prd.xxxxxxxxxxxx" | doppler configure set token --scope /opt/insights_dashboard

# Testar - ver todos os secrets
doppler secrets
```

---

## ✅ Pronto!

Agora seus secrets estão:
- ✅ Versionados (histórico completo no Doppler)
- ✅ Seguros (criptografados)
- ✅ Fora do Git
- ✅ Fácil de gerenciar

---

## 📋 Próximos Passos

1. ✅ Upload do código para GitHub (sem .env)
2. ✅ Na VPS, instalar Doppler CLI
3. ✅ Configurar token do Doppler
4. ✅ Deploy usando `doppler run`

Vou criar os scripts atualizados para você!
