import * as React from 'react';
import Box from '@mui/material/Box';
import TextField from '@mui/material/TextField';
import Button from '@mui/material/Button';
import ButtonGroup from '@mui/material/ButtonGroup';

// Funcoes auxiliares para datas
const formatDateForInput = (date) => {
  return date.toISOString().split('T')[0];
};

const getDateRange = (days) => {
  const until = new Date();
  const since = new Date();
  since.setDate(since.getDate() - days);

  return {
    since: formatDateForInput(since),
    until: formatDateForInput(until),
  };
};

const presetRanges = [
  { label: 'Hoje', days: 0 },
  { label: '7 dias', days: 7 },
  { label: '14 dias', days: 14 },
  { label: '30 dias', days: 30 },
  { label: '90 dias', days: 90 },
];

export default function DateFilter({ since, until, onDateChange, onSearch, loading }) {
  const handlePresetClick = (days) => {
    const range = getDateRange(days);
    onDateChange(range.since, range.until);
    // Disparar busca automaticamente apos mudar as datas
    // Usar setTimeout para garantir que o estado foi atualizado
    setTimeout(() => {
      onSearch(range.since, range.until);
    }, 100);
  };

  const handleSinceChange = (e) => {
    onDateChange(e.target.value, until);
  };

  const handleUntilChange = (e) => {
    onDateChange(since, e.target.value);
  };

  return (
    <Box
      sx={{
        display: 'flex',
        gap: 2,
        alignItems: 'center',
        flexWrap: 'wrap',
        mb: 3,
        p: 2,
        backgroundColor: '#fff',
        borderRadius: 1,
        boxShadow: '0 1px 3px rgba(0,0,0,0.1)',
      }}
    >
      {/* Presets */}
      <ButtonGroup variant="outlined" size="small">
        {presetRanges.map((preset) => (
          <Button
            key={preset.days}
            onClick={() => handlePresetClick(preset.days)}
            disabled={loading}
          >
            {preset.label}
          </Button>
        ))}
      </ButtonGroup>

      {/* Date Inputs */}
      <Box sx={{ display: 'flex', gap: 1, alignItems: 'center' }}>
        <TextField
          label="De"
          type="date"
          value={since}
          onChange={handleSinceChange}
          size="small"
          InputLabelProps={{ shrink: true }}
          disabled={loading}
        />
        <span>ate</span>
        <TextField
          label="Ate"
          type="date"
          value={until}
          onChange={handleUntilChange}
          size="small"
          InputLabelProps={{ shrink: true }}
          disabled={loading}
        />
        <Button
          variant="contained"
          onClick={() => onSearch(since, until)}
          disabled={loading}
          size="small"
        >
          {loading ? 'Carregando...' : 'Atualizar'}
        </Button>
      </Box>
    </Box>
  );
}
