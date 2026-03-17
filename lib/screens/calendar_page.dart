import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/todo_item.dart';
import '../main.dart';

class CalendarPage extends StatefulWidget {
  final List<TodoItem> dailyTasks;
  final List<TodoItem> weeklyTasks;
  final List<TodoItem> longTermTasks;
  final List<TodoItem> deadlineTasks;
  final Function(TodoItem, DateTime) onTaskToggle;
  final Function(String title,
      {required String type,
      String? weekday,
      int? current,
      int? target,
      DateTime? deadline}) onAddTask;
  final Function(BuildContext, TodoItem) onTaskEdit;

  const CalendarPage({
    Key? key,
    required this.dailyTasks,
    required this.weeklyTasks,
    required this.longTermTasks,
    required this.deadlineTasks,
    required this.onTaskToggle,
    required this.onAddTask,
    required this.onTaskEdit,
  }) : super(key: key);

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  List<TodoItem> _getTasksForDay(DateTime day) {
    final List<TodoItem> result = [];

    const weekdayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final dayOfWeek = weekdayNames[day.weekday - 1];
    result.addAll(
      widget.weeklyTasks.where((task) => task.weekday == dayOfWeek),
    );

    result.addAll(widget.deadlineTasks.where((task) {
      if (task.deadline == null) return false;
      return isSameDay(task.deadline!, day);
    }));

    return result;
  }

  bool _isTaskCompletedOnDay(TodoItem task, DateTime day) {
    if (task.target != null) return false;

    if (task.weekday != null) {
      final dateStr = day.toIso8601String().substring(0, 10);
      return task.completedDates.contains(dateStr);
    } else {
      return task.isDone;
    }
  }

  List<String> _getTaskTitlesForDay(DateTime day) {
    final tasks = _getTasksForDay(day);
    return tasks.map((task) {
      final isCompleted = _isTaskCompletedOnDay(task, day);
      return isCompleted ? '✅ ${task.title}' : task.title;
    }).toList();
  }

