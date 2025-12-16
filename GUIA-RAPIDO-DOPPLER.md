# 🚀 Deploy com Doppler - Guia Rápido

## 📋 Visão Geral

1. **Doppler** = Guarda seus secrets (chaves, senhas)
2. **GitHub** = Guarda seu código
3. **VPS** = Roda a aplicação pegando secrets do Doppler

---

## Passo 1️⃣: Configurar Doppler (10 minutos)

### 1.1 - Criar conta
- Acesse: **https://www.doppler.com/**
- Clique em **"Start for Free"**
- Use Google/GitHub para login
- **Plano Free** (não precisa cartão)

### 1.2 - Criar projeto
- Clique em **"Create Project"**
- Nome: `insights-dashboard`
- Usar ambiente: **`prd`** (produção)

### 1.3 - Adicionar secrets
Clique no ambiente **`prd`** e adicione esses secrets:

**Abra seu arquivo `.env.production` e copie os valores:**

```
NEXT_PUBLIC_SUPABASE_URL
NEXT_PUBLIC_SUPABASE_ANON_KEY
SUPABASE_SERVICE_ROLE_KEY
GRAPH_API_VERSION
GRAPH_API_URL
NEXT_PUBLIC_BACKEND_URL
```

Cole cada um no Doppler (botão **"Add Secret"**)

### 1.4 - Gerar Service Token
- Clique em **"Access"** → **"Service Tokens"**
- **"Generate"**
- Nome: `vps-production`
- Environment: `prd`
- Access: `Read`
- **Copie o token!** (começa com `dp.st.prd...`)

⚠️ **GUARDE ESTE TOKEN!** Você vai precisar na VPS.

---

## Passo 2️⃣: Enviar código para GitHub (5 minutos)

### 2.1 - Criar repositório no GitHub
- https://github.com/new
- Nome: `insights-dashboard`
- **Privado** ✅
- **NÃO** marque nada
- Create repository

### 2.2 - Upload pelo navegador

**Opção A - Arrastar e soltar:**
1. Na página do repo, clique **"uploading an existing file"**
2. Abra a pasta do projeto no Windows Explorer
3. Selecione **TUDO** (Ctrl+A)
4. Arraste para a página do GitHub
5. Commit changes

**Opção B - Git Bash (se preferir):**
```bash
cd /c/Users/William/Desktop/Soft/dev/insights_dashboard
git init
git add .
git commit -m "deploy"
git branch -M main
git remote add origin https://github.com/SEU-USUARIO/insights-dashboard.git
git push -u origin main --force
```

✅ **Agora pode enviar o .env também!** Porque seus secrets estão no Doppler, não no arquivo.

---

## Passo 3️⃣: Deploy na VPS (10 minutos)

### 3.1 - Conectar na VPS
```bash
ssh root@SEU-IP
```

### 3.2 - Rodar script de instalação

**Cole este comando completo na VPS:**

```bash
curl -sSL https://raw.githubusercontent.com/SEU-USUARIO/insights-dashboard/main/install-vps-doppler.sh | bash
```

*Substitua `SEU-USUARIO` pelo seu usuário do GitHub*

**OU baixe e execute manualmente:**

```bash
cd /tmp
curl -O https://raw.githubusercontent.com/SEU-USUARIO/insights-dashboard/main/install-vps-doppler.sh
bash install-vps-doppler.sh
```

### 3.3 - Informar dados quando pedir:

1. **URL do GitHub**: `https://github.com/seu-usuario/insights-dashboard.git`
2. **Token do Doppler**: `dp.st.prd.xxxxxxxxxx` (que você copiou no passo 1.4)

### 3.4 - Aguardar

O script vai:
- ✅ Instalar Git, Docker, Doppler
- ✅ Baixar código do GitHub
- ✅ Pegar secrets do Doppler
- ✅ Construir e fazer deploy
- ✅ Configurar SSL (Traefik)

**Aguarde 2-3 minutos** após terminar.

---

## ✅ Pronto!

Acesse: **https://gestor.disparazap.com**

---

## 🔄 Para Atualizar Depois

### Atualizar código:
1. Faça alterações no código
2. Commit no GitHub (pelo navegador ou Git)
3. Na VPS: `bash /opt/insights_dashboard/atualizar-vps-doppler.sh`

### Atualizar secrets:
1. Entre no Doppler: https://dashboard.doppler.com
2. Edite o secret
3. Na VPS: `bash /opt/insights_dashboard/atualizar-vps-doppler.sh`

**Doppler sincroniza automaticamente!** ✨

---

## 📝 Comandos Úteis na VPS

```bash
# Ver logs
docker service logs -f insights_insights-dashboard

# Ver secrets do Doppler
cd /opt/insights_dashboard && doppler secrets

# Ver status
docker service ls

# Atualizar
bash /opt/insights_dashboard/atualizar-vps-doppler.sh
```

---

## 🎉 Vantagens do Doppler

- ✅ Histórico de todas as mudanças nos secrets
- ✅ Nunca expõe secrets no Git
- ✅ Fácil de atualizar (só edita no Doppler)
- ✅ Dashboard bonito
- ✅ 100% Grátis para você

---

## ❓ Problemas?

### Token do Doppler inválido
- Gere um novo token no Doppler
- Execute: `cd /opt/insights_dashboard && doppler configure set token`

### Secrets não atualizam
- Na VPS: `bash /opt/insights_dashboard/atualizar-vps-doppler.sh`

### Ver histórico de mudanças
- Doppler Dashboard → seu projeto → Activity

---

**Pronto para começar?** Comece pelo Passo 1! 🚀
