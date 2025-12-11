import React, { useState } from 'react';
import { useRouter } from 'next/router';
import Head from 'next/head';
import Link from 'next/link';
import Box from '@mui/material/Box';
import Container from '@mui/material/Container';
import Paper from '@mui/material/Paper';
import Typography from '@mui/material/Typography';
import TextField from '@mui/material/TextField';
import Button from '@mui/material/Button';
import Alert from '@mui/material/Alert';
import CircularProgress from '@mui/material/CircularProgress';
import { supabase } from '../lib/supabase';

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const handleLogin = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    try {
      const { data, error: authError } = await supabase.auth.signInWithPassword({
        email,
        password,
      });

      console.log('Login response:', { data, authError });

      if (authError) {
        if (authError.message.includes('Invalid login')) {
          setError('Email ou senha incorretos');
        } else if (authError.message.includes('Email not confirmed')) {
          setError('Email nao confirmado. Verifique sua caixa de entrada.');
        } else {
          setError(authError.message);
        }
        setLoading(false);
        return;
      }

      if (data?.user) {
        // Usar window.location para garantir redirecionamento
        window.location.href = '/gestor';
      }
    } catch (err) {
      console.error('Login error:', err);
      setError('Erro ao fazer login. Tente novamente.');
      setLoading(false);
    }
  };

  return (
    <>
      <Head>
        <title>Login - Dashboard Meta Ads</title>
      </Head>

      <Box
        sx={{
          minHeight: '100vh',
          backgroundColor: '#f0f2f5',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          py: 3,
        }}
      >
        <Container maxWidth="sm">
          <Paper sx={{ p: 4 }}>
            {/* Header */}
            <Box sx={{ textAlign: 'center', mb: 4 }}>
              <Typography variant="h4" fontWeight="bold" color="primary">
                Meta Ads Dashboard
              </Typography>
              <Typography variant="body2" color="text.secondary" sx={{ mt: 1 }}>
                Acesse sua conta para gerenciar seus anuncios
              </Typography>
            </Box>

            {/* Erro */}
            {error && (
              <Alert severity="error" sx={{ mb: 3 }}>
                {error}
              </Alert>
            )}

            {/* Formulario */}
            <form onSubmit={handleLogin}>
              <TextField
                fullWidth
                label="Email"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                sx={{ mb: 2 }}
              />

              <TextField
                fullWidth
                label="Senha"
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                sx={{ mb: 3 }}
              />

              <Button
                type="submit"
                variant="contained"
                fullWidth
                size="large"
                disabled={loading}
                sx={{ mb: 2 }}
              >
                {loading ? <CircularProgress size={24} /> : 'Entrar'}
              </Button>
            </form>

            {/* Links */}
            <Box sx={{ textAlign: 'center' }}>
              <Typography variant="body2" color="text.secondary">
                Nao tem uma conta?{' '}
                <Link href="/registro" style={{ color: '#1976d2' }}>
                  Criar conta
                </Link>
              </Typography>
            </Box>
          </Paper>

          {/* Footer */}
          <Box sx={{ mt: 3, textAlign: 'center', color: '#999', fontSize: '0.75rem' }}>
            <p>Dashboard para Gestores de Trafego</p>
          </Box>
        </Container>
      </Box>
    </>
  );
}
