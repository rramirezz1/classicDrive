import 'package:flutter/material.dart';
import '../services/promo_code_service.dart';
import '../models/promo_code_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';

/// Widget para input e validação de código promocional.
class PromoCodeInput extends StatefulWidget {
  final double bookingValue;
  final ValueChanged<PromoCodeResult?> onCodeValidated;

  const PromoCodeInput({
    super.key,
    required this.bookingValue,
    required this.onCodeValidated,
  });

  @override
  State<PromoCodeInput> createState() => _PromoCodeInputState();
}

class _PromoCodeInputState extends State<PromoCodeInput> {
  final TextEditingController _controller = TextEditingController();
  final PromoCodeService _service = PromoCodeService();
  
  bool _isLoading = false;
  PromoCodeResult? _result;
  bool _isExpanded = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _validateCode() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    final result = await _service.validateCode(
      _controller.text.trim(),
      widget.bookingValue,
    );

    setState(() {
      _isLoading = false;
      _result = result;
    });

    widget.onCodeValidated(result.isValid ? result : null);
  }

  void _clearCode() {
    setState(() {
      _controller.clear();
      _result = null;
    });
    widget.onCodeValidated(null);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: AppRadius.borderRadiusMd,
        border: Border.all(
          color: _result != null
              ? (_result!.isValid ? AppColors.success : AppColors.error)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: AppRadius.borderRadiusMd,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.1),
                      borderRadius: AppRadius.borderRadiusSm,
                    ),
                    child: Icon(
                      Icons.local_offer_rounded,
                      color: AppColors.accent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Código Promocional',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        if (_result != null && _result!.isValid)
                          Text(
                            _result!.promo!.discountDescription,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.success,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_result != null && _result!.isValid)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: AppRadius.borderRadiusFull,
                      ),
                      child: Text(
                        '-€${_result!.discount.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    )
                  else
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                ],
              ),
            ),
          ),

          // Input field
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _isExpanded || (_result != null)
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          enabled: !(_result?.isValid ?? false),
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            hintText: 'Inserir código',
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: AppRadius.borderRadiusSm,
                            ),
                            suffixIcon: _result?.isValid ?? false
                                ? IconButton(
                                    icon: const Icon(Icons.close_rounded),
                                    onPressed: _clearCode,
                                  )
                                : null,
                          ),
                          onSubmitted: (_) => _validateCode(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!(_result?.isValid ?? false))
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _validateCode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: AppRadius.borderRadiusSm,
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Aplicar'),
                          ),
                        ),
                    ],
                  ),
                  if (_result != null && !_result!.isValid) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.error,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _result!.errorMessage ?? 'Código inválido',
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card para exibir código promocional aplicado.
class AppliedPromoCard extends StatelessWidget {
  final PromoCodeModel promo;
  final double discount;
  final VoidCallback onRemove;

  const AppliedPromoCard({
    super.key,
    required this.promo,
    required this.discount,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: AppRadius.borderRadiusMd,
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: AppColors.success,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  promo.code,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  promo.discountDescription,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '-€${discount.toStringAsFixed(0)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.success,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: onRemove,
            color: AppColors.error,
          ),
        ],
      ),
    );
  }
}
