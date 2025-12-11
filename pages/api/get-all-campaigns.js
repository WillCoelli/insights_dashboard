// API para buscar campanhas ativas de TODAS as Ad Accounts
const GRAPH_API_URL = 'https://graph.facebook.com/v21.0';

export default async function handler(req, res) {
  try {
    const { accessToken, since, until, accountIds, accounts, onlyActive = true } = JSON.parse(req.body);

    if (!accessToken) {
      return res.status(400).json({ error: 'Token nao fornecido' });
    }

    if (!accountIds || accountIds.length === 0) {
      return res.status(200).json({ data: [] });
    }

    // Criar mapa de nomes das contas
    const accountNamesMap = {};
    if (accounts && Array.isArray(accounts)) {
      accounts.forEach(acc => {
        accountNamesMap[acc.id] = acc.accountName || acc.name || acc.id;
      });
    }

    // Buscar campanhas de todas as contas
    const campaignsPromises = accountIds.map(async (accountId) => {
      try {
        const url = buildCampaignsUrl(accountId, accessToken, since, until, onlyActive);
        const response = await fetch(url);
        const data = await response.json();

        if (data.error) {
          console.error(`Erro na conta ${accountId}:`, data.error);
          return [];
        }

        // Processar campanhas
        return (data.data || []).map(campaign => ({
          id: campaign.id,
          accountId: accountId,
          accountName: accountNamesMap[accountId] || accountId,
          name: campaign.name,
          status: campaign.effective_status,
          effectiveStatus: campaign.effective_status,
          objectiveRaw: campaign.objective,
          objective: formatObjective(campaign.objective),
          dailyBudget: campaign.daily_budget ? parseFloat(campaign.daily_budget) / 100 : 0,
          lifetimeBudget: campaign.lifetime_budget ? parseFloat(campaign.lifetime_budget) / 100 : 0,
          budgetRemaining: campaign.budget_remaining ? parseFloat(campaign.budget_remaining) / 100 : 0,
          // Metricas de insights
          ...extractInsights(campaign.insights, campaign.objective),
        }));
      } catch (err) {
        console.error(`Erro ao buscar campanhas da conta ${accountId}:`, err);
        return [];
      }
    });

    const results = await Promise.all(campaignsPromises);
    let allCampaigns = results.flat();

    // Ordenar por gasto (maior primeiro)
    allCampaigns.sort((a, b) => b.spend - a.spend);

    res.status(200).json({ data: allCampaigns });

  } catch (error) {
    console.error('Erro na API:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
}

function buildCampaignsUrl(accountId, accessToken, since, until, onlyActive = true) {
  const insightsFields = [
    'spend',
    'impressions',
    'reach',
    'clicks',
    'ctr',
    'cpc',
    'cpm',
    'actions',
    'purchase_roas',
    'cost_per_action_type'
  ].join(',');

  // Filtrar apenas ativas ou todas (ativas + pausadas)
  const statusFilter = onlyActive
    ? '["ACTIVE"]'
    : '["ACTIVE","PAUSED"]';

  let url = `${GRAPH_API_URL}/${accountId}/campaigns`;
  url += `?access_token=${accessToken}`;
  url += `&filtering=[{"field":"effective_status","operator":"IN","value":${statusFilter}}]`;
  url += `&fields=id,name,objective,status,effective_status,daily_budget,lifetime_budget,budget_remaining,account_id`;
  url += `,insights.time_range({"since":"${since}","until":"${until}"}){${insightsFields}}`;
  url += `&limit=100`;

  return url;
}

function formatObjective(objective) {
  const objectives = {
    'OUTCOME_AWARENESS': 'Reconhecimento',
    'OUTCOME_ENGAGEMENT': 'Engajamento',
    'OUTCOME_LEADS': 'Leads',
    'OUTCOME_SALES': 'Vendas',
    'OUTCOME_TRAFFIC': 'Trafego',
    'OUTCOME_APP_PROMOTION': 'App',
    'LINK_CLICKS': 'Cliques',
    'CONVERSIONS': 'Conversoes',
    'MESSAGES': 'Mensagens',
    'POST_ENGAGEMENT': 'Engajamento',
    'VIDEO_VIEWS': 'Videos',
    'REACH': 'Alcance',
    'BRAND_AWARENESS': 'Marca',
    'LEAD_GENERATION': 'Leads',
  };
  return objectives[objective] || objective || '-';
}

function extractInsights(insights, objective) {
  if (!insights || !insights.data || insights.data.length === 0) {
    return {
      spend: 0,
      impressions: 0,
      reach: 0,
      clicks: 0,
      ctr: 0,
      cpc: 0,
      cpm: 0,
      conversions: 0,
      cpa: 0,
      resultado: 0,
      custoPorResultado: 0,
    };
  }

  const data = insights.data[0];

  const resultado = extractResultado(data, objective);
  const spend = parseFloat(data.spend || 0);

  return {
    spend: spend,
    impressions: parseInt(data.impressions || 0),
    reach: parseInt(data.reach || 0),
    clicks: parseInt(data.clicks || 0),
    ctr: parseFloat(data.ctr || 0),
    cpc: parseFloat(data.cpc || 0),
    cpm: parseFloat(data.cpm || 0),
    conversions: extractConversions(data),
    cpa: calculateCPA(data),
    resultado: resultado,
    custoPorResultado: resultado > 0 ? spend / resultado : 0,
  };
}

// Extrai o resultado principal baseado no objetivo da campanha
function extractResultado(data, objective) {
  if (!data || !data.actions) return 0;

  // Mapear objetivo para tipos de acao relevantes
  // IMPORTANTE: Para mensagens/engajamento, usar APENAS os tipos especificos
  const objectiveActionMap = {
    // Vendas
    'OUTCOME_SALES': ['purchase', 'omni_purchase', 'onsite_conversion.purchase', 'offsite_conversion.fb_pixel_purchase'],
    'CONVERSIONS': ['purchase', 'omni_purchase', 'onsite_conversion.purchase', 'offsite_conversion.fb_pixel_purchase'],
    // Leads
    'OUTCOME_LEADS': ['lead', 'onsite_conversion.lead_grouped', 'offsite_conversion.fb_pixel_lead'],
    'LEAD_GENERATION': ['lead', 'onsite_conversion.lead_grouped', 'offsite_conversion.fb_pixel_lead'],
    // Trafego
    'OUTCOME_TRAFFIC': ['link_click'],
    'LINK_CLICKS': ['link_click'],
    // Mensagens - APENAS conversas iniciadas
    'MESSAGES': ['onsite_conversion.messaging_conversation_started_7d', 'messaging_conversation_started_7d'],
    // Engajamento - pode ser mensagens ou engajamento em posts
    // O Meta usa OUTCOME_ENGAGEMENT para campanhas de mensagens tambem
    'OUTCOME_ENGAGEMENT': ['onsite_conversion.messaging_conversation_started_7d', 'messaging_conversation_started_7d'],
    'POST_ENGAGEMENT': ['post_engagement', 'page_engagement'],
    // Videos
    'VIDEO_VIEWS': ['video_view'],
    // Alcance
    'OUTCOME_AWARENESS': ['reach'],
    'REACH': ['reach'],
    'BRAND_AWARENESS': ['reach'],
    // App
    'OUTCOME_APP_PROMOTION': ['app_install', 'mobile_app_install'],
  };

  const relevantActions = objectiveActionMap[objective] || [];

  let total = 0;
  for (const action of data.actions) {
    if (relevantActions.includes(action.action_type)) {
      total += parseInt(action.value || 0);
    }
  }

  return total;
}

function extractConversions(data) {
  if (!data || !data.actions) return 0;

  // Tipos de conversao do Meta Ads (somar todos)
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

  for (const action of data.actions) {
    if (conversionTypes.includes(action.action_type)) {
      totalConversions += parseInt(action.value || 0);
    }
    // Verificar conversoes com prefixo
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

function calculateCPA(data) {
  const conversions = extractConversions(data);
  const spend = parseFloat(data.spend || 0);

  if (conversions > 0 && spend > 0) {
    return spend / conversions;
  }

  return 0;
}

function extractROAS(data) {
  if (!data || !data.purchase_roas) return 0;

  if (Array.isArray(data.purchase_roas) && data.purchase_roas.length > 0) {
    return parseFloat(data.purchase_roas[0].value || 0);
  }

  return 0;
}
