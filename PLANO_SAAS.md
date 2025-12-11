# Plano de Implementacao - SaaS Multi-Conta Meta Ads

## Visao Geral

Transformar o insights_dashboard em um SaaS para gestores de trafego visualizarem multiplas contas de anuncios Meta em uma unica tela.

---

## Metricas a Exibir (10 Parametros)

| # | Metrica | Campo API | Descricao |
|---|---------|-----------|-----------|
| 1 | Gasto | `spend` | Valor total gasto |
| 2 | Impressoes | `impressions` | Numero de exibicoes |
| 3 | Alcance | `reach` | Usuarios unicos alcancados |
| 4 | Cliques | `clicks` ou `actions.link_click` | Cliques no anuncio |
| 5 | CTR | `ctr` | Taxa de cliques (%) |
| 6 | CPC | `cost_per_inline_link_click` | Custo por clique |
| 7 | CPM | `cpm` | Custo por mil impressoes |
| 8 | Conversoes | `actions.purchase` | Numero de compras |
| 9 | CPA | calculado | Custo por aquisicao |
| 10 | ROAS | `purchase_roas` | Retorno sobre gasto |

---

## Arquitetura Proposta

```
┌─────────────────────────────────────────────────────────────────┐
│                         FRONTEND (Next.js)                       │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │   Login     │  │  Dashboard  │  │   Tabela Multi-Conta    │  │
│  │   OAuth     │  │   Graficos  │  │   (DataGrid MUI)        │  │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘  │
└────────────────────────────┬────────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────────┐
│                      BACKEND (Node.js/Express)                   │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │   Auth      │  │   API       │  │   Scheduler             │  │
│  │   JWT       │  │   Routes    │  │   (Atualizar dados)     │  │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘  │
└────────────────────────────┬────────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────────┐
│                      BANCO DE DADOS (PostgreSQL)                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │   users     │  │   accounts  │  │   tokens                │  │
│  │   plans     │  │   insights  │  │   refresh_tokens        │  │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘  │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
                    ┌──────────────────┐
                    │   Meta Graph API │
                    └──────────────────┘
```

---

## Modificacoes Necessarias

### 1. Estrutura de Arquivos a Adicionar

```
insights_dashboard/
├── prisma/
│   └── schema.prisma          # Schema do banco de dados
├── lib/
│   ├── prisma.js              # Cliente Prisma
│   └── auth.js                # Funcoes de autenticacao
├── pages/
│   ├── login.js               # Pagina de login
│   ├── register.js            # Pagina de cadastro
│   ├── connect-account.js     # Conectar conta Meta
│   └── api/
│       ├── auth/
│       │   ├── login.js
│       │   ├── register.js
│       │   ├── facebook-callback.js
│       │   └── refresh-token.js
│       └── accounts/
│           ├── list.js
│           ├── connect.js
│           └── insights-all.js  # NOVO: Busca todas as contas
├── components/
│   └── multi-account-table/
│       └── index.js           # Tabela comparativa
└── middleware.js              # Protecao de rotas
```

### 2. Schema do Banco de Dados (Prisma)

```prisma
model User {
  id            String    @id @default(cuid())
  email         String    @unique
  password      String
  name          String?
  plan          String    @default("free")
  createdAt     DateTime  @default(now())
  accounts      MetaAccount[]
}

model MetaAccount {
  id              String    @id @default(cuid())
  userId          String
  user            User      @relation(fields: [userId], references: [id])
  adAccountId     String
  adAccountName   String
  accessToken     String
  tokenExpiresAt  DateTime?
  createdAt       DateTime  @default(now())
  insights        Insight[]
}

model Insight {
  id            String      @id @default(cuid())
  accountId     String
  account       MetaAccount @relation(fields: [accountId], references: [id])
  date          DateTime
  spend         Float
  impressions   Int
  reach         Int
  clicks        Int
  ctr           Float
  cpc           Float
  cpm           Float
  conversions   Int
  cpa           Float
  roas          Float
  createdAt     DateTime    @default(now())
}
```

### 3. Nova API - Buscar Todas as Contas

Criar `pages/api/accounts/insights-all.js`:

