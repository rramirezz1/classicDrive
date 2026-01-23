-- =============================================================================
-- Migration: Anti-Overlap Exclusion Constraint
-- Date: 2024-01-22
-- Description: 
--   Adiciona exclusion constraint para GARANTIR que não existam reservas
--   sobrepostas para o mesmo veículo, mesmo com requests concorrentes.
-- =============================================================================

-- =============================================================================
-- 1. HABILITAR EXTENSÃO BTREE_GIST (necessária para exclusion constraints)
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS btree_gist;

-- =============================================================================
-- 2. CRIAR EXCLUSION CONSTRAINT PARA ANTI-OVERLAP
-- =============================================================================

-- Esta constraint garante que para o mesmo vehicle_id, não podem existir
-- duas reservas (não canceladas/rejeitadas) com datas que se sobreponham.

-- IMPORTANTE: Só aplicamos a constraint para reservas "ativas":
-- - pending, confirmed, completed (não cancelled, rejected, payment_failed)

-- Primeiro, criar um índice auxiliar se não existir
CREATE INDEX IF NOT EXISTS idx_bookings_vehicle_dates 
ON bookings(vehicle_id, start_date, end_date);

-- Remover constraint se existir (para poder recriar)
ALTER TABLE bookings DROP CONSTRAINT IF EXISTS bookings_no_overlap;

-- Adicionar a EXCLUSION CONSTRAINT
-- Usa daterange para verificar overlap
ALTER TABLE bookings 
ADD CONSTRAINT bookings_no_overlap 
EXCLUDE USING gist (
    vehicle_id WITH =,
    daterange(start_date, end_date, '[]') WITH &&
) WHERE (status NOT IN ('cancelled', 'rejected', 'payment_failed', 'refunded'));

-- Comentário para documentação
COMMENT ON CONSTRAINT bookings_no_overlap ON bookings IS 
'Impede reservas sobrepostas para o mesmo veículo. Apenas considera reservas ativas (não canceladas/rejeitadas).';

-- =============================================================================
-- 3. ALTERNATIVA: TRIGGER (se a constraint falhar em algumas versões)
-- =============================================================================

-- Se por algum motivo a exclusion constraint não funcionar, 
-- este trigger é um fallback:

CREATE OR REPLACE FUNCTION prevent_booking_overlap()
RETURNS TRIGGER AS $$
BEGIN
    -- Verificar se há overlap com reservas existentes
    IF EXISTS (
        SELECT 1 FROM bookings
        WHERE vehicle_id = NEW.vehicle_id
        AND id != COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::uuid)
        AND status NOT IN ('cancelled', 'rejected', 'payment_failed', 'refunded')
        AND daterange(start_date, end_date, '[]') && daterange(NEW.start_date, NEW.end_date, '[]')
    ) THEN
        RAISE EXCEPTION 'Já existe uma reserva para este veículo neste período'
            USING ERRCODE = 'unique_violation';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Remover trigger se existir
DROP TRIGGER IF EXISTS check_booking_overlap ON bookings;

-- Criar trigger
CREATE TRIGGER check_booking_overlap
BEFORE INSERT OR UPDATE ON bookings
FOR EACH ROW
WHEN (NEW.status NOT IN ('cancelled', 'rejected', 'payment_failed', 'refunded'))
EXECUTE FUNCTION prevent_booking_overlap();

-- =============================================================================
-- 4. DOCUMENTAÇÃO DA ESTRATÉGIA ANTI-OVERLAP
-- =============================================================================

/*
ESTRATÉGIA DE ANTI-OVERLAP IMPLEMENTADA:

1. PRÉ-VALIDAÇÃO (camada aplicação):
   - Função check_vehicle_availability() verifica antes de criar
   - Permite feedback rápido ao utilizador

2. GARANTIA FORTE (camada base de dados):
   - Exclusion constraint com daterange && (overlap)
   - Trigger como fallback adicional
   
3. COMO FUNCIONA:
   - Quando se tenta inserir uma reserva, o PostgreSQL verifica:
     a) Se vehicle_id é igual a alguma reserva existente
     b) Se o daterange sobrepõe com alguma reserva existente
     c) Se a reserva existente está ativa (não cancelada)
   - Se todas as condições forem verdadeiras → ERRO

4. CENÁRIO DE CONCORRÊNCIA:
   - User A e User B tentam reservar o mesmo veículo nas mesmas datas
   - Ambos passam a validação check_vehicle_availability() (race condition)
   - User A faz INSERT → sucesso
   - User B faz INSERT → FALHA pela exclusion constraint
   - User B recebe erro e pode tentar outras datas

5. ESTADOS EXCLUÍDOS DA VERIFICAÇÃO:
   - cancelled: reserva cancelada
   - rejected: rejeitada pelo proprietário
   - payment_failed: pagamento falhou
   - refunded: reembolsada
   
   Estes estados não bloqueiam novas reservas.
*/

-- =============================================================================
-- FIM DA MIGRAÇÃO
-- =============================================================================
