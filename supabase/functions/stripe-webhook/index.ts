// =============================================================================
// Edge Function: stripe-webhook
// Recebe eventos do Stripe e atualiza o estado das reservas
// =============================================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import Stripe from 'https://esm.sh/stripe@12.0.0'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// Inicializar Stripe
const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') ?? '', {
    apiVersion: '2022-11-15',
    httpClient: Stripe.createFetchHttpClient(),
})

// Webhook secret para validar assinaturas
const webhookSecret = Deno.env.get('STRIPE_WEBHOOK_SECRET') ?? ''

// Eventos que tratamos
const HANDLED_EVENTS = [
    'payment_intent.succeeded',
    'payment_intent.payment_failed',
    'payment_intent.canceled',
    'charge.refunded',
    'charge.dispute.created',
]

serve(async (req) => {
    // Apenas aceitar POST
    if (req.method !== 'POST') {
        return new Response('Method not allowed', { status: 405 })
    }

    try {
        // 1. VALIDAÇÃO DA ASSINATURA
        const signature = req.headers.get('stripe-signature')
        if (!signature) {
            console.error('Missing stripe-signature header')
            return new Response(
                JSON.stringify({ error: 'Missing signature' }),
                { status: 400 }
            )
        }

        const body = await req.text()
        let event: Stripe.Event

        try {
            event = stripe.webhooks.constructEvent(body, signature, webhookSecret)
        } catch (err) {
            console.error('Webhook signature verification failed:', err.message)
            return new Response(
                JSON.stringify({ error: 'Invalid signature' }),
                { status: 400 }
            )
        }

        console.log(`Received event: ${event.type} (${event.id})`)

        // 2. VERIFICAR SE É UM EVENTO QUE TRATAMOS
        if (!HANDLED_EVENTS.includes(event.type)) {
            console.log(`Ignoring event type: ${event.type}`)
            return new Response(JSON.stringify({ received: true }), { status: 200 })
        }

        // 3. IDEMPOTÊNCIA - Verificar se já processámos este evento
        const supabase = createClient(
            Deno.env.get('SUPABASE_URL') ?? '',
            Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
        )

        const { data: existingEvent } = await supabase
            .from('stripe_events')
            .select('id')
            .eq('event_id', event.id)
            .single()

        if (existingEvent) {
            console.log(`Event ${event.id} already processed, skipping`)
            return new Response(
                JSON.stringify({ received: true, duplicate: true }),
                { status: 200 }
            )
        }

        // 4. REGISTAR O EVENTO (para idempotência)
        await supabase.from('stripe_events').insert({
            event_id: event.id,
            event_type: event.type,
            payload: event.data.object,
            processed_at: new Date().toISOString(),
        })

        // 5. PROCESSAR O EVENTO
        let result = { success: true, action: 'none' }

        switch (event.type) {
            case 'payment_intent.succeeded':
                result = await handlePaymentSucceeded(supabase, event.data.object as Stripe.PaymentIntent)
                break

            case 'payment_intent.payment_failed':
                result = await handlePaymentFailed(supabase, event.data.object as Stripe.PaymentIntent)
                break

            case 'payment_intent.canceled':
                result = await handlePaymentCanceled(supabase, event.data.object as Stripe.PaymentIntent)
                break

            case 'charge.refunded':
                result = await handleChargeRefunded(supabase, event.data.object as Stripe.Charge)
                break

            case 'charge.dispute.created':
                result = await handleDisputeCreated(supabase, event.data.object as Stripe.Dispute)
                break
        }

        // 6. ATUALIZAR O REGISTO DO EVENTO COM O RESULTADO
        await supabase
            .from('stripe_events')
            .update({ 
                processing_result: result,
                completed_at: new Date().toISOString()
            })
            .eq('event_id', event.id)

        console.log(`Event ${event.id} processed:`, result)

        return new Response(
            JSON.stringify({ received: true, result }),
            { status: 200, headers: { 'Content-Type': 'application/json' } }
        )

    } catch (error) {
        console.error('Webhook error:', error.message)
        return new Response(
            JSON.stringify({ error: error.message }),
            { status: 500 }
        )
    }
})

// =============================================================================
// HANDLERS DE EVENTOS
// =============================================================================

/**
 * Pagamento bem-sucedido - confirmar a reserva
 */
async function handlePaymentSucceeded(
    supabase: any, 
    paymentIntent: Stripe.PaymentIntent
): Promise<{ success: boolean; action: string; bookingId?: string }> {
    const paymentIntentId = paymentIntent.id
    
    // Procurar a booking associada a este payment_intent
    const { data: booking, error } = await supabase
        .from('bookings')
        .select('id, status')
        .eq('payment_intent_id', paymentIntentId)
        .single()

    if (error || !booking) {
        console.log(`No booking found for payment_intent: ${paymentIntentId}`)
        return { success: true, action: 'no_booking_found' }
    }

    // Atualizar o estado da reserva para confirmed
    if (booking.status === 'pending') {
        await supabase
            .from('bookings')
            .update({
                status: 'confirmed',
                payment: {
                    status: 'paid',
                    method: 'card',
                    transaction_id: paymentIntentId,
                    paid_at: new Date().toISOString(),
                },
                updated_at: new Date().toISOString(),
            })
            .eq('id', booking.id)

        console.log(`Booking ${booking.id} confirmed after payment`)
        return { success: true, action: 'booking_confirmed', bookingId: booking.id }
    }

    return { success: true, action: 'booking_already_processed', bookingId: booking.id }
}

/**
 * Pagamento falhou - marcar a reserva como falhada
 */
