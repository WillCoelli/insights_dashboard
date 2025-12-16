# 🎯 COMECE AQUI - Deploy em 2 Passos

Você tem acesso ao terminal da VPS? Perfeito! Siga estes 2 passos simples:

---

## 📍 PASSO 1: No seu PC (Windows)

Abra o **PowerShell** e execute:

```powershell
cd C:\Users\William\Desktop\Soft\dev\insights_dashboard

.\1-executar-no-pc.ps1 -VpsIp "SEU-IP-AQUI"
```

**Exemplo:**
```powershell
.\1-executar-no-pc.ps1 -VpsIp "192.168.1.100"
```

Isso vai:
- ✅ Construir a imagem Docker
- ✅ Exportar e comprimir
- ✅ Transferir para a VPS via SCP

**Importante:** Substitua `SEU-IP-AQUI` pelo IP real da sua VPS!

---

## 📍 PASSO 2: No Terminal da VPS

Agora **copie e cole** todo este comando no terminal da VPS:

```bash
curl -sSL https://gist.githubusercontent.com/YOUR-GIST/raw/install.sh | bash
```

**OU** (se o comando acima não funcionar):

Abra o arquivo `2-executar-na-vps.sh` deste projeto, copie TODO o conteúdo e cole no terminal da VPS, depois pressione ENTER.

Isso vai:
- ✅ Instalar Docker (se necessário)
- ✅ Configurar Docker Swarm
- ✅ Instalar Traefik (SSL automático)
- ✅ Fazer deploy da aplicação

---

## ✅ Verificar se funcionou

Após 2-3 minutos, acesse no navegador:

**https://gestor.disparazap.com**

---

## 🔍 Comandos úteis na VPS

```bash
# Ver logs em tempo real
docker service logs -f insights_insights-dashboard

# Ver status
docker service ls

# Reiniciar aplicação
docker service update --force insights_insights-dashboard

# Testar localmente
curl http://localhost:3000/api/health
```

---

## ❓ Precisa de ajuda?

### Problema: SSH não funciona
**Solução:** Configure a chave SSH ou use senha:
```powershell
ssh root@SEU-IP
```

### Problema: Permissão negada no PowerShell
**Solução:** Execute como Administrador:
1. Clique direito no PowerShell
2. "Executar como Administrador"

### Problema: Script não executa
**Solução:** Libere a execução:
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```

### Problema: SSL não funciona
**Solução:** Verifique se o DNS está correto:
```bash
nslookup gestor.disparazap.com
```
O IP retornado deve ser o da sua VPS.

---

## 🎉 Pronto!

Depois destes 2 passos, sua aplicação estará rodando em:

**https://gestor.disparazap.com**

Com SSL automático via Let's Encrypt! 🔒
