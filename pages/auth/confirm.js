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
      const { token_hash, type, error_description } = router.query;

      // Se veio erro do Supabase
      if (error_description) {
        setStatus('error');
        setMessage(decodeURIComponent(error_description));
        return;
      }

      if (!token_hash) {
        // Aguardar query params carregarem
        return;
      }

      try {
        // Tentar diferentes tipos de verificação
        const verifyType = type === 'recovery' ? 'recovery' : 'email';

        const { data, error } = await supabase.auth.verifyOtp({
          token_hash,
          type: verifyType,
        });

        console.log('Verify response:', { data, error });

        if (error) {
          // Tentar com tipo 'signup' se 'email' falhar
          if (verifyType === 'email') {
            const { data: data2, error: error2 } = await supabase.auth.verifyOtp({
              token_hash,
              type: 'signup',
            });

            if (error2) {
              console.error('Verify error:', error2);
              setStatus('error');
              setMessage('Link de confirmacao invalido ou expirado. Solicite um novo email.');
              return;
            }
          } else {
            setStatus('error');
            setMessage('Link de confirmacao invalido ou expirado. Solicite um novo email.');
            return;
          }
        }

        setStatus('success');
        setMessage('Email confirmado com sucesso! Redirecionando para login...');

        setTimeout(() => {
          router.push('/login');
        }, 2000);

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
