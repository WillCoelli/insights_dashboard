# 🚀 Guia de Deploy - Insights Dashboard

## Pré-requisitos na VPS

- Debian 12 (Bookworm)
- Docker e Docker Compose instalados
- Docker Swarm inicializado
- Traefik configurado com rede `traefik-public`
- Acesso SSH à VPS

## Passo a Passo

### 1. Conectar na VPS via SSH

```bash
ssh user@seu-servidor.com
```

### 2. Clonar o repositório

```bash
cd /opt
git clone https://github.com/WillCoelli/insights_dashboard.git
cd insights_dashboard
```

### 3. Configurar variáveis de ambiente

Crie o arquivo `.env.production` com suas credenciais:

```bash
nano .env.production
```

Cole o conteúdo:

```env
# Supabase Configuration
NEXT_PUBLIC_SUPABASE_URL=https://ixenaufwnyqlkzpgwzoe.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=sua-chave-anon-aqui
SUPABASE_SERVICE_ROLE_KEY=sua-chave-service-role-aqui

# Meta Graph API Configuration
GRAPH_API_VERSION=v21.0
GRAPH_API_URL=https://graph.facebook.com/v21.0

# URL do Backend
NEXT_PUBLIC_BACKEND_URL=https://gestor.disparazap.com
```

**IMPORTANTE:** Configure o **Site URL** no Supabase para `https://gestor.disparazap.com`

### 4. Dar permissão de execução ao script

```bash
chmod +x deploy.sh
```

### 5. Executar o deploy

```bash
./deploy.sh
```

## Comandos Úteis

### Ver logs em tempo real

```bash
docker service logs -f insights_insights-dashboard
```

### Ver status do serviço

```bash
docker service ls | grep insights
docker service ps insights_insights-dashboard
```

### Atualizar aplicação (após git push)

```bash
./deploy.sh
```

### Escalar replicas (opcional)

```bash
docker service scale insights_insights-dashboard=3
```

### Remover stack (cuidado!)

```bash
docker stack rm insights
```

## Troubleshooting

### Serviço não inicia

```bash
# Verificar logs detalhados
docker service logs insights_insights-dashboard --tail 100

# Verificar se a imagem foi buildada
docker images | grep insights

# Verificar se a rede traefik-public existe
docker network ls | grep traefik
```

### SSL não funciona

Verifique se:
- DNS do domínio `gestor.disparazap.com` aponta para o IP da VPS
- Traefik está rodando: `docker service ls | grep traefik`
- Porta 443 está aberta no firewall

### Rebuild forçado

```bash
docker build --no-cache -t insights-dashboard:latest .
docker stack deploy -c docker-compose.prod.yml insights
```

## Monitoramento

### Health Check

O serviço tem health check configurado. Verifique:

```bash
docker service inspect insights_insights-dashboard --format='{{json .Health}}'
```

### Recursos do Container

```bash
docker stats $(docker ps -q -f name=insights)
```

## Rollback

Para voltar para versão anterior:

```bash
# Ver versões disponíveis
git log --oneline -10

# Voltar para commit específico
git checkout <commit-hash>

# Fazer deploy da versão antiga
./deploy.sh
```
