# 🚀 Deploy Rápido - Terminal VPS Aberto

## Passo 1: Exportar e Transferir Imagem (no seu PC)

Abra o PowerShell e execute:

```powershell
cd C:\Users\William\Desktop\Soft\dev\insights_dashboard

# Build da imagem
docker build -t insights-dashboard:latest .

# Exportar e comprimir
docker save insights-dashboard:latest | gzip > insights-dashboard.tar.gz

# Ver tamanho do arquivo
Get-Item insights-dashboard.tar.gz | Select-Object Name, @{Name="Size(MB)";Expression={[math]::Round($_.Length/1MB,2)}}
```

## Passo 2: Transferir para VPS

```powershell
# Substitua SEU-IP-VPS pelo IP real
scp insights-dashboard.tar.gz root@SEU-IP-VPS:/tmp/
scp .env.production root@SEU-IP-VPS:/tmp/
scp docker-compose.prod.yml root@SEU-IP-VPS:/tmp/
```

## Passo 3: Na VPS (cole tudo de uma vez)

```bash
# Criar diretório do projeto
mkdir -p /opt/insights_dashboard
cd /opt/insights_dashboard

# Mover arquivos
mv /tmp/.env.production .
mv /tmp/docker-compose.prod.yml .

# Carregar imagem Docker
echo "📦 Carregando imagem..."
gunzip -c /tmp/insights-dashboard.tar.gz | docker load
rm /tmp/insights-dashboard.tar.gz

# Inicializar Docker Swarm (se não estiver ativo)
if ! docker info | grep -q "Swarm: active"; then
    echo "🔧 Inicializando Docker Swarm..."
    docker swarm init
fi

# Criar rede traefik-public
if ! docker network ls | grep -q "traefik-public"; then
    echo "📡 Criando rede traefik-public..."
    docker network create --driver=overlay traefik-public
fi

# Carregar variáveis de ambiente e fazer deploy
echo "🚀 Fazendo deploy..."
export $(cat .env.production | grep -v '^#' | xargs)
docker stack deploy -c docker-compose.prod.yml insights

# Aguardar um pouco
sleep 5

# Verificar status
echo ""
echo "✅ Deploy iniciado!"
echo ""
echo "📊 Status dos serviços:"
docker service ls

echo ""
echo "📝 Logs (CTRL+C para sair):"
docker service logs -f insights_insights-dashboard
```

## Passo 4: Instalar Traefik (se não tiver)

Se você ainda não tem Traefik, execute isso **na VPS**:

```bash
# Criar diretório
mkdir -p /opt/traefik
cd /opt/traefik

# Criar docker-compose.yml
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  traefik:
    image: traefik:v2.10
    command:
      - "--api.dashboard=true"
      - "--providers.docker.swarmMode=true"
      - "--providers.docker.exposedbydefault=false"
      - "--providers.docker.network=traefik-public"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
      - "--certificatesresolvers.letsencrypt.acme.email=seu-email@example.com"
      - "--certificatesresolvers.letsencrypt.acme.storage=/letsencrypt/acme.json"
      - "--certificatesresolvers.letsencrypt.acme.httpchallenge=true"
      - "--certificatesresolvers.letsencrypt.acme.httpchallenge.entrypoint=web"
      - "--entrypoints.web.http.redirections.entryPoint.to=websecure"
      - "--entrypoints.web.http.redirections.entryPoint.scheme=https"
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - traefik-certificates:/letsencrypt
    networks:
      - traefik-public
    deploy:
      placement:
        constraints:
          - node.role == manager

volumes:
  traefik-certificates:

networks:
  traefik-public:
    external: true
EOF

# ALTERE O EMAIL AQUI!
nano docker-compose.yml
# Procure por "seu-email@example.com" e substitua pelo seu email real

# Deploy do Traefik
docker stack deploy -c docker-compose.yml traefik

# Verificar
docker service ls
```

## Comandos Úteis na VPS

```bash
# Ver todos os serviços
docker service ls

# Ver logs em tempo real
docker service logs -f insights_insights-dashboard

# Ver status detalhado
docker service ps insights_insights-dashboard

# Reiniciar serviço
docker service update --force insights_insights-dashboard

# Remover stack (cuidado!)
docker stack rm insights
```

## ✅ Verificação Final

```bash
# Testar localmente na VPS
curl http://localhost:3000/api/health

# Testar externamente (após alguns minutos para SSL)
curl https://gestor.disparazap.com
```

## 🌐 Acessar a aplicação

Aguarde 2-3 minutos para o SSL ser configurado, depois acesse:

**https://gestor.disparazap.com**
