// API para buscar insights de TODAS as Ad Accounts do token
import { withRateLimit } from '../../lib/rate-limit';

const GRAPH_API_URL = 'https://graph.facebook.com/v21.0';

async function handler(req, res) {
  // Validar metodo HTTP
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Metodo nao permitido' });
  }

  try {
    // Validar e parsear body com tratamento de erro
    let body;
    try {
      body = typeof req.body === 'string' ? JSON.parse(req.body) : req.body;
    } catch {
      return res.status(400).json({ error: 'JSON invalido no body da requisicao' });
    }

    const { accessToken, since, until } = body;

    if (!accessToken) {
      return res.status(400).json({ error: 'Token nao fornecido' });
    }

    // Validar formato das datas
    const dateRegex = /^\d{4}-\d{2}-\d{2}$/;
    if (since && !dateRegex.test(since)) {
      return res.status(400).json({ error: 'Formato de data "since" invalido. Use YYYY-MM-DD' });
    }
    if (until && !dateRegex.test(until)) {
      return res.status(400).json({ error: 'Formato de data "until" invalido. Use YYYY-MM-DD' });
    }

    // 1. Buscar todas as Ad Accounts do token (incluindo saldo e business)
    const accountsUrl = `${GRAPH_API_URL}/me/adaccounts?access_token=${accessToken}&fields=id,name,account_status,currency,business_name,business{id,name},balance,amount_spent,spend_cap`;
    const accountsRes = await fetch(accountsUrl);
    const accountsData = await accountsRes.json();

    if (accountsData.error) {
      return res.status(400).json({ error: accountsData.error });
    }

    if (!accountsData.data || accountsData.data.length === 0) {
      return res.status(200).json({ data: [], message: 'Nenhuma conta encontrada' });
    }

    // 2. Para cada conta, buscar os insights
    const insightsPromises = accountsData.data.map(async (account) => {
      try {
        const insightsUrl = buildInsightsUrl(account.id, accessToken, since, until);
        const insightsRes = await fetch(insightsUrl);
        const insightsData = await insightsRes.json();

        // Processar os dados de insights
        const insights = insightsData.data && insightsData.data[0] ? insightsData.data[0] : null;

        return {
          id: account.id,
          accountName: account.name || account.id,
          businessName: account.business_name || '-',
          businessId: account.business?.id || '',
          currency: account.currency || 'BRL',
          status: account.account_status === 1 ? 'Ativo' : 'Inativo',
          balanceRaw: account.balance ? parseFloat(account.balance) / 100 : 0,
          amountSpent: account.amount_spent ? parseFloat(account.amount_spent) / 100 : 0,
          spendCap: account.spend_cap ? parseFloat(account.spend_cap) / 100 : 0,
          balance: calculateAvailableBalance(account),
          spend: insights ? parseFloat(insights.spend || 0) : 0,
          impressions: insights ? parseInt(insights.impressions || 0) : 0,
          reach: insights ? parseInt(insights.reach || 0) : 0,
          clicks: insights ? parseInt(insights.clicks || 0) : 0,
          ctr: insights ? parseFloat(insights.ctr || 0) : 0,
          cpc: insights ? parseFloat(insights.cpc || 0) : 0,
          cpm: insights ? parseFloat(insights.cpm || 0) : 0,
          conversions: extractConversions(insights),
          cpa: calculateCPA(insights),
          roas: extractROAS(insights),
        };
      } catch (err) {
        console.error(`Erro ao buscar insights da conta ${account.id}:`, err);
        return {
          id: account.id,
          accountName: account.name || account.id,
          businessName: account.business_name || '-',
          businessId: account.business?.id || '',
          currency: account.currency || 'BRL',
          status: 'Erro',
          balanceRaw: account.balance ? parseFloat(account.balance) / 100 : 0,
          amountSpent: account.amount_spent ? parseFloat(account.amount_spent) / 100 : 0,
          spendCap: account.spend_cap ? parseFloat(account.spend_cap) / 100 : 0,
          balance: calculateAvailableBalance(account),
          spend: 0,
          impressions: 0,
          reach: 0,
          clicks: 0,
          ctr: 0,
          cpc: 0,
          cpm: 0,
          conversions: 0,
          cpa: 0,
          roas: 0,
        };
      }
    });

    const results = await Promise.all(insightsPromises);
    results.sort((a, b) => b.spend - a.spend);
    res.status(200).json({ data: results });

  } catch (error) {
    console.error('Erro na API:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
}

// Exportar com rate limiting (30 req/min)
export default withRateLimit(handler, { windowMs: 60000, max: 30 });

function buildInsightsUrl(accountId, accessToken, since, until) {
  const fields = [
    'spend',
    'impressions',
    'reach',
    'clicks',
    'ctr',
    'cpc',
    'cpm',
    'actions',
    'cost_per_action_type',
    'purchase_roas'
  ].join(',');

  let url = `${GRAPH_API_URL}/${accountId}/insights`;
  url += `?access_token=${accessToken}`;
  url += `&fields=${fields}`;
  url += `&time_range={"since":"${since}","until":"${until}"}`;

  return url;
}

function extractConversions(insights) {
  if (!insights || !insights.actions) return 0;

  const conversionTypes = [
    'purchase',
    'omni_purchase',
    'onsite_conversion.purchase',
    'offsite_conversion.fb_pixel_purchase',
    'lead',
    'onsite_conversion.lead_grouped',
    'offsite_conversion.fb_pixel_lead',
    'complete_registration',
    'onsite_conversion.complete_registration',
    'offsite_conversion.fb_pixel_complete_registration',
    'initiate_checkout',
    'add_to_cart',
  ];

  let totalConversions = 0;

  for (const action of insights.actions) {
    if (conversionTypes.includes(action.action_type)) {
      totalConversions += parseInt(action.value || 0);
    }
    if (action.action_type && (
      action.action_type.startsWith('offsite_conversion.fb_pixel_') ||
      action.action_type.startsWith('onsite_conversion.')
    )) {
      if (!conversionTypes.includes(action.action_type)) {
        totalConversions += parseInt(action.value || 0);
      }
    }
  }

  return totalConversions;
}

function calculateCPA(insights) {
  const conversions = extractConversions(insights);
  const spend = insights ? parseFloat(insights.spend || 0) : 0;

  if (conversions > 0 && spend > 0) {
    return spend / conversions;
  }

  return 0;
}

function extractROAS(insights) {
  if (!insights || !insights.purchase_roas) return 0;

  if (Array.isArray(insights.purchase_roas) && insights.purchase_roas.length > 0) {
    return parseFloat(insights.purchase_roas[0].value || 0);
  }

  return 0;
}

function calculateAvailableBalance(account) {
  const balance = account.balance ? parseFloat(account.balance) / 100 : 0;
  const amountSpent = account.amount_spent ? parseFloat(account.amount_spent) / 100 : 0;
  const spendCap = account.spend_cap ? parseFloat(account.spend_cap) / 100 : 0;

  if (spendCap > 0) {
    return Math.max(0, spendCap - amountSpent);
  }

  return balance;
}
