import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

import '../models/todo_item.dart';
import '../widgets/task_title.dart';
import '../widgets/weekly_task_title.dart';
import 'calendar_page.dart';

class TodoHomePage extends StatefulWidget {
  @override
  _TodoHomePageState createState() => _TodoHomePageState();
}

class _TodoHomePageState extends State<TodoHomePage> {
  int _currentIndex = 0; // 0:每日,1:每周,2:长期,3:截止,4:日历
  List<TodoItem> dailyTasks = [];
  List<TodoItem> weeklyTasks = [];
  List<TodoItem> longTermTasks = [];
  List<TodoItem> deadlineTasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      dailyTasks = _decodeTaskList(prefs.getString('daily') ?? '[]');
      weeklyTasks = _decodeTaskList(prefs.getString('weekly') ?? '[]');
      longTermTasks = _decodeTaskList(prefs.getString('longterm') ?? '[]');
      deadlineTasks = _decodeTaskList(prefs.getString('deadline') ?? '[]');
    });
    _checkDailyReset();
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('daily', _encodeTaskList(dailyTasks));
    await prefs.setString('weekly', _encodeTaskList(weeklyTasks));
    await prefs.setString('longterm', _encodeTaskList(longTermTasks));
    await prefs.setString('deadline', _encodeTaskList(deadlineTasks));
  }

  String _encodeTaskList(List<TodoItem> list) {
    return jsonEncode(list.map((e) => e.toJson()).toList());
  }

  List<TodoItem> _decodeTaskList(String str) {
    List<dynamic> jsonList = jsonDecode(str);
    return jsonList.map((e) => TodoItem.fromJson(e)).toList();
  }

  void _checkDailyReset() async {
    final prefs = await SharedPreferences.getInstance();
    String lastDate = prefs.getString('lastDailyDate') ?? '';
    String today = DateTime.now().toIso8601String().substring(0, 10);
    if (lastDate != today) {
      for (var task in dailyTasks) {
        task.completedDates.clear();
      }
      await prefs.setString('lastDailyDate', today);
      _saveTasks();
      setState(() {});
    }
  }

  void _addTask(String title,
      {String? weekday,
        int? current,
        int? target,
        DateTime? deadline}) {
    final task = TodoItem(
      title: title,
      weekday: weekday,
      current: current,
      target: target,
      deadline: deadline,
    );
    if (_currentIndex == 0) {
      dailyTasks.add(task);
    } else if (_currentIndex == 1) {
      weeklyTasks.add(task);
    } else if (_currentIndex == 2) {
      longTermTasks.add(task);
    } else if (_currentIndex == 3) {
      deadlineTasks.add(task);
    }
    _saveTasks();
    setState(() {});
  }

  void _addTaskFromCalendar(String title,
      {required String type,
        String? weekday,
        int? current,
        int? target,
        DateTime? deadline}) {
    final task = TodoItem(
      title: title,
      weekday: type == 'weekly' ? weekday : null,
      current: current,
      target: target,
      deadline: type == 'deadline' ? deadline : null,
    );
    if (type == 'weekly') {
      weeklyTasks.add(task);
    } else if (type == 'longterm') {
      longTermTasks.add(task);
    } else if (type == 'deadline') {
      deadlineTasks.add(task);
    }
    _saveTasks();
    setState(() {});
  }

  void _toggleTask(int index) {
    List<TodoItem> tasks;
    if (_currentIndex == 0) {
      tasks = dailyTasks;
    } else if (_currentIndex == 2) {
      tasks = longTermTasks;
    } else if (_currentIndex == 3) {
      tasks = deadlineTasks;
    } else {
      return;
    }

    final task = tasks[index];
    if (task.target == null) {
      task.isDone = !task.isDone;
      _saveTasks();
      setState(() {});
    }
  }

  void _toggleTaskByItem(TodoItem task) {
    if (task.target != null) return;
    task.isDone = !task.isDone;
    _saveTasks();
    setState(() {});
  }

  void _deleteTask(int index) {
    List<TodoItem> tasks;
    if (_currentIndex == 0) {
      tasks = dailyTasks;
    } else if (_currentIndex == 1) {
      tasks = weeklyTasks;
    } else if (_currentIndex == 2) {
      tasks = longTermTasks;
    } else {
      tasks = deadlineTasks;
    }

    tasks.removeAt(index);
    _saveTasks();
    setState(() {});
  }

  void _deleteTaskByItem(TodoItem task) {
    if (dailyTasks.contains(task)) {
      dailyTasks.remove(task);
    } else if (weeklyTasks.contains(task)) {
      weeklyTasks.remove(task);
    } else if (longTermTasks.contains(task)) {
      longTermTasks.remove(task);
    } else if (deadlineTasks.contains(task)) {
      deadlineTasks.remove(task);
    }
    _saveTasks();
    setState(() {});
  }

  void _showEditDialog(BuildContext context, TodoItem task) {
    final titleController = TextEditingController(text: task.title);
    final currentController = TextEditingController(
      text: task.current?.toString() ?? '',
    );
    final targetController = TextEditingController(
      text: task.target?.toString() ?? '',
    );
    bool isProgressTask = task.target != null && task.target! > 0;
    String? selectedWeekday = task.weekday;
    bool isWeeklyTask = task.weekday != null;
    DateTime? selectedDate = task.deadline;
    bool isDeadlineTask = task.deadline != null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: const Text('编辑任务'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: '任务内容'),
                  ),
                  if (isWeeklyTask) ...[
                    const SizedBox(height: 8),
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
                  ],
                  if (isDeadlineTask) ...[
                    const SizedBox(height: 8),
                    ListTile(
                      title: Text(selectedDate == null
                          ? '选择截止日期'
                          : '截止日期: ${DateFormat('yyyy-MM-dd').format(selectedDate!)}'),
                      trailing: const Icon(Icons.calendar_today),
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
                  ],
                  if (isProgressTask) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: currentController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: '当前完成数'),
                    ),
                    const SizedBox(height: 8),
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
                  if (isWeeklyTask && selectedWeekday == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('请选择星期几')));
                    return;
                  }
                  if (isProgressTask) {
                    final current = int.tryParse(currentController.text);
                    final target = int.tryParse(targetController.text);
                    if (current == null || target == null || target <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('请填写有效的数字')));
                      return;
                    }
                    task.current = current;
                    task.target = target;
                  }
                  task.title = titleController.text;
                  if (isWeeklyTask) {
                    task.weekday = selectedWeekday;
                  }
                  if (isDeadlineTask) {
                    task.deadline = selectedDate;
                  }
                  _saveTasks();
                  setState(() {});
                  Navigator.pop(ctx);
                },
                child: const Text('保存'),
              ),
            ],
          );
        },
      ),
    );
  }

  Map<String, List<TodoItem>> _groupWeeklyTasks() {
    final Map<String, List<TodoItem>> grouped = {};
    for (var task in weeklyTasks) {
      final day = task.weekday ?? '其他';
      if (!grouped.containsKey(day)) {
        grouped[day] = [];
      }
      grouped[day]!.add(task);
    }
    const weekOrder = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
      '其他'
    ];
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) => weekOrder.indexOf(a).compareTo(weekOrder.indexOf(b)));
    return Map.fromIterable(sortedKeys,
        key: (k) => k, value: (k) => grouped[k]!);
  }

  Widget _buildSimpleList(List<TodoItem> tasks) {
    if (tasks.isEmpty) return const Center(child: Text('暂无任务'));
    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (ctx, index) => TaskTile(
        task: tasks[index],
        onToggle: () => _toggleTask(index),
        onDelete: () => _deleteTask(index),
        onProgressChanged: (newCurrent) {
          tasks[index].current = newCurrent;
          _saveTasks();
          setState(() {});
        },
        onEdit: () => _showEditDialog(context, tasks[index]),
      ),
    );
  }

  Widget _buildWeeklyList() {
    final grouped = _groupWeeklyTasks();
    if (grouped.isEmpty) {
      return const Center(child: Text('暂无每周任务'));
    }
    return ListView(
      children: grouped.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                entry.key,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ...entry.value.map((task) {
              return WeeklyTaskTile(
                task: task,
                onDelete: () => _deleteTaskByItem(task),
                onViewCalendar: () {
                  setState(() {
                    _currentIndex = 4;
                  });
                },
                onEdit: () => _showEditDialog(context, task),
              );
            }).toList(),
          ],
        );
      }).toList(),
    );
  }

  void _showAddDialog(BuildContext context) {
    final titleController = TextEditingController();
    final currentController = TextEditingController();
    final targetController = TextEditingController();
    bool isProgressTask = false;
    String? selectedWeekday;
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: const Text('添加新任务'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: '任务内容'),
                  ),
                  if (_currentIndex == 1)
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
                  if (_currentIndex == 3)
                    ListTile(
                      title: Text(selectedDate == null
                          ? '选择截止日期'
                          : '截止日期: ${DateFormat('yyyy-MM-dd').format(selectedDate!)}'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
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
                      const Text('进度任务'),
                      Switch(
                        value: isProgressTask,
                        onChanged: (val) => setState(() => isProgressTask = val),
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
                  if (_currentIndex == 1 && selectedWeekday == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('请选择星期几')));
                    return;
                  }
                  if (_currentIndex == 3 && selectedDate == null) {
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
                  _addTask(
                    titleController.text,
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

  void _onCalendarTaskToggle(TodoItem task, DateTime date) {
    final dateStr = date.toIso8601String().substring(0, 10);
    if (task.target != null) return;

    if (task.weekday != null) {
      if (task.completedDates.contains(dateStr)) {
        task.completedDates.remove(dateStr);
      } else {
        task.completedDates.add(dateStr);
      }
    } else {
      task.isDone = !task.isDone;
    }
    _saveTasks();
    setState(() {});
  }

  void _onCalendarTaskEdit(BuildContext context, TodoItem task) {
    _showEditDialog(context, task);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(['每日待办', '每周固定', '长期待办', '截止任务', '日历'][_currentIndex]),
      ),
      body: _currentIndex == 4
          ? CalendarPage(
        dailyTasks: dailyTasks,
        weeklyTasks: weeklyTasks,
        longTermTasks: longTermTasks,
        deadlineTasks: deadlineTasks,
        onTaskToggle: _onCalendarTaskToggle,
        onAddTask: _addTaskFromCalendar,
        onTaskEdit: _onCalendarTaskEdit,
      )
          : _currentIndex == 1
          ? _buildWeeklyList()
          : _buildSimpleList(_getTasksForCurrentIndex()),
      floatingActionButton: _currentIndex == 4
          ? null
          : FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 0) _checkDailyReset();
        },
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.today), label: '每日'),
          BottomNavigationBarItem(icon: Icon(Icons.date_range), label: '每周'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: '长期'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: '截止'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: '日历'),
        ],
      ),
    );
  }

  List<TodoItem> _getTasksForCurrentIndex() {
    if (_currentIndex == 0) return dailyTasks;
    if (_currentIndex == 2) return longTermTasks;
    if (_currentIndex == 3) return deadlineTasks;
    return [];
  }
}