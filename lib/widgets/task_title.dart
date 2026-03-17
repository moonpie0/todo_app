import 'package:flutter/material.dart';
import '../models/todo_item.dart';
import '../models/task_set.dart';
import 'package:intl/intl.dart';
import '../main.dart';

class TaskTile extends StatelessWidget {
  final TodoItem task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final ValueChanged<int> onProgressChanged;
  final VoidCallback onEdit;
  final TaskSet? taskSet;

  const TaskTile({
    Key? key,
    required this.task,
    required this.onToggle,
    required this.onDelete,
    required this.onProgressChanged,
    required this.onEdit,
    this.taskSet,
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
                  if (taskSet != null)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: morandiBlue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        taskSet!.name,
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
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
                  // 备注显示
                  if (task.note != null && task.note!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${task.note}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
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