import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Resultado de um pagamento.
class PaymentResult {
  final bool success;
  final String? paymentIntentId;
  final String? errorMessage;

  PaymentResult({
    required this.success,
    this.paymentIntentId,
    this.errorMessage,
  });

  factory PaymentResult.success(String paymentIntentId) {
    return PaymentResult(success: true, paymentIntentId: paymentIntentId);
  }

  factory PaymentResult.failure(String error) {
    return PaymentResult(success: false, errorMessage: error);
  }

  factory PaymentResult.cancelled() {
    return PaymentResult(success: false, errorMessage: 'Pagamento cancelado');
  }
}

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

  /// Processa um pagamento e retorna o resultado com payment_intent_id.
  Future<PaymentResult> processPaymentWithIntent({
    required double amount,
    required String currency,
    required BuildContext context,
  }) async {
    if (mockMode) {
      return await _processMockPaymentWithIntent(context, amount, currency);
    }

    try {
      final paymentIntentData = await _createPaymentIntent(amount, currency);
      
      if (paymentIntentData == null) {
        return PaymentResult.failure('Falha ao criar PaymentIntent');
      }

      final clientSecret = paymentIntentData['clientSecret'] as String;
      // Extrair o payment_intent_id do client_secret (formato: pi_xxx_secret_yyy)
      final paymentIntentId = clientSecret.split('_secret_').first;

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Classic Drive',
          style: ThemeMode.system,
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      return PaymentResult.success(paymentIntentId);
    } on StripeException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pagamento cancelado ou falhou: ${e.error.localizedMessage}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return PaymentResult.failure(e.error.localizedMessage ?? 'Erro no pagamento');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao processar pagamento: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return PaymentResult.failure(e.toString());
    }
  }

  /// Processa um pagamento (versão simplificada para compatibilidade).
  Future<bool> processPayment({
    required double amount,
    required String currency,
    required BuildContext context,
  }) async {
    final result = await processPaymentWithIntent(
      amount: amount,
      currency: currency,
      context: context,
    );
    return result.success;
  }

  /// Simula um pagamento para testes (retorna PaymentResult).
  Future<PaymentResult> _processMockPaymentWithIntent(
      BuildContext context, double amount, String currency) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    await Future.delayed(const Duration(seconds: 2));

    if (context.mounted) Navigator.pop(context);

    if (!context.mounted) return PaymentResult.cancelled();
    
    // Gerar um mock payment_intent_id
    final mockPaymentIntentId = 'pi_mock_${DateTime.now().millisecondsSinceEpoch}';
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pagamento simulado com sucesso! 💳'),
        backgroundColor: Colors.green,
      ),
    );
    
    return PaymentResult.success(mockPaymentIntentId);
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
