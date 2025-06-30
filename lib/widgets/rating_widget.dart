import 'package:flutter/material.dart';

class RatingWidget extends StatelessWidget {
  final double rating;
  final int itemCount;
  final double size;
  final Color? color;
  final void Function(double)? onRatingChanged;
  final bool readOnly;

  const RatingWidget({
    super.key,
    required this.rating,
    this.itemCount = 5,
    this.size = 24.0,
    this.color,
    this.onRatingChanged,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final starColor = color ?? Colors.amber;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(itemCount, (index) {
        final starValue = index + 1.0;
        final filled = starValue <= rating;
        final halfFilled = starValue - 0.5 <= rating && starValue > rating;

        return GestureDetector(
          onTap: readOnly || onRatingChanged == null
              ? null
              : () => onRatingChanged!(starValue),
          child: Icon(
            halfFilled
                ? Icons.star_half
                : filled
                    ? Icons.star
                    : Icons.star_border,
            size: size,
            color: starColor,
          ),
        );
      }),
    );
  }
}

// Widget para mostrar rating com texto
class RatingDisplay extends StatelessWidget {
  final double rating;
  final int totalReviews;
  final double starSize;
  final TextStyle? textStyle;

  const RatingDisplay({
    super.key,
    required this.rating,
    required this.totalReviews,
    this.starSize = 16.0,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RatingWidget(
          rating: rating,
          size: starSize,
          readOnly: true,
        ),
        const SizedBox(width: 8),
        Text(
          '${rating.toStringAsFixed(1)} ($totalReviews)',
          style: textStyle ??
              TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
        ),
      ],
    );
  }
}

// Widget para input de rating com feedback visual
class RatingInput extends StatefulWidget {
  final double initialRating;
  final void Function(double) onRatingChanged;
  final double size;
  final String? label;

  const RatingInput({
    super.key,
    this.initialRating = 0.0,
    required this.onRatingChanged,
    this.size = 40.0,
    this.label,
  });

  @override
  State<RatingInput> createState() => _RatingInputState();
}

class _RatingInputState extends State<RatingInput> {
  late double _rating;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
  }

  String _getRatingText() {
    if (_rating == 0) return 'Toque para avaliar';
    if (_rating <= 1) return 'Muito Mau';
    if (_rating <= 2) return 'Mau';
    if (_rating <= 3) return 'Razoável';
    if (_rating <= 4) return 'Bom';
    return 'Excelente';
  }

  Color _getRatingColor() {
    if (_rating == 0) return Colors.grey;
    if (_rating <= 2) return Colors.red;
    if (_rating <= 3) return Colors.orange;
    if (_rating <= 4) return Colors.green;
    return Colors.green.shade700;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
        ],
        RatingWidget(
          rating: _rating,
          size: widget.size,
          onRatingChanged: (value) {
            setState(() {
              _rating = value;
            });
            widget.onRatingChanged(value);
          },
        ),
        const SizedBox(height: 8),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            color: _getRatingColor(),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          child: Text(_getRatingText()),
        ),
      ],
    );
  }
}
