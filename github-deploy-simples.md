# 🚀 Deploy Simples via GitHub

## Passo 1️⃣ : Criar Repositório no GitHub (uma vez só)

1. Acesse: https://github.com/new
2. Nome do repo: `insights-dashboard` (ou qualquer nome)
3. **Privado** ✅ (recomendado para segurança)
4. **NÃO** adicione README, .gitignore, licença (deixe vazio)
5. Clique em "Create repository"

Anote a URL do repo, será algo como:
```
https://github.com/SEU-USUARIO/insights-dashboard.git
```

---

## Passo 2️⃣ : No seu PC - Enviar código (PowerShell)

```powershell
cd C:\Users\William\Desktop\Soft\dev\insights_dashboard

# Primeira vez - configurar o repo
git remote remove origin 2>$null
git remote add origin https://github.com/SEU-USUARIO/insights-dashboard.git

# Enviar código (sempre use isso, sobrescreve tudo)
git add -A
git commit -m "deploy" --no-verify
git push origin main --force
```

**Pronto!** Código está no GitHub.

---

## Passo 3️⃣ : Na VPS - Instalar e rodar

**Cole tudo de uma vez no terminal da VPS:**

```bash
#!/bin/bash

# Instalar Git (se não tiver)
apt-get update && apt-get install -y git

# Baixar código
cd /opt
rm -rf insights_dashboard
git clone https://github.com/SEU-USUARIO/insights-dashboard.git insights_dashboard
cd insights_dashboard

# Instalar Docker (se não tiver)
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com | sh
fi

# Configurar Swarm
docker swarm init 2>/dev/null || true
docker network create --driver=overlay traefik-public 2>/dev/null || true

# Build e Deploy
export $(cat .env.production | grep -v '^#' | xargs)
docker build -t insights-dashboard:latest .
docker stack deploy -c docker-compose.prod.yml insights

# Status
echo "✅ Deploy concluído!"
docker service ls
```

---

## 🔄 Para Atualizar Depois

### No PC:
```powershell
cd C:\Users\William\Desktop\Soft\dev\insights_dashboard

git add -A
git commit -m "update" --no-verify
git push origin main --force
```

### Na VPS:
```bash
cd /opt/insights_dashboard
git pull origin main --force
export $(cat .env.production | grep -v '^#' | xargs)
docker build -t insights-dashboard:latest .
docker service update --force insights_insights-dashboard
```

---

## ⚠️ IMPORTANTE

Antes de enviar pro GitHub, adicione o `.env.production` no `.gitignore` para não expor suas chaves:

```powershell
# No PC
echo ".env.production" >> .gitignore
```

Depois, você copia o `.env.production` manualmente para a VPS via SCP:
```powershell
scp .env.production root@SEU-IP:/opt/insights_dashboard/
```

---

## 🎯 Resumo

1. **GitHub** = Apenas ponte para transferir código
2. **PC** = `git push --force` (sobrescreve sempre)
3. **VPS** = `git pull` + rebuild + deploy
4. Sem histórico, sem branches, sem complicação!
