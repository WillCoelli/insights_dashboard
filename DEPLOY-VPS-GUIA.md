# 🚀 Guia Completo: Deploy do PC para VPS

Este guia mostra como fazer o deploy do container `insights-dashboard-debian12` do seu PC direto para a VPS.

## 📋 Pré-requisitos

### No seu PC (Windows):
- Docker Desktop rodando
- Git Bash ou PowerShell
- Acesso SSH à VPS configurado

### Na VPS:
- Debian 12 ou Ubuntu
- Docker instalado
- Acesso SSH root ou sudo
- Portas 80 e 443 abertas no firewall
- DNS do domínio `gestor.disparazap.com` apontando para o IP da VPS

---

## 🎯 Método 1: Deploy Automatizado (RECOMENDADO)

### Usando PowerShell (Windows):

1. **Abra o PowerShell** no diretório do projeto:
```powershell
cd C:\Users\William\Desktop\Soft\dev\insights_dashboard
```

2. **Execute o script de deploy**:
```powershell
.\deploy-to-vps.ps1 -VpsHost "SEU-IP-OU-DOMINIO"
```

Exemplo:
```powershell
.\deploy-to-vps.ps1 -VpsHost "192.168.1.100"
# ou
.\deploy-to-vps.ps1 -VpsHost "disparazap.com"
```

3. **Aguarde o processo** (pode levar alguns minutos):
   - Build da imagem Docker
   - Exportação e compressão
   - Transferência para VPS
   - Deploy automático

---

## 🔧 Método 2: Deploy Manual (Passo a Passo)

### Passo 1: Exportar a imagem do Docker

No seu PC, abra o PowerShell e execute:

```powershell
# Navegar até o diretório
cd C:\Users\William\Desktop\Soft\dev\insights_dashboard

# Build da imagem
docker build -t insights-dashboard:latest -f Dockerfile .

# Salvar e comprimir a imagem
docker save insights-dashboard:latest | gzip > insights-dashboard.tar.gz
```

### Passo 2: Transferir para VPS

```powershell
# Transferir via SCP
scp insights-dashboard.tar.gz root@SEU-IP-VPS:/tmp/

# Transferir arquivos de configuração
scp .env.production root@SEU-IP-VPS:/opt/insights_dashboard/.env.production
scp docker-compose.prod.yml root@SEU-IP-VPS:/opt/insights_dashboard/docker-compose.prod.yml
```

### Passo 3: Conectar na VPS e fazer deploy

```powershell
# Conectar via SSH
ssh root@SEU-IP-VPS
```

Agora, **na VPS**, execute:

```bash
# Carregar imagem Docker
gunzip -c /tmp/insights-dashboard.tar.gz | docker load
rm /tmp/insights-dashboard.tar.gz

# Ir para diretório do projeto
cd /opt/insights_dashboard

# Inicializar Docker Swarm (se não estiver ativo)
docker swarm init

# Criar rede Traefik
docker network create --driver=overlay traefik-public

# Carregar variáveis de ambiente
export $(cat .env.production | grep -v '^#' | xargs)

# Fazer deploy
docker stack deploy -c docker-compose.prod.yml insights

# Verificar status
docker service ls | grep insights
docker service logs -f insights_insights-dashboard
```

---

## 🔒 Configurar Traefik (Proxy Reverso + SSL)

Se você ainda não tem o Traefik configurado na VPS, siga estes passos:

### 1. Criar diretório do Traefik

```bash
mkdir -p /opt/traefik
cd /opt/traefik
```

### 2. Criar arquivo `docker-compose.yml`

```bash
nano docker-compose.yml
```

Cole o conteúdo:

```yaml
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
      # Redirecionar HTTP para HTTPS
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
      labels:
        - "traefik.enable=true"
        # Dashboard
        - "traefik.http.routers.traefik.rule=Host(`traefik.disparazap.com`)"
        - "traefik.http.routers.traefik.service=api@internal"
        - "traefik.http.routers.traefik.entrypoints=websecure"
        - "traefik.http.routers.traefik.tls.certresolver=letsencrypt"
        - "traefik.http.services.traefik.loadbalancer.server.port=8080"

volumes:
  traefik-certificates:

networks:
  traefik-public:
    external: true
```

