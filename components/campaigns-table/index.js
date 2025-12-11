import * as React from 'react';
import { useState, useMemo, useEffect } from 'react';
import { DataGrid } from '@mui/x-data-grid';
import Box from '@mui/material/Box';
import Chip from '@mui/material/Chip';
import FormControlLabel from '@mui/material/FormControlLabel';
import Switch from '@mui/material/Switch';

// Formatadores
const formatCurrency = (value, currency = 'BRL') => {
  if (value === null || value === undefined || value === 0) return '-';
  return new Intl.NumberFormat('pt-BR', {
    style: 'currency',
    currency: currency,
  }).format(value);
};

const formatNumber = (value) => {
  if (value === null || value === undefined || value === 0) return '-';
  return new Intl.NumberFormat('pt-BR').format(value);
};

const formatPercent = (value) => {
  if (value === null || value === undefined || value === 0) return '-';
  return `${parseFloat(value).toFixed(2)}%`;
};


// Status colors
const getStatusColor = (status) => {
  switch (status) {
    case 'ACTIVE':
      return 'success';
    case 'PAUSED':
      return 'warning';
    case 'DELETED':
    case 'ARCHIVED':
      return 'error';
    default:
      return 'default';
  }
};

const getStatusLabel = (status) => {
  const labels = {
    'ACTIVE': 'Ativo',
    'PAUSED': 'Pausado',
    'DELETED': 'Deletado',
    'ARCHIVED': 'Arquivado',
    'PENDING_REVIEW': 'Em Revisao',
    'DISAPPROVED': 'Reprovado',
    'PREAPPROVED': 'Pre-aprovado',
    'PENDING_BILLING_INFO': 'Aguardando',
    'CAMPAIGN_PAUSED': 'Camp. Pausada',
    'ADSET_PAUSED': 'Conj. Pausado',
    'IN_PROCESS': 'Processando',
    'WITH_ISSUES': 'Com Problemas',
  };
  return labels[status] || status;
};

// Colunas
const columns = [
  {
    field: 'accountName',
    headerName: 'Conta',
    width: 150,
    renderCell: (params) => (
      <Box sx={{ overflow: 'hidden', textOverflow: 'ellipsis' }}>
        <span title={params.value} style={{ fontSize: '0.8rem' }}>{params.value}</span>
      </Box>
    ),
  },
  {
    field: 'name',
    headerName: 'Campanha',
    width: 220,
    renderCell: (params) => (
      <Box sx={{ overflow: 'hidden', textOverflow: 'ellipsis' }}>
        <strong title={params.value}>{params.value}</strong>
      </Box>
    ),
  },
  {
    field: 'status',
    headerName: 'Status',
    width: 100,
    renderCell: (params) => (
      <Chip
        label={getStatusLabel(params.value)}
        size="small"
        color={getStatusColor(params.value)}
        variant="outlined"
      />
    ),
  },
  {
    field: 'objective',
    headerName: 'Objetivo',
    width: 100,
  },
  {
    field: 'resultado',
    headerName: 'Resultado',
    width: 90,
    type: 'number',
    valueFormatter: (params) => formatNumber(params.value),
    cellClassName: (params) => {
      if (params.value > 0) return 'resultado-positive';
      return '';
    },
  },
  {
    field: 'custoPorResultado',
    headerName: 'Custo/Result.',
    width: 100,
    type: 'number',
    valueFormatter: (params) => formatCurrency(params.value),
    cellClassName: (params) => {
      if (params.value > 0 && params.value < 5) return 'custo-low';
      if (params.value >= 5 && params.value <= 9) return 'custo-medium';
      if (params.value > 9) return 'custo-high';
      return '';
    },
  },
  {
    field: 'spend',
    headerName: 'Gasto',
    width: 110,
    type: 'number',
    valueFormatter: (params) => formatCurrency(params.value),
    cellClassName: 'font-bold',
  },
  {
    field: 'dailyBudget',
    headerName: 'Orç. Diário',
    width: 100,
    type: 'number',
    valueFormatter: (params) => formatCurrency(params.value),
  },
  {
    field: 'cpm',
    headerName: 'CPM',
    width: 80,
    type: 'number',
    valueFormatter: (params) => formatCurrency(params.value),
  },
  {
    field: 'ctr',
    headerName: 'CTR',
    width: 70,
    type: 'number',
    valueFormatter: (params) => formatPercent(params.value),
  },
];

// Calcular totais das campanhas
const calculateTotals = (rows) => {
  if (!rows || rows.length === 0) return null;

  const totals = rows.reduce(
    (acc, row) => ({
      spend: acc.spend + (row.spend || 0),
      resultado: acc.resultado + (row.resultado || 0),
    }),
    { spend: 0, resultado: 0 }
  );

  // Custo por resultado medio
  totals.custoPorResultado = totals.resultado > 0 ? totals.spend / totals.resultado : 0;

  // Contar campanhas
  totals.totalCount = rows.length;

  return totals;
};

