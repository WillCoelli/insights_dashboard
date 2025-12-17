#!/bin/bash
#==============================================================================
# INSIGHTS DASHBOARD - DEPLOY AUTOMÁTICO VPS
# Versão: 1.1.0
# Sistema: Debian 12 + Docker Swarm + Traefik
# Domínio: gestor.disparazap.com
#==============================================================================

set -e  # Parar em caso de erro

echo "========================================="
echo "🚀 INSIGHTS DASHBOARD - DEPLOY v1.1.0"
echo "========================================="
echo ""

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

#==============================================================================
# FUNÇÃO: Verificar se comando existe
#==============================================================================
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

#==============================================================================
# PASSO 1: Verificar/Instalar Docker
#==============================================================================
echo "📦 [1/9] Verificando Docker..."
if command_exists docker; then
    echo -e "${GREEN}✅ Docker já instalado: $(docker --version)${NC}"
else
    echo -e "${YELLOW}⚠️  Docker não encontrado. Instalando...${NC}"
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
    echo -e "${GREEN}✅ Docker instalado com sucesso${NC}"
fi
echo ""

#==============================================================================
# PASSO 2: Inicializar Docker Swarm
#==============================================================================
echo "🐝 [2/9] Verificando Docker Swarm..."
if docker info 2>/dev/null | grep -q "Swarm: active"; then
    echo -e "${GREEN}✅ Docker Swarm já está ativo${NC}"
else
    echo -e "${YELLOW}⚠️  Inicializando Docker Swarm...${NC}"
    docker swarm init
    echo -e "${GREEN}✅ Docker Swarm inicializado${NC}"
fi
echo ""

#==============================================================================
# PASSO 3: Criar network traefik-public
#==============================================================================
echo "🌐 [3/9] Verificando network traefik-public..."
if docker network ls | grep -q "traefik-public"; then
    echo -e "${GREEN}✅ Network traefik-public já existe${NC}"
else
    echo -e "${YELLOW}⚠️  Criando network traefik-public...${NC}"
    docker network create --driver=overlay traefik-public
    echo -e "${GREEN}✅ Network criada com sucesso${NC}"
fi
echo ""

#==============================================================================
# PASSO 4: Preparar diretório de deploy
#==============================================================================
echo "📁 [4/9] Preparando diretório..."
DEPLOY_DIR="$HOME/insights-deploy"
mkdir -p "$DEPLOY_DIR"
cd "$DEPLOY_DIR"
echo -e "${GREEN}✅ Diretório: $DEPLOY_DIR${NC}"
echo ""

#==============================================================================
# PASSO 5: Baixar arquivos da stack
#==============================================================================
echo "⬇️  [5/9] Baixando arquivos de configuração..."

# Backup de arquivos existentes
if [ -f "docker-stack.yml" ]; then
    cp docker-stack.yml docker-stack.yml.bak
    echo "   📦 Backup: docker-stack.yml.bak"
fi
if [ -f ".env" ]; then
    cp .env .env.bak
    echo "   📦 Backup: .env.bak"
fi

# Baixar arquivos
wget -q -O docker-stack.yml https://raw.githubusercontent.com/WillCoelli/insights_dashboard/main/docker-stack.yml
wget -q -O traefik-stack.yml https://raw.githubusercontent.com/WillCoelli/insights_dashboard/main/traefik-stack.yml
wget -q -O .env.production.example https://raw.githubusercontent.com/WillCoelli/insights_dashboard/main/.env.production.example

echo -e "${GREEN}✅ Arquivos baixados com sucesso${NC}"
echo ""

#==============================================================================
# PASSO 6: Configurar variáveis de ambiente
#==============================================================================
echo "⚙️  [6/9] Configurando variáveis de ambiente..."
echo ""

