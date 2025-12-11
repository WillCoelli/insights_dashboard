// Rate limiter simples para APIs - baseado em memoria
// Em producao considere usar Redis para persistencia entre instancias

const rateLimit = new Map();

// Configuracao padrao
const DEFAULT_WINDOW_MS = 60 * 1000; // 1 minuto
const DEFAULT_MAX_REQUESTS = 30; // 30 requisicoes por minuto

/**
 * Middleware de rate limiting
 * @param {Object} options - Configuracoes
 * @param {number} options.windowMs - Janela de tempo em ms
 * @param {number} options.max - Maximo de requisicoes na janela
 */
export function checkRateLimit(ip, options = {}) {
  const windowMs = options.windowMs || DEFAULT_WINDOW_MS;
  const max = options.max || DEFAULT_MAX_REQUESTS;

  const now = Date.now();
  const key = ip;

  // Limpar entradas antigas periodicamente
  if (Math.random() < 0.01) {
    cleanupOldEntries(windowMs);
  }

  const record = rateLimit.get(key);

  if (!record) {
    rateLimit.set(key, { count: 1, startTime: now });
    return { allowed: true, remaining: max - 1 };
  }

  // Verificar se a janela expirou
  if (now - record.startTime > windowMs) {
    rateLimit.set(key, { count: 1, startTime: now });
    return { allowed: true, remaining: max - 1 };
  }

  // Incrementar contador
  record.count += 1;

  if (record.count > max) {
    return {
      allowed: false,
      remaining: 0,
      retryAfter: Math.ceil((record.startTime + windowMs - now) / 1000),
    };
  }

  return { allowed: true, remaining: max - record.count };
}

function cleanupOldEntries(windowMs) {
  const now = Date.now();
  for (const [key, value] of rateLimit.entries()) {
    if (now - value.startTime > windowMs) {
      rateLimit.delete(key);
    }
  }
}

/**
 * Wrapper para usar em API routes
 */
export function withRateLimit(handler, options = {}) {
  return async (req, res) => {
    // Obter IP do cliente
    const forwarded = req.headers['x-forwarded-for'];
    const ip = forwarded ? forwarded.split(',')[0].trim() : req.socket?.remoteAddress || 'unknown';

    const result = checkRateLimit(ip, options);

    // Adicionar headers de rate limit
    res.setHeader('X-RateLimit-Remaining', result.remaining);

    if (!result.allowed) {
      res.setHeader('Retry-After', result.retryAfter);
      return res.status(429).json({
        error: 'Muitas requisicoes. Tente novamente em alguns segundos.',
        retryAfter: result.retryAfter,
      });
    }

    return handler(req, res);
  };
}

export default withRateLimit;