export default function CampaignsTable({ campaigns, loading, onlyActive = true, onActiveFilterChange }) {
  const [accountFilters, setAccountFilters] = useState({});

  // Extrair lista unica de contas
  const accountOptions = useMemo(() => {
    if (!campaigns || campaigns.length === 0) return [];
    const accounts = [...new Set(campaigns.map(c => c.accountName))].filter(Boolean);
    return accounts.sort();
  }, [campaigns]);

  // Inicializar filtros quando as contas mudam (todas ativas por padrao)
  useEffect(() => {
    if (accountOptions.length > 0) {
      const initialFilters = {};
      accountOptions.forEach(account => {
        // Manter estado anterior se existir, senao ativar
        initialFilters[account] = accountFilters[account] !== undefined ? accountFilters[account] : true;
      });
      setAccountFilters(initialFilters);
    }
  }, [accountOptions]);

  // Toggle para uma conta especifica
  const handleAccountToggle = (accountName) => {
    setAccountFilters(prev => ({
      ...prev,
      [accountName]: !prev[accountName]
    }));
  };

  // Handler para mudanca do switch de campanhas ativas
  const handleActiveToggle = (e) => {
    if (onActiveFilterChange) {
      onActiveFilterChange(e.target.checked);
    }
  };

  // Filtrar campanhas por contas selecionadas
  const filteredCampaigns = useMemo(() => {
    let filtered = campaigns || [];

    // Filtrar por contas selecionadas
    const activeAccounts = Object.keys(accountFilters).filter(acc => accountFilters[acc]);
    if (activeAccounts.length > 0 && activeAccounts.length < accountOptions.length) {
      filtered = filtered.filter(c => accountFilters[c.accountName]);
    }

    return filtered;
  }, [campaigns, accountFilters, accountOptions]);

  const totals = calculateTotals(filteredCampaigns);

  return (
    <Box sx={{ width: '100%' }}>
      {/* Filtros */}
      <Box sx={{ mb: 2 }}>
        {/* Filtro de status */}
        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 1 }}>
          <FormControlLabel
            control={
              <Switch
                checked={onlyActive}
                onChange={handleActiveToggle}
                color="primary"
                size="small"
                disabled={loading}
              />
            }
            label={onlyActive ? "Apenas campanhas ativas" : "Todas as campanhas"}
          />
          <Box sx={{ fontSize: '0.875rem', color: '#666' }}>
            Mostrando {filteredCampaigns.length} de {campaigns?.length || 0} campanhas
          </Box>
        </Box>

        {/* Filtros por conta */}
        {accountOptions.length > 0 && (
          <Box sx={{
            display: 'flex',
            gap: 1,
            flexWrap: 'wrap',
            p: 1.5,
            backgroundColor: '#f5f5f5',
            borderRadius: 1,
            alignItems: 'center'
          }}>
            <Box sx={{ fontSize: '0.8rem', color: '#666', mr: 1 }}>Contas:</Box>
            {accountOptions.map((account) => (
              <Chip
                key={account}
                label={account}
                size="small"
                onClick={() => handleAccountToggle(account)}
                color={accountFilters[account] ? 'primary' : 'default'}
                variant={accountFilters[account] ? 'filled' : 'outlined'}
                sx={{
                  cursor: 'pointer',
                  '&:hover': { opacity: 0.8 }
                }}
              />
            ))}
          </Box>
        )}
      </Box>

      {/* Resumo */}
      {totals && (
        <Box
          sx={{
            display: 'flex',
            gap: 3,
            mb: 2,
            p: 2,
            backgroundColor: '#e3f2fd',
            borderRadius: 1,
            flexWrap: 'wrap',
            alignItems: 'center',
          }}
        >
          <Box sx={{ textAlign: 'center', minWidth: 80 }}>
            <div style={{ fontSize: '0.75rem', color: '#666' }}>Campanhas</div>
            <div style={{ fontSize: '1.25rem', fontWeight: 'bold', color: '#1976d2' }}>
              {totals.totalCount}
            </div>
          </Box>
          <Box sx={{ textAlign: 'center', minWidth: 100 }}>
            <div style={{ fontSize: '0.75rem', color: '#666' }}>Gasto Total</div>
            <div style={{ fontSize: '1.25rem', fontWeight: 'bold', color: '#d32f2f' }}>
              {formatCurrency(totals.spend)}
            </div>
          </Box>
          <Box sx={{ textAlign: 'center', minWidth: 80 }}>
            <div style={{ fontSize: '0.75rem', color: '#666' }}>Resultados</div>
            <div style={{ fontSize: '1.25rem', fontWeight: 'bold', color: '#2e7d32' }}>
              {formatNumber(totals.resultado)}
            </div>
          </Box>
          <Box sx={{ textAlign: 'center', minWidth: 100 }}>
            <div style={{ fontSize: '0.75rem', color: '#666' }}>Custo/Result. Medio</div>
            <div style={{ fontSize: '1.25rem', fontWeight: 'bold', color: '#ed6c02' }}>
              {formatCurrency(totals.custoPorResultado)}
            </div>
          </Box>
        </Box>
      )}

      {/* Tabela */}
      <DataGrid
        rows={filteredCampaigns}
        columns={columns}
        loading={loading}
        autoHeight
        disableRowSelectionOnClick
        pageSizeOptions={[10, 25, 50]}
        initialState={{
          pagination: {
            paginationModel: { pageSize: 10 },
          },
          sorting: {
            sortModel: [{ field: 'custoPorResultado', sort: 'desc' }],
          },
        }}
        sx={{
          '& .font-bold': {
            fontWeight: 'bold',
          },
          '& .resultado-positive': {
            color: '#1976d2',
            fontWeight: 'bold',
          },
          '& .custo-low': {
            color: '#2e7d32',
            fontWeight: 'bold',
          },
          '& .custo-medium': {
            color: '#ed6c02',
            fontWeight: 'bold',
          },
          '& .custo-high': {
            color: '#d32f2f',
            fontWeight: 'bold',
          },
          '& .MuiDataGrid-cell': {
            fontSize: '0.8rem',
          },
          '& .MuiDataGrid-columnHeader': {
            backgroundColor: '#e3f2fd',
            fontWeight: 'bold',
            fontSize: '0.8rem',
          },
        }}
        localeText={{
          noRowsLabel: 'Nenhuma campanha encontrada',
          MuiTablePagination: {
            labelRowsPerPage: 'Linhas:',
          },
        }}
      />
    </Box>
  );
}
