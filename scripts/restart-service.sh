#!/bin/bash
# Script para reiniciar o serviço Insights Dashboard

STACK_NAME="${1:-insights}"
SERVICE_NAME="${STACK_NAME}_insights-dashboard"

echo "========================================="
echo "INSIGHTS DASHBOARD - RESTART SERVICE"
echo "========================================="
echo ""

# Verificar se o serviço existe
docker service ls | grep -q "$SERVICE_NAME" || {
  echo "❌ Serviço não encontrado: $SERVICE_NAME"
  echo ""
  echo "Serviços disponíveis:"
  docker service ls
  exit 1
}

echo "Serviço: $SERVICE_NAME"
echo ""

# Confirmar antes de reiniciar
read -p "⚠️  Tem certeza que deseja reiniciar o serviço? (s/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[SsYy]$ ]]; then
  echo "❌ Operação cancelada"
  exit 0
fi

echo ""
echo "🔄 Forçando atualização do serviço (rolling restart)..."
docker service update --force "$SERVICE_NAME"

if [ $? -eq 0 ]; then
  echo "✅ Comando de restart enviado com sucesso"
  echo ""
  echo "⏳ Aguardando nova réplica subir..."
  sleep 5

  echo ""
  echo "Status das réplicas:"
  docker service ps "$SERVICE_NAME" --format "table {{.Name}}\t{{.Node}}\t{{.CurrentState}}\t{{.Error}}" | head -n 5

  echo ""
  echo "========================================="
  echo "✅ Restart completo!"
  echo ""
  echo "Para acompanhar os logs:"
  echo "  ./view-logs.sh $STACK_NAME 50 true"
  echo "========================================="
else
  echo "❌ Falha ao reiniciar o serviço"
  exit 1
fi
