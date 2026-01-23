-- =============================================================================
-- Migration: Stripe Webhook Support
-- Date: 2024-01-22
-- Description:
--   1. Cria tabela stripe_events para idempotência
--   2. Adiciona coluna payment_intent_id à tabela bookings
--   3. Adiciona novos estados de reserva relacionados com pagamentos
-- =============================================================================

-- =============================================================================
-- 1. TABELA STRIPE_EVENTS (IDEMPOTÊNCIA)
-- =============================================================================

CREATE TABLE IF NOT EXISTS stripe_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id TEXT UNIQUE NOT NULL,           -- ID do evento Stripe (evt_xxx)
    event_type TEXT NOT NULL,                -- Tipo do evento (payment_intent.succeeded)
    payload JSONB,                           -- Payload completo do evento
    processing_result JSONB,                 -- Resultado do processamento
    processed_at TIMESTAMPTZ NOT NULL,       -- Quando foi recebido
    completed_at TIMESTAMPTZ,                -- Quando terminou o processamento
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índice para busca rápida por event_id (idempotência)
CREATE INDEX IF NOT EXISTS idx_stripe_events_event_id 
ON stripe_events(event_id);

-- Índice para listagem por tipo
CREATE INDEX IF NOT EXISTS idx_stripe_events_type 
ON stripe_events(event_type);

-- Índice para ordenação por data
CREATE INDEX IF NOT EXISTS idx_stripe_events_processed 
ON stripe_events(processed_at DESC);

-- RLS para stripe_events (apenas service role pode aceder)
ALTER TABLE stripe_events ENABLE ROW LEVEL SECURITY;

-- Não criar políticas para authenticated - só service role pode manipular
-- O webhook usa SUPABASE_SERVICE_ROLE_KEY

-- =============================================================================
-- 2. ADICIONAR COLUNA payment_intent_id À TABELA BOOKINGS
-- =============================================================================

-- Adicionar a coluna se não existir
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'bookings' AND column_name = 'payment_intent_id'
    ) THEN
        ALTER TABLE bookings ADD COLUMN payment_intent_id TEXT;
    END IF;
END $$;

-- Índice para buscar bookings por payment_intent_id
CREATE INDEX IF NOT EXISTS idx_bookings_payment_intent 
ON bookings(payment_intent_id);

-- =============================================================================
-- 3. ADICIONAR NOVOS ESTADOS DE BOOKING (se usar enum, senão ignorar)
-- =============================================================================

-- Se a coluna status for TEXT (não enum), não precisa de alteração
-- Os novos estados são:
--   - 'payment_failed'  : Pagamento falhou
--   - 'refunded'        : Totalmente reembolsado
--   - 'disputed'        : Em disputa (chargeback)

-- Comentário para referência:
COMMENT ON COLUMN bookings.status IS 'Estados possíveis: pending, confirmed, completed, cancelled, rejected, payment_failed, refunded, disputed';

-- =============================================================================
-- 4. TABELA DE LOGS DE WEBHOOK (OPCIONAL - PARA DEBUG)
-- =============================================================================

CREATE TABLE IF NOT EXISTS webhook_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source TEXT NOT NULL,                    -- 'stripe', 'other'
    endpoint TEXT NOT NULL,                  -- Nome do endpoint
    headers JSONB,                           -- Headers do request
    body TEXT,                               -- Body raw
    response_status INTEGER,                 -- Status code da resposta
    response_body TEXT,                      -- Resposta enviada
    error_message TEXT,                      -- Se houver erro
    processing_time_ms INTEGER,              -- Tempo de processamento
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índice para ordenação
CREATE INDEX IF NOT EXISTS idx_webhook_logs_created 
ON webhook_logs(created_at DESC);

-- RLS
ALTER TABLE webhook_logs ENABLE ROW LEVEL SECURITY;

-- =============================================================================
-- 5. FUNÇÃO PARA LIMPAR EVENTOS ANTIGOS (MANUTENÇÃO)
-- =============================================================================

CREATE OR REPLACE FUNCTION cleanup_old_stripe_events(days_to_keep INTEGER DEFAULT 90)
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM stripe_events
    WHERE processed_at < NOW() - (days_to_keep || ' days')::INTERVAL;
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Comentário
COMMENT ON FUNCTION cleanup_old_stripe_events IS 'Remove eventos Stripe com mais de X dias. Usar: SELECT cleanup_old_stripe_events(90);';

-- =============================================================================
-- FIM DA MIGRAÇÃO
-- =============================================================================