async function handlePaymentFailed(
    supabase: any, 
    paymentIntent: Stripe.PaymentIntent
): Promise<{ success: boolean; action: string; bookingId?: string }> {
    const paymentIntentId = paymentIntent.id
    const failureMessage = paymentIntent.last_payment_error?.message ?? 'Payment failed'

    const { data: booking, error } = await supabase
        .from('bookings')
        .select('id, status')
        .eq('payment_intent_id', paymentIntentId)
        .single()

    if (error || !booking) {
        return { success: true, action: 'no_booking_found' }
    }

    if (booking.status === 'pending') {
        await supabase
            .from('bookings')
            .update({
                status: 'payment_failed',
                payment: {
                    status: 'failed',
                    method: 'card',
                    transaction_id: paymentIntentId,
                    error_message: failureMessage,
                    failed_at: new Date().toISOString(),
                },
                updated_at: new Date().toISOString(),
            })
            .eq('id', booking.id)

        console.log(`Booking ${booking.id} marked as payment_failed`)
        return { success: true, action: 'booking_payment_failed', bookingId: booking.id }
    }

    return { success: true, action: 'booking_already_processed', bookingId: booking.id }
}

/**
 * Pagamento cancelado - cancelar a reserva
 */
async function handlePaymentCanceled(
    supabase: any, 
    paymentIntent: Stripe.PaymentIntent
): Promise<{ success: boolean; action: string; bookingId?: string }> {
    const paymentIntentId = paymentIntent.id

    const { data: booking, error } = await supabase
        .from('bookings')
        .select('id, status')
        .eq('payment_intent_id', paymentIntentId)
        .single()

    if (error || !booking) {
        return { success: true, action: 'no_booking_found' }
    }

    if (booking.status === 'pending') {
        await supabase
            .from('bookings')
            .update({
                status: 'cancelled',
                payment: {
                    status: 'cancelled',
                    method: 'card',
                    transaction_id: paymentIntentId,
                    cancelled_at: new Date().toISOString(),
                },
                updated_at: new Date().toISOString(),
            })
            .eq('id', booking.id)

        console.log(`Booking ${booking.id} cancelled due to payment cancellation`)
        return { success: true, action: 'booking_cancelled', bookingId: booking.id }
    }

    return { success: true, action: 'booking_already_processed', bookingId: booking.id }
}

/**
 * Reembolso processado - atualizar a reserva
 */
async function handleChargeRefunded(
    supabase: any, 
    charge: Stripe.Charge
): Promise<{ success: boolean; action: string; bookingId?: string }> {
    const paymentIntentId = charge.payment_intent as string

    if (!paymentIntentId) {
        return { success: true, action: 'no_payment_intent_in_charge' }
    }

    const { data: booking, error } = await supabase
        .from('bookings')
        .select('id, status, payment')
        .eq('payment_intent_id', paymentIntentId)
        .single()

    if (error || !booking) {
        return { success: true, action: 'no_booking_found' }
    }

    // Determinar se é reembolso total ou parcial
    const refundAmount = charge.amount_refunded
    const totalAmount = charge.amount
    const isFullRefund = refundAmount >= totalAmount

    const currentPayment = booking.payment ?? {}

    await supabase
        .from('bookings')
        .update({
            status: isFullRefund ? 'refunded' : booking.status,
            payment: {
                ...currentPayment,
                refund_status: isFullRefund ? 'full' : 'partial',
                refund_amount: refundAmount / 100, // converter de cêntimos
                refunded_at: new Date().toISOString(),
            },
            updated_at: new Date().toISOString(),
        })
        .eq('id', booking.id)

    console.log(`Booking ${booking.id} refund processed: ${isFullRefund ? 'full' : 'partial'}`)
    return { 
        success: true, 
        action: isFullRefund ? 'booking_fully_refunded' : 'booking_partially_refunded', 
        bookingId: booking.id 
    }
}

/**
 * Disputa criada - alertar para investigação
 */
async function handleDisputeCreated(
    supabase: any, 
    dispute: Stripe.Dispute
): Promise<{ success: boolean; action: string; bookingId?: string }> {
    const chargeId = dispute.charge as string
    
    // Obter o charge para encontrar o payment_intent
    const charge = await stripe.charges.retrieve(chargeId)
    const paymentIntentId = charge.payment_intent as string

    if (!paymentIntentId) {
        return { success: true, action: 'no_payment_intent_in_dispute' }
    }

    const { data: booking, error } = await supabase
        .from('bookings')
        .select('id, status, payment')
        .eq('payment_intent_id', paymentIntentId)
        .single()

    if (error || !booking) {
        return { success: true, action: 'no_booking_found' }
    }

    const currentPayment = booking.payment ?? {}

    await supabase
        .from('bookings')
        .update({
            status: 'disputed',
            payment: {
                ...currentPayment,
                dispute_id: dispute.id,
                dispute_reason: dispute.reason,
                dispute_amount: dispute.amount / 100,
                dispute_created_at: new Date().toISOString(),
            },
            updated_at: new Date().toISOString(),
        })
        .eq('id', booking.id)

    // Opcionalmente, criar um registo de admin log para investigação
    await supabase.from('admin_logs').insert({
        action: 'dispute_created',
        target_type: 'booking',
        target_id: booking.id,
        details: {
            dispute_id: dispute.id,
            reason: dispute.reason,
            amount: dispute.amount / 100,
        },
        created_at: new Date().toISOString(),
    })

    console.log(`Dispute created for booking ${booking.id}`)
    return { success: true, action: 'dispute_logged', bookingId: booking.id }
}
