import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../utils/app_theme.dart';

class MiniCalendar extends StatelessWidget {
  final List<DateTime> activeDates;

  const MiniCalendar({
    Key? key,
    required this.activeDates,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.card2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: DateTime.now(),
        calendarFormat: CalendarFormat.week,
        startingDayOfWeek: StartingDayOfWeek.monday,
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(color: AppTheme.text, fontWeight: FontWeight.bold),
          leftChevronIcon: Icon(Icons.chevron_left, color: AppTheme.text),
          rightChevronIcon: Icon(Icons.chevron_right, color: AppTheme.text),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(color: AppTheme.muted),
          weekendStyle: TextStyle(color: AppTheme.muted),
        ),
        calendarStyle: const CalendarStyle(
          defaultTextStyle: TextStyle(color: AppTheme.text),
          weekendTextStyle: TextStyle(color: AppTheme.text),
          todayDecoration: BoxDecoration(
            color: AppTheme.border,
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: AppTheme.blue,
            shape: BoxShape.circle,
          ),
        ),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, events) {
            bool isActive = activeDates.any((d) => 
              d.year == date.year && d.month == date.month && d.day == date.day
            );
            if (isActive) {
              return Positioned(
                bottom: 1,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppTheme.green,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }
            return null;
          },
        ),
      ),
    );
  }
}
