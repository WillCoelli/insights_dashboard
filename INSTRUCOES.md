# Dashboard Meta Ads - Guia de Instalacao

## Requisitos

- Node.js 18+ (https://nodejs.org/)
- NPM ou Yarn

## Instalacao

```bash
# 1. Entre na pasta do projeto
cd insights_dashboard

# 2. Instale as dependencias
npm install

# 3. Rode o projeto
npm run dev

# 4. Acesse no navegador
http://localhost:3000/gestor
```

## Como Usar

### 1. Gerar o System User Token

1. Acesse [business.facebook.com](https://business.facebook.com)
2. Va em **Configuracoes do negocio** (icone de engrenagem)
3. No menu lateral: **Usuarios** → **Usuarios do sistema**
4. Clique em **Adicionar** (se nao tiver um usuario)
   - Nome: "Dashboard API" (ou qualquer nome)
   - Funcao: Admin
5. Clique no usuario criado
6. Clique em **Adicionar ativos** e adicione as Ad Accounts que deseja ver
7. Clique em **Gerar novo token**
8. Selecione um App (ou crie um em developers.facebook.com)
9. Marque as permissoes:
   - `ads_read`
   - `business_management`
   - `read_insights`
10. Clique em **Gerar token**
11. **COPIE O TOKEN** (ele so aparece uma vez!)

### 2. Usar o Dashboard

1. Acesse `http://localhost:3000/gestor`
2. Cole o token no campo
3. Clique em **Conectar**
4. Suas contas aparecerao na tabela!

## Metricas Exibidas

| Metrica | Descricao |
|---------|-----------|
| Gasto | Valor total gasto no periodo |
| Impressoes | Numero de vezes que os anuncios foram exibidos |
| Alcance | Usuarios unicos que viram os anuncios |
| Cliques | Numero de cliques nos anuncios |
| CTR | Taxa de cliques (Cliques / Impressoes) |
| CPC | Custo por clique |
| CPM | Custo por mil impressoes |
| Conversoes | Numero de conversoes (compras/leads) |
| CPA | Custo por aquisicao |
| ROAS | Retorno sobre investimento em ads |

## Filtros de Data

- **Hoje**: Dados do dia atual
- **7 dias**: Ultima semana
- **14 dias**: Ultimas duas semanas
- **30 dias**: Ultimo mes
- **90 dias**: Ultimo trimestre
- **Custom**: Selecione datas especificas

## Seguranca

- O token fica salvo **apenas no seu navegador** (localStorage)
- Nenhum dado e enviado para servidores externos
- Os dados vem diretamente da API do Meta

## Troubleshooting

### Erro "Invalid OAuth access token"
- Verifique se o token foi copiado corretamente
- Gere um novo token se necessario

### Erro "User does not have permission"
- Certifique-se de que o System User tem acesso as Ad Accounts
- Va em Configuracoes → Usuarios do sistema → Adicionar ativos

### Nenhuma conta aparece
- Verifique se o System User tem Ad Accounts associadas
- Verifique se as contas tem dados no periodo selecionado

## Proximos Passos (Roadmap)

- [ ] Sistema de login para multiplos gestores
- [ ] Banco de dados para salvar tokens
- [ ] Exportacao de relatorios (PDF/Excel)
- [ ] Graficos de evolucao
- [ ] Alertas de performance
- [ ] Deploy em VPS

## Suporte

Em caso de duvidas, verifique a documentacao do Meta:
- [Marketing API](https://developers.facebook.com/docs/marketing-apis/)
- [System Users](https://www.facebook.com/business/help/503306463479099)
