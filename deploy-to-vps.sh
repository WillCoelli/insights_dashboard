#!/bin/bash

# ========================================
# Deploy Insights Dashboard do PC para VPS
# ========================================

set -e

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configurações - ALTERE AQUI
VPS_USER="root"
VPS_HOST="seu-ip-ou-dominio"
VPS_DEPLOY_PATH="/opt/insights_dashboard"
IMAGE_NAME="insights-dashboard"
IMAGE_TAG="latest"

echo -e "${BLUE}🚀 Deploy do Insights Dashboard para VPS${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Verificar conexão SSH
echo -e "${YELLOW}📡 Testando conexão SSH com a VPS...${NC}"
if ! ssh -o ConnectTimeout=5 ${VPS_USER}@${VPS_HOST} "echo 'Conexão OK'" > /dev/null 2>&1; then
    echo -e "${RED}❌ Falha ao conectar na VPS. Verifique as credenciais.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Conexão SSH OK${NC}"

# Build da imagem local
echo -e "\n${BLUE}🏗️  Construindo imagem Docker...${NC}"
docker build \
  --build-arg NEXT_PUBLIC_SUPABASE_URL=$(grep NEXT_PUBLIC_SUPABASE_URL .env.production | cut -d '=' -f2) \
  --build-arg NEXT_PUBLIC_SUPABASE_ANON_KEY=$(grep NEXT_PUBLIC_SUPABASE_ANON_KEY .env.production | cut -d '=' -f2) \
  --build-arg NEXT_PUBLIC_BACKEND_URL=$(grep NEXT_PUBLIC_BACKEND_URL .env.production | cut -d '=' -f2) \
  -t ${IMAGE_NAME}:${IMAGE_TAG} \
  -f Dockerfile .
echo -e "${GREEN}✓ Imagem construída${NC}"

# Salvar e comprimir imagem
echo -e "\n${BLUE}📦 Exportando imagem...${NC}"
docker save ${IMAGE_NAME}:${IMAGE_TAG} | gzip > /tmp/${IMAGE_NAME}.tar.gz
IMAGE_SIZE=$(du -h /tmp/${IMAGE_NAME}.tar.gz | cut -f1)
echo -e "${GREEN}✓ Imagem exportada (${IMAGE_SIZE})${NC}"

# Transferir imagem para VPS
echo -e "\n${BLUE}🚚 Transferindo imagem para VPS...${NC}"
scp /tmp/${IMAGE_NAME}.tar.gz ${VPS_USER}@${VPS_HOST}:/tmp/
echo -e "${GREEN}✓ Transferência concluída${NC}"

# Criar estrutura de diretórios na VPS
echo -e "\n${BLUE}📁 Preparando diretórios na VPS...${NC}"
ssh ${VPS_USER}@${VPS_HOST} << 'EOF'
mkdir -p /opt/insights_dashboard
EOF
echo -e "${GREEN}✓ Diretórios criados${NC}"

# Transferir arquivos de configuração
echo -e "\n${BLUE}📄 Transferindo arquivos de configuração...${NC}"
scp .env.production ${VPS_USER}@${VPS_HOST}:${VPS_DEPLOY_PATH}/.env.production
scp docker-compose.prod.yml ${VPS_USER}@${VPS_HOST}:${VPS_DEPLOY_PATH}/docker-compose.prod.yml
scp deploy.sh ${VPS_USER}@${VPS_HOST}:${VPS_DEPLOY_PATH}/deploy.sh
echo -e "${GREEN}✓ Arquivos transferidos${NC}"

# Carregar imagem e fazer deploy na VPS
echo -e "\n${BLUE}🚢 Fazendo deploy na VPS...${NC}"
ssh ${VPS_USER}@${VPS_HOST} << EOF
set -e

# Carregar imagem Docker
echo "Carregando imagem Docker..."
gunzip -c /tmp/${IMAGE_NAME}.tar.gz | docker load
rm /tmp/${IMAGE_NAME}.tar.gz

# Entrar no diretório do projeto
cd ${VPS_DEPLOY_PATH}

# Verificar se Docker Swarm está ativo
if ! docker info | grep -q "Swarm: active"; then
    echo "⚠️  Inicializando Docker Swarm..."
    docker swarm init
fi

# Criar rede traefik-public se não existir
if ! docker network ls | grep -q "traefik-public"; then
    echo "📡 Criando rede traefik-public..."
    docker network create --driver=overlay traefik-public
fi

# Carregar variáveis de ambiente
export \$(cat .env.production | grep -v '^#' | xargs)

# Deploy no Swarm
echo "🚀 Fazendo deploy no Docker Swarm..."
docker stack deploy -c docker-compose.prod.yml insights

echo "✅ Deploy concluído!"
echo ""
echo "📊 Status dos serviços:"
docker service ls | grep insights || true

EOF

# Limpar arquivo temporário local
rm /tmp/${IMAGE_NAME}.tar.gz

echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Deploy concluído com sucesso!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}🌐 Aplicação disponível em:${NC}"
echo -e "   https://gestor.disparazap.com"
echo ""
echo -e "${BLUE}📝 Ver logs:${NC}"
echo -e "   ssh ${VPS_USER}@${VPS_HOST} 'docker service logs -f insights_insights-dashboard'"
echo ""
echo -e "${BLUE}📊 Ver status:${NC}"
echo -e "   ssh ${VPS_USER}@${VPS_HOST} 'docker service ps insights_insights-dashboard'"
echo ""
