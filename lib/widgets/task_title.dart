import 'package:flutter/material.dart';
import '../models/todo_item.dart';
import 'package:intl/intl.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    final isProgress = task.target != null && task.target! > 0;
    final isWeekly = task.weekday != null;
    final hasDeadline = task.deadline != null;
    final isDone = task.isDone;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: isProgress ? null : onToggle,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              if (!isProgress && !isWeekly)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: Icon(
                    isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: isDone ? colorScheme.primary : colorScheme.outline,
                    size: 28,
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        decoration: !isProgress && isDone
                            ? TextDecoration.lineThrough
                            : null,
                        color: isDone ? colorScheme.outline : colorScheme.onSurface,
                      ),
                    ),
                    if (isWeekly)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '每周 ${task.weekday}',
                            style: TextStyle(
                              color: colorScheme.onSecondaryContainer,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    if (hasDeadline)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(Icons.event, size: 14, color: colorScheme.outline),
                            const SizedBox(width: 4),
                            Text(
                              '截止: ${DateFormat('yyyy-MM-dd').format(task.deadline!)}',
                              style: TextStyle(color: colorScheme.outline, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    if (isProgress) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: task.current! / task.target!,
                          backgroundColor: colorScheme.surfaceVariant,
                          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '${task.current}/${task.target}',
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          _buildSmallIconButton(
                            icon: Icons.remove,
                            onPressed: task.current! > 0
                                ? () => onProgressChanged(task.current! - 1)
                                : null,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          _buildSmallIconButton(
                            icon: Icons.add,
                            onPressed: task.current! < task.target!
                                ? () => onProgressChanged(task.current! + 1)
                                : null,
                            color: colorScheme.primary,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: colorScheme.outline),
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit();
                  } else if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [Icon(Icons.edit), SizedBox(width: 8), Text('编辑')],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [Icon(Icons.delete, color: Colors.red), SizedBox(width: 8), Text('删除')],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmallIconButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 18, color: onPressed != null ? color : Colors.grey),
        ),
      ),
    );
  }
}