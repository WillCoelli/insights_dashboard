#!/bin/bash

# ========================================
# Script de Deploy VPS via GitHub
# Cole este script completo no terminal da VPS
# ========================================

set -e

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🚀 Deploy Insights Dashboard via GitHub"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${NC}"

# Configurações - ALTERE AQUI
GITHUB_REPO="https://github.com/SEU-USUARIO/insights-dashboard.git"
DEPLOY_PATH="/opt/insights_dashboard"
DOMAIN="gestor.disparazap.com"

# Perguntar URL do GitHub se não configurada
if [[ $GITHUB_REPO == *"SEU-USUARIO"* ]]; then
    echo -e "${YELLOW}📝 Cole a URL do repositório GitHub:${NC}"
    read -p "URL: " GITHUB_REPO
fi

# Verificar se é root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}❌ Execute como root: sudo su${NC}"
    exit 1
fi

# Atualizar sistema
echo -e "\n${BLUE}📦 Atualizando sistema...${NC}"
apt-get update -qq

# Instalar Git
if ! command -v git &> /dev/null; then
    echo -e "${BLUE}📦 Instalando Git...${NC}"
    apt-get install -y git curl
fi

# Instalar Docker
if ! command -v docker &> /dev/null; then
    echo -e "${BLUE}🐳 Instalando Docker...${NC}"
    curl -fsSL https://get.docker.com | sh
    systemctl enable docker
    systemctl start docker
fi

echo -e "${GREEN}✓ Dependências OK${NC}"

# Clonar/Atualizar repositório
echo -e "\n${BLUE}📥 Baixando código do GitHub...${NC}"
if [ -d "$DEPLOY_PATH" ]; then
    echo -e "${YELLOW}  Diretório existe, atualizando...${NC}"
    cd $DEPLOY_PATH
    git fetch origin main
    git reset --hard origin/main
else
    mkdir -p $(dirname $DEPLOY_PATH)
    git clone $GITHUB_REPO $DEPLOY_PATH
    cd $DEPLOY_PATH
fi

echo -e "${GREEN}✓ Código baixado${NC}"

# Verificar se .env.production existe
if [ ! -f .env.production ]; then
    echo -e "${RED}❌ Arquivo .env.production não encontrado!${NC}"
    echo -e "${YELLOW}"
    echo "Por favor, crie o arquivo .env.production com suas configurações:"
    echo ""
    echo "cat > .env.production << 'EOF'"
    echo "NEXT_PUBLIC_SUPABASE_URL=https://seu-projeto.supabase.co"
    echo "NEXT_PUBLIC_SUPABASE_ANON_KEY=sua-chave-aqui"
    echo "SUPABASE_SERVICE_ROLE_KEY=sua-chave-service-aqui"
    echo "GRAPH_API_VERSION=v21.0"
    echo "NEXT_PUBLIC_BACKEND_URL=https://$DOMAIN"
    echo "EOF"
    echo -e "${NC}"
    exit 1
fi

# Configurar Docker Swarm
echo -e "\n${BLUE}🔧 Configurando Docker Swarm...${NC}"
if ! docker info | grep -q "Swarm: active"; then
    docker swarm init
    echo -e "${GREEN}✓ Swarm inicializado${NC}"
else
    echo -e "${GREEN}✓ Swarm já ativo${NC}"
fi

# Criar rede
if ! docker network ls | grep -q "traefik-public"; then
    docker network create --driver=overlay traefik-public
    echo -e "${GREEN}✓ Rede criada${NC}"
else
    echo -e "${GREEN}✓ Rede já existe${NC}"
fi

# Configurar Traefik
echo -e "\n${BLUE}🔒 Configurando Traefik (SSL Automático)...${NC}"
mkdir -p /opt/traefik
cd /opt/traefik

if [ ! -f docker-compose.yml ]; then
    cat > docker-compose.yml << 'TRAEFIK_EOF'
version: '3.8'

services:
  traefik:
    image: traefik:v2.10
    command:
      - "--api.dashboard=true"
      - "--providers.docker.swarmMode=true"
      - "--providers.docker.exposedbydefault=false"
      - "--providers.docker.network=traefik-public"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
      - "--certificatesresolvers.letsencrypt.acme.email=contato@disparazap.com"
      - "--certificatesresolvers.letsencrypt.acme.storage=/letsencrypt/acme.json"
      - "--certificatesresolvers.letsencrypt.acme.httpchallenge=true"
      - "--certificatesresolvers.letsencrypt.acme.httpchallenge.entrypoint=web"
      - "--entrypoints.web.http.redirections.entryPoint.to=websecure"
      - "--entrypoints.web.http.redirections.entryPoint.scheme=https"
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - traefik-certificates:/letsencrypt
    networks:
      - traefik-public
    deploy:
      placement:
        constraints:
          - node.role == manager

volumes:
  traefik-certificates:

networks:
  traefik-public:
    external: true
TRAEFIK_EOF
fi

if ! docker service ls | grep -q "traefik_traefik"; then
    docker stack deploy -c docker-compose.yml traefik
    echo -e "${GREEN}✓ Traefik iniciado${NC}"
    sleep 5
else
    echo -e "${GREEN}✓ Traefik já rodando${NC}"
fi

# Build e Deploy da aplicação
echo -e "\n${BLUE}🏗️  Buildando aplicação...${NC}"
cd $DEPLOY_PATH

# Carregar variáveis de ambiente
export $(cat .env.production | grep -v '^#' | xargs)

# Build da imagem
docker build -t insights-dashboard:latest .

echo -e "\n${BLUE}🚀 Fazendo deploy...${NC}"
docker stack deploy -c docker-compose.prod.yml insights

# Aguardar inicialização
echo -e "\n${YELLOW}⏳ Aguardando serviços iniciarem...${NC}"
sleep 15

# Mostrar status
echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Deploy concluído com sucesso!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e "\n${BLUE}📊 Status dos serviços:${NC}"
docker service ls

echo -e "\n${BLUE}🌐 Aplicação disponível em:${NC}"
echo -e "   ${GREEN}https://$DOMAIN${NC}"

echo -e "\n${YELLOW}⏰ Aguarde 2-3 minutos para o SSL ser configurado${NC}"

echo -e "\n${BLUE}📝 Comandos úteis:${NC}"
echo -e "   Ver logs:     ${YELLOW}docker service logs -f insights_insights-dashboard${NC}"
echo -e "   Ver status:   ${YELLOW}docker service ps insights_insights-dashboard${NC}"
echo -e "   Atualizar:    ${YELLOW}cd $DEPLOY_PATH && git pull && docker build -t insights-dashboard:latest . && docker service update --force insights_insights-dashboard${NC}"

echo -e "\n${GREEN}🎉 Tudo pronto!${NC}\n"
