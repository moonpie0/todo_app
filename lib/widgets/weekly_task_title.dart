import 'package:flutter/material.dart';
import '../models/todo_item.dart';

class WeeklyTaskTile extends StatelessWidget {
  final TodoItem task;
  final VoidCallback onDelete;
  final VoidCallback onViewCalendar;
  final VoidCallback onEdit;

  const WeeklyTaskTile({
    Key? key,
    required this.task,
    required this.onDelete,
    required this.onViewCalendar,
    required this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.repeat, color: colorScheme.onPrimaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '每周 ${task.weekday}',
                    style: TextStyle(color: colorScheme.outline, fontSize: 12),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: colorScheme.primary),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: Icon(Icons.calendar_today, color: colorScheme.primary),
                  onPressed: onViewCalendar,
                  tooltip: '在日历中查看',
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: colorScheme.error),
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}