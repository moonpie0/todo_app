import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

import '../models/todo_item.dart';
import '../models/task_set.dart';
import '../widgets/task_title.dart';
import '../widgets/weekly_task_title.dart';
import 'calendar_page.dart';
import 'task_set_page.dart';
import '../main.dart';

// 星期映射函数
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

class TodoHomePage extends StatefulWidget {
  @override
  _TodoHomePageState createState() => _TodoHomePageState();
}

class _TodoHomePageState extends State<TodoHomePage> {
  int _currentIndex = 0; // 0:每日,1:每周,2:长期,3:截止,4:待办集,5:日历
  List<TodoItem> dailyTasks = [];
  List<TodoItem> weeklyTasks = [];
  List<TodoItem> longTermTasks = [];
  List<TodoItem> deadlineTasks = [];
  List<TaskSet> taskSets = [];

  // 搜索相关
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _loadTaskSets();
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 加载待办集
  Future<void> _loadTaskSets() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      String setsJson = prefs.getString('taskSets') ?? '[]';
      List<dynamic> setsList = jsonDecode(setsJson);
      taskSets = setsList.map((e) => TaskSet.fromJson(e)).toList();
    });
  }

  Future<void> _saveTaskSets() async {
    final prefs = await SharedPreferences.getInstance();
    String setsJson = jsonEncode(taskSets.map((e) => e.toJson()).toList());
    await prefs.setString('taskSets', setsJson);
  }

  // 加载待办
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

  // 添加待办集
  void _addTaskSet(String name) {
    final newSet = TaskSet(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      createdAt: DateTime.now(),
    );
    setState(() {
      taskSets.add(newSet);
    });
    _saveTaskSets();
  }

  // 添加待办（支持待办集选择）
  void _addTask(String title,
      {String? weekday,
        int? current,
        int? target,
        DateTime? deadline,
        String? setId,
        String? note}) {
    final task = TodoItem(
      title: title,
      weekday: weekday,
      current: current,
      target: target,
      deadline: deadline,
      setId: setId,
      note: note,
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
        DateTime? deadline,
        String? setId,
        String? note}) {
    final task = TodoItem(
      title: title,
      weekday: type == 'weekly' ? weekday : null,
      current: current,
      target: target,
      deadline: type == 'deadline' ? deadline : null,
      setId: setId,
      note: note,
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
    } else if (_currentIndex == 3) {
      tasks = deadlineTasks;
    } else {
      return;
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
    final noteController = TextEditingController(text: task.note ?? '');
    bool isProgressTask = task.target != null && task.target! > 0;
    String? selectedWeekday = task.weekday;
    bool isWeeklyTask = task.weekday != null;
    DateTime? selectedDate = task.deadline;
    bool isDeadlineTask = task.deadline != null;
    String? selectedSetId = task.setId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: const Text('编辑待办'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: '待办内容'),
                  ),
                  // 待办集选择
                  if (taskSets.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      value: selectedSetId,
                      hint: const Text('选择待办集（可选）'),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('无'),
                        ),
                        ...taskSets.map((set) => DropdownMenuItem(
                          value: set.id,
                          child: Text(set.name),
                        )),
                      ],
                      onChanged: (value) => setState(() => selectedSetId = value),
                    ),
                  ],
                  // 进度待办开关
                  Row(
                    children: [
                      const Text('进度待办'),
                      Switch(
                        value: isProgressTask,
                        onChanged: (val) {
                          setState(() {
                            isProgressTask = val;
                            if (isProgressTask && task.target == null) {
                              // 默认初始值
                              currentController.text = '0';
                              targetController.text = '1';
                            } else if (!isProgressTask) {
                              currentController.clear();
                              targetController.clear();
                            }
                          });
                        },
                        activeColor: morandiPurple,
                      ),
                    ],
                  ),
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
                  if (isWeeklyTask) ...[
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      value: selectedWeekday,
                      hint: const Text('选择星期几'),
                      isExpanded: true,
                      // 下拉选项显示中文
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
                        child: Text(_getChineseWeekday(day)),
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
                  ],
                  const SizedBox(height: 8),
                  TextField(
                    controller: noteController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: '备注（可选）',
                      border: OutlineInputBorder(),
                    ),
                  ),
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
                  } else {
                    task.current = null;
                    task.target = null;
                  }
                  task.title = titleController.text;
                  if (isWeeklyTask) {
                    task.weekday = selectedWeekday;
                  } else {
                    task.weekday = null;
                  }
                  if (isDeadlineTask) {
                    task.deadline = selectedDate;
                  } else {
                    task.deadline = null;
                  }
                  task.setId = selectedSetId;
                  task.note = noteController.text.isNotEmpty ? noteController.text : null;
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

  // 新增待办集对话框
  void _showAddTaskSetDialog(BuildContext context) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新增待办集'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: '待办集名称'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                _addTaskSet(nameController.text);
                Navigator.pop(ctx);
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  // 添加待办对话框（增加待办集选择）
  void _showAddDialog(BuildContext context) {
    final titleController = TextEditingController();
    final currentController = TextEditingController();
    final targetController = TextEditingController();
    final noteController = TextEditingController();
    bool isProgressTask = false;
    String? selectedWeekday;
    DateTime? selectedDate;
    String? selectedSetId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: const Text('添加新待办'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: '待办内容'),
                  ),
                  // 待办集选择
                  if (taskSets.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      value: selectedSetId,
                      hint: const Text('选择待办集（可选）'),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('无'),
                        ),
                        ...taskSets.map((set) => DropdownMenuItem(
                          value: set.id,
                          child: Text(set.name),
                        )),
                      ],
                      onChanged: (value) => setState(() => selectedSetId = value),
                    ),
                  ],
                  if (_currentIndex == 1)
                    DropdownButton<String>(
                      value: selectedWeekday,
                      hint: const Text('选择星期几'),
                      isExpanded: true,
                      // 下拉选项显示中文
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
                        child: Text(_getChineseWeekday(day)),
                      )).toList(),
                      onChanged: (value) => setState(() => selectedWeekday = value),
                    ),
                  if (_currentIndex == 3)
                    ListTile(
                      title: Text(selectedDate == null
                          ? '选择截止日期'
                          : '截止日期: ${DateFormat('yyyy-MM-dd').format(selectedDate!)}'),
                      trailing: Icon(Icons.calendar_today, color: morandiBlue),
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
                  const SizedBox(height: 8),
                  TextField(
                    controller: noteController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: '备注（可选）',
                      border: OutlineInputBorder(),
                    ),
                  ),
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
                    setId: selectedSetId,
                    note: noteController.text.isNotEmpty ? noteController.text : null,
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

  // 分组每周待办，分组标题显示中文
  Map<String, List<TodoItem>> _groupWeeklyTasks() {
    final Map<String, List<TodoItem>> grouped = {};
    for (var task in weeklyTasks) {
      final day = task.weekday ?? '其他';
      if (!grouped.containsKey(day)) {
        grouped[day] = [];
      }
      grouped[day]!.add(task);
    }
    // 星期顺序（英文）
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

  // 过滤待办列表
  List<TodoItem> _filterTasks(List<TodoItem> tasks) {
    if (_searchText.isEmpty) return tasks;
    return tasks.where((task) =>
        task.title.toLowerCase().contains(_searchText)).toList();
  }

  Widget _buildSimpleList(List<TodoItem> tasks) {
    final filtered = _filterTasks(tasks);
    if (filtered.isEmpty) {
      return Center(
        child: Text(_searchText.isEmpty ? '暂无待办' : '没有匹配的待办'),
      );
    }
    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (ctx, index) {
        final task = filtered[index];
        final matchingSets = taskSets.where((set) => set.id == task.setId);
        final taskSet = matchingSets.isNotEmpty ? matchingSets.first : null;
        return TaskTile(
          task: task,
          onToggle: () => _toggleTask(tasks.indexOf(task)),
          onDelete: () => _deleteTaskByItem(task),
          onProgressChanged: (newCurrent) {
            task.current = newCurrent;
            _saveTasks();
            setState(() {});
          },
          onEdit: () => _showEditDialog(context, task),
          taskSet: taskSet,
        );
      },
    );
  }

  Widget _buildWeeklyList() {
    final grouped = _groupWeeklyTasks();
    if (grouped.isEmpty) {
      return const Center(child: Text('暂无每周待办'));
    }
    // 过滤每个分组内的待办
    final filteredGrouped = <String, List<TodoItem>>{};
    grouped.forEach((key, tasks) {
      final filtered = _filterTasks(tasks);
      if (filtered.isNotEmpty) {
        filteredGrouped[key] = filtered;
      }
    });

    if (filteredGrouped.isEmpty) {
      return Center(child: Text(_searchText.isEmpty ? '暂无每周待办' : '没有匹配的待办'));
    }

    return ListView(
      children: filteredGrouped.entries.map((entry) {
        // 将分组标题转换为中文
        final chineseTitle = _getChineseWeekday(entry.key) == entry.key ? entry.key : _getChineseWeekday(entry.key);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                chineseTitle,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ...entry.value.map((task) {
              return WeeklyTaskTile(
                task: task,
                onDelete: () => _deleteTaskByItem(task),
                onViewCalendar: () {
                  setState(() {
                    _currentIndex = 5;
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
        title: Text(['每日待办', '每周待办', '长期待办', '截止待办', '待办集', '日历'][_currentIndex]), // 修改这里
        backgroundColor: morandiBlue,
        foregroundColor: Colors.white,
        actions: [
          // 新增待办按钮
          IconButton(
            icon: const Icon(Icons.add_task),
            onPressed: _currentIndex == 5 ? null : () => _showAddDialog(context),
          ),
          // 新增待办集按钮
          IconButton(
            icon: const Icon(Icons.create_new_folder),
            onPressed: () => _showAddTaskSetDialog(context),
          ),
        ],
        bottom: _currentIndex != 5
            ? PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索待办...',
                prefixIcon: Icon(Icons.search, color: morandiPurple),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
        )
            : null,
      ),
      body: _currentIndex == 5
          ? CalendarPage(
        dailyTasks: dailyTasks,
        weeklyTasks: weeklyTasks,
        longTermTasks: longTermTasks,
        deadlineTasks: deadlineTasks,
        onTaskToggle: _onCalendarTaskToggle,
        onAddTask: _addTaskFromCalendar,
        onTaskEdit: _onCalendarTaskEdit,
      )
          : _currentIndex == 4
          ? TaskSetPage(
        taskSets: taskSets,
        allTasks: [...dailyTasks, ...weeklyTasks, ...longTermTasks, ...deadlineTasks],
        onTaskToggle: _toggleTaskByItem,
        onTaskDelete: _deleteTaskByItem,
        onProgressChanged: (task, newCurrent) {
          task.current = newCurrent;
          _saveTasks();
          setState(() {});
        },
        onTaskEdit: _onCalendarTaskEdit,
      )
          : _currentIndex == 1
          ? _buildWeeklyList()
          : _buildSimpleList(_getTasksForCurrentIndex()),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 0) _checkDailyReset();
        },
        selectedItemColor: morandiPurple,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.today), label: '每日'),
          BottomNavigationBarItem(icon: Icon(Icons.date_range), label: '每周'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: '长期'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: '截止'),
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: '待办集'),
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