```javascript
// Busca insights de TODAS as contas do usuario
export default async function handler(req, res) {
  const { userId, since, until } = JSON.parse(req.body);

  // 1. Buscar todas as contas do usuario no banco
  const accounts = await prisma.metaAccount.findMany({
    where: { userId }
  });

  // 2. Para cada conta, buscar insights da Meta API
  const results = await Promise.all(
    accounts.map(async (account) => {
      const insights = await fetchMetaInsights(
        account.adAccountId,
        account.accessToken,
        since,
        until
      );
      return {
        accountName: account.adAccountName,
        ...insights
      };
    })
  );

  res.status(200).json({ data: results });
}
```

### 4. Componente Tabela Multi-Conta

Criar `components/multi-account-table/index.js`:

```javascript
import { DataGrid } from '@mui/x-data-grid';

const columns = [
  { field: 'accountName', headerName: 'Cliente', width: 150 },
  { field: 'spend', headerName: 'Gasto', width: 100,
    valueFormatter: (params) => `R$ ${params.value?.toFixed(2)}` },
  { field: 'impressions', headerName: 'Impressoes', width: 120 },
  { field: 'reach', headerName: 'Alcance', width: 100 },
  { field: 'clicks', headerName: 'Cliques', width: 80 },
  { field: 'ctr', headerName: 'CTR', width: 80,
    valueFormatter: (params) => `${params.value?.toFixed(2)}%` },
  { field: 'cpc', headerName: 'CPC', width: 80,
    valueFormatter: (params) => `R$ ${params.value?.toFixed(2)}` },
  { field: 'cpm', headerName: 'CPM', width: 80,
    valueFormatter: (params) => `R$ ${params.value?.toFixed(2)}` },
  { field: 'conversions', headerName: 'Conv.', width: 80 },
  { field: 'roas', headerName: 'ROAS', width: 80,
    valueFormatter: (params) => `${params.value?.toFixed(2)}x` },
];

export default function MultiAccountTable({ accounts }) {
  return (
    <DataGrid
      rows={accounts}
      columns={columns}
      pageSize={10}
      autoHeight
    />
  );
}
```

---

## Etapas de Implementacao

### Fase 1: Base do SaaS
- [ ] Configurar Prisma + PostgreSQL
- [ ] Implementar autenticacao (registro/login)
- [ ] Criar pagina de conexao OAuth Meta
- [ ] Armazenar tokens no banco

### Fase 2: Dashboard Multi-Conta
- [ ] Criar API para buscar insights de todas as contas
- [ ] Implementar tabela comparativa com DataGrid
- [ ] Adicionar filtros de data
- [ ] Implementar refresh automatico

### Fase 3: Features SaaS
- [ ] Sistema de planos (free/pro)
- [ ] Limitar numero de contas por plano
- [ ] Integracao com Stripe para pagamentos
- [ ] Exportacao de relatorios (PDF/Excel)

### Fase 4: Deploy
- [ ] Configurar VPS (DigitalOcean/Vultr)
- [ ] Setup Docker + Nginx
- [ ] SSL com Let's Encrypt
- [ ] CI/CD com GitHub Actions

---

## Dependencias a Adicionar

```bash
npm install @prisma/client prisma
npm install bcryptjs jsonwebtoken
npm install next-auth  # ou implementar OAuth manual
npm install @stripe/stripe-js stripe  # para pagamentos
```

---

## Obtendo Credenciais Meta

1. Acesse https://developers.facebook.com
2. Crie um App tipo "Business"
3. Adicione o produto "Marketing API"
4. Configure OAuth:
   - Redirect URI: `https://seudominio.com/api/auth/facebook-callback`
5. Solicite permissoes:
   - `ads_read`
   - `ads_management`
   - `business_management`
6. Submeta para App Review (obrigatorio para producao)

---

## Proximos Passos

Para continuar, voce precisa:

1. **Instalar Node.js** (v18+) em sua maquina
2. Rodar `npm install` na pasta do projeto
3. Configurar o `.env.local` com seu token Meta
4. Rodar `npm run dev` para testar localmente

Depois posso ajudar a implementar cada fase do plano acima.
