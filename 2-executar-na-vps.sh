#!/bin/bash

# ========================================
# PASSO 2: Execute este script na VPS
# Cole todo este conteúdo no terminal da VPS
# ========================================

set -e

echo "🚀 Instalando Insights Dashboard na VPS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Verificar se é root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}❌ Execute como root (sudo su)${NC}"
    exit 1
fi

# Verificar Docker
echo -e "${BLUE}🔍 Verificando Docker...${NC}"
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}📦 Instalando Docker...${NC}"
    curl -fsSL https://get.docker.com | sh
    systemctl enable docker
    systemctl start docker
fi
echo -e "${GREEN}✓ Docker OK${NC}"

# Criar estrutura de diretórios
echo -e "\n${BLUE}📁 Criando diretórios...${NC}"
mkdir -p /opt/insights_dashboard
mkdir -p /opt/traefik
cd /opt/insights_dashboard

# Mover arquivos transferidos
echo -e "${BLUE}📦 Movendo arquivos...${NC}"
if [ -f /tmp/.env.production ]; then
    mv /tmp/.env.production .
    echo -e "${GREEN}✓ .env.production movido${NC}"
fi

if [ -f /tmp/docker-compose.prod.yml ]; then
    mv /tmp/docker-compose.prod.yml .
    echo -e "${GREEN}✓ docker-compose.prod.yml movido${NC}"
fi

# Carregar imagem Docker
if [ -f /tmp/insights-dashboard.tar.gz ]; then
    echo -e "\n${BLUE}📦 Carregando imagem Docker (isso pode demorar)...${NC}"
    gunzip -c /tmp/insights-dashboard.tar.gz | docker load
    rm /tmp/insights-dashboard.tar.gz
    echo -e "${GREEN}✓ Imagem carregada${NC}"
fi

# Inicializar Docker Swarm
echo -e "\n${BLUE}🔧 Configurando Docker Swarm...${NC}"
if ! docker info | grep -q "Swarm: active"; then
    docker swarm init
    echo -e "${GREEN}✓ Swarm inicializado${NC}"
else
    echo -e "${GREEN}✓ Swarm já estava ativo${NC}"
fi

# Criar rede traefik-public
if ! docker network ls | grep -q "traefik-public"; then
    echo -e "${BLUE}📡 Criando rede traefik-public...${NC}"
    docker network create --driver=overlay traefik-public
    echo -e "${GREEN}✓ Rede criada${NC}"
else
    echo -e "${GREEN}✓ Rede já existe${NC}"
fi

# Configurar Traefik
echo -e "\n${BLUE}🔒 Configurando Traefik (Proxy Reverso + SSL)...${NC}"
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
      - "--log.level=INFO"
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
      restart_policy:
        condition: on-failure

volumes:
  traefik-certificates:

networks:
  traefik-public:
    external: true
TRAEFIK_EOF
    echo -e "${GREEN}✓ Traefik configurado${NC}"
fi

# Verificar se Traefik está rodando
if ! docker service ls | grep -q "traefik_traefik"; then
    echo -e "${BLUE}🚀 Iniciando Traefik...${NC}"
    docker stack deploy -c docker-compose.yml traefik
    echo -e "${GREEN}✓ Traefik iniciado${NC}"
    sleep 5
else
    echo -e "${GREEN}✓ Traefik já está rodando${NC}"
fi

# Deploy da aplicação
echo -e "\n${BLUE}🚀 Fazendo deploy da aplicação...${NC}"
cd /opt/insights_dashboard

# Carregar variáveis de ambiente
if [ -f .env.production ]; then
    export $(cat .env.production | grep -v '^#' | xargs)
fi

# Deploy
docker stack deploy -c docker-compose.prod.yml insights

echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Deploy concluído com sucesso!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Aguardar serviços iniciarem
echo -e "\n${YELLOW}⏳ Aguardando serviços iniciarem (30 segundos)...${NC}"
sleep 30

# Mostrar status
echo -e "\n${BLUE}📊 Status dos serviços:${NC}"
docker service ls

echo -e "\n${BLUE}📊 Status detalhado do Insights Dashboard:${NC}"
docker service ps insights_insights-dashboard

# Testar health check
echo -e "\n${BLUE}🏥 Testando health check...${NC}"
sleep 10
if curl -s http://localhost:3000/api/health > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Health check OK${NC}"
else
    echo -e "${YELLOW}⚠️  Health check ainda não disponível (aguarde mais alguns segundos)${NC}"
fi

# Instruções finais
echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}🎉 Instalação completa!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e "\n${BLUE}🌐 Sua aplicação estará disponível em:${NC}"
echo -e "   ${GREEN}https://gestor.disparazap.com${NC}"

echo -e "\n${YELLOW}⏰ Aguarde 2-3 minutos para:${NC}"
echo -e "   - Certificado SSL ser gerado"
echo -e "   - Aplicação inicializar completamente"

echo -e "\n${BLUE}📝 Comandos úteis:${NC}"
echo -e "   Ver logs:        ${YELLOW}docker service logs -f insights_insights-dashboard${NC}"
echo -e "   Ver status:      ${YELLOW}docker service ps insights_insights-dashboard${NC}"
echo -e "   Ver serviços:    ${YELLOW}docker service ls${NC}"
echo -e "   Reiniciar:       ${YELLOW}docker service update --force insights_insights-dashboard${NC}"

echo -e "\n${BLUE}🔍 Verificar se está funcionando:${NC}"
echo -e "   ${YELLOW}curl -I https://gestor.disparazap.com${NC}"

echo -e "\n${GREEN}✅ Tudo pronto!${NC}\n"
