import '../common/app_icon.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../typography/app_text.dart';
import '../../config/constants/app_colors.dart';

/// A simple date picker dialog using App design system
class AppDatePickerDialog {
  /// Shows a simple date picker dialog
  static Future<DateTime?> showDatePicker({
    required BuildContext context,
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
    String? title,
    String? helpText,
  }) async {
    final initial = initialDate ?? DateTime.now();
    final first = firstDate ?? DateTime(2020);
    final last = lastDate ?? DateTime(2030);

    return await showDialog<DateTime>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return _SimpleDatePickerDialog(
          initialDate: initial,
          firstDate: first,
          lastDate: last,
          title: title ?? 'Select Date',
        );
      },
    );
  }

  /// Shows a date range picker dialog
  static Future<Map<String, DateTime?>?> showDateRangePicker({
    required BuildContext context,
    DateTime? initialStartDate,
    DateTime? initialEndDate,
    DateTime? firstDate,
    DateTime? lastDate,
    String? title,
  }) async {
    final first = firstDate ?? DateTime(2020);
    final last = lastDate ?? DateTime(2030);

    return await showDialog<Map<String, DateTime?>>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return _DateRangePickerDialog(
          initialStartDate: initialStartDate,
          initialEndDate: initialEndDate,
          firstDate: first,
          lastDate: last,
          title: title ?? 'Select Date Range',
        );
      },
    );
  }
}

/// Simple single date picker dialog
class _SimpleDatePickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final String title;

  const _SimpleDatePickerDialog({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.title,
  });

  @override
  State<_SimpleDatePickerDialog> createState() =>
      _SimpleDatePickerDialogState();
}

