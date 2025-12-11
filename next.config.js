/** @type {import('next').NextConfig} */
const nextConfig = {
  // Output standalone para Docker
  output: 'standalone',

  // Configuracoes de seguranca
  poweredByHeader: false,

  // Headers de seguranca
  async headers() {
    return [
      {
        source: '/:path*',
        headers: [
          {
            key: 'X-Frame-Options',
            value: 'DENY',
          },
          {
            key: 'X-Content-Type-Options',
            value: 'nosniff',
          },
          {
            key: 'X-XSS-Protection',
            value: '1; mode=block',
          },
          {
            key: 'Referrer-Policy',
            value: 'strict-origin-when-cross-origin',
          },
        ],
      },
    ];
  },

  // Otimizacoes de imagem
  images: {
    domains: ['graph.facebook.com', 'scontent.xx.fbcdn.net'],
    unoptimized: true, // Desabilitar otimizacao para evitar problemas no Docker
  },

  // Configuracoes de compilacao
  reactStrictMode: true,

  // Configuracoes experimentais
  experimental: {
    // Otimizacoes de bundle
  },
};

module.exports = nextConfig;
