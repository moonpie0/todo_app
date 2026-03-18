import 'package:flutter/material.dart';
import '../models/task_set.dart';
import '../models/todo_item.dart';
import '../main.dart';
import '../widgets/task_title.dart';

class TaskSetPage extends StatefulWidget {
  final List<TaskSet> taskSets;
  final List<TodoItem> allTasks;
  final Function(TodoItem) onTaskToggle;
  final Function(TodoItem) onTaskDelete;
  final Function(TodoItem, int) onProgressChanged;
  final Function(BuildContext, TodoItem) onTaskEdit;
  final Function(TodoItem, SubTask) onSubTaskToggle;

  const TaskSetPage({
    Key? key,
    required this.taskSets,
    required this.allTasks,
    required this.onTaskToggle,
    required this.onTaskDelete,
    required this.onProgressChanged,
    required this.onTaskEdit,
    required this.onSubTaskToggle,
  }) : super(key: key);

  @override
  _TaskSetPageState createState() => _TaskSetPageState();
}

class _TaskSetPageState extends State<TaskSetPage> {
  // 计算待办集的副标题：显示待办数量和事项总数
  String _getTaskSetSubtitle(List<TodoItem> tasks) {
    int taskCount = tasks.length;
    int itemCount = 0;
    for (var task in tasks) {
      if (task.subtasks.isEmpty) {
        // 没有子任务时，任务本身算一个事项
        itemCount += 1;
      } else {
        // 有子任务时，只计算子任务作为事项
        itemCount += task.subtasks.length;
      }
    }
    return '$taskCount个待办，共$itemCount个事项';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.taskSets.isEmpty) {
      return const Center(child: Text('暂无待办集，点击右上角添加'));
    }

    return ListView.builder(
      itemCount: widget.taskSets.length,
      itemBuilder: (ctx, index) {
        final taskSet = widget.taskSets[index];
        final tasksInSet = widget.allTasks
            .where((task) => task.setId == taskSet.id)
            .toList();

        return ExpansionTile(
          leading: Icon(Icons.folder, color: morandiPurple),
          title: Text(taskSet.name),
          subtitle: Text(_getTaskSetSubtitle(tasksInSet)),
          children: tasksInSet.isEmpty
              ? [const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('该待办集暂无待办'),
          )]
              : tasksInSet.map((task) {
            return TaskTile(
              task: task,
              isSelecting: false,
              isSelected: false,
              onTap: () => widget.onTaskEdit(context, task),
              onLongPress: () {},
              onToggle: () => widget.onTaskToggle(task),
              onSubTaskToggle: (subTask) => widget.onSubTaskToggle(task, subTask),
              onDelete: () => widget.onTaskDelete(task),
              onProgressChanged: (newCurrent) {
                widget.onProgressChanged(task, newCurrent);
              },
              taskSet: taskSet,
            );
          }).toList(),
        );
      },
    );
  }
}