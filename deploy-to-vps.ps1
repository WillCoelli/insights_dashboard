# ========================================
# Deploy Insights Dashboard do PC para VPS
# Script PowerShell para Windows
# ========================================

param(
    [Parameter(Mandatory=$false)]
    [string]$VpsUser = "root",

    [Parameter(Mandatory=$true)]
    [string]$VpsHost,

    [Parameter(Mandatory=$false)]
    [string]$VpsPath = "/opt/insights_dashboard"
)

$ErrorActionPreference = "Stop"

$ImageName = "insights-dashboard"
$ImageTag = "latest"

Write-Host "`n🚀 Deploy do Insights Dashboard para VPS" -ForegroundColor Blue
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Blue

# Verificar se SSH está disponível
Write-Host "📡 Verificando conectividade SSH..." -ForegroundColor Yellow
try {
    ssh -o ConnectTimeout=5 "${VpsUser}@${VpsHost}" "echo 'OK'" | Out-Null
    Write-Host "✓ Conexão SSH OK`n" -ForegroundColor Green
} catch {
    Write-Host "❌ Falha ao conectar na VPS" -ForegroundColor Red
    Write-Host "Certifique-se de que o SSH está configurado e acessível" -ForegroundColor Red
    exit 1
}

# Ler variáveis do .env.production
Write-Host "📋 Lendo variáveis de ambiente..." -ForegroundColor Yellow
$envContent = Get-Content .env.production
$supabaseUrl = ($envContent | Select-String "NEXT_PUBLIC_SUPABASE_URL=").ToString().Split("=")[1]
$supabaseKey = ($envContent | Select-String "NEXT_PUBLIC_SUPABASE_ANON_KEY=").ToString().Split("=")[1]
$backendUrl = ($envContent | Select-String "NEXT_PUBLIC_BACKEND_URL=").ToString().Split("=")[1]
Write-Host "✓ Variáveis carregadas`n" -ForegroundColor Green

# Build da imagem
Write-Host "🏗️  Construindo imagem Docker..." -ForegroundColor Blue
docker build `
    --build-arg NEXT_PUBLIC_SUPABASE_URL=$supabaseUrl `
    --build-arg NEXT_PUBLIC_SUPABASE_ANON_KEY=$supabaseKey `
    --build-arg NEXT_PUBLIC_BACKEND_URL=$backendUrl `
    -t "${ImageName}:${ImageTag}" `
    -f Dockerfile .

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erro ao construir imagem" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Imagem construída`n" -ForegroundColor Green

# Exportar imagem
Write-Host "📦 Exportando imagem..." -ForegroundColor Blue
$tempFile = "$env:TEMP\${ImageName}.tar.gz"
docker save "${ImageName}:${ImageTag}" | gzip > $tempFile

$fileSize = [math]::Round((Get-Item $tempFile).Length / 1MB, 2)
Write-Host "✓ Imagem exportada (${fileSize} MB)`n" -ForegroundColor Green

# Transferir imagem
Write-Host "🚚 Transferindo imagem para VPS (isso pode demorar)..." -ForegroundColor Blue
scp $tempFile "${VpsUser}@${VpsHost}:/tmp/${ImageName}.tar.gz"
Write-Host "✓ Imagem transferida`n" -ForegroundColor Green

# Criar diretórios na VPS
Write-Host "📁 Preparando VPS..." -ForegroundColor Blue
ssh "${VpsUser}@${VpsHost}" "mkdir -p ${VpsPath}"
Write-Host "✓ Diretórios criados`n" -ForegroundColor Green

# Transferir arquivos de configuração
Write-Host "📄 Transferindo arquivos de configuração..." -ForegroundColor Blue
scp .env.production "${VpsUser}@${VpsHost}:${VpsPath}/.env.production"
scp docker-compose.prod.yml "${VpsUser}@${VpsHost}:${VpsPath}/docker-compose.prod.yml"
Write-Host "✓ Arquivos transferidos`n" -ForegroundColor Green

# Deploy na VPS
Write-Host "🚢 Fazendo deploy na VPS..." -ForegroundColor Blue

$deployScript = @"
set -e

# Carregar imagem
echo '📦 Carregando imagem Docker...'
gunzip -c /tmp/${ImageName}.tar.gz | docker load
rm /tmp/${ImageName}.tar.gz

cd ${VpsPath}

# Verificar Swarm
if ! docker info | grep -q 'Swarm: active'; then
    echo '🔧 Inicializando Docker Swarm...'
    docker swarm init
fi

# Criar rede
if ! docker network ls | grep -q 'traefik-public'; then
    echo '📡 Criando rede traefik-public...'
    docker network create --driver=overlay traefik-public
fi

# Deploy
echo '🚀 Fazendo deploy...'
export `$(cat .env.production | grep -v '^#' | xargs)
docker stack deploy -c docker-compose.prod.yml insights

echo ''
echo '✅ Deploy concluído!'
echo ''
echo '📊 Status dos serviços:'
docker service ls | grep insights || true
"@

ssh "${VpsUser}@${VpsHost}" $deployScript

# Limpar arquivo temporário
Remove-Item $tempFile -Force

Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host "✅ Deploy concluído com sucesso!" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Green

Write-Host "🌐 Aplicação disponível em:" -ForegroundColor Blue
Write-Host "   https://gestor.disparazap.com`n"

Write-Host "📝 Comandos úteis:" -ForegroundColor Blue
Write-Host "   Ver logs:" -ForegroundColor Gray
Write-Host "   ssh ${VpsUser}@${VpsHost} 'docker service logs -f insights_insights-dashboard'`n" -ForegroundColor Gray

Write-Host "   Ver status:" -ForegroundColor Gray
Write-Host "   ssh ${VpsUser}@${VpsHost} 'docker service ps insights_insights-dashboard'`n" -ForegroundColor Gray

Write-Host "   Acessar VPS:" -ForegroundColor Gray
Write-Host "   ssh ${VpsUser}@${VpsHost}`n" -ForegroundColor Gray
