import 'package:flutter/material.dart';
import '../models/todo_item.dart';
import '../main.dart';

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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Icon(Icons.repeat, color: morandiPurple),
        title: Text(task.title),
        subtitle: Text('每周 ${task.weekday}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: onEdit,
              color: morandiBlue,
            ),
            IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: onViewCalendar,
              tooltip: '在日历中查看',
              color: morandiPurple,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: onDelete,
              color: morandiRed,
            ),
          ],
        ),
      ),
    );
  }
}