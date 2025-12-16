#!/bin/bash

# ========================================
# Script de Atualização Rápida
# Execute na VPS para atualizar do GitHub
# ========================================

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

DEPLOY_PATH="/opt/insights_dashboard"

echo -e "${BLUE}🔄 Atualizando aplicação...${NC}\n"

cd $DEPLOY_PATH

# Baixar última versão
echo -e "${BLUE}📥 Baixando código atualizado...${NC}"
git fetch origin main
git reset --hard origin/main

# Carregar env
export $(cat .env.production | grep -v '^#' | xargs)

# Rebuild
echo -e "${BLUE}🏗️  Reconstruindo imagem...${NC}"
docker build -t insights-dashboard:latest .

# Atualizar serviço
echo -e "${BLUE}🚀 Atualizando serviço...${NC}"
docker service update --force insights_insights-dashboard

echo -e "\n${GREEN}✅ Atualização concluída!${NC}"
echo -e "${YELLOW}⏰ Aguarde 30 segundos para a aplicação reiniciar${NC}\n"

sleep 5
docker service ps insights_insights-dashboard
