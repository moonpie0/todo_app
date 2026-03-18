import 'package:flutter/material.dart';
import '../models/todo_item.dart';
import '../main.dart';

class WeeklyTaskTile extends StatelessWidget {
  final TodoItem task;
  final bool isSelecting;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const WeeklyTaskTile({
    Key? key,
    required this.task,
    required this.isSelecting,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: isSelected
            ? BorderSide(color: morandiPurple, width: 2)
            : BorderSide.none,
      ),
      child: ListTile(
        leading: Icon(Icons.repeat, color: morandiPurple),
        title: Text(task.title),
        subtitle: (task.note != null && task.note!.isNotEmpty)
            ? Text(
          task.note!,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        )
            : null,
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}