# Se .env.bak existe e contém as variáveis, usar como base
if [ -f ".env.bak" ] && grep -q "NEXT_PUBLIC_SUPABASE_URL" .env.bak; then
    echo -e "${YELLOW}📋 Arquivo .env anterior encontrado. Deseja reutilizar? (s/N)${NC}"
    read -r REUSE_ENV
    if [[ "$REUSE_ENV" =~ ^[SsYy]$ ]]; then
        cp .env.bak .env
        echo -e "${GREEN}✅ Variáveis anteriores reutilizadas${NC}"
    else
        cp .env.production.example .env
        echo -e "${YELLOW}⚠️  Configure as variáveis em: $DEPLOY_DIR/.env${NC}"
        echo -e "${YELLOW}⚠️  Variáveis OBRIGATÓRIAS:${NC}"
        echo "   - NEXT_PUBLIC_SUPABASE_URL"
        echo "   - NEXT_PUBLIC_SUPABASE_ANON_KEY"
        echo "   - SUPABASE_SERVICE_ROLE_KEY"
        echo "   - ACME_EMAIL"
        echo ""
        echo "Pressione ENTER para editar o arquivo .env agora..."
        read -r
        nano .env
    fi
else
    cp .env.production.example .env
    echo -e "${YELLOW}⚠️  Configure as variáveis OBRIGATÓRIAS:${NC}"
    echo "   - NEXT_PUBLIC_SUPABASE_URL"
    echo "   - NEXT_PUBLIC_SUPABASE_ANON_KEY"
    echo "   - SUPABASE_SERVICE_ROLE_KEY"
    echo "   - ACME_EMAIL"
    echo ""
    echo "Pressione ENTER para editar o arquivo .env agora..."
    read -r
    nano .env
fi
echo ""

# Carregar variáveis
set -a
source .env
set +a

# Validar variáveis obrigatórias
echo "🔍 Validando variáveis obrigatórias..."
MISSING_VARS=()

if [ -z "$NEXT_PUBLIC_SUPABASE_URL" ] || [ "$NEXT_PUBLIC_SUPABASE_URL" = "https://seu-projeto.supabase.co" ]; then
    MISSING_VARS+=("NEXT_PUBLIC_SUPABASE_URL")
fi

if [ -z "$NEXT_PUBLIC_SUPABASE_ANON_KEY" ] || [[ "$NEXT_PUBLIC_SUPABASE_ANON_KEY" == *"..."* ]]; then
    MISSING_VARS+=("NEXT_PUBLIC_SUPABASE_ANON_KEY")
fi

if [ -z "$SUPABASE_SERVICE_ROLE_KEY" ] || [[ "$SUPABASE_SERVICE_ROLE_KEY" == *"..."* ]]; then
    MISSING_VARS+=("SUPABASE_SERVICE_ROLE_KEY")
fi

if [ -z "$ACME_EMAIL" ] || [ "$ACME_EMAIL" = "seu-email@exemplo.com" ]; then
    MISSING_VARS+=("ACME_EMAIL")
fi

