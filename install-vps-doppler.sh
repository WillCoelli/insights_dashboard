#!/bin/bash

# ========================================
# Deploy VPS com Doppler (Secrets Manager)
# ========================================

set -e

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}"
echo "========================================"
echo "  Deploy Insights Dashboard + Doppler"
echo "========================================"
echo -e "${NC}"

# Configuracoes
GITHUB_REPO="https://github.com/SEU-USUARIO/insights-dashboard.git"
DEPLOY_PATH="/opt/insights_dashboard"
DOMAIN="gestor.disparazap.com"

# Perguntar URL do GitHub
if [[ $GITHUB_REPO == *"SEU-USUARIO"* ]]; then
    echo -e "${YELLOW}Cole a URL do repositorio GitHub:${NC}"
    read -p "URL: " GITHUB_REPO
fi

# Perguntar token do Doppler
echo -e "${YELLOW}Cole o Service Token do Doppler:${NC}"
echo -e "${BLUE}(Comeca com dp.st.prd...)${NC}"
read -p "Token: " DOPPLER_TOKEN

# Verificar root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Execute como root: sudo su${NC}"
    exit 1
fi

# Atualizar sistema
echo -e "\n${BLUE}Atualizando sistema...${NC}"
apt-get update -qq

# Instalar dependencias
echo -e "${BLUE}Instalando dependencias...${NC}"
apt-get install -y git curl gnupg

# Instalar Doppler CLI
if ! command -v doppler &> /dev/null; then
    echo -e "${BLUE}Instalando Doppler CLI...${NC}"
    curl -sLf --retry 3 --tlsv1.2 --proto "=https" 'https://packages.doppler.com/public/cli/gpg.DE2A7741A397C129.key' | gpg --dearmor -o /usr/share/keyrings/doppler-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/doppler-archive-keyring.gpg] https://packages.doppler.com/public/cli/deb/debian any-version main" | tee /etc/apt/sources.list.d/doppler-cli.list
    apt-get update
    apt-get install -y doppler
    echo -e "${GREEN}Doppler CLI instalado${NC}"
fi

# Instalar Docker
if ! command -v docker &> /dev/null; then
    echo -e "${BLUE}Instalando Docker...${NC}"
    curl -fsSL https://get.docker.com | sh
    systemctl enable docker
    systemctl start docker
fi

echo -e "${GREEN}Dependencias OK${NC}"

# Clonar repositorio
echo -e "\n${BLUE}Baixando codigo do GitHub...${NC}"
if [ -d "$DEPLOY_PATH" ]; then
    cd $DEPLOY_PATH
    git fetch origin main
    git reset --hard origin/main
else
    mkdir -p $(dirname $DEPLOY_PATH)
    git clone $GITHUB_REPO $DEPLOY_PATH
    cd $DEPLOY_PATH
fi

echo -e "${GREEN}Codigo baixado${NC}"

# Configurar Doppler
echo -e "\n${BLUE}Configurando Doppler...${NC}"
cd $DEPLOY_PATH
echo "$DOPPLER_TOKEN" | doppler configure set token --scope .

# Testar Doppler
echo -e "${BLUE}Testando conexao com Doppler...${NC}"
if doppler secrets --silent > /dev/null 2>&1; then
    echo -e "${GREEN}Doppler configurado com sucesso!${NC}"
else
    echo -e "${RED}Erro ao conectar com Doppler. Verifique o token.${NC}"
    exit 1
fi

# Configurar Docker Swarm
echo -e "\n${BLUE}Configurando Docker Swarm...${NC}"
if ! docker info | grep -q "Swarm: active"; then
    docker swarm init
    echo -e "${GREEN}Swarm inicializado${NC}"
else
    echo -e "${GREEN}Swarm ja ativo${NC}"
fi

# Criar rede
if ! docker network ls | grep -q "traefik-public"; then
    docker network create --driver=overlay traefik-public
    echo -e "${GREEN}Rede criada${NC}"
else
    echo -e "${GREEN}Rede ja existe${NC}"
fi

# Configurar Traefik
echo -e "\n${BLUE}Configurando Traefik (SSL Automatico)...${NC}"
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
    echo -e "${GREEN}Traefik iniciado${NC}"
    sleep 5
else
    echo -e "${GREEN}Traefik ja rodando${NC}"
fi

# Build da aplicacao
echo -e "\n${BLUE}Buildando aplicacao com secrets do Doppler...${NC}"
cd $DEPLOY_PATH

# Build usando doppler para injetar as variaveis
doppler run -- docker build \
  --build-arg NEXT_PUBLIC_SUPABASE_URL=$(doppler secrets get NEXT_PUBLIC_SUPABASE_URL --plain) \
  --build-arg NEXT_PUBLIC_SUPABASE_ANON_KEY=$(doppler secrets get NEXT_PUBLIC_SUPABASE_ANON_KEY --plain) \
  --build-arg NEXT_PUBLIC_BACKEND_URL=$(doppler secrets get NEXT_PUBLIC_BACKEND_URL --plain) \
  -t insights-dashboard:latest .

# Criar arquivo .env temporario para o docker stack
echo -e "${BLUE}Preparando variaveis de ambiente...${NC}"
doppler secrets download --no-file --format env > /tmp/doppler.env

# Carregar variaveis
export $(cat /tmp/doppler.env | xargs)
rm /tmp/doppler.env

# Deploy
echo -e "\n${BLUE}Fazendo deploy...${NC}"
docker stack deploy -c docker-compose.prod.yml insights

# Aguardar
echo -e "\n${YELLOW}Aguardando servicos iniciarem...${NC}"
sleep 15

# Status
echo -e "\n${BLUE}========================================${NC}"
echo -e "${GREEN}Deploy concluido com sucesso!${NC}"
echo -e "${BLUE}========================================${NC}"

echo -e "\n${BLUE}Status dos servicos:${NC}"
docker service ls

echo -e "\n${BLUE}Aplicacao disponivel em:${NC}"
echo -e "   ${GREEN}https://$DOMAIN${NC}"

echo -e "\n${YELLOW}Aguarde 2-3 minutos para o SSL ser configurado${NC}"

echo -e "\n${BLUE}Comandos uteis:${NC}"
echo -e "   Ver logs:     ${YELLOW}docker service logs -f insights_insights-dashboard${NC}"
echo -e "   Ver secrets:  ${YELLOW}cd $DEPLOY_PATH && doppler secrets${NC}"
echo -e "   Atualizar:    ${YELLOW}bash $DEPLOY_PATH/atualizar-vps-doppler.sh${NC}"

echo -e "\n${GREEN}Tudo pronto!${NC}\n"
