# ========================================
# Script: Enviar codigo para GitHub
# Uso: .\push-github.ps1
# ========================================

param(
    [Parameter(Mandatory=$false)]
    [string]$RepoUrl = ""
)

$ErrorActionPreference = "Stop"

Write-Host "`nEnviando codigo para GitHub`n" -ForegroundColor Blue

# Verificar se esta no diretorio correto
if (-not (Test-Path ".\package.json")) {
    Write-Host "ERRO: Execute no diretorio insights_dashboard" -ForegroundColor Red
    exit 1
}

# Se nao passar a URL, perguntar
if ($RepoUrl -eq "") {
    Write-Host "Cole a URL do seu repositorio GitHub:" -ForegroundColor Yellow
    Write-Host "Exemplo: https://github.com/seu-usuario/insights-dashboard.git" -ForegroundColor Gray
    $RepoUrl = Read-Host "`nURL"
}

# Verificar se .gitignore esta protegendo .env.production
if (-not (Select-String -Path ".gitignore" -Pattern ".env.production" -Quiet)) {
    Write-Host "`nAdicionando .env.production ao .gitignore..." -ForegroundColor Yellow
    Add-Content -Path ".gitignore" -Value "`n.env.production"
    Add-Content -Path ".gitignore" -Value ".env.local"
}

# Configurar git (se necessario)
Write-Host "`nPreparando repositorio..." -ForegroundColor Blue
git init 2>$null

# Remover origin anterior e adicionar novo
git remote remove origin 2>$null
git remote add origin $RepoUrl

# Adicionar todos os arquivos
Write-Host "Adicionando arquivos..." -ForegroundColor Blue
git add -A

# Commit
Write-Host "Fazendo commit..." -ForegroundColor Blue
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
git commit -m "deploy $timestamp" --no-verify 2>$null

# Push forcado (sobrescreve tudo)
Write-Host "Enviando para GitHub..." -ForegroundColor Blue
git branch -M main
git push origin main --force

Write-Host "`nCodigo enviado com sucesso!" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

Write-Host "Proximo passo: Execute na VPS:" -ForegroundColor Yellow
Write-Host "`ncurl -sSL https://raw.githubusercontent.com/SEU-USUARIO/insights-dashboard/main/install-vps.sh | bash" -ForegroundColor Cyan
Write-Host "`nOu copie o conteudo de: install-vps.sh`n" -ForegroundColor Gray
