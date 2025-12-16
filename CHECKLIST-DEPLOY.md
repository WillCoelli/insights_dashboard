# ✅ Checklist de Deploy - gestor.disparazap.com

## 📋 Antes de Iniciar o Deploy

### 1. Configurações DNS
- [ ] DNS de `gestor.disparazap.com` está apontando para o IP da VPS
- [ ] Propagação DNS concluída (teste: `nslookup gestor.disparazap.com`)
- [ ] Registro A configurado corretamente no painel do domínio

### 2. VPS Preparada
- [ ] Acesso SSH funcionando (`ssh root@SEU-IP`)
- [ ] Docker instalado na VPS (`docker --version`)
- [ ] Docker Compose instalado (`docker-compose --version`)
- [ ] Portas 80 e 443 abertas no firewall
- [ ] Pelo menos 2GB RAM disponível
- [ ] Pelo menos 10GB de espaço em disco

### 3. Configurações Locais
- [ ] Docker Desktop rodando no PC
- [ ] Container `insights-dashboard-debian12` funcionando localmente
- [ ] Arquivo `.env.production` configurado com:
  - [ ] `NEXT_PUBLIC_SUPABASE_URL` correto
  - [ ] `NEXT_PUBLIC_SUPABASE_ANON_KEY` correto
  - [ ] `SUPABASE_SERVICE_ROLE_KEY` correto
  - [ ] `NEXT_PUBLIC_BACKEND_URL=https://gestor.disparazap.com`

### 4. Supabase Configurado
- [ ] Site URL no Supabase: `https://gestor.disparazap.com`
- [ ] Redirect URLs configurados:
  - `https://gestor.disparazap.com/**`
  - `https://gestor.disparazap.com/auth/callback`
- [ ] RLS (Row Level Security) configurado nas tabelas

### 5. Arquivos Necessários
- [ ] `deploy-to-vps.ps1` existe
- [ ] `docker-compose.prod.yml` existe
- [ ] `.env.production` existe e está atualizado
- [ ] `Dockerfile` existe

---

## 🚀 Durante o Deploy

### Passo 1: Preparação
- [ ] Abrir PowerShell como Administrador
- [ ] Navegar até o diretório do projeto
- [ ] Verificar se não há mudanças não commitadas importantes

### Passo 2: Executar Deploy
```powershell
cd C:\Users\William\Desktop\Soft\dev\insights_dashboard
.\deploy-to-vps.ps1 -VpsHost "SEU-IP-OU-DOMINIO"
```

- [ ] Script iniciou sem erros
- [ ] Build da imagem concluído
- [ ] Transferência para VPS concluída
- [ ] Deploy no Swarm executado

### Passo 3: Configurar Traefik (Se ainda não estiver)
- [ ] Conectar na VPS via SSH
- [ ] Criar diretório `/opt/traefik`
- [ ] Criar `docker-compose.yml` do Traefik
- [ ] Alterar email no certresolver
- [ ] Deploy do Traefik: `docker stack deploy -c docker-compose.yml traefik`

---

## ✅ Após o Deploy

### Verificação Imediata
- [ ] Serviços rodando: `docker service ls | grep insights`
- [ ] Status healthy: `docker service ps insights_insights-dashboard`
- [ ] Sem erros nos logs: `docker service logs insights_insights-dashboard --tail 50`
- [ ] Health check OK: `curl http://localhost:3000/api/health` (na VPS)

### Verificação de Acesso
- [ ] Site acessível via HTTPS: `https://gestor.disparazap.com`
- [ ] Certificado SSL válido (cadeado verde no navegador)
- [ ] Página carrega sem erros
- [ ] Console do navegador sem erros críticos (F12)
- [ ] Redirecionamento HTTP → HTTPS funcionando

### Testes Funcionais
- [ ] Login do Supabase funcionando
- [ ] Autenticação redirecionando corretamente
- [ ] APIs respondendo
- [ ] Conexão com Supabase OK
- [ ] Integração com Meta Graph API funcionando (se aplicável)

### Monitoramento
- [ ] Logs em tempo real: `docker service logs -f insights_insights-dashboard`
- [ ] Verificar uso de recursos: `docker stats`
- [ ] Verificar health check periódico

---

## 🐛 Se Algo Der Errado

### Container não inicia
```bash
# Ver erro específico
docker service ps insights_insights-dashboard --no-trunc

# Ver logs completos
docker service logs insights_insights-dashboard --tail 200

# Verificar variáveis de ambiente
ssh root@VPS "cat /opt/insights_dashboard/.env.production"
```

### SSL não funciona
```bash
# Verificar DNS
nslookup gestor.disparazap.com

# Verificar Traefik
docker service logs traefik_traefik --tail 100

# Verificar portas
netstat -tlnp | grep -E ':(80|443)'
```

### Erro 502/503/504
- [ ] Verificar se container está healthy
- [ ] Verificar porta 3000 exposta
- [ ] Verificar rede traefik-public existe
- [ ] Verificar labels do Traefik no docker-compose

### Rollback (se necessário)
```bash
# Na VPS
docker stack rm insights

# No PC - transferir versão anterior
# Depois na VPS
docker stack deploy -c docker-compose.prod.yml insights
```

---

## 📞 Informações de Acesso

### VPS
- **IP**: _______________
- **Usuário**: root
- **SSH**: `ssh root@_______________`

### Aplicação
- **URL**: https://gestor.disparazap.com
- **Health Check**: https://gestor.disparazap.com/api/health

### Supabase
- **URL**: https://ixenaufwnyqlkzpgwzoe.supabase.co
- **Dashboard**: https://supabase.com/dashboard

### Domínio
- **Registrar**: _______________
- **DNS Provider**: _______________

---

## 📝 Notas Importantes

1. **Primeira vez demorará mais**: Download de dependências, build, etc.
2. **SSL pode levar até 5 minutos**: Let's Encrypt precisa validar o domínio
3. **Sempre fazer backup**: Antes de updates importantes
4. **Monitorar logs**: Primeiros 30 minutos após deploy
5. **Testar em horário de baixo tráfego**: Se possível

---

## 🎯 Próximos Passos

Após deploy bem-sucedido:

- [ ] Configurar backup automático do banco (Supabase)
- [ ] Configurar monitoramento (opcional)
- [ ] Documentar procedimentos específicos do projeto
- [ ] Testar fluxo completo da aplicação
- [ ] Configurar alertas (opcional)

---

## ✨ Deploy Concluído!

Data do deploy: _______________
Versão deployed: _______________
Deploy feito por: _______________

**Status**: ✅ Sucesso / ❌ Falhou / ⚠️ Parcial

**Observações**:
_____________________________________________________________________________
_____________________________________________________________________________
_____________________________________________________________________________
