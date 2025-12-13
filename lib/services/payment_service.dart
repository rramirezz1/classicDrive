import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Serviço de pagamentos com Stripe.
class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  bool mockMode = true;

  /// Inicializa o serviço de pagamentos.
  Future<void> init() async {
    if (mockMode) return;

    final key = dotenv.env['STRIPE_PUBLISHABLE_KEY'];
    if (key != null) {
      Stripe.publishableKey = key;
      await Stripe.instance.applySettings();
    } else {
      mockMode = true;
    }
  }

  /// Processa um pagamento.
  Future<bool> processPayment({
    required double amount,
    required String currency,
    required BuildContext context,
  }) async {
    if (mockMode) {
      return await _processMockPayment(context, amount, currency);
    }

    try {
      final paymentIntentData = await _createPaymentIntent(amount, currency);
      
      if (paymentIntentData == null) {
        throw Exception('Falha ao criar PaymentIntent');
      }

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntentData['clientSecret'],
          merchantDisplayName: 'Classic Drive',
          style: ThemeMode.system,
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      return true;
    } on StripeException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pagamento cancelado ou falhou: ${e.error.localizedMessage}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao processar pagamento: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  /// Simula um pagamento para testes.
  Future<bool> _processMockPayment(
      BuildContext context, double amount, String currency) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    await Future.delayed(const Duration(seconds: 2));

    if (context.mounted) Navigator.pop(context);

    if (!context.mounted) return false;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pagamento simulado com sucesso! 💳'),
        backgroundColor: Colors.green,
      ),
    );
    
    return true;
  }

  /// Cria um PaymentIntent através da Edge Function.
  Future<Map<String, dynamic>?> _createPaymentIntent(
      double amount, String currency) async {
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'payment-sheet',
        body: {
          'amount': (amount * 100).toInt(),
          'currency': currency,
        },
      );

      return response.data as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
}
