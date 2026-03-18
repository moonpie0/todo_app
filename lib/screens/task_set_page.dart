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
  // 判断一个待办是否未完成（即“待办”数中的一项）
  bool _isPending(TodoItem task) {
    if (task.target != null && task.target! > 0) {
      // 进度任务：当前 < 目标 则为未完成
      return task.current! < task.target!;
    } else if (task.subtasks.isNotEmpty) {
      // 有子任务：任一子任务未完成则为未完成
      return task.subtasks.any((s) => !s.isDone);
    } else {
      // 普通任务：isDone == false
      return !task.isDone;
    }
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

        final totalCount = tasksInSet.length;
        final pendingCount = tasksInSet.where((task) => _isPending(task)).length;

        return ExpansionTile(
          leading: Icon(Icons.folder, color: morandiPurple),
          title: Text(taskSet.name),
          subtitle: Text('$pendingCount个待办，共$totalCount个事项'),
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