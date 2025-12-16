#!/bin/bash

# Script de Deploy para VPS com Docker Swarm
# Uso: ./deploy.sh

set -e

echo "🚀 Iniciando deploy do Insights Dashboard..."

# Cores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Verificar se está no Swarm
if ! docker info | grep -q "Swarm: active"; then
    echo -e "${RED}❌ Docker Swarm não está ativo!${NC}"
    exit 1
fi

# Verificar se arquivo .env existe
if [ ! -f .env.production ]; then
    echo -e "${RED}❌ Arquivo .env.production não encontrado!${NC}"
    echo "Crie o arquivo .env.production com as variáveis necessárias"
    exit 1
fi

# Carregar variáveis de ambiente
export $(cat .env.production | grep -v '^#' | xargs)

echo -e "${BLUE}📦 Fazendo pull do código...${NC}"
git pull origin main

echo -e "${BLUE}🏗️  Buildando imagem...${NC}"
docker build \
  --build-arg NEXT_PUBLIC_SUPABASE_URL=${NEXT_PUBLIC_SUPABASE_URL} \
  --build-arg NEXT_PUBLIC_SUPABASE_ANON_KEY=${NEXT_PUBLIC_SUPABASE_ANON_KEY} \
  --build-arg NEXT_PUBLIC_BACKEND_URL=${NEXT_PUBLIC_BACKEND_URL} \
  -t insights-dashboard:latest \
  -f Dockerfile .

echo -e "${BLUE}🚢 Fazendo deploy no Swarm...${NC}"
docker stack deploy -c docker-compose.prod.yml insights --with-registry-auth

echo -e "${GREEN}✅ Deploy concluído com sucesso!${NC}"
echo ""
echo -e "${BLUE}📊 Status do serviço:${NC}"
docker service ls | grep insights

echo ""
echo -e "${BLUE}📝 Logs (CTRL+C para sair):${NC}"
docker service logs -f insights_insights-dashboard
