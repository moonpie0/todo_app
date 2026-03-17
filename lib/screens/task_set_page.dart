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

  const TaskSetPage({
    Key? key,
    required this.taskSets,
    required this.allTasks,
    required this.onTaskToggle,
    required this.onTaskDelete,
    required this.onProgressChanged,
    required this.onTaskEdit,
  }) : super(key: key);

  @override
  _TaskSetPageState createState() => _TaskSetPageState();
}

class _TaskSetPageState extends State<TaskSetPage> {
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
          subtitle: Text('${tasksInSet.length}个待办'),
          children: tasksInSet.isEmpty
              ? [const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('该待办集暂无待办'),
          )]
              : tasksInSet.map((task) {
            return TaskTile(
              task: task,
              onToggle: () => widget.onTaskToggle(task),
              onDelete: () => widget.onTaskDelete(task),
              onProgressChanged: (newCurrent) {
                widget.onProgressChanged(task, newCurrent);
              },
              onEdit: () => widget.onTaskEdit(context, task),
              taskSet: taskSet,
            );
          }).toList(),
        );
      },
    );
  }
}