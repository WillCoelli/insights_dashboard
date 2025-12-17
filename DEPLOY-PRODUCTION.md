# 🚀 Deploy em Produção - Insights Dashboard v1.1.0

## 📋 Índice
- [Pré-requisitos](#pré-requisitos)
- [Arquitetura](#arquitetura)
- [Deploy Inicial](#deploy-inicial)
- [Configuração de Variáveis](#configuração-de-variáveis)
- [Deploy Automático (CI/CD)](#deploy-automático-cicd)
- [Manutenção](#manutenção)
- [Troubleshooting](#troubleshooting)

---

## 🔧 Pré-requisitos

### Na VPS (Debian 12)

✅ **Sistema Operacional:**
```bash
# Verificar versão
cat /etc/os-release
# Deve mostrar: Debian GNU/Linux 12 (bookworm)
```

✅ **Docker Engine:**
```bash
# Instalar Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Verificar instalação
docker --version  # Requer >= 20.10
```

✅ **Docker Swarm:**
```bash
# Inicializar Swarm
docker swarm init

# Verificar status
docker node ls
```

✅ **Portainer (opcional, mas recomendado):**
```bash
# Criar volume
docker volume create portainer_data

# Deploy Portainer
docker run -d \
  -p 9000:9000 \
  -p 9443:9443 \
  --name=portainer \
  --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce:latest
```

Acessar: `https://SEU_IP:9443`

---

## 🏗️ Arquitetura

```
┌─────────────────────────────────────────────────┐
│              Internet (HTTPS)                    │
└────────────────┬────────────────────────────────┘
                 │
        ┌────────▼────────┐
        │   Traefik       │ (Let's Encrypt)
        │   Port 80/443   │
        └────────┬────────┘
                 │
        ┌────────▼────────────────┐
        │  Insights Dashboard     │
        │  2 Replicas             │
        │  Port 3000 (internal)   │
        └─────────────────────────┘
```

**Stack completa:**
- **Traefik**: Reverse proxy + HTTPS automático
- **Insights Dashboard**: Aplicação Next.js (2 réplicas)
- **Network**: `traefik-public` (overlay)

---

## 🚀 Deploy Inicial

### Passo 1: Clonar arquivos de configuração

```bash
# Na VPS
mkdir -p ~/insights-deploy
cd ~/insights-deploy

# Baixar arquivos do repositório
wget https://raw.githubusercontent.com/WillCoelli/insights_dashboard/main/docker-stack.yml
wget https://raw.githubusercontent.com/WillCoelli/insights_dashboard/main/traefik-stack.yml
wget https://raw.githubusercontent.com/WillCoelli/insights_dashboard/main/.env.production.example

# Copiar template de variáveis
cp .env.production.example .env
```

### Passo 2: Configurar variáveis de ambiente

```bash
# Editar arquivo .env
nano .env
```

**Variáveis OBRIGATÓRIAS:**
```bash
# Supabase
NEXT_PUBLIC_SUPABASE_URL=https://seu-projeto.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# Domínio
NEXT_PUBLIC_BACKEND_URL=https://gestor.disparazap.com

# Traefik
ACME_EMAIL=seu-email@exemplo.com
DOMAIN=gestor.disparazap.com
```

### Passo 3: Deploy do Traefik

```bash
# Carregar variáveis
export $(cat .env | xargs)

# Criar network
docker network create --driver=overlay traefik-public

# Deploy Traefik
docker stack deploy -c traefik-stack.yml traefik

# Verificar
docker service ls
docker service logs traefik_traefik -f
```

**Aguardar:** Traefik precisa estar "healthy" antes de prosseguir.

### Passo 4: Deploy da Aplicação

```bash
# Deploy Insights Dashboard
docker stack deploy -c docker-stack.yml insights

# Verificar status
docker service ls
docker service ps insights_insights-dashboard

# Acompanhar logs
docker service logs insights_insights-dashboard -f
```

### Passo 5: Verificar deploy

```bash
# Testar endpoint de health
curl https://gestor.disparazap.com/api/health

# Resposta esperada:
# {"status":"healthy","timestamp":"2024-01-01T00:00:00.000Z","uptime":123.45}
```

---

## ⚙️ Configuração de Variáveis

### Via Portainer (Recomendado)

1. Acesse Portainer: `https://SEU_IP:9443`
2. Navegue: **Stacks** → **insights**
3. Clique em **Editor**
4. Role até a seção `environment:`
5. Edite as variáveis necessárias
6. Clique em **Update the stack**

### Via CLI

```bash
cd ~/insights-deploy

# Editar .env
nano .env

# Recarregar variáveis
export $(cat .env | xargs)

# Atualizar stack
docker stack deploy -c docker-stack.yml insights
```

---

## 🔄 Deploy Automático (CI/CD)

### Configuração no GitHub

1. **Acesse:** `https://github.com/WillCoelli/insights_dashboard/settings/secrets/actions`

2. **Adicione os secrets:**

| Secret Name | Valor | Descrição |
|------------|-------|-----------|
| `NEXT_PUBLIC_SUPABASE_URL` | `https://...` | URL do Supabase |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | `eyJ...` | Chave anônima |
| `NEXT_PUBLIC_BACKEND_URL` | `https://gestor...` | URL backend |
| `WEBHOOK_URL` | (opcional) | Webhook Portainer |

### Webhook do Portainer (Auto-deploy)

**Criar webhook no Portainer:**
1. Acesse: **Stacks** → **insights** → **Webhooks**
2. Clique em **Add webhook**
3. Copie a URL gerada

**Adicionar ao GitHub:**
```bash
# Settings > Secrets > Actions > New secret
# Nome: WEBHOOK_URL
# Valor: https://gestor.disparazap.com/api/webhooks/xxxxx-xxxxx-xxxxx
```

**Funcionamento:**
- Push no `main` → GitHub Actions → Build → Push GHCR → Webhook → Portainer → Deploy automático

---

## 🛠️ Manutenção

### Scripts de Utilidade

Baixar scripts para VPS:
```bash
mkdir -p ~/scripts
cd ~/scripts

wget https://raw.githubusercontent.com/WillCoelli/insights_dashboard/main/scripts/check-health.sh
wget https://raw.githubusercontent.com/WillCoelli/insights_dashboard/main/scripts/view-logs.sh
wget https://raw.githubusercontent.com/WillCoelli/insights_dashboard/main/scripts/restart-service.sh

chmod +x *.sh
```

#### 1. Verificar Health

```bash
./check-health.sh
# ou
./check-health.sh insights gestor.disparazap.com
```

#### 2. Ver Logs

```bash
# Últimas 100 linhas
./view-logs.sh

# Últimas 50 linhas
./view-logs.sh insights 50

# Seguir em tempo real
./view-logs.sh insights 100 true
```

#### 3. Reiniciar Serviço

```bash
./restart-service.sh
# ou
./restart-service.sh insights
```

### Comandos Úteis

```bash
# Listar serviços
docker service ls

# Status detalhado
docker service ps insights_insights-dashboard

# Inspecionar serviço
docker service inspect insights_insights-dashboard

# Escalar réplicas
docker service scale insights_insights-dashboard=3

# Atualizar imagem
docker service update --image ghcr.io/willcoelli/insights_dashboard:1.1.0 insights_insights-dashboard

# Remover stack
docker stack rm insights
```

---

## 🔍 Troubleshooting

### 1. Serviço não inicia

**Verificar logs:**
```bash
docker service logs insights_insights-dashboard --tail 100
```

**Causas comuns:**
- ❌ Variáveis de ambiente faltando
- ❌ Imagem não encontrada (verificar GHCR)
- ❌ Porta 3000 em uso

**Solução:**
```bash
# Verificar variáveis
docker service inspect insights_insights-dashboard | grep -A 20 Env

# Forçar pull da imagem
docker pull ghcr.io/willcoelli/insights_dashboard:1.1.0

# Verificar portas
docker ps -a
```

### 2. HTTPS não funciona

**Verificar Traefik:**
```bash
docker service logs traefik_traefik --tail 50
```

**Causas comuns:**
- ❌ DNS não aponta para VPS
- ❌ Portas 80/443 bloqueadas no firewall
- ❌ Email inválido no Let's Encrypt

**Solução:**
```bash
# Verificar DNS
nslookup gestor.disparazap.com

# Abrir portas
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Verificar certificados
docker exec $(docker ps -qf "name=traefik") ls -la /letsencrypt/
```

### 3. Deploy automático não funciona

**Verificar GitHub Actions:**
1. Acesse: `https://github.com/WillCoelli/insights_dashboard/actions`
2. Verifique última execução
3. Veja logs de erro

**Verificar webhook:**
```bash
# Testar manualmente
curl -X POST https://gestor.disparazap.com/api/webhooks/xxxxx
```

### 4. Alta latência / lentidão

**Verificar recursos:**
```bash
# CPU e memória
docker stats

# Número de réplicas
docker service ls
```

**Solução - Escalar:**
```bash
docker service scale insights_insights-dashboard=4
```

### 5. Health check falhando

**Testar endpoint:**
```bash
# Local (dentro do container)
docker exec $(docker ps -qf "name=insights") wget --spider http://localhost:3000/api/health

# Externo
curl https://gestor.disparazap.com/api/health
```

---

## 📊 Monitoramento

### Logs em tempo real
```bash
docker service logs insights_insights-dashboard -f --tail 50
```

### Métricas
```bash
docker stats --no-stream
```

### Health checks
```bash
watch -n 5 'curl -s https://gestor.disparazap.com/api/health | jq'
```

---

## 🔐 Segurança

### Recomendações

✅ **Firewall:**
```bash
sudo ufw enable
sudo ufw allow 22/tcp   # SSH
sudo ufw allow 80/tcp   # HTTP
sudo ufw allow 443/tcp  # HTTPS
sudo ufw allow 9443/tcp # Portainer (apenas IP confiável)
```

✅ **Secrets:**
- Nunca commitar `.env` no repositório
- Usar GitHub Secrets para variáveis sensíveis
- Rotacionar tokens periodicamente

✅ **Updates:**
```bash
# Atualizar sistema
sudo apt update && sudo apt upgrade -y

# Atualizar Docker
curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh
```

---

## 📝 Notas Finais

- **Versão atual:** v1.1.0
- **Imagem Docker:** `ghcr.io/willcoelli/insights_dashboard:1.1.0`
- **Porta interna:** 3000
- **Réplicas padrão:** 2
- **Domínio:** gestor.disparazap.com

**Suporte:**
- Repository: https://github.com/WillCoelli/insights_dashboard
- Issues: https://github.com/WillCoelli/insights_dashboard/issues

---

**Última atualização:** 2024-12-17
