import { useEffect, useState } from 'react';
import { useRouter } from 'next/router';
import { supabase } from '../../lib/supabase';
import Box from '@mui/material/Box';
import CircularProgress from '@mui/material/CircularProgress';
import Typography from '@mui/material/Typography';
import Alert from '@mui/material/Alert';

export default function ConfirmPage() {
  const router = useRouter();
  const [status, setStatus] = useState('loading');
  const [message, setMessage] = useState('Verificando seu email...');

  useEffect(() => {
    const handleConfirmation = async () => {
      const { token_hash, type } = router.query;

      if (!token_hash) {
        // Aguardar query params carregarem
        return;
      }

      try {
        if (type === 'signup' || type === 'email') {
          const { error } = await supabase.auth.verifyOtp({
            token_hash,
            type: 'signup',
          });

          if (error) {
            setStatus('error');
            setMessage('Link de confirmacao invalido ou expirado.');
            return;
          }

          setStatus('success');
          setMessage('Email confirmado com sucesso! Redirecionando...');

          setTimeout(() => {
            router.push('/login');
          }, 2000);
        } else if (type === 'recovery') {
          setStatus('success');
          setMessage('Redirecionando para redefinir senha...');
          router.push(`/reset-password?token_hash=${token_hash}`);
        } else {
          setStatus('error');
          setMessage('Tipo de confirmacao desconhecido.');
        }
      } catch (err) {
        console.error('Erro na confirmacao:', err);
        setStatus('error');
        setMessage('Erro ao confirmar email. Tente novamente.');
      }
    };

    if (router.isReady) {
      handleConfirmation();
    }
  }, [router.isReady, router.query]);

  return (
    <Box
      sx={{
        minHeight: '100vh',
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        backgroundColor: '#f0f2f5',
        p: 3,
      }}
    >
      {status === 'loading' && (
        <>
          <CircularProgress size={48} sx={{ mb: 3 }} />
          <Typography variant="h6">{message}</Typography>
        </>
      )}

      {status === 'success' && (
        <Alert severity="success" sx={{ maxWidth: 400 }}>
          {message}
        </Alert>
      )}

      {status === 'error' && (
        <Alert severity="error" sx={{ maxWidth: 400 }}>
          {message}
        </Alert>
      )}
    </Box>
  );
}
