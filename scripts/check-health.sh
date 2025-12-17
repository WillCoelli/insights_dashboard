#!/bin/bash
# Script para verificar o health do serviço Insights Dashboard

STACK_NAME="${1:-insights}"
SERVICE_NAME="${STACK_NAME}_insights-dashboard"
DOMAIN="${2:-gestor.disparazap.com}"

echo "========================================="
echo "INSIGHTS DASHBOARD - HEALTH CHECK"
echo "========================================="
echo ""

# Verificar se o serviço está rodando
echo "1. Verificando status do serviço..."
docker service ls | grep "$SERVICE_NAME" || {
  echo "❌ Serviço não encontrado: $SERVICE_NAME"
  exit 1
}

# Verificar replicas
echo ""
echo "2. Verificando réplicas..."
docker service ps "$SERVICE_NAME" --format "table {{.Name}}\t{{.Node}}\t{{.CurrentState}}\t{{.Error}}"

# Verificar health endpoint local
echo ""
echo "3. Testando health endpoint (local)..."
CONTAINER_ID=$(docker ps --filter "name=${SERVICE_NAME}" -q | head -n1)
if [ -n "$CONTAINER_ID" ]; then
  docker exec "$CONTAINER_ID" wget --no-verbose --tries=1 --spider http://localhost:3000/api/health
  if [ $? -eq 0 ]; then
    echo "✅ Health check local: OK"
  else
    echo "❌ Health check local: FALHOU"
  fi
else
  echo "⚠️  Nenhum container em execução"
fi

# Verificar health endpoint via HTTPS
echo ""
echo "4. Testando acesso HTTPS..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "https://${DOMAIN}/api/health")
if [ "$HTTP_CODE" = "200" ]; then
  echo "✅ HTTPS: OK (Status: $HTTP_CODE)"
  curl -s "https://${DOMAIN}/api/health" | jq . 2>/dev/null || echo ""
else
  echo "❌ HTTPS: FALHOU (Status: $HTTP_CODE)"
fi

# Logs recentes
echo ""
echo "5. Últimas 10 linhas de log..."
docker service logs "$SERVICE_NAME" --tail 10 --no-trunc

echo ""
echo "========================================="
echo "Health check completo!"
echo "========================================="