class _SimpleDatePickerDialogState extends State<_SimpleDatePickerDialog> {
  late DateTime _selectedDate;
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _currentMonth = DateTime(widget.initialDate.year, widget.initialDate.month);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 340,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            AppText(
              widget.title,
              variant: AppTextVariant.heading3,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            const SizedBox(height: 20),

            // Month navigation
            _buildMonthNavigation(),
            const SizedBox(height: 16),

            // Weekday headers
            _buildWeekdayHeaders(),
            const SizedBox(height: 8),

            // Calendar grid
            _buildCalendarGrid(),
            const SizedBox(height: 16),

            // Selected date display
            _buildSelectedDateDisplay(),
            const SizedBox(height: 20),

            // Action buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthNavigation() {
    final monthYear = DateFormat('MMMM yyyy').format(_currentMonth);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: AppIcon(icon: Icons.chevron_left),
          onPressed: () {
            setState(() {
              _currentMonth = DateTime(
                _currentMonth.year,
                _currentMonth.month - 1,
              );
            });
          },
          color: AppColors.primary,
        ),
        AppText(
          monthYear,
          variant: AppTextVariant.bodyLarge,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        IconButton(
          icon: AppIcon(icon: Icons.chevron_right),
          onPressed: () {
            setState(() {
              _currentMonth = DateTime(
                _currentMonth.year,
                _currentMonth.month + 1,
              );
            });
          },
          color: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildWeekdayHeaders() {
    const weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return Row(
      children: weekdays.map((day) {
        return Expanded(
          child: Center(
            child: AppText(
              day,
              variant: AppTextVariant.labelSmall,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCalendarGrid() {
    final days = _generateDaysInMonth();

    return SizedBox(
      height: 240,
      child: GridView.count(
        crossAxisCount: 7,
        physics: const NeverScrollableScrollPhysics(),
        children: days.map((day) {
          if (day == null) {
            return const SizedBox();
          }

          final isSelected = _isSameDay(day, _selectedDate);
          final isToday = _isSameDay(day, DateTime.now());
          final isCurrentMonth = day.month == _currentMonth.month;
          final isSelectable =
              isCurrentMonth &&
              day.isAfter(widget.firstDate.subtract(const Duration(days: 1))) &&
              day.isBefore(widget.lastDate.add(const Duration(days: 1)));

          return GestureDetector(
            onTap: isSelectable
                ? () {
                    setState(() {
                      _selectedDate = day;
                    });
                  }
                : null,
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : isToday && isCurrentMonth
                    ? AppColors.primary.withOpacity(0.1)
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: isToday && !isSelected && isCurrentMonth
                    ? Border.all(color: AppColors.primary, width: 1)
                    : null,
              ),
              child: Center(
                child: AppText(
                  '${day.day}',
                  variant: AppTextVariant.bodySmall,
                  fontWeight: isSelected || isToday
                      ? FontWeight.w600
                      : FontWeight.normal,
                  color: isSelected
                      ? Colors.white
                      : !isCurrentMonth
                      ? Colors.grey[300]
                      : !isSelectable
                      ? Colors.grey[400]
                      : AppColors.textPrimary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSelectedDateDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppIcon(
            icon: Icons.calendar_today,
            size: 18,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          AppText(
            DateFormat('EEE, MMM d, yyyy').format(_selectedDate),
            variant: AppTextVariant.bodySmall,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: AppText(
              'Cancel',
              variant: AppTextVariant.button,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(_selectedDate),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: AppText(
              'Select',
              variant: AppTextVariant.button,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  List<DateTime?> _generateDaysInMonth() {
    final firstDayOfMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month,
      1,
    );
    final lastDayOfMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      0,
    );

    // Get weekday of first day (Sunday = 0)
    final firstWeekday = firstDayOfMonth.weekday % 7;

    final List<DateTime?> days = [];

    // Add empty slots for days before the first day of the month
    for (int i = 0; i < firstWeekday; i++) {
      final prevDay = firstDayOfMonth.subtract(
        Duration(days: firstWeekday - i),
      );
      days.add(prevDay);
    }

    // Add all days of the current month
    for (int i = 1; i <= lastDayOfMonth.day; i++) {
      days.add(DateTime(_currentMonth.year, _currentMonth.month, i));
    }

    // Add days from next month to complete the grid (6 rows)
    final remainingDays = 42 - days.length;
    for (int i = 1; i <= remainingDays; i++) {
      days.add(DateTime(_currentMonth.year, _currentMonth.month + 1, i));
    }

    return days;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

/// Date range picker dialog
class _DateRangePickerDialog extends StatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final String title;

  const _DateRangePickerDialog({
    this.initialStartDate,
    this.initialEndDate,
    required this.firstDate,
    required this.lastDate,
    required this.title,
  });

  @override
  State<_DateRangePickerDialog> createState() => _DateRangePickerDialogState();
}

class _DateRangePickerDialogState extends State<_DateRangePickerDialog> {
  DateTime? _startDate;
  DateTime? _endDate;
  late DateTime _currentMonth;
  bool _isSelectingEnd = false;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
    _currentMonth = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 340,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            AppText(
              widget.title,
              variant: AppTextVariant.heading3,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            const SizedBox(height: 16),

            // Selection mode indicator
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isSelectingEnd = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: !_isSelectingEnd
                            ? AppColors.primary.withOpacity(0.1)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: !_isSelectingEnd
                              ? AppColors.primary
                              : Colors.grey[300]!,
                        ),
                      ),
                      child: Column(
                        children: [
                          AppText(
                            'Start',
                            variant: AppTextVariant.labelSmall,
                            color: !_isSelectingEnd
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(height: 4),
                          AppText(
                            _startDate != null
                                ? DateFormat('MMM d').format(_startDate!)
                                : 'Select',
                            variant: AppTextVariant.bodySmall,
                            fontWeight: FontWeight.w600,
                            color: !_isSelectingEnd
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isSelectingEnd = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _isSelectingEnd
                            ? AppColors.primary.withOpacity(0.1)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _isSelectingEnd
                              ? AppColors.primary
                              : Colors.grey[300]!,
                        ),
                      ),
                      child: Column(
                        children: [
                          AppText(
                            'End',
                            variant: AppTextVariant.labelSmall,
                            color: _isSelectingEnd
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(height: 4),
                          AppText(
                            _endDate != null
                                ? DateFormat('MMM d').format(_endDate!)
                                : 'Select',
                            variant: AppTextVariant.bodySmall,
                            fontWeight: FontWeight.w600,
                            color: _isSelectingEnd
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Month navigation
            _buildMonthNavigation(),
            const SizedBox(height: 12),

            // Weekday headers
            _buildWeekdayHeaders(),
            const SizedBox(height: 8),

            // Calendar grid
            _buildCalendarGrid(),
            const SizedBox(height: 20),

            // Action buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthNavigation() {
    final monthYear = DateFormat('MMMM yyyy').format(_currentMonth);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: AppIcon(icon: Icons.chevron_left),
          onPressed: () {
            setState(() {
              _currentMonth = DateTime(
                _currentMonth.year,
                _currentMonth.month - 1,
              );
            });
          },
          color: AppColors.primary,
        ),
        AppText(
          monthYear,
          variant: AppTextVariant.bodyLarge,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        IconButton(
          icon: AppIcon(icon: Icons.chevron_right),
          onPressed: () {
            setState(() {
              _currentMonth = DateTime(
                _currentMonth.year,
                _currentMonth.month + 1,
              );
            });
          },
          color: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildWeekdayHeaders() {
    const weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return Row(
      children: weekdays.map((day) {
        return Expanded(
          child: Center(
            child: AppText(
              day,
              variant: AppTextVariant.labelSmall,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCalendarGrid() {
    final days = _generateDaysInMonth();

    return SizedBox(
      height: 240,
      child: GridView.count(
        crossAxisCount: 7,
        physics: const NeverScrollableScrollPhysics(),
        children: days.map((day) {
          if (day == null) {
            return const SizedBox();
          }

          final isCurrentMonth = day.month == _currentMonth.month;
          final isStartDate =
              _startDate != null && _isSameDay(day, _startDate!);
          final isEndDate = _endDate != null && _isSameDay(day, _endDate!);
          final isInRange =
              _startDate != null &&
              _endDate != null &&
              day.isAfter(_startDate!) &&
              day.isBefore(_endDate!);
          final isToday = _isSameDay(day, DateTime.now());

          return GestureDetector(
            onTap: isCurrentMonth
                ? () {
                    setState(() {
                      if (_isSelectingEnd) {
                        if (_startDate != null && day.isAfter(_startDate!)) {
                          _endDate = day;
                        }
                      } else {
                        _startDate = day;
                        if (_endDate != null && day.isAfter(_endDate!)) {
                          _endDate = null;
                        }
                        _isSelectingEnd = true;
                      }
                    });
                  }
                : null,
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isStartDate || isEndDate
                    ? AppColors.primary
                    : isInRange
                    ? AppColors.primary.withOpacity(0.2)
                    : isToday && isCurrentMonth
                    ? AppColors.primary.withOpacity(0.1)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: AppText(
                  '${day.day}',
                  variant: AppTextVariant.bodySmall,
                  fontWeight: isStartDate || isEndDate || isToday
                      ? FontWeight.w600
                      : FontWeight.normal,
                  color: isStartDate || isEndDate
                      ? Colors.white
                      : !isCurrentMonth
                      ? Colors.grey[300]
                      : AppColors.textPrimary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: AppText(
              'Cancel',
              variant: AppTextVariant.button,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextButton(
            onPressed: () {
              Navigator.of(context).pop({'startDate': null, 'endDate': null});
            },
            child: AppText('Clear', variant: AppTextVariant.button),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(
                context,
              ).pop({'startDate': _startDate, 'endDate': _endDate});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const AppText(
              'Apply',
              variant: AppTextVariant.button,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  List<DateTime?> _generateDaysInMonth() {
    final firstDayOfMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month,
      1,
    );
    final lastDayOfMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      0,
    );

    // Get weekday of first day (Sunday = 0)
    final firstWeekday = firstDayOfMonth.weekday % 7;

    final List<DateTime?> days = [];

    // Add days from previous month
    for (int i = 0; i < firstWeekday; i++) {
      final prevDay = firstDayOfMonth.subtract(
        Duration(days: firstWeekday - i),
      );
      days.add(prevDay);
    }

    // Add all days of the current month
    for (int i = 1; i <= lastDayOfMonth.day; i++) {
      days.add(DateTime(_currentMonth.year, _currentMonth.month, i));
    }

    // Add days from next month to complete the grid
    final remainingDays = 42 - days.length;
    for (int i = 1; i <= remainingDays; i++) {
      days.add(DateTime(_currentMonth.year, _currentMonth.month + 1, i));
    }

    return days;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
