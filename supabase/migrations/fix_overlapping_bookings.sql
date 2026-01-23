-- =============================================================================
-- Script: Corrigir Reservas Sobrepostas Existentes
-- Executar ANTES da constraint anti-overlap
-- =============================================================================

-- PASSO 1: Ver quais reservas estão em conflito
SELECT 
    b1.id as booking1_id,
    b2.id as booking2_id,
    b1.vehicle_id,
    b1.start_date as b1_start, b1.end_date as b1_end, b1.status as b1_status,
    b2.start_date as b2_start, b2.end_date as b2_end, b2.status as b2_status
FROM bookings b1
JOIN bookings b2 ON b1.vehicle_id = b2.vehicle_id 
    AND b1.id < b2.id
    AND daterange(b1.start_date, b1.end_date, '[]') && daterange(b2.start_date, b2.end_date, '[]')
WHERE b1.status NOT IN ('cancelled', 'rejected', 'payment_failed', 'refunded')
  AND b2.status NOT IN ('cancelled', 'rejected', 'payment_failed', 'refunded');

-- PASSO 2: Marcar a reserva mais antiga como "cancelled" (ou a mais recente, à escolha)
-- Isto resolve o conflito mantendo a reserva mais recente

-- Opção A: Cancelar a reserva MAIS ANTIGA em cada par de conflito
UPDATE bookings
SET status = 'cancelled', 
    updated_at = NOW()
WHERE id IN (
    SELECT b1.id
    FROM bookings b1
    JOIN bookings b2 ON b1.vehicle_id = b2.vehicle_id 
        AND b1.id < b2.id
        AND daterange(b1.start_date, b1.end_date, '[]') && daterange(b2.start_date, b2.end_date, '[]')
    WHERE b1.status NOT IN ('cancelled', 'rejected', 'payment_failed', 'refunded')
      AND b2.status NOT IN ('cancelled', 'rejected', 'payment_failed', 'refunded')
      AND b1.created_at < b2.created_at  -- Cancelar a mais antiga
);

-- PASSO 3: Verificar que já não há conflitos
SELECT COUNT(*) as conflitos_restantes
FROM bookings b1
JOIN bookings b2 ON b1.vehicle_id = b2.vehicle_id 
    AND b1.id < b2.id
    AND daterange(b1.start_date, b1.end_date, '[]') && daterange(b2.start_date, b2.end_date, '[]')
WHERE b1.status NOT IN ('cancelled', 'rejected', 'payment_failed', 'refunded')
  AND b2.status NOT IN ('cancelled', 'rejected', 'payment_failed', 'refunded');

-- Se o resultado for 0, podes agora correr a migração anti_overlap_constraint.sql
