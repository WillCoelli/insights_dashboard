import * as React from 'react';
import Box from '@mui/material/Box';
import TextField from '@mui/material/TextField';
import Button from '@mui/material/Button';
import Alert from '@mui/material/Alert';
import IconButton from '@mui/material/IconButton';
import InputAdornment from '@mui/material/InputAdornment';
import Visibility from '@mui/icons-material/Visibility';
import VisibilityOff from '@mui/icons-material/VisibilityOff';
import SaveIcon from '@mui/icons-material/Save';
import DeleteIcon from '@mui/icons-material/Delete';

export default function TokenInput({ token, onTokenChange, onConnect, loading, error, connected }) {
  const [showToken, setShowToken] = React.useState(false);
  const [localToken, setLocalToken] = React.useState(token || '');

  React.useEffect(() => {
    setLocalToken(token || '');
  }, [token]);

  const handleToggleVisibility = () => {
    setShowToken(!showToken);
  };

  const handleConnect = () => {
    onTokenChange(localToken);
    onConnect();
  };

  const handleClear = () => {
    setLocalToken('');
    onTokenChange('');
    // Limpar localStorage
    if (typeof window !== 'undefined') {
      localStorage.removeItem('metaAdsToken');
    }
  };

  const handleSaveToken = () => {
    if (typeof window !== 'undefined' && localToken) {
      localStorage.setItem('metaAdsToken', localToken);
      alert('Token salvo no navegador!');
    }
  };

  return (
    <Box
      sx={{
        mb: 3,
        p: 3,
        backgroundColor: '#fff',
        borderRadius: 2,
        boxShadow: '0 2px 8px rgba(0,0,0,0.1)',
      }}
    >
      <Box sx={{ mb: 2 }}>
        <h3 style={{ margin: '0 0 8px 0', color: '#333' }}>
          System User Token (Meta Business)
        </h3>
        <p style={{ margin: 0, fontSize: '0.875rem', color: '#666' }}>
          Cole seu token de System User do Business Manager.
          O token fica salvo apenas no seu navegador.
        </p>
      </Box>

      {error && (
        <Alert severity="error" sx={{ mb: 2 }}>
          {error.message || 'Erro ao conectar. Verifique seu token.'}
        </Alert>
      )}

      {connected && (
        <Alert severity="success" sx={{ mb: 2 }}>
          Conectado com sucesso! Suas contas estao sendo carregadas.
        </Alert>
      )}

      <Box sx={{ display: 'flex', gap: 1, alignItems: 'flex-start' }}>
        <TextField
          fullWidth
          label="Access Token"
          type={showToken ? 'text' : 'password'}
          value={localToken}
          onChange={(e) => setLocalToken(e.target.value)}
          placeholder="Cole seu System User Token aqui..."
          size="small"
          disabled={loading}
          InputProps={{
            endAdornment: (
              <InputAdornment position="end">
                <IconButton onClick={handleToggleVisibility} edge="end" size="small">
                  {showToken ? <VisibilityOff /> : <Visibility />}
                </IconButton>
              </InputAdornment>
            ),
          }}
        />

        <Button
          variant="contained"
          onClick={handleConnect}
          disabled={loading || !localToken}
          sx={{ minWidth: 120 }}
        >
          {loading ? 'Conectando...' : 'Conectar'}
        </Button>

        <IconButton
          onClick={handleSaveToken}
          disabled={!localToken}
          title="Salvar token no navegador"
          color="primary"
        >
          <SaveIcon />
        </IconButton>

        <IconButton
          onClick={handleClear}
          disabled={!localToken && !token}
          title="Limpar token"
          color="error"
        >
          <DeleteIcon />
        </IconButton>
      </Box>

      <Box sx={{ mt: 2, p: 2, backgroundColor: '#f5f5f5', borderRadius: 1 }}>
        <p style={{ margin: '0 0 8px 0', fontSize: '0.75rem', fontWeight: 'bold', color: '#666' }}>
          Como obter o token:
        </p>
        <ol style={{ margin: 0, paddingLeft: '1.25rem', fontSize: '0.75rem', color: '#666' }}>
          <li>Acesse business.facebook.com</li>
          <li>Va em Configuracoes → Usuarios → Usuarios do sistema</li>
          <li>Crie ou selecione um System User</li>
          <li>Clique em "Gerar novo token"</li>
          <li>Selecione as permissoes: ads_read, business_management</li>
          <li>Copie e cole o token aqui</li>
        </ol>
      </Box>
    </Box>
  );
}
