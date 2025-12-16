# Setup GitHub Actions - Deployment Automático

## 1. Configurar Secrets no GitHub

Vá em: **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

Adicione os seguintes secrets:

| Name | Value |
|------|-------|
| `NEXT_PUBLIC_SUPABASE_URL` | `https://ixenaufwnyqlkzpgwzoe.supabase.co` |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml4ZW5hdWZ3bnlxbGt6cGd3em9lIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUyNDk5MTgsImV4cCI6MjA4MDgyNTkxOH0.lWgy29Jez6Vb3Ct5iIHUlPcLYklk4Bc7zKuEiCauqfo` |
| `NEXT_PUBLIC_BACKEND_URL` | `https://gestor.disparazap.com` |

## 2. Configurar Permissões do GHCR

Após o primeiro build, configure a visibilidade do pacote:

1. Vá em **Packages** no seu perfil GitHub
2. Clique no pacote `insights_dashboard`
3. **Package settings** → **Change visibility** → **Private**
4. **Package settings** → **Manage Actions access**
5. Adicione o repositório com permissão de **Read**

## 3. Criar Personal Access Token (PAT) para VPS

Se seu repositório for privado, crie um PAT:

1. GitHub → **Settings** → **Developer settings** → **Personal access tokens** → **Tokens (classic)**
2. **Generate new token (classic)**
3. Selecione scopes:
   - `read:packages`
   - `write:packages` (opcional, só para CI/CD)
4. Copie o token gerado

## 4. Login no GHCR na VPS

Execute na VPS:

```bash
# Login no GitHub Container Registry
echo "SEU_PAT_TOKEN" | docker login ghcr.io -u SEU_USUARIO_GITHUB --password-stdin
```

## 5. Stack para Portainer

Após o workflow fazer o build, use esta stack:

```yaml
version: '3.8'

services:
  insights-dashboard:
    image: ghcr.io/SEU_USUARIO/insights_dashboard:latest
    environment:
      - NODE_ENV=production
      - NEXT_PUBLIC_SUPABASE_URL=https://ixenaufwnyqlkzpgwzoe.supabase.co
      - NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml4ZW5hdWZ3bnlxbGt6cGd3em9lIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUyNDk5MTgsImV4cCI6MjA4MDgyNTkxOH0.lWgy29Jez6Vb3Ct5iIHUlPcLYklk4Bc7zKuEiCauqfo
      - SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml4ZW5hdWZ3bnlxbGt6cGd3em9lIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NTI0OTkxOCwiZXhwIjoyMDgwODI1OTE4fQ.1nz0jTCqiu2pV04sELV1-bDTR5E2XF3mn-Yhji6i47U
      - NEXT_PUBLIC_BACKEND_URL=https://gestor.disparazap.com
      - GRAPH_API_VERSION=v21.0
    networks:
      - externa
    deploy:
      mode: replicated
      replicas: 1
      placement:
        constraints:
          - node.role == manager
      restart_policy:
        condition: any
        delay: 5s
      labels:
        - "traefik.enable=true"
        - "traefik.http.routers.insights.rule=Host(`gestor.disparazap.com`)"
        - "traefik.http.routers.insights.entrypoints=websecure"
        - "traefik.http.routers.insights.tls.certresolver=le"
        - "traefik.http.services.insights.loadbalancer.server.port=3000"
        - "traefik.docker.network=externa"

networks:
  externa:
    external: true
```

## 6. Workflow de Deploy

O workflow dispara automaticamente quando:
- Push no branch `main`
- Criação de tags `v*` (exemplo: `v1.0.1`)
- Manual via **Actions** → **Run workflow**

## 7. Atualização na VPS

Após cada push/tag, atualize na VPS:

```bash
# Atualizar imagem
docker service update --image ghcr.io/SEU_USUARIO/insights_dashboard:latest insights_insights-dashboard

# Ou force recreate
docker service update --force insights_insights-dashboard
```

## 8. Fluxo Completo

```bash
# No PC - fazer alterações e versionar
git add .
git commit -m "feat: Nova funcionalidade"
git tag v1.0.1
git push origin main --tags

# GitHub Actions faz build automaticamente

# Na VPS - atualizar
docker service update --image ghcr.io/SEU_USUARIO/insights_dashboard:v1.0.1 insights_insights-dashboard
```
