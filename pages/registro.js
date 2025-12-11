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

export default function RegistroPage() {
  const router = useRouter();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [success, setSuccess] = useState(false);

  // Dados do formulario
  const [nome, setNome] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');

  // Criar conta
  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    // Validar senhas
    if (password !== confirmPassword) {
      setError('As senhas nao coincidem');
      setLoading(false);
      return;
    }

    if (password.length < 6) {
      setError('A senha deve ter no minimo 6 caracteres');
      setLoading(false);
      return;
    }

    try {
      // Criar usuario no Supabase Auth
      const { data, error: signUpError } = await supabase.auth.signUp({
        email,
        password,
        options: {
          data: {
            nome: nome,
          },
        },
      });

      if (signUpError) {
        if (signUpError.message.includes('already registered')) {
          setError('Este email ja esta cadastrado');
        } else {
          setError(signUpError.message);
        }
        return;
      }

      setSuccess(true);

      // Redirecionar para login apos 2 segundos
      setTimeout(() => {
        router.push('/login');
      }, 2000);
    } catch (err) {
      setError('Erro ao criar conta. Tente novamente.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <>
      <Head>
        <title>Criar Conta - Dashboard Meta Ads</title>
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
            <Box sx={{ textAlign: 'center', mb: 3 }}>
              <Typography variant="h4" fontWeight="bold" color="primary">
                Criar Conta
              </Typography>
              <Typography variant="body2" color="text.secondary" sx={{ mt: 1 }}>
                Preencha os dados para criar sua conta
              </Typography>
            </Box>

            {/* Mensagens */}
            {error && (
              <Alert severity="error" sx={{ mb: 3 }}>
                {error}
              </Alert>
            )}
            {success && (
              <Alert severity="success" sx={{ mb: 3 }}>
                Conta criada com sucesso! Redirecionando para o login...
              </Alert>
            )}

            {/* Formulario */}
            {!success && (
              <form onSubmit={handleSubmit}>
                <TextField
                  fullWidth
                  label="Nome completo"
                  value={nome}
                  onChange={(e) => setNome(e.target.value)}
                  required
                  sx={{ mb: 2 }}
                />

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
                  helperText="Minimo 6 caracteres"
                  sx={{ mb: 2 }}
                />

                <TextField
                  fullWidth
                  label="Confirmar senha"
                  type="password"
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                  required
                  error={confirmPassword.length > 0 && password !== confirmPassword}
                  helperText={confirmPassword.length > 0 && password !== confirmPassword ? 'As senhas nao coincidem' : ''}
                  sx={{ mb: 3 }}
                />

                <Button
                  type="submit"
                  variant="contained"
                  fullWidth
                  size="large"
                  disabled={loading || password.length < 6}
                  sx={{
                    backgroundColor: '#1877f2',
                    '&:hover': {
                      backgroundColor: '#166fe5',
                    },
                  }}
                >
                  {loading ? <CircularProgress size={24} color="inherit" /> : 'Criar Conta'}
                </Button>
              </form>
            )}

            {/* Links */}
            {!success && (
              <Box sx={{ textAlign: 'center', mt: 3 }}>
                <Typography variant="body2" color="text.secondary">
                  Ja tem uma conta?{' '}
                  <Link href="/login" style={{ color: '#1976d2' }}>
                    Fazer login
                  </Link>
                </Typography>
              </Box>
            )}
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
