import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';

/// Widget de calendário de disponibilidade.
class AvailabilityCalendar extends StatefulWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final List<DateTime> blockedDates;
  final List<DateTime> bookedDates;
  final ValueChanged<DateTimeRange?>? onDateRangeSelected;
  final bool isReadOnly;

  const AvailabilityCalendar({
    super.key,
    this.startDate,
    this.endDate,
    this.blockedDates = const [],
    this.bookedDates = const [],
    this.onDateRangeSelected,
    this.isReadOnly = false,
  });

  @override
  State<AvailabilityCalendar> createState() => _AvailabilityCalendarState();
}

class _AvailabilityCalendarState extends State<AvailabilityCalendar> {
  late DateTime _currentMonth;
  DateTime? _selectedStart;
  DateTime? _selectedEnd;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
    _selectedStart = widget.startDate;
    _selectedEnd = widget.endDate;
  }

  bool _isBlocked(DateTime date) {
    return widget.blockedDates.any((d) =>
        d.year == date.year && d.month == date.month && d.day == date.day);
  }

  bool _isBooked(DateTime date) {
    return widget.bookedDates.any((d) =>
        d.year == date.year && d.month == date.month && d.day == date.day);
  }

  bool _isSelected(DateTime date) {
    if (_selectedStart == null) return false;
    if (_selectedEnd == null) {
      return _isSameDay(date, _selectedStart!);
    }
    return (date.isAfter(_selectedStart!) || _isSameDay(date, _selectedStart!)) &&
        (date.isBefore(_selectedEnd!) || _isSameDay(date, _selectedEnd!));
  }

  bool _isStart(DateTime date) {
    return _selectedStart != null && _isSameDay(date, _selectedStart!);
  }

  bool _isEnd(DateTime date) {
    return _selectedEnd != null && _isSameDay(date, _selectedEnd!);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isPast(DateTime date) {
    final today = DateTime.now();
    return date.isBefore(DateTime(today.year, today.month, today.day));
  }

  void _onDayTap(DateTime date) {
    if (widget.isReadOnly) return;
    if (_isBlocked(date) || _isBooked(date) || _isPast(date)) return;

    setState(() {
      if (_selectedStart == null || (_selectedStart != null && _selectedEnd != null)) {
        _selectedStart = date;
        _selectedEnd = null;
      } else {
        if (date.isBefore(_selectedStart!)) {
          _selectedEnd = _selectedStart;
          _selectedStart = date;
        } else {
          _selectedEnd = date;
        }
        
        // Verificar se há datas bloqueadas no range
        bool hasBlockedInRange = false;
        for (var d = _selectedStart!; 
             d.isBefore(_selectedEnd!) || _isSameDay(d, _selectedEnd!); 
             d = d.add(const Duration(days: 1))) {
          if (_isBlocked(d) || _isBooked(d)) {
            hasBlockedInRange = true;
            break;
          }
        }

        if (hasBlockedInRange) {
          _selectedStart = date;
          _selectedEnd = null;
        } else {
          widget.onDateRangeSelected?.call(
            DateTimeRange(start: _selectedStart!, end: _selectedEnd!),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: AppRadius.borderRadiusLg,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(isDark),
          const Divider(height: 1),
          // Weekday labels
          _buildWeekdayLabels(isDark),
          // Calendar grid
          _buildCalendarGrid(isDark),
          // Legend
          _buildLegend(isDark),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    final months = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: () {
              setState(() {
                _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
              });
            },
          ),
          Text(
            '${months[_currentMonth.month - 1]} ${_currentMonth.year}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: () {
              setState(() {
                _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayLabels(bool isDark) {
    const weekdays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: weekdays
            .map((day) => Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildCalendarGrid(bool isDark) {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final startWeekday = (firstDay.weekday - 1) % 7;

    final days = <Widget>[];

    // Empty cells before first day
    for (var i = 0; i < startWeekday; i++) {
      days.add(const SizedBox());
    }

    // Days of month
    for (var day = 1; day <= lastDay.day; day++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
      days.add(_buildDayCell(date, isDark));
    }

    return Padding(
      padding: const EdgeInsets.all(8),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 7,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        children: days,
      ),
    );
  }

  Widget _buildDayCell(DateTime date, bool isDark) {
    final isBlocked = _isBlocked(date);
    final isBooked = _isBooked(date);
    final isPast = _isPast(date);
    final isSelected = _isSelected(date);
    final isStart = _isStart(date);
    final isEnd = _isEnd(date);
    final isToday = _isSameDay(date, DateTime.now());

    Color bgColor;
    Color textColor;
    BoxDecoration? decoration;

    if (isBlocked) {
      bgColor = AppColors.errorOpacity15;
      textColor = AppColors.error;
    } else if (isBooked) {
      bgColor = AppColors.warningOpacity15;
      textColor = AppColors.warning;
    } else if (isSelected) {
      if (isStart || isEnd) {
        bgColor = AppColors.primary;
        textColor = Colors.white;
      } else {
        bgColor = AppColors.primaryOpacity20;
        textColor = AppColors.primary;
      }
    } else if (isPast) {
      bgColor = Colors.transparent;
      textColor = isDark
          ? AppColors.darkTextTertiary
          : AppColors.lightTextTertiary;
    } else {
      bgColor = Colors.transparent;
      textColor = isDark
          ? AppColors.darkTextPrimary
          : AppColors.lightTextPrimary;
    }

    if (isStart && isEnd) {
      decoration = BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.borderRadiusSm,
      );
    } else if (isStart) {
      decoration = BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
      );
    } else if (isEnd) {
      decoration = BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
      );
    } else if (isSelected) {
      decoration = BoxDecoration(color: bgColor);
    } else {
      decoration = BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.borderRadiusSm,
      );
    }

    return GestureDetector(
      onTap: () => _onDayTap(date),
      child: Container(
        decoration: decoration,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '${date.day}',
              style: TextStyle(
                color: textColor,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isToday)
              Positioned(
                bottom: 4,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        children: [
          _buildLegendItem('Disponível', AppColors.success, isDark),
          _buildLegendItem('Reservado', AppColors.warning, isDark),
          _buildLegendItem('Bloqueado', AppColors.error, isDark),
          _buildLegendItem('Selecionado', AppColors.primary, isDark),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: color),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }
}

/// Widget compacto mostrando disponibilidade rápida.
class AvailabilityIndicator extends StatelessWidget {
  final int availableDays;
  final int totalDays;
  final bool showLabel;

  const AvailabilityIndicator({
    super.key,
    required this.availableDays,
    required this.totalDays,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = totalDays > 0 ? availableDays / totalDays : 0.0;
    final color = percentage > 0.7
        ? AppColors.success
        : percentage > 0.3
            ? AppColors.warning
            : AppColors.error;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 60,
          height: 6,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: AppRadius.borderRadiusFull,
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: AppRadius.borderRadiusFull,
              ),
            ),
          ),
        ),
        if (showLabel) ...[
          const SizedBox(width: 8),
          Text(
            '$availableDays dias',
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
