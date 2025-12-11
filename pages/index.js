import { useEffect } from 'react';
import { useRouter } from 'next/router';
import { supabase } from '../lib/supabase';
import Box from '@mui/material/Box';
import CircularProgress from '@mui/material/CircularProgress';

export default function Home() {
  const router = useRouter();

  useEffect(() => {
    const checkAuth = async () => {
      const { data: { session } } = await supabase.auth.getSession();

      if (session) {
        router.replace('/gestor');
      } else {
        router.replace('/login');
      }
    };

    checkAuth();
  }, [router]);

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
