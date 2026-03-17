import 'package:flutter/material.dart';
import '../models/todo_item.dart';
import '../main.dart';

// 星期映射函数
String _getChineseWeekday(String? englishWeekday) {
  if (englishWeekday == null) return '';
  const map = {
    'Monday': '周一',
    'Tuesday': '周二',
    'Wednesday': '周三',
    'Thursday': '周四',
    'Friday': '周五',
    'Saturday': '周六',
    'Sunday': '周日',
  };
  return map[englishWeekday] ?? englishWeekday;
}

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
        subtitle: Text('每${_getChineseWeekday(task.weekday)}'), // 修改这里
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