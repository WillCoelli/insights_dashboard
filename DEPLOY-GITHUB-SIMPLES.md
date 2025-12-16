# 🚀 Deploy Simples via GitHub - 3 Passos

Sistema configurado para: **gestor.disparazap.com**

---

## 🎯 PASSO 1: Criar Repositório GitHub

1. Acesse: https://github.com/new
2. Nome: `insights-dashboard` (ou qualquer nome)
3. **Privado** ✅
4. **NÃO** marque nada (README, .gitignore, etc)
5. Create repository

---

## 💻 PASSO 2: No seu PC (PowerShell)

```powershell
cd C:\Users\William\Desktop\Soft\dev\insights_dashboard

.\push-github.ps1
```

O script vai pedir a URL do repo GitHub. Cole algo como:
```
https://github.com/seu-usuario/insights-dashboard.git
```

**Pronto!** Código enviado para o GitHub.

---

## 🖥️ PASSO 3: Na VPS (Terminal)

### 3.1 - Transferir o .env.production (UMA VEZ SÓ)

**No PC (PowerShell):**
```powershell
scp .env.production root@SEU-IP:/tmp/
```

### 3.2 - Executar instalação

**Na VPS, cole TODO este bloco:**

```bash
# Baixar e executar script de instalação
curl -sSL https://raw.githubusercontent.com/SEU-USUARIO/insights-dashboard/main/install-vps.sh > /tmp/install.sh

# Mover .env.production
mkdir -p /opt/insights_dashboard
mv /tmp/.env.production /opt/insights_dashboard/

# Executar instalação
bash /tmp/install.sh
```

Quando pedir a URL do GitHub, cole:
```
https://github.com/seu-usuario/insights-dashboard.git
```

**Aguarde 2-3 minutos** e acesse:
**https://gestor.disparazap.com** ✅

---

## 🔄 Para Atualizar Depois

### No PC:
```powershell
cd C:\Users\William\Desktop\Soft\dev\insights_dashboard
.\push-github.ps1
```

### Na VPS:
```bash
bash /opt/insights_dashboard/atualizar-vps.sh
```

---

## 📋 Comandos Úteis na VPS

```bash
# Ver logs
docker service logs -f insights_insights-dashboard

# Ver status
docker service ls

# Reiniciar
docker service update --force insights_insights-dashboard

# Atualizar do GitHub
cd /opt/insights_dashboard && git pull && docker build -t insights-dashboard:latest . && docker service update --force insights_insights-dashboard
```

---

## ❓ Problemas Comuns

### PowerShell não executa script
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```

### Git pede senha no PC
Use token do GitHub:
1. GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Generate new token → Marque `repo`
3. Use o token como senha

### SSL não funciona na VPS
Verifique DNS:
```bash
nslookup gestor.disparazap.com
```
Deve retornar o IP da VPS.

---

## 🎉 Resumo

1. **GitHub** = Ponte para transferir código
2. **PC** = `.\push-github.ps1` (envia código)
3. **VPS** = Executa script de instalação
4. **Atualizações** = Push no PC + Pull na VPS

Simples assim! Sem commits, sem branches, sem complicação! 🚀
