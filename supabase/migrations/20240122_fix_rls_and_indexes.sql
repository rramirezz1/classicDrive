-- =============================================================================
-- Migration: Fix RLS policies and add performance indexes
-- Date: 2024-01-22
-- Description:
--   1. Corrige RLS dos seguros (remove SELECT true, aplica join via bookings)
--   2. Cria RLS para chat (conversations/messages)
--   3. Cria RLS para verifications (KYC)
--   4. Adiciona índices para performance do chat
-- =============================================================================

-- =============================================================================
-- 1. CORRIGIR RLS DOS SEGUROS
-- =============================================================================

-- Remover políticas antigas (todas as possíveis)
DROP POLICY IF EXISTS "Users can view their own quotes" ON insurance_quotes;
DROP POLICY IF EXISTS "Users can view quotes for their bookings" ON insurance_quotes;
DROP POLICY IF EXISTS "Users can view their own policies" ON insurance_policies;
DROP POLICY IF EXISTS "Users can view policies for their bookings" ON insurance_policies;
DROP POLICY IF EXISTS "Users can view their own claims" ON insurance_claims;
DROP POLICY IF EXISTS "Users can insert their own quotes" ON insurance_quotes;
DROP POLICY IF EXISTS "Users can insert quotes for their bookings" ON insurance_quotes;
DROP POLICY IF EXISTS "Users can insert their own policies" ON insurance_policies;
DROP POLICY IF EXISTS "Users can insert policies for their bookings" ON insurance_policies;
DROP POLICY IF EXISTS "Users can insert their own claims" ON insurance_claims;
DROP POLICY IF EXISTS "Users can insert claims for their policies" ON insurance_claims;

-- Criar políticas seguras via JOIN com bookings
-- insurance_quotes: só pode ver cotações das suas reservas
CREATE POLICY "Users can view quotes for their bookings"
ON insurance_quotes FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM bookings
    WHERE bookings.id = insurance_quotes.booking_id
    AND (bookings.renter_id = auth.uid() OR bookings.owner_id = auth.uid())
  )
);

-- insurance_policies: só pode ver apólices das suas reservas
CREATE POLICY "Users can view policies for their bookings"
ON insurance_policies FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM bookings
    WHERE bookings.id = insurance_policies.booking_id
    AND (bookings.renter_id = auth.uid() OR bookings.owner_id = auth.uid())
  )
);

-- insurance_claims: só pode ver sinistros das suas apólices
CREATE POLICY "Users can view their own claims"
ON insurance_claims FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM insurance_policies ip
    JOIN bookings b ON b.id = ip.booking_id
    WHERE ip.policy_number = insurance_claims.policy_number
    AND (b.renter_id = auth.uid() OR b.owner_id = auth.uid())
  )
);

-- Corrigir INSERT para insurance_quotes (verificar que o user é dono da reserva)
DROP POLICY IF EXISTS "Users can insert their own quotes" ON insurance_quotes;
CREATE POLICY "Users can insert quotes for their bookings"
ON insurance_quotes FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM bookings
    WHERE bookings.id = booking_id
    AND bookings.renter_id = auth.uid()
  )
);

-- Corrigir INSERT para insurance_policies
DROP POLICY IF EXISTS "Users can insert their own policies" ON insurance_policies;
CREATE POLICY "Users can insert policies for their bookings"
ON insurance_policies FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM bookings
    WHERE bookings.id = booking_id
    AND bookings.renter_id = auth.uid()
  )
);

-- Corrigir INSERT para insurance_claims
DROP POLICY IF EXISTS "Users can insert their own claims" ON insurance_claims;
CREATE POLICY "Users can insert claims for their policies"
ON insurance_claims FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM insurance_policies ip
    JOIN bookings b ON b.id = ip.booking_id
    WHERE ip.policy_number = policy_number
    AND b.renter_id = auth.uid()
  )
);

-- =============================================================================
-- 2. RLS PARA CONVERSATIONS (CHAT)
-- =============================================================================

-- Ativar RLS na tabela conversations
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;

-- Remover políticas antigas para conversations
DROP POLICY IF EXISTS "Users can view their own conversations" ON conversations;
DROP POLICY IF EXISTS "Users can create conversations they participate in" ON conversations;
DROP POLICY IF EXISTS "Users can update their own conversations" ON conversations;

-- SELECT: só pode ver conversas onde é participante
CREATE POLICY "Users can view their own conversations"
ON conversations FOR SELECT
TO authenticated
USING (
  participant_1_id = auth.uid() OR participant_2_id = auth.uid()
);

-- INSERT: só pode criar conversas onde é um dos participantes
CREATE POLICY "Users can create conversations they participate in"
ON conversations FOR INSERT
TO authenticated
WITH CHECK (
  participant_1_id = auth.uid() OR participant_2_id = auth.uid()
);

-- UPDATE: só pode atualizar conversas onde é participante
CREATE POLICY "Users can update their own conversations"
ON conversations FOR UPDATE
TO authenticated
USING (
  participant_1_id = auth.uid() OR participant_2_id = auth.uid()
);

