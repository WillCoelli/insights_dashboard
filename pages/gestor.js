import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/router';
import Head from 'next/head';
import Box from '@mui/material/Box';
import Container from '@mui/material/Container';
import Typography from '@mui/material/Typography';
import Paper from '@mui/material/Paper';
import Button from '@mui/material/Button';
import CircularProgress from '@mui/material/CircularProgress';
import LogoutIcon from '@mui/icons-material/Logout';

import TokenInput from '../components/token-input';
import DateFilter from '../components/date-filter';
import MultiAccountTable from '../components/multi-account-table';
import CampaignsTable from '../components/campaigns-table';
import { supabase } from '../lib/supabase';

// Funcao para obter data formatada
const formatDate = (date) => date.toISOString().split('T')[0];

const getDefaultDates = () => {
  const until = new Date();
  const since = new Date();
  since.setDate(since.getDate() - 7); // Ultimos 7 dias por padrao

  return {
    since: formatDate(since),
    until: formatDate(until),
  };
};

export default function GestorDashboard() {
  const router = useRouter();

  // Estados
  const [token, setToken] = useState('');
  const [accounts, setAccounts] = useState([]);
  const [campaigns, setCampaigns] = useState([]);
  const [loading, setLoading] = useState(false);
  const [loadingCampaigns, setLoadingCampaigns] = useState(false);
  const [error, setError] = useState(null);
  const [connected, setConnected] = useState(false);
  const [dates, setDates] = useState(getDefaultDates());
  const [onlyActiveCampaigns, setOnlyActiveCampaigns] = useState(true);
  const [user, setUser] = useState(null);
  const [authLoading, setAuthLoading] = useState(true);

  // Verificar usuario logado e redirecionar se nao estiver
  useEffect(() => {
    const checkAuth = async () => {
      const { data: { user } } = await supabase.auth.getUser();

      if (!user) {
        router.replace('/login');
        return;
      }

      setUser(user);
      setAuthLoading(false);
    };

    checkAuth();

    // Listener para mudancas de auth
    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      if (!session?.user) {
        router.replace('/login');
        return;
      }
      setUser(session?.user ?? null);
    });

    return () => subscription.unsubscribe();
  }, [router]);

  // Carregar token do localStorage ao iniciar
  useEffect(() => {
    if (typeof window !== 'undefined') {
      const savedToken = localStorage.getItem('metaAdsToken');
      if (savedToken) {
        setToken(savedToken);
      }
    }
  }, []);

  // Funcao de logout
  const handleLogout = async () => {
    await supabase.auth.signOut();
    router.push('/login');
  };

  // Funcao para buscar dados (aceita datas como parametro opcional)
  const fetchData = async (customSince, customUntil) => {
    if (!token) {
      setError({ message: 'Por favor, insira um token valido.' });
      return;
    }

    // Usar datas customizadas se fornecidas, senao usar do estado
    const sinceDateToUse = customSince || dates.since;
    const untilDateToUse = customUntil || dates.until;

    setLoading(true);
    setError(null);

    try {
      const response = await fetch('/api/get-all-accounts-insights', {
        method: 'POST',
        body: JSON.stringify({
          accessToken: token,
          since: sinceDateToUse,
          until: untilDateToUse,
        }),
      });

      const result = await response.json();

      if (result.error) {
        setError(result.error);
        setConnected(false);
        setAccounts([]);
      } else {
        const accountsData = result.data || [];
        setAccounts(accountsData);
        setConnected(true);
        setError(null);

        // Salvar token no localStorage se conectou com sucesso
        if (typeof window !== 'undefined') {
          localStorage.setItem('metaAdsToken', token);
        }

        // Buscar campanhas de todas as contas
        if (accountsData.length > 0) {
          fetchCampaigns(accountsData, sinceDateToUse, untilDateToUse, onlyActiveCampaigns);
        }
      }
    } catch (err) {
      console.error('Erro ao buscar dados:', err);
      setError({ message: 'Erro ao conectar com a API. Tente novamente.' });
      setConnected(false);
    } finally {
      setLoading(false);
    }
  };

  // Funcao para buscar campanhas
  const fetchCampaigns = async (accountsData, customSince, customUntil, onlyActive = true) => {
    setLoadingCampaigns(true);

    // Usar datas customizadas se fornecidas
    const sinceDateToUse = customSince || dates.since;
    const untilDateToUse = customUntil || dates.until;

    try {
      const response = await fetch('/api/get-all-campaigns', {
        method: 'POST',
        body: JSON.stringify({
          accessToken: token,
          since: sinceDateToUse,
          until: untilDateToUse,
          accountIds: accountsData.map(a => a.id),
          accounts: accountsData,
          onlyActive: onlyActive,
        }),
      });

      const result = await response.json();

      if (!result.error) {
        setCampaigns(result.data || []);
      }
    } catch (err) {
      console.error('Erro ao buscar campanhas:', err);
    } finally {
      setLoadingCampaigns(false);
    }
  };

  // Handler para mudanca do filtro de campanhas ativas
  const handleActiveFilterChange = (onlyActive) => {
    setOnlyActiveCampaigns(onlyActive);
    if (accounts.length > 0) {
      fetchCampaigns(accounts, dates.since, dates.until, onlyActive);
    }
  };

  // Handler para mudanca de datas
  const handleDateChange = (since, until) => {
    setDates({ since, until });
  };

  // Tela de loading enquanto verifica autenticacao
  if (authLoading) {
    return (
      <Box
        sx={{
          minHeight: '100vh',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          backgroundColor: '#f0f2f5',
        }}
      >
        <CircularProgress />
      </Box>
    );
  }

  return (
    <>
      <Head>
        <title>Dashboard Meta Ads - Gestor de Trafego</title>
        <meta name="description" content="Dashboard para gestores de trafego visualizarem multiplas contas Meta Ads" />
      </Head>

      <Box
        sx={{
          minHeight: '100vh',
          backgroundColor: '#f0f2f5',
          py: 3,
        }}
      >
        <Container maxWidth="xl">
          {/* Header */}
          <Paper
            sx={{
              p: 3,
              mb: 3,
              background: 'linear-gradient(135deg, #1877f2 0%, #42b72a 100%)',
              color: 'white',
            }}
          >
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
              <Box>
                <Typography variant="h4" component="h1" fontWeight="bold">
                  Dashboard Meta Ads
                </Typography>
                <Typography variant="subtitle1">
                  Visualize todas as suas contas de anuncios em um so lugar
                </Typography>
              </Box>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                {user && (
                  <Typography variant="body2" sx={{ opacity: 0.9 }}>
                    {user.email}
                  </Typography>
                )}
                <Button
                  variant="outlined"
                  size="small"
                  onClick={handleLogout}
                  startIcon={<LogoutIcon />}
                  sx={{
                    color: 'white',
                    borderColor: 'rgba(255,255,255,0.5)',
                    '&:hover': {
                      borderColor: 'white',
                      backgroundColor: 'rgba(255,255,255,0.1)',
                    },
                  }}
                >
                  Sair
                </Button>
              </Box>
            </Box>
          </Paper>

          {/* Token Input */}
          <TokenInput
            token={token}
            onTokenChange={setToken}
            onConnect={fetchData}
            loading={loading}
            error={error}
            connected={connected}
          />

          {/* Date Filter - So mostra se conectado */}
          {connected && (
            <DateFilter
              since={dates.since}
              until={dates.until}
              onDateChange={handleDateChange}
              onSearch={fetchData}
              loading={loading}
            />
          )}

          {/* Tabela de Contas */}
          {connected && (
            <Paper sx={{ p: 2, mb: 3 }}>
              <Typography variant="h6" sx={{ mb: 2 }}>
                Suas Contas de Anuncios ({accounts.length} contas)
              </Typography>
              <MultiAccountTable accounts={accounts} loading={loading} />
            </Paper>
          )}

          {/* Tabela de Campanhas */}
          {connected && (
            <Paper sx={{ p: 2 }}>
              <Typography variant="h6" sx={{ mb: 2 }}>
                Campanhas ({campaigns.length} campanhas)
              </Typography>
              <CampaignsTable
                campaigns={campaigns}
                loading={loadingCampaigns}
                onlyActive={onlyActiveCampaigns}
                onActiveFilterChange={handleActiveFilterChange}
              />
            </Paper>
          )}

          {/* Estado vazio */}
          {!connected && !loading && (
            <Paper
              sx={{
                p: 5,
                textAlign: 'center',
                color: '#666',
              }}
            >
              <Typography variant="h6" sx={{ mb: 1 }}>
                Conecte seu token para visualizar suas contas
              </Typography>
              <Typography variant="body2">
                Insira seu System User Token do Meta Business Manager acima para comecar.
              </Typography>
            </Paper>
          )}

          {/* Footer */}
          <Box sx={{ mt: 4, textAlign: 'center', color: '#999', fontSize: '0.75rem' }}>
            <p>Dashboard Meta Ads para Gestores de Trafego</p>
            <p>Os dados sao buscados diretamente da API do Meta. Seu token fica salvo apenas no seu navegador.</p>
          </Box>
        </Container>
      </Box>
    </>
  );
}