if [ ${#MISSING_VARS[@]} -gt 0 ]; then
    echo -e "${RED}❌ Variáveis obrigatórias não configuradas:${NC}"
    for var in "${MISSING_VARS[@]}"; do
        echo -e "${RED}   - $var${NC}"
    done
    echo ""
    echo -e "${YELLOW}Por favor, edite o arquivo .env e configure as variáveis.${NC}"
    echo "Comando: nano $DEPLOY_DIR/.env"
    exit 1
fi

echo -e "${GREEN}✅ Todas as variáveis obrigatórias configuradas${NC}"
echo ""

#==============================================================================
# PASSO 7: Deploy Traefik
#==============================================================================
echo "🔀 [7/9] Deploy do Traefik (Reverse Proxy + HTTPS)..."

# Verificar se Traefik já está rodando
if docker service ls | grep -q "traefik_traefik"; then
    echo -e "${YELLOW}⚠️  Traefik já está em execução. Atualizar? (s/N)${NC}"
    read -r UPDATE_TRAEFIK
    if [[ "$UPDATE_TRAEFIK" =~ ^[SsYy]$ ]]; then
        docker stack deploy -c traefik-stack.yml traefik
        echo -e "${GREEN}✅ Traefik atualizado${NC}"
    else
        echo -e "${YELLOW}⏭️  Pulando deploy do Traefik${NC}"
    fi
else
    docker stack deploy -c traefik-stack.yml traefik
    echo -e "${GREEN}✅ Traefik deployado com sucesso${NC}"
    echo "   ⏳ Aguardando 15 segundos para Traefik inicializar..."
    sleep 15
fi
echo ""

#==============================================================================
# PASSO 8: Deploy Insights Dashboard
#==============================================================================
echo "🚀 [8/9] Deploy do Insights Dashboard..."

# Fazer pull da imagem antes do deploy
echo "   📥 Baixando imagem ghcr.io/willcoelli/insights_dashboard:1.1.0..."
docker pull ghcr.io/willcoelli/insights_dashboard:1.1.0 2>/dev/null || {
    echo -e "${YELLOW}⚠️  Aviso: Não foi possível fazer pull da imagem (pode ser permissão)${NC}"
    echo -e "${YELLOW}   O deploy tentará baixar automaticamente.${NC}"
}

docker stack deploy -c docker-stack.yml insights
echo -e "${GREEN}✅ Insights Dashboard deployado com sucesso${NC}"
echo ""

#==============================================================================
# PASSO 9: Verificar status
#==============================================================================
echo "📊 [9/9] Verificando status do deploy..."
echo ""

echo "Aguardando 10 segundos para os serviços subirem..."
sleep 10

echo ""
echo "========================================="
echo "📋 STATUS DOS SERVIÇOS"
echo "========================================="
docker service ls

echo ""
echo "========================================="
echo "📋 RÉPLICAS - INSIGHTS DASHBOARD"
echo "========================================="
docker service ps insights_insights-dashboard --format "table {{.Name}}\t{{.Node}}\t{{.CurrentState}}\t{{.Error}}"

echo ""
echo "========================================="
echo "✅ DEPLOY COMPLETO!"
echo "========================================="
echo ""
echo "🌐 URL: https://gestor.disparazap.com"
echo ""
echo "📌 Comandos úteis:"
echo ""
echo "   # Ver logs em tempo real"
echo "   docker service logs insights_insights-dashboard -f"
echo ""
echo "   # Verificar serviços"
echo "   docker service ls"
echo ""
echo "   # Testar health"
echo "   curl https://gestor.disparazap.com/api/health"
echo ""
echo "   # Escalar réplicas"
echo "   docker service scale insights_insights-dashboard=4"
echo ""
echo "   # Reiniciar serviço"
echo "   docker service update --force insights_insights-dashboard"
echo ""
echo "========================================="
echo ""

# Testar endpoint de health (se curl estiver disponível)
if command_exists curl; then
    echo "🔍 Testando endpoint de health em 20 segundos..."
    sleep 20
    echo ""
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://gestor.disparazap.com/api/health 2>/dev/null || echo "000")
    if [ "$HTTP_CODE" = "200" ]; then
        echo -e "${GREEN}✅ HTTPS funcionando! Status: $HTTP_CODE${NC}"
        curl -s https://gestor.disparazap.com/api/health 2>/dev/null | grep -q "healthy" && echo -e "${GREEN}✅ Health check: OK${NC}"
    else
        echo -e "${YELLOW}⚠️  HTTPS ainda não está respondendo (Status: $HTTP_CODE)${NC}"
        echo -e "${YELLOW}   Aguarde alguns minutos para o Let's Encrypt gerar o certificado.${NC}"
        echo -e "${YELLOW}   DNS: Certifique-se que gestor.disparazap.com aponta para este servidor.${NC}"
    fi
fi

echo ""
echo "========================================="
echo "📖 Documentação completa:"
echo "   https://github.com/WillCoelli/insights_dashboard/blob/main/DEPLOY-PRODUCTION.md"
echo "========================================="
echo ""