-- =============================================================================
-- 3. RLS PARA MESSAGES (CHAT)
-- =============================================================================

-- Ativar RLS na tabela messages
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Remover políticas antigas para messages
DROP POLICY IF EXISTS "Users can view messages in their conversations" ON messages;
DROP POLICY IF EXISTS "Users can send messages in their conversations" ON messages;
DROP POLICY IF EXISTS "Users can update messages in their conversations" ON messages;

-- SELECT: só pode ver mensagens de conversas onde é participante
CREATE POLICY "Users can view messages in their conversations"
ON messages FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM conversations
    WHERE conversations.id = messages.conversation_id
    AND (conversations.participant_1_id = auth.uid() OR conversations.participant_2_id = auth.uid())
  )
);

-- INSERT: só pode enviar mensagens em conversas onde é participante
CREATE POLICY "Users can send messages in their conversations"
ON messages FOR INSERT
TO authenticated
WITH CHECK (
  sender_id = auth.uid()
  AND EXISTS (
    SELECT 1 FROM conversations
    WHERE conversations.id = conversation_id
    AND (conversations.participant_1_id = auth.uid() OR conversations.participant_2_id = auth.uid())
  )
);

-- UPDATE: só pode atualizar as próprias mensagens (ex: marcar como lida)
CREATE POLICY "Users can update messages in their conversations"
ON messages FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM conversations
    WHERE conversations.id = messages.conversation_id
    AND (conversations.participant_1_id = auth.uid() OR conversations.participant_2_id = auth.uid())
  )
);

-- =============================================================================
-- 4. RLS PARA VERIFICATIONS (KYC)
-- =============================================================================

-- Ativar RLS na tabela verifications
ALTER TABLE verifications ENABLE ROW LEVEL SECURITY;

-- Remover políticas antigas para verifications
DROP POLICY IF EXISTS "Users can view their own verification" ON verifications;
DROP POLICY IF EXISTS "Users can submit their own verification" ON verifications;
DROP POLICY IF EXISTS "Users can update their own verification" ON verifications;

-- SELECT: utilizador só vê a sua própria verificação
CREATE POLICY "Users can view their own verification"
ON verifications FOR SELECT
TO authenticated
USING (
  user_id = auth.uid()
);

-- INSERT: utilizador só pode submeter a sua própria verificação
CREATE POLICY "Users can submit their own verification"
ON verifications FOR INSERT
TO authenticated
WITH CHECK (
  user_id = auth.uid()
);

-- UPDATE: utilizador pode atualizar a sua própria verificação (resubmeter)
-- Nota: Admin updates são feitos via service role key
CREATE POLICY "Users can update their own verification"
ON verifications FOR UPDATE
TO authenticated
USING (
  user_id = auth.uid()
);

-- =============================================================================
-- 5. ÍNDICES PARA PERFORMANCE DO CHAT
-- =============================================================================

-- Índice para buscar conversas por participante
CREATE INDEX IF NOT EXISTS idx_conversations_participant_1 
ON conversations(participant_1_id);

CREATE INDEX IF NOT EXISTS idx_conversations_participant_2 
ON conversations(participant_2_id);

-- Índice composto para ordenação por última mensagem
CREATE INDEX IF NOT EXISTS idx_conversations_last_message_at 
ON conversations(last_message_at DESC NULLS LAST);

-- Índice para buscar mensagens por conversa (mais usado)
CREATE INDEX IF NOT EXISTS idx_messages_conversation_id 
ON messages(conversation_id);

-- Índice composto para ordenação de mensagens por data
CREATE INDEX IF NOT EXISTS idx_messages_conversation_created 
ON messages(conversation_id, created_at DESC);

-- Índice para buscar mensagens não lidas
CREATE INDEX IF NOT EXISTS idx_messages_read_at 
ON messages(read_at) WHERE read_at IS NULL;

-- Índice para sender_id (para verificar permissões)
CREATE INDEX IF NOT EXISTS idx_messages_sender 
ON messages(sender_id);

-- =============================================================================
-- 6. ÍNDICES EXTRAS PARA OUTRAS TABELAS
-- =============================================================================

-- Índice para bookings (usado nos JOINs de seguros)
CREATE INDEX IF NOT EXISTS idx_bookings_renter 
ON bookings(renter_id);

CREATE INDEX IF NOT EXISTS idx_bookings_owner 
ON bookings(owner_id);

-- Índice para insurance_quotes
CREATE INDEX IF NOT EXISTS idx_insurance_quotes_booking 
ON insurance_quotes(booking_id);

-- Índice para insurance_policies
CREATE INDEX IF NOT EXISTS idx_insurance_policies_booking 
ON insurance_policies(booking_id);

-- Índice para verifications
CREATE INDEX IF NOT EXISTS idx_verifications_user 
ON verifications(user_id);

CREATE INDEX IF NOT EXISTS idx_verifications_status 
ON verifications(status);

-- =============================================================================
-- FIM DA MIGRAÇÃO
-- =============================================================================
