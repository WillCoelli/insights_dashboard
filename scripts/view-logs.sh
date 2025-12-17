#!/bin/bash
# Script para visualizar logs do serviço Insights Dashboard

STACK_NAME="${1:-insights}"
SERVICE_NAME="${STACK_NAME}_insights-dashboard"
LINES="${2:-100}"
FOLLOW="${3:-false}"

echo "========================================="
echo "INSIGHTS DASHBOARD - LOGS"
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
echo "Linhas: $LINES"
echo ""
echo "========================================="
echo ""

# Seguir logs em tempo real ou mostrar últimas linhas
if [ "$FOLLOW" = "true" ] || [ "$FOLLOW" = "f" ]; then
  echo "📡 Seguindo logs em tempo real (Ctrl+C para sair)..."
  echo ""
  docker service logs "$SERVICE_NAME" --follow --tail "$LINES" --timestamps
else
  echo "📄 Últimas $LINES linhas..."
  echo ""
  docker service logs "$SERVICE_NAME" --tail "$LINES" --timestamps
fi

echo ""
echo "========================================="
echo "Uso:"
echo "  ./view-logs.sh [stack_name] [linhas] [follow]"
echo ""
echo "Exemplos:"
echo "  ./view-logs.sh              # 100 últimas linhas"
echo "  ./view-logs.sh insights 50  # 50 últimas linhas"
echo "  ./view-logs.sh insights 100 true  # Seguir em tempo real"
echo "========================================="
