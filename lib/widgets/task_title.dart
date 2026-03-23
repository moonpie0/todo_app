import 'package:flutter/material.dart';
import '../models/todo_item.dart';
import '../models/task_set.dart';
import 'package:intl/intl.dart';
import '../main.dart';

class TaskTile extends StatelessWidget {
  final TodoItem task;
  final bool isSelecting;
  final bool isSelected;
  final VoidCallback onTap;
  //final VoidCallback onLongPress;
  final VoidCallback onToggle;
  final Function(SubTask) onSubTaskToggle;
  final VoidCallback onDelete;
  final ValueChanged<int> onProgressChanged;
  final TaskSet? taskSet;

  const TaskTile({
    Key? key,
    required this.task,
    required this.isSelecting,
    required this.isSelected,
    required this.onTap,
    //required this.onLongPress,
    required this.onToggle,
    required this.onSubTaskToggle,
    required this.onDelete,
    required this.onProgressChanged,
    this.taskSet,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isProgress = task.target != null && task.target! > 0;
    final isWeekly = task.weekday != null;
    final hasDeadline = task.deadline != null;
    final hasSubtasks = task.subtasks.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      //onLongPress: onLongPress,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: isSelected
              ? BorderSide(color: morandiPurple, width: 2)
              : BorderSide.none,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 第一行：复选框 + 标题 + 任务集标签
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (isSelecting)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Checkbox(
                        value: isSelected,
                        onChanged: (_) => onTap(),
                        activeColor: morandiPurple,
                      ),
                    ),
                  if (!isProgress && !isWeekly && !hasSubtasks)
                    Checkbox(
                      value: task.isDone,
                      onChanged: (_) => onToggle(),
                      activeColor: morandiPurple,
                    ),
                  Expanded(
                    child: Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        decoration: !isProgress && !hasSubtasks && task.isDone
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                  if (taskSet != null)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
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
                ],
              ),
              // 第二行：每周/截止等额外信息
              if (isWeekly)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '每${_getChineseWeekday(task.weekday)}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              if (hasDeadline)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '截止: ${DateFormat('yyyy-MM-dd').format(task.deadline!)}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              // 子任务列表
              if (hasSubtasks) ...[
                const SizedBox(height: 8),
                ...task.subtasks.map((sub) => Padding(
                  padding: const EdgeInsets.only(left: 16.0, top: 4),
                  child: Row(
                    children: [
                      Checkbox(
                        value: sub.isDone,
                        onChanged: (_) => onSubTaskToggle(sub),
                        activeColor: morandiPurple,
                      ),
                      Expanded(
                        child: Text(
                          sub.title,
                          style: TextStyle(
                            decoration: sub.isDone ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
              // 进度条
              if (isProgress) ...[
                const SizedBox(height: 8),
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
              // 备注
              if (task.note != null && task.note!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    task.note!,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

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
}