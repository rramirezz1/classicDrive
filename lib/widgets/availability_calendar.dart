import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';

/// Calendário moderno para selecionar datas de disponibilidade.
class AvailabilityCalendar extends StatefulWidget {
  final List<DateTime> blockedDates;
  final List<DateTime> bookedDates;
  final Function(DateTime)? onDateTapped;
  final Function(List<DateTime>)? onBlockedDatesChanged;
  final bool isEditable;

  const AvailabilityCalendar({
    super.key,
    this.blockedDates = const [],
    this.bookedDates = const [],
    this.onDateTapped,
    this.onBlockedDatesChanged,
    this.isEditable = false,
  });

  @override
  State<AvailabilityCalendar> createState() => _AvailabilityCalendarState();
}

class _AvailabilityCalendarState extends State<AvailabilityCalendar> {
  late DateTime _currentMonth;
  late List<DateTime> _blockedDates;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
    _blockedDates = List.from(widget.blockedDates);
  }

  @override
  void didUpdateWidget(AvailabilityCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.blockedDates != widget.blockedDates) {
      _blockedDates = List.from(widget.blockedDates);
    }
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  void _toggleDateBlock(DateTime date) {
    if (!widget.isEditable) return;
    if (_isBooked(date)) return;

    setState(() {
      if (_isBlocked(date)) {
        _blockedDates.removeWhere((d) => _isSameDay(d, date));
      } else {
        _blockedDates.add(date);
      }
    });

    widget.onBlockedDatesChanged?.call(_blockedDates);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isBlocked(DateTime date) {
    return _blockedDates.any((d) => _isSameDay(d, date));
  }

  bool _isBooked(DateTime date) {
    return widget.bookedDates.any((d) => _isSameDay(d, date));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        _buildHeader(isDark),
        const SizedBox(height: 12),
        _buildWeekDays(isDark),
        const SizedBox(height: 8),
        _buildDaysGrid(isDark),
        const SizedBox(height: 16),
        _buildLegend(isDark),
      ],
    );
  }

  Widget _buildHeader(bool isDark) {
    final monthNames = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: Icon(
            Icons.chevron_left_rounded,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
          onPressed: _previousMonth,
        ),
        Text(
          '${monthNames[_currentMonth.month - 1]} ${_currentMonth.year}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        IconButton(
          icon: Icon(
            Icons.chevron_right_rounded,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
          onPressed: _nextMonth,
        ),
      ],
    );
  }

  Widget _buildWeekDays(bool isDark) {
    final weekDays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekDays.map((day) {
        return Expanded(
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
        );
      }).toList(),
    );
  }

  Widget _buildDaysGrid(bool isDark) {
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    
    // Ajustar para começar na segunda-feira (1) em vez de domingo (7)
    int startingWeekday = firstDayOfMonth.weekday;
    
    final days = <Widget>[];

    // Espaços vazios antes do primeiro dia
    for (int i = 1; i < startingWeekday; i++) {
      days.add(const SizedBox());
    }

    // Dias do mês
    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
      days.add(_buildDayCell(date, isDark));
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 7,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      children: days,
    );
  }

  Widget _buildDayCell(DateTime date, bool isDark) {
    final isToday = _isSameDay(date, DateTime.now());
    final isPast = date.isBefore(DateTime.now().subtract(const Duration(days: 1)));
    final isBlocked = _isBlocked(date);
    final isBooked = _isBooked(date);

    Color backgroundColor;
    Color textColor;

    if (isBooked) {
      backgroundColor = AppColors.warning.withOpacity(0.15);
      textColor = AppColors.warning;
    } else if (isBlocked) {
      backgroundColor = AppColors.error.withOpacity(0.15);
      textColor = AppColors.error;
    } else if (isToday) {
      backgroundColor = AppColors.primary;
      textColor = Colors.white;
    } else if (isPast) {
      backgroundColor = Colors.transparent;
      textColor = isDark ? AppColors.darkTextTertiary : Colors.grey[400]!;
    } else {
      backgroundColor = isDark ? AppColors.darkCardHover : Colors.grey[100]!;
      textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    }

    return GestureDetector(
      onTap: () {
        if (!isPast) {
          _toggleDateBlock(date);
          widget.onDateTapped?.call(date);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: AppRadius.borderRadiusSm,
          border: isToday && !isBlocked && !isBooked
              ? null
              : Border.all(
                  color: isBlocked
                      ? AppColors.error.withOpacity(0.3)
                      : isBooked
                          ? AppColors.warning.withOpacity(0.3)
                          : Colors.transparent,
                  width: 1.5,
                ),
        ),
        child: Center(
          child: Text(
            date.day.toString(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegend(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(isDark, 'Disponível', Colors.grey[200]!),
        const SizedBox(width: 16),
        _buildLegendItem(isDark, 'Reservado', AppColors.warning.withOpacity(0.3)),
        const SizedBox(width: 16),
        _buildLegendItem(isDark, 'Bloqueado', AppColors.error.withOpacity(0.3)),
      ],
    );
  }

  Widget _buildLegendItem(bool isDark, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }
}
