// Redireciona para a pagina do gestor
import { useEffect } from 'react';
import { useRouter } from 'next/router';

export default function Painel() {
  const router = useRouter();

  useEffect(() => {
    router.replace('/gestor');
  }, [router]);

  return null;
}
