import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/promo_code_model.dart';

/// Serviço para gestão de códigos promocionais.
class PromoCodeService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Valida e obtém um código promocional.
  Future<PromoCodeResult> validateCode(String code, double bookingValue) async {
    try {
      final response = await _supabase
          .from('promo_codes')
          .select()
          .eq('code', code.toUpperCase())
          .maybeSingle();

      if (response == null) {
        return PromoCodeResult.error('Código não encontrado');
      }

      final promo = PromoCodeModel.fromMap(response);

      if (!promo.isActive) {
        return PromoCodeResult.error('Código inativo');
      }

      if (promo.validUntil != null && DateTime.now().isAfter(promo.validUntil!)) {
        return PromoCodeResult.error('Código expirado');
      }

      if (promo.validFrom != null && DateTime.now().isBefore(promo.validFrom!)) {
        return PromoCodeResult.error('Código ainda não está válido');
      }

      if (promo.maxUses != null && promo.usedCount >= promo.maxUses!) {
        return PromoCodeResult.error('Código esgotado');
      }

      if (promo.minBookingValue != null && bookingValue < promo.minBookingValue!) {
        return PromoCodeResult.error(
          'Valor mínimo: €${promo.minBookingValue!.toStringAsFixed(0)}',
        );
      }

      final discount = promo.calculateDiscount(bookingValue);
      return PromoCodeResult.success(promo, discount);
    } catch (e) {
      print('Erro ao validar código: $e');
      return PromoCodeResult.error('Erro ao validar código');
    }
  }

  /// Aplica um código promocional (incrementa contador de uso).
  Future<bool> applyCode(String codeId) async {
    try {
      await _supabase.rpc('increment_promo_usage', params: {'code_id': codeId});
      return true;
    } catch (e) {
      // Fallback se a função não existir
      try {
        final current = await _supabase
            .from('promo_codes')
            .select('used_count')
            .eq('id', codeId)
            .single();
        
        await _supabase
            .from('promo_codes')
            .update({'used_count': (current['used_count'] ?? 0) + 1})
            .eq('id', codeId);
        return true;
      } catch (e2) {
        print('Erro ao aplicar código: $e2');
        return false;
      }
    }
  }

  /// Cria um novo código promocional (admin).
  Future<PromoCodeModel?> createCode(PromoCodeModel promo) async {
    try {
      final response = await _supabase
          .from('promo_codes')
          .insert(promo.toMap())
          .select()
          .single();

      return PromoCodeModel.fromMap(response);
    } catch (e) {
      print('Erro ao criar código: $e');
      return null;
    }
  }

  /// Lista todos os códigos promocionais (admin).
  Future<List<PromoCodeModel>> getAllCodes() async {
    try {
      final response = await _supabase
          .from('promo_codes')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((e) => PromoCodeModel.fromMap(e))
          .toList();
    } catch (e) {
      print('Erro ao listar códigos: $e');
      return [];
    }
  }

  /// Desativa um código promocional.
  Future<bool> deactivateCode(String codeId) async {
    try {
      await _supabase
          .from('promo_codes')
          .update({'is_active': false})
          .eq('id', codeId);
      return true;
    } catch (e) {
      print('Erro ao desativar código: $e');
      return false;
    }
  }
}

/// Resultado da validação de código.
class PromoCodeResult {
  final bool isValid;
  final PromoCodeModel? promo;
  final double discount;
  final String? errorMessage;

  PromoCodeResult._({
    required this.isValid,
    this.promo,
    this.discount = 0,
    this.errorMessage,
  });

  factory PromoCodeResult.success(PromoCodeModel promo, double discount) {
    return PromoCodeResult._(
      isValid: true,
      promo: promo,
      discount: discount,
    );
  }

  factory PromoCodeResult.error(String message) {
    return PromoCodeResult._(
      isValid: false,
      errorMessage: message,
    );
  }
}
