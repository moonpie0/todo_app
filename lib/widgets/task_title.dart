import 'package:flutter/material.dart';
import '../models/todo_item.dart';
import 'package:intl/intl.dart';
import '../main.dart'; // 导入颜色

class TaskTile extends StatelessWidget {
  final TodoItem task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final ValueChanged<int> onProgressChanged;
  final VoidCallback onEdit;

  const TaskTile({
    Key? key,
    required this.task,
    required this.onToggle,
    required this.onDelete,
    required this.onProgressChanged,
    required this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isProgress = task.target != null && task.target! > 0;
    final isWeekly = task.weekday != null;
    final hasDeadline = task.deadline != null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            if (!isProgress && !isWeekly)
              Checkbox(
                value: task.isDone,
                onChanged: (_) => onToggle(),
                activeColor: morandiPurple,
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 16,
                      decoration: !isProgress && task.isDone
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  if (isWeekly)
                    Text(
                      '每周 ${task.weekday}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  if (hasDeadline)
                    Text(
                      '截止: ${DateFormat('yyyy-MM-dd').format(task.deadline!)}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  if (isProgress) ...[
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: task.current! / task.target!,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(morandiBlue),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('${task.current}/${task.target}'),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.remove, size: 18),
                          onPressed: () {
                            if (task.current! > 0) {
                              onProgressChanged(task.current! - 1);
                            }
                          },
                          color: morandiPurple,
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, size: 18),
                          onPressed: () {
                            if (task.current! < task.target!) {
                              onProgressChanged(task.current! + 1);
                            }
                          },
                          color: morandiPurple,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: onEdit,
              color: morandiBlue,
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