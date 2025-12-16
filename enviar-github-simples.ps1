# Script simples para enviar codigo ao GitHub
# Uso: powershell -ExecutionPolicy Bypass -File .\enviar-github-simples.ps1

Write-Host ""
Write-Host "Enviando codigo para GitHub" -ForegroundColor Blue
Write-Host ""

# Pedir URL do repositorio
Write-Host "Cole a URL do repositorio GitHub:" -ForegroundColor Yellow
Write-Host "Exemplo: https://github.com/seu-usuario/insights-dashboard.git" -ForegroundColor Gray
Write-Host ""
$RepoUrl = Read-Host "URL"

# Configurar git
Write-Host ""
Write-Host "Configurando repositorio..." -ForegroundColor Blue
git init
git remote remove origin 2>$null
git remote add origin $RepoUrl

# Enviar codigo
Write-Host "Adicionando arquivos..." -ForegroundColor Blue
git add -A

Write-Host "Fazendo commit..." -ForegroundColor Blue
git commit -m "deploy" --no-verify

Write-Host "Enviando para GitHub..." -ForegroundColor Blue
git branch -M main
git push origin main --force

Write-Host ""
Write-Host "Codigo enviado com sucesso!" -ForegroundColor Green
Write-Host ""
Write-Host "Proximo passo: Execute na VPS o arquivo install-vps.sh" -ForegroundColor Yellow
Write-Host ""
