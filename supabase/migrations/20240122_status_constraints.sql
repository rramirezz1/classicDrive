-- =============================================================================
-- Migration: Status Constraints (CHECK)
-- Date: 2024-01-22
-- Description: Adiciona CHECK constraints para garantir consistência dos estados
-- =============================================================================

-- =============================================================================
-- 1. BOOKING STATUS CONSTRAINT
-- =============================================================================

-- Remover constraint se existir (para poder recriar)
ALTER TABLE bookings DROP CONSTRAINT IF EXISTS chk_booking_status;

-- Adicionar constraint com todos os estados válidos
ALTER TABLE bookings 
ADD CONSTRAINT chk_booking_status 
CHECK (status IN (
    'pending',         -- Aguarda confirmação
    'confirmed',       -- Confirmado pelo owner
    'completed',       -- Concluído
    'cancelled',       -- Cancelado
    'rejected',        -- Rejeitado pelo owner
    'payment_failed',  -- Pagamento falhou (webhook)
    'refunded',        -- Reembolsado (webhook)
    'disputed'         -- Em disputa/chargeback (webhook)
));

-- Comentário para documentação
COMMENT ON COLUMN bookings.status IS 'Estados: pending, confirmed, completed, cancelled, rejected, payment_failed, refunded, disputed';

-- =============================================================================
-- 2. VEHICLE VALIDATION STATUS CONSTRAINT
-- =============================================================================

ALTER TABLE vehicles DROP CONSTRAINT IF EXISTS chk_vehicle_validation_status;

ALTER TABLE vehicles 
ADD CONSTRAINT chk_vehicle_validation_status 
CHECK (validation_status IN (
    'pending',    -- Aguarda aprovação admin
    'approved',   -- Aprovado e visível
    'rejected'    -- Rejeitado pelo admin
));

COMMENT ON COLUMN vehicles.validation_status IS 'Estados: pending, approved, rejected';

-- =============================================================================
-- 3. KYC STATUS CONSTRAINT (se a coluna existir)
-- =============================================================================

DO $$ 
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'kyc_status'
    ) THEN
        -- Remover constraint se existir
        ALTER TABLE users DROP CONSTRAINT IF EXISTS chk_kyc_status;
        
        -- PRIMEIRO: Atualizar valores inválidos para um valor válido
        -- Valores vazios ou NULL ficam como NULL
        UPDATE users SET kyc_status = NULL WHERE kyc_status = '';
        
        -- Valores desconhecidos ficam como 'not_submitted'
        UPDATE users SET kyc_status = 'not_submitted' 
        WHERE kyc_status IS NOT NULL 
        AND kyc_status NOT IN ('not_submitted', 'pending', 'approved', 'rejected');
        
        -- DEPOIS: Adicionar constraint (agora todos os valores são válidos)
        ALTER TABLE users 
        ADD CONSTRAINT chk_kyc_status 
        CHECK (kyc_status IS NULL OR kyc_status IN (
            'not_submitted',  -- Não submetido
            'pending',        -- Em análise
            'approved',       -- Verificado
            'rejected'        -- Rejeitado
        ));
        
        COMMENT ON COLUMN users.kyc_status IS 'Estados: not_submitted, pending, approved, rejected';
    END IF;
END $$;

-- =============================================================================
-- 4. INSURANCE POLICY STATUS (se a tabela existir)
-- =============================================================================

DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'insurance_policies') THEN
        ALTER TABLE insurance_policies DROP CONSTRAINT IF EXISTS chk_insurance_policy_status;
        
        ALTER TABLE insurance_policies 
        ADD CONSTRAINT chk_insurance_policy_status 
        CHECK (status IN (
            'active',     -- Apólice ativa
            'expired',    -- Expirada
            'cancelled',  -- Cancelada
            'claimed'     -- Com sinistro em curso
        ));
    END IF;
END $$;

-- =============================================================================
-- 5. INSURANCE CLAIM STATUS (se a tabela existir)
-- =============================================================================

DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'insurance_claims') THEN
        ALTER TABLE insurance_claims DROP CONSTRAINT IF EXISTS chk_insurance_claim_status;
        
        ALTER TABLE insurance_claims 
        ADD CONSTRAINT chk_insurance_claim_status 
        CHECK (status IN (
            'submitted',    -- Submetido
            'under_review', -- Em análise
            'approved',     -- Aprovado
            'rejected',     -- Rejeitado
            'paid'          -- Indemnização paga
        ));
    END IF;
END $$;

-- =============================================================================
-- 6. VERIFICATION STATUS (se a tabela existir)
-- =============================================================================

DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'verifications') THEN
        ALTER TABLE verifications DROP CONSTRAINT IF EXISTS chk_verification_status;
        
        ALTER TABLE verifications 
        ADD CONSTRAINT chk_verification_status 
        CHECK (status IN (
            'pending',   -- Em análise
            'approved',  -- Aprovado
            'rejected'   -- Rejeitado
        ));
    END IF;
END $$;

-- =============================================================================
-- FIM DA MIGRAÇÃO
-- =============================================================================
