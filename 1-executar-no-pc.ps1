# ========================================
# PASSO 1: Execute este script no seu PC
# ========================================

param(
    [Parameter(Mandatory=$true)]
    [string]$VpsIp
)

Write-Host "`n🚀 Preparando deploy para VPS: $VpsIp`n" -ForegroundColor Blue

# Verificar se está no diretório correto
if (-not (Test-Path ".\docker-compose.prod.yml")) {
    Write-Host "❌ Execute este script no diretório insights_dashboard" -ForegroundColor Red
    exit 1
}

Write-Host "📦 Passo 1/4: Construindo imagem Docker..." -ForegroundColor Yellow
docker build -t insights-dashboard:latest -f Dockerfile .
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erro no build" -ForegroundColor Red
    exit 1
}

Write-Host "`n📦 Passo 2/4: Exportando imagem..." -ForegroundColor Yellow
docker save insights-dashboard:latest | gzip > insights-dashboard.tar.gz
$size = [math]::Round((Get-Item insights-dashboard.tar.gz).Length / 1MB, 2)
Write-Host "✓ Imagem exportada: ${size} MB" -ForegroundColor Green

Write-Host "`n🚚 Passo 3/4: Transferindo arquivos para VPS..." -ForegroundColor Yellow
Write-Host "   Isso pode demorar alguns minutos..." -ForegroundColor Gray

scp insights-dashboard.tar.gz root@${VpsIp}:/tmp/
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erro ao transferir imagem" -ForegroundColor Red
    exit 1
}

scp .env.production root@${VpsIp}:/tmp/
scp docker-compose.prod.yml root@${VpsIp}:/tmp/

Write-Host "`n✅ Passo 4/4: Arquivos transferidos com sucesso!" -ForegroundColor Green

# Limpar arquivo local
Remove-Item insights-dashboard.tar.gz

Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host "✅ Pronto! Agora execute no terminal da VPS:" -ForegroundColor Green
Write-Host "`ncurl -sSL https://raw.githubusercontent.com/WillCoelli/insights_dashboard/main/install-vps.sh | bash" -ForegroundColor Cyan
Write-Host "`nOu copie e cole o conteúdo do arquivo:" -ForegroundColor Yellow
Write-Host "2-executar-na-vps.sh" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Blue
