import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';

/// Dropdown estilizado.
class StyledDropdown<T> extends StatelessWidget {
  final T? value;
  final List<DropdownItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final String? errorText;

  const StyledDropdown({
    super.key,
    this.value,
    required this.items,
    required this.onChanged,
    this.label,
    this.hint,
    this.prefixIcon,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: AppRadius.borderRadiusMd,
            border: Border.all(
              color: errorText != null
                  ? AppColors.error
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              hint: hint != null ? Text(hint!) : null,
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
              items: items.map((item) {
                return DropdownMenuItem<T>(
                  value: item.value,
                  child: Row(
                    children: [
                      if (item.icon != null) ...[
                        Icon(item.icon, size: 20, color: AppColors.primary),
                        const SizedBox(width: 12),
                      ],
                      Text(item.label),
                    ],
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            errorText!,
            style: TextStyle(
              color: AppColors.error,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}

class DropdownItem<T> {
  final T value;
  final String label;
  final IconData? icon;

  const DropdownItem({
    required this.value,
    required this.label,
    this.icon,
  });
}

/// Range slider estilizado.
class StyledRangeSlider extends StatelessWidget {
  final RangeValues values;
  final double min;
  final double max;
  final ValueChanged<RangeValues> onChanged;
  final String? label;
  final String Function(double)? formatValue;
  final int? divisions;

  const StyledRangeSlider({
    super.key,
    required this.values,
    required this.min,
    required this.max,
    required this.onChanged,
    this.label,
    this.formatValue,
    this.divisions,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final format = formatValue ?? (v) => v.toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label!,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              Text(
                '${format(values.start)} - ${format(values.end)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: isDark
                ? AppColors.darkCardHover
                : Colors.grey[300],
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primaryOpacity20,
            rangeThumbShape: const RoundRangeSliderThumbShape(
              enabledThumbRadius: 10,
            ),
            rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
          ),
          child: RangeSlider(
            values: values,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              format(min),
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.lightTextTertiary,
              ),
            ),
            Text(
              format(max),
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.lightTextTertiary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Switch estilizado.
class StyledSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? label;
  final String? subtitle;
  final IconData? icon;

  const StyledSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.subtitle,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: AppRadius.borderRadiusMd,
          border: Border.all(
            color: value
                ? AppColors.primary
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (value ? AppColors.primary : Colors.grey).withOpacity(0.1),
                  borderRadius: AppRadius.borderRadiusSm,
                ),
                child: Icon(
                  icon,
                  color: value ? AppColors.primary : Colors.grey,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (label != null)
                    Text(
                      label!,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Checkbox estilizado.
class StyledCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  final String label;
  final String? subtitle;

  const StyledCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
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

/// Radio buttons estilizados.
class StyledRadioGroup<T> extends StatelessWidget {
  final T? value;
  final List<RadioOption<T>> options;
  final ValueChanged<T?> onChanged;
  final String? label;
  final Axis direction;

  const StyledRadioGroup({
    super.key,
    this.value,
    required this.options,
    required this.onChanged,
    this.label,
    this.direction = Axis.vertical,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 12),
        ],
        direction == Axis.vertical
            ? Column(
                children: options.map((option) => _buildOption(context, option)).toList(),
              )
            : Wrap(
                spacing: 12,
                runSpacing: 12,
                children: options.map((option) => _buildOption(context, option)).toList(),
              ),
      ],
    );
  }

  Widget _buildOption(BuildContext context, RadioOption<T> option) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = value == option.value;

    return GestureDetector(
      onTap: () => onChanged(option.value),
      child: Container(
        margin: direction == Axis.vertical
            ? const EdgeInsets.only(bottom: 8)
            : EdgeInsets.zero,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryOpacity10
              : (isDark ? AppColors.darkCard : Colors.white),
          borderRadius: AppRadius.borderRadiusMd,
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: Row(
          mainAxisSize: direction == Axis.vertical ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark
                          ? AppColors.darkTextTertiary
                          : Colors.grey[400]!),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            if (option.icon != null) ...[
              Icon(option.icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
            ],
            Text(
              option.label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RadioOption<T> {
  final T value;
  final String label;
  final IconData? icon;

  const RadioOption({
    required this.value,
    required this.label,
    this.icon,
  });
}

/// Chips de seleção múltipla.
class ChipSelect extends StatelessWidget {
  final List<String> options;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;
  final bool multiSelect;

  const ChipSelect({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.multiSelect = true,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selected.contains(option);
        return FilterChip(
          label: Text(option),
          selected: isSelected,
          onSelected: (value) {
            if (multiSelect) {
              if (value) {
                onChanged([...selected, option]);
              } else {
                onChanged(selected.where((s) => s != option).toList());
              }
            } else {
              onChanged(value ? [option] : []);
            }
          },
          selectedColor: AppColors.primaryOpacity20,
          checkmarkColor: AppColors.primary,
          labelStyle: TextStyle(
            color: isSelected ? AppColors.primary : null,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.borderRadiusFull,
            side: BorderSide(
              color: isSelected ? AppColors.primary : Colors.grey[300]!,
            ),
          ),
        );
      }).toList(),
    );
  }
}
