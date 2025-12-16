#!/bin/bash

# ========================================
# Atualizar aplicacao (com Doppler)
# ========================================

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

DEPLOY_PATH="/opt/insights_dashboard"

echo -e "${BLUE}Atualizando aplicacao...${NC}\n"

cd $DEPLOY_PATH

# Baixar ultima versao do codigo
echo -e "${BLUE}Baixando codigo atualizado do GitHub...${NC}"
git fetch origin main
git reset --hard origin/main

# Rebuild com secrets do Doppler
echo -e "${BLUE}Reconstruindo imagem com secrets atualizados...${NC}"
doppler run -- docker build \
  --build-arg NEXT_PUBLIC_SUPABASE_URL=$(doppler secrets get NEXT_PUBLIC_SUPABASE_URL --plain) \
  --build-arg NEXT_PUBLIC_SUPABASE_ANON_KEY=$(doppler secrets get NEXT_PUBLIC_SUPABASE_ANON_KEY --plain) \
  --build-arg NEXT_PUBLIC_BACKEND_URL=$(doppler secrets get NEXT_PUBLIC_BACKEND_URL --plain) \
  -t insights-dashboard:latest .

# Atualizar servico
echo -e "${BLUE}Atualizando servico...${NC}"
docker service update --force insights_insights-dashboard

echo -e "\n${GREEN}Atualizacao concluida!${NC}"
echo -e "${YELLOW}Aguarde 30 segundos para a aplicacao reiniciar${NC}\n"

sleep 5
docker service ps insights_insights-dashboard