  void _showDayTasksBottomSheet(DateTime day) {
    final tasksForDay = _getTasksForDay(day);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Text(
                    '${day.year}年${day.month}月${day.day}日 待办',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                  Expanded(
                    child: tasksForDay.isEmpty
                        ? const Center(child: Text('今天没有待办'))
                        : ListView.builder(
                      controller: scrollController,
                      itemCount: tasksForDay.length,
                      itemBuilder: (ctx, index) {
                        final task = tasksForDay[index];
                        final isProgress = task.target != null && task.target! > 0;
                        final isCompleted = _isTaskCompletedOnDay(task, day);

                        return ListTile(
                          leading: isProgress
                              ? Icon(Icons.pie_chart, color: morandiPurple)
                              : (isCompleted
                              ? Icon(Icons.check_box, color: morandiBlue)
                              : Icon(Icons.check_box_outline_blank, color: morandiBlue)),
                          title: Text(
                            task.title,
                            style: TextStyle(
                              decoration: !isProgress && isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          subtitle: task.target != null
                              ? Text('进度: ${task.current}/${task.target}')
                              : (task.weekday != null
                              ? Text('每周 ${task.weekday}')
                              : (task.deadline != null
                              ? Text('截止: ${DateFormat('yyyy-MM-dd').format(task.deadline!)}')
                              : null)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  Navigator.pop(context);
                                  widget.onTaskEdit(context, task);
                                },
                                color: morandiBlue,
                              ),
                            ],
                          ),
                          onTap: () {
                            if (!isProgress) {
                              widget.onTaskToggle(task, day);
                              Navigator.pop(context);
                            }
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showAddDialog(context, day);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: morandiPurple,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('添加待办'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddDialog(BuildContext context, DateTime selectedDay) {
    final titleController = TextEditingController();
    final currentController = TextEditingController();
    final targetController = TextEditingController();
    bool isProgressTask = false;
    String taskType = 'weekly';
    String? selectedWeekday;
    DateTime? selectedDate;

    final defaultWeekday = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ][selectedDay.weekday - 1];
    selectedWeekday = defaultWeekday;
    selectedDate = selectedDay;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: const Text('添加待办'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: '待办内容'),
                  ),
                  Row(
                    children: [
                      const Text('待办类型'),
                      const SizedBox(width: 10),
                      DropdownButton<String>(
                        value: taskType,
                        items: const [
                          DropdownMenuItem(value: 'weekly', child: Text('每周待办')),
                          DropdownMenuItem(value: 'longterm', child: Text('长期待办')),
                          DropdownMenuItem(value: 'deadline', child: Text('截止待办')),
                        ],
                        onChanged: (value) => setState(() => taskType = value!),
                      ),
                    ],
                  ),
                  if (taskType == 'weekly')
                    DropdownButton<String>(
                      value: selectedWeekday,
                      hint: const Text('选择星期几'),
                      isExpanded: true,
                      items: const [
                        'Monday',
                        'Tuesday',
                        'Wednesday',
                        'Thursday',
                        'Friday',
                        'Saturday',
                        'Sunday'
                      ].map((day) => DropdownMenuItem(
                        value: day,
                        child: Text(day),
                      )).toList(),
                      onChanged: (value) => setState(() => selectedWeekday = value),
                    ),
                  if (taskType == 'deadline')
                    ListTile(
                      title: Text(selectedDate == null
                          ? '选择截止日期'
                          : '截止日期: ${DateFormat('yyyy-MM-dd').format(selectedDate!)}'),
                      trailing: Icon(Icons.calendar_today, color: morandiBlue),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          setState(() => selectedDate = date);
                        }
                      },
                    ),
                  Row(
                    children: [
                      const Text('进度待办'),
                      Switch(
                        value: isProgressTask,
                        onChanged: (val) => setState(() => isProgressTask = val),
                        activeColor: morandiPurple,
                      ),
                    ],
                  ),
                  if (isProgressTask) ...[
                    TextField(
                      controller: currentController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: '当前完成数'),
                    ),
                    TextField(
                      controller: targetController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: '目标总数'),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  if (titleController.text.isEmpty) return;
                  if (taskType == 'weekly' && selectedWeekday == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('请选择星期几')));
                    return;
                  }
                  if (taskType == 'deadline' && selectedDate == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('请选择截止日期')));
                    return;
                  }
                  int? current, target;
                  if (isProgressTask) {
                    current = int.tryParse(currentController.text);
                    target = int.tryParse(targetController.text);
                    if (current == null || target == null || target <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('请填写有效的数字')));
                      return;
                    }
                  }
                  widget.onAddTask(
                    titleController.text,
                    type: taskType,
                    weekday: selectedWeekday,
                    current: current,
                    target: target,
                    deadline: selectedDate,
                  );
                  Navigator.pop(ctx);
                },
                child: const Text('添加'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: null, // 去掉标题
        backgroundColor: morandiBlue,
        foregroundColor: Colors.white,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final availableHeight = constraints.maxHeight;
          const verticalPadding = 30.0;
          double rowHeight = (availableHeight - verticalPadding) / 6;
          rowHeight = rowHeight.clamp(40.0, 120.0);

          return TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              _showDayTasksBottomSheet(selectedDay);
            },
            calendarFormat: CalendarFormat.month,
            headerVisible: false,
            rowHeight: rowHeight,
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                final isSelected = isSameDay(day, _selectedDay);
                final taskTitles = _getTaskTitlesForDay(day);

                return Container(
                  margin: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected ? morandiPurple : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(2),
                    color: isSelected ? morandiBlue.withOpacity(0.1) : null,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${day.day}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: isSelected ? morandiPurple : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Expanded(
                          child: ListView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: taskTitles.length > 2 ? 2 : taskTitles.length,
                            itemBuilder: (ctx, index) {
                              return Text(
                                taskTitles[index],
                                style: const TextStyle(fontSize: 8),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              );
                            },
                          ),
                        ),
                        if (taskTitles.length > 2)
                          const Text(
                            '...',
                            style: TextStyle(fontSize: 8, color: Colors.grey),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            calendarStyle: const CalendarStyle(
              defaultTextStyle: TextStyle(fontSize: 0),
              weekendTextStyle: TextStyle(fontSize: 0),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, _selectedDay ?? _focusedDay),
        backgroundColor: morandiPurple,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}