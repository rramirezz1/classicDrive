import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';

/// Widget de seleção de localização para filtros.
class LocationFilterWidget extends StatefulWidget {
  final String? selectedCity;
  final ValueChanged<String?> onCityChanged;
  final List<String> cities;

  const LocationFilterWidget({
    super.key,
    this.selectedCity,
    required this.onCityChanged,
    this.cities = const [
      'Lisboa',
      'Porto',
      'Braga',
      'Coimbra',
      'Faro',
      'Setúbal',
      'Aveiro',
      'Évora',
      'Viseu',
      'Leiria',
    ],
  });

  @override
  State<LocationFilterWidget> createState() => _LocationFilterWidgetState();
}

class _LocationFilterWidgetState extends State<LocationFilterWidget> {
  bool _isExpanded = false;
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredCities = [];

  @override
  void initState() {
    super.initState();
    _filteredCities = widget.cities;
  }

  void _filterCities(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCities = widget.cities;
      } else {
        _filteredCities = widget.cities
            .where((city) => city.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: AppRadius.borderRadiusMd,
              border: Border.all(
                color: widget.selectedCity != null
                    ? AppColors.primary
                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_on_rounded,
                  color: widget.selectedCity != null
                      ? AppColors.primary
                      : (isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.selectedCity ?? 'Todas as localizações',
                    style: TextStyle(
                      fontWeight: widget.selectedCity != null
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: widget.selectedCity != null
                          ? null
                          : (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary),
                    ),
                  ),
                ),
                if (widget.selectedCity != null)
                  GestureDetector(
                    onTap: () => widget.onCityChanged(null),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ),
                AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: _isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: AppRadius.borderRadiusMd,
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Column(
              children: [
                // Search field
                TextField(
                  controller: _searchController,
                  onChanged: _filterCities,
                  decoration: InputDecoration(
                    hintText: 'Pesquisar cidade...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.borderRadiusSm,
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor:
                        isDark ? AppColors.darkCardHover : Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                
                // Cities list
                SizedBox(
                  height: 150,
                  child: ListView.builder(
                    itemCount: _filteredCities.length,
                    itemBuilder: (context, index) {
                      final city = _filteredCities[index];
                      final isSelected = city == widget.selectedCity;
                      
                      return InkWell(
                        onTap: () {
                          widget.onCityChanged(city);
                          setState(() => _isExpanded = false);
                        },
                        borderRadius: AppRadius.borderRadiusSm,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withOpacity(0.1)
                                : null,
                            borderRadius: AppRadius.borderRadiusSm,
                          ),
                          child: Row(
                            children: [
                              Text(
                                city,
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: isSelected ? AppColors.primary : null,
                                ),
                              ),
                              const Spacer(),
                              if (isSelected)
                                Icon(
                                  Icons.check_rounded,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

/// Widget de rating com estrelas interativas.
class RatingWidget extends StatelessWidget {
  final double rating;
  final int maxRating;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  final ValueChanged<double>? onRatingChanged;
  final bool showValue;

  const RatingWidget({
    super.key,
    required this.rating,
    this.maxRating = 5,
    this.size = 20,
    this.activeColor,
    this.inactiveColor,
    this.onRatingChanged,
    this.showValue = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(maxRating, (index) {
          final starRating = index + 1;
          double fillAmount;

          if (rating >= starRating) {
            fillAmount = 1.0;
          } else if (rating > starRating - 1) {
            fillAmount = rating - (starRating - 1);
          } else {
            fillAmount = 0.0;
          }

          return GestureDetector(
            onTap: onRatingChanged != null
                ? () => onRatingChanged!(starRating.toDouble())
                : null,
            child: Padding(
              padding: const EdgeInsets.only(right: 2),
              child: Stack(
                children: [
                  Icon(
                    Icons.star_rounded,
                    size: size,
                    color: inactiveColor ??
                        (isDark ? Colors.grey[700] : Colors.grey[300]),
                  ),
                  ClipRect(
                    clipper: _StarClipper(fillAmount),
                    child: Icon(
                      Icons.star_rounded,
                      size: size,
                      color: activeColor ?? AppColors.accent,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        if (showValue) ...[
          const SizedBox(width: 6),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: size * 0.7,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

class _StarClipper extends CustomClipper<Rect> {
  final double fillAmount;

  _StarClipper(this.fillAmount);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width * fillAmount, size.height);
  }

  @override
  bool shouldReclip(_StarClipper oldClipper) => fillAmount != oldClipper.fillAmount;
}

/// Widget de filtros rápidos em chips.
class QuickFiltersWidget extends StatelessWidget {
  final List<QuickFilter> filters;
  final List<String> selectedFilters;
  final ValueChanged<String> onFilterToggle;

  const QuickFiltersWidget({
    super.key,
    required this.filters,
    required this.selectedFilters,
    required this.onFilterToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = selectedFilters.contains(filter.id);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: FilterChip(
                selected: isSelected,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      filter.icon,
                      size: 16,
                      color: isSelected
                          ? Colors.white
                          : (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary),
                    ),
                    const SizedBox(width: 6),
                    Text(filter.label),
                  ],
                ),
                onSelected: (_) => onFilterToggle(filter.id),
                selectedColor: AppColors.primary,
                backgroundColor: isDark ? AppColors.darkCard : Colors.white,
                labelStyle: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : (isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                side: BorderSide(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.borderRadiusFull,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class QuickFilter {
  final String id;
  final String label;
  final IconData icon;

  const QuickFilter({
    required this.id,
    required this.label,
    required this.icon,
  });
}
