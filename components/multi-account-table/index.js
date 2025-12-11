import * as React from 'react';
import { DataGrid } from '@mui/x-data-grid';
import Box from '@mui/material/Box';
import Chip from '@mui/material/Chip';
import Button from '@mui/material/Button';
import AddCardIcon from '@mui/icons-material/AddCard';

// Formatadores de valores
const formatCurrency = (value, currency = 'BRL') => {
  if (value === null || value === undefined) return '-';
  return new Intl.NumberFormat('pt-BR', {
    style: 'currency',
    currency: currency,
  }).format(value);
};

// Colunas da tabela
const columns = [
  {
    field: 'accountName',
    headerName: 'Conta',
    width: 250,
    renderCell: (params) => (
      <Box sx={{ display: 'flex', flexDirection: 'column' }}>
        <strong>{params.value}</strong>
        <span style={{ fontSize: '0.75rem', color: '#666' }}>
          {params.row.businessName}
        </span>
      </Box>
    ),
  },
  {
    field: 'status',
    headerName: 'Status',
    width: 100,
    renderCell: (params) => (
      <Chip
        label={params.value}
        size="small"
        color={params.value === 'Ativo' ? 'success' : 'default'}
        variant="outlined"
      />
    ),
  },
  {
    field: 'balance',
    headerName: 'Saldo',
    width: 150,
    type: 'number',
    valueFormatter: (params) => formatCurrency(params.value, params.row?.currency),
    cellClassName: (params) => {
      if (params.value > 1000) return 'balance-high';
      if (params.value > 100) return 'balance-medium';
      return 'balance-low';
    },
  },
  {
    field: 'spend',
    headerName: 'Gasto',
    width: 150,
    type: 'number',
    valueFormatter: (params) => formatCurrency(params.value, params.row?.currency),
    cellClassName: 'font-bold',
  },
  {
    field: 'actions',
    headerName: 'Ações',
    width: 160,
    sortable: false,
    filterable: false,
    renderCell: (params) => {
      // Remover 'act_' do ID se existir para o link
      const accountId = params.row.id?.replace('act_', '') || params.row.id;
      const billingUrl = `https://business.facebook.com/billing_hub/payment_activity?asset_id=${accountId}&business_id=${params.row.businessId || ''}`;

      return (
        <Button
          variant="contained"
          size="small"
          startIcon={<AddCardIcon />}
          onClick={() => window.open(billingUrl, '_blank')}
          sx={{
            backgroundColor: '#1877f2',
            textTransform: 'none',
            fontSize: '0.75rem',
            '&:hover': {
              backgroundColor: '#166fe5',
            },
          }}
        >
          Adicionar Saldo
        </Button>
      );
    },
  },
];

// Calcular totais
const calculateTotals = (rows) => {
  if (!rows || rows.length === 0) return null;

  const totals = rows.reduce(
    (acc, row) => ({
      balance: acc.balance + (row.balance || 0),
      spend: acc.spend + (row.spend || 0),
    }),
    { balance: 0, spend: 0 }
  );

  totals.accountCount = rows.length;

  return totals;
};

export default function MultiAccountTable({ accounts, loading }) {
  const totals = calculateTotals(accounts);

  return (
    <Box sx={{ width: '100%' }}>
      {/* Resumo Totais */}
      {totals && (
        <Box
          sx={{
            display: 'flex',
            gap: 3,
            mb: 2,
            p: 2,
            backgroundColor: '#f5f5f5',
            borderRadius: 1,
            flexWrap: 'wrap',
          }}
        >
          <Box sx={{ textAlign: 'center', minWidth: 100 }}>
            <div style={{ fontSize: '0.75rem', color: '#666' }}>Contas</div>
            <div style={{ fontSize: '1.25rem', fontWeight: 'bold', color: '#1976d2' }}>
              {totals.accountCount}
            </div>
          </Box>
          <Box sx={{ textAlign: 'center', minWidth: 120 }}>
            <div style={{ fontSize: '0.75rem', color: '#666' }}>Saldo Total</div>
            <div style={{ fontSize: '1.25rem', fontWeight: 'bold', color: '#2e7d32' }}>
              {formatCurrency(totals.balance)}
            </div>
          </Box>
          <Box sx={{ textAlign: 'center', minWidth: 120 }}>
            <div style={{ fontSize: '0.75rem', color: '#666' }}>Gasto Total</div>
            <div style={{ fontSize: '1.25rem', fontWeight: 'bold', color: '#d32f2f' }}>
              {formatCurrency(totals.spend)}
            </div>
          </Box>
        </Box>
      )}

      {/* Tabela */}
      <DataGrid
        rows={accounts || []}
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
            sortModel: [{ field: 'balance', sort: 'asc' }],
          },
        }}
        sx={{
          '& .font-bold': {
            fontWeight: 'bold',
          },
          '& .balance-high': {
            color: '#2e7d32',
            fontWeight: 'bold',
          },
          '& .balance-medium': {
            color: '#ed6c02',
          },
          '& .balance-low': {
            color: '#d32f2f',
          },
          '& .MuiDataGrid-cell': {
            fontSize: '0.875rem',
          },
          '& .MuiDataGrid-columnHeader': {
            backgroundColor: '#f5f5f5',
            fontWeight: 'bold',
          },
        }}
        localeText={{
          noRowsLabel: 'Nenhuma conta encontrada',
          MuiTablePagination: {
            labelRowsPerPage: 'Linhas por pagina:',
          },
        }}
      />
    </Box>
  );
}