**IMPORTANTE**: Altere `seu-email@example.com` para seu email real.

### 3. Deploy do Traefik

```bash
# Criar rede (se ainda não existe)
docker network create --driver=overlay traefik-public

# Deploy
docker stack deploy -c docker-compose.yml traefik

# Verificar
docker service ls | grep traefik
```

---

## ✅ Verificação Final

### 1. Verificar se os serviços estão rodando:

```bash
docker service ls
```

Saída esperada:
```
NAME                          REPLICAS   IMAGE
insights_insights-dashboard   1/1        insights-dashboard:latest
traefik_traefik              1/1        traefik:v2.10
```

### 2. Verificar logs:

```bash
docker service logs insights_insights-dashboard --tail 50
```

### 3. Verificar DNS:

```bash
# Testar resolução DNS
nslookup gestor.disparazap.com

# Deve retornar o IP da sua VPS
```

### 4. Testar acesso:

Abra no navegador:
- https://gestor.disparazap.com

---

## 🐛 Troubleshooting

### Container não inicia

```bash
# Ver logs detalhados
docker service logs insights_insights-dashboard --tail 100

# Ver tarefas do serviço
docker service ps insights_insights-dashboard
```

### SSL não funciona

1. Verificar se DNS está correto:
```bash
nslookup gestor.disparazap.com
```

2. Verificar portas abertas:
```bash
netstat -tlnp | grep -E ':(80|443)'
```

3. Verificar logs do Traefik:
```bash
docker service logs traefik_traefik --tail 50
```

### Reiniciar serviço

```bash
# Reiniciar serviço específico
docker service update --force insights_insights-dashboard

# Remover e recriar stack
docker stack rm insights
sleep 10
docker stack deploy -c docker-compose.prod.yml insights
```

### Rebuild completo

Se precisar fazer rebuild completo:

```bash
# Na VPS
cd /opt/insights_dashboard

# Remover stack
docker stack rm insights

# Remover imagem antiga
docker rmi insights-dashboard:latest

# No seu PC, transfira novamente a imagem
# Depois, na VPS:
gunzip -c /tmp/insights-dashboard.tar.gz | docker load

# Deploy novamente
export $(cat .env.production | grep -v '^#' | xargs)
docker stack deploy -c docker-compose.prod.yml insights
```

---

## 📊 Monitoramento

### Ver status em tempo real:

```bash
# Logs em tempo real
docker service logs -f insights_insights-dashboard

# Status dos containers
docker service ps insights_insights-dashboard

# Estatísticas de uso
docker stats $(docker ps -q -f name=insights)
```

### Health Check:

```bash
# Verificar health do serviço
curl http://localhost:3000/api/health

# ou remotamente
curl https://gestor.disparazap.com/api/health
```

---

## 🔄 Atualizações Futuras

Para atualizar a aplicação posteriormente:

### Opção 1: Deploy do PC novamente

```powershell
# No PC
.\deploy-to-vps.ps1 -VpsHost "SEU-IP"
```

### Opção 2: Git Pull na VPS

```bash
# Na VPS
cd /opt/insights_dashboard
git pull origin main
chmod +x deploy.sh
./deploy.sh
```

---

## 📝 Comandos Úteis

```bash
# Ver todos os serviços
docker service ls

# Ver logs
docker service logs -f insights_insights-dashboard

# Escalar serviço (criar mais réplicas)
docker service scale insights_insights-dashboard=3

# Ver containers rodando
docker ps

# Acessar container
docker exec -it $(docker ps -q -f name=insights) sh

# Remover tudo (CUIDADO!)
docker stack rm insights
```

---

## 🎉 Pronto!

Sua aplicação deve estar rodando em:
**https://gestor.disparazap.com**

Se tiver problemas, verifique:
1. ✅ DNS apontando para IP correto
2. ✅ Portas 80/443 abertas no firewall
3. ✅ Docker Swarm ativo
4. ✅ Traefik rodando corretamente
5. ✅ Variáveis de ambiente corretas no .env.production

---

## 📞 Suporte

Em caso de problemas:
1. Verifique os logs: `docker service logs insights_insights-dashboard`
2. Verifique o status: `docker service ps insights_insights-dashboard`
3. Teste o health check: `curl https://gestor.disparazap.com/api/health`
