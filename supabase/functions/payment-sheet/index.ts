import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import Stripe from 'https://esm.sh/stripe@12.0.0'

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') ?? '', {
    apiVersion: '2022-11-15',
    httpClient: Stripe.createFetchHttpClient(),
})

serve(async (req) => {
    try {
        const { amount, currency } = await req.json()

        // 1. Criar um Customer (Opcional, mas recomendado)
        // Aqui podíamos verificar se o user já existe no Stripe

        // 2. Criar o PaymentIntent
        const paymentIntent = await stripe.paymentIntents.create({
            amount: amount,
            currency: currency,
            automatic_payment_methods: { enabled: true },
        })

        // 3. Retornar o Client Secret para o Frontend
        return new Response(
            JSON.stringify({
                clientSecret: paymentIntent.client_secret,
            }),
            {
                headers: { "Content-Type": "application/json" },
                status: 200,
            }
        )
    } catch (error) {
        return new Response(
            JSON.stringify({ error: error.message }),
            {
                headers: { "Content-Type": "application/json" },
                status: 400,
            }
        )
    }
})
