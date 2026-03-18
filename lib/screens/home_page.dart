import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';

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
  // 页面索引：0-每日，1-每周，2-待办（合并），3-待办集，4-日历
  int _currentIndex = 0;
  List<TodoItem> dailyTasks = [];
  List<TodoItem> weeklyTasks = [];
  List<TodoItem> generalTasks = []; // 合并长期和截止

  List<TaskSet> taskSets = [];

  // 搜索相关
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  // Hive 盒子
  late Box tasksBox;
  late Box taskSetsBox;

  // 多选模式
  bool _isSelecting = false;
  Set<TodoItem> _selectedTasks = {};

  @override
  void initState() {
    super.initState();
    tasksBox = Hive.box('tasks');
    taskSetsBox = Hive.box('taskSets');
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

  // ---------- 任务集操作 ----------
  Future<void> _loadTaskSets() async {
    List<dynamic>? setsList = taskSetsBox.get('sets');
    setState(() {
      taskSets = setsList?.cast<TaskSet>() ?? [];
    });
  }

  Future<void> _saveTaskSets() async {
    await taskSetsBox.put('sets', taskSets);
  }

  // ---------- 待办操作 ----------
  Future<void> _loadTasks() async {
    setState(() {
      dailyTasks = _getTaskList('daily');
      weeklyTasks = _getTaskList('weekly');
      generalTasks = _getTaskList('general'); // 新 key
    });
    _checkDailyReset();
  }

  List<TodoItem> _getTaskList(String key) {
    List<dynamic>? list = tasksBox.get(key);
    return list?.cast<TodoItem>() ?? [];
  }

  Future<void> _saveTasks() async {
    await tasksBox.put('daily', dailyTasks);
    await tasksBox.put('weekly', weeklyTasks);
    await tasksBox.put('general', generalTasks);
  }

  void _checkDailyReset() async {
    String lastDate = tasksBox.get('lastDailyDate', defaultValue: '');
    String today = DateTime.now().toIso8601String().substring(0, 10);
    if (lastDate != today) {
      for (var task in dailyTasks) {
        task.completedDates.clear();
      }
      await tasksBox.put('lastDailyDate', today);
      _saveTasks();
      setState(() {});
    }
  }

  // ---------- 添加待办集 ----------
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

  // ---------- 添加待办（根据当前标签页）----------
  void _addTask(String title,
      {String? weekday,
        int? current,
        int? target,
        DateTime? deadline,
        String? setId,
        String? note,
        List<SubTask>? subtasks}) {
    final task = TodoItem(
      title: title,
      weekday: weekday,
      current: current,
      target: target,
      deadline: deadline,
      setId: setId,
      note: note,
      subtasks: subtasks,
    );
    if (_currentIndex == 0) {
      dailyTasks.add(task);
    } else if (_currentIndex == 1) {
      weeklyTasks.add(task);
    } else if (_currentIndex == 2) {
      generalTasks.add(task);
    }
    _saveTasks();
    setState(() {});
  }

  // 从日历页面添加待办（区分类型，但日历只添加每周和带截止的待办）
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
    } else if (type == 'deadline') {
      // 带截止日期的任务也放入 generalTasks
      generalTasks.add(task);
    }
    _saveTasks();
    setState(() {});
  }

  // 切换待办完成状态（列表）
  void _toggleTask(TodoItem task) {
    if (task.target != null) return; // 进度任务不能直接切换
    // 如果有子任务，则通过子任务控制完成状态，主任务完成状态由子任务决定
    if (task.subtasks.isNotEmpty) {
      // 子任务完成状态变化在子任务勾选时处理，这里不处理
      return;
    }
    task.isDone = !task.isDone;
    _saveTasks();
    setState(() {});
  }

  // 切换子任务完成状态
  void _toggleSubTask(TodoItem parent, SubTask subTask) {
    subTask.isDone = !subTask.isDone;
    // 如果所有子任务完成，主任务标记为完成
    parent.isDone = parent.subtasks.every((s) => s.isDone);
    _saveTasks();
    setState(() {});
  }

  // 删除单个待办
  void _deleteTask(TodoItem task) {
    if (dailyTasks.contains(task)) {
      dailyTasks.remove(task);
    } else if (weeklyTasks.contains(task)) {
      weeklyTasks.remove(task);
    } else if (generalTasks.contains(task)) {
      generalTasks.remove(task);
    }
    _saveTasks();
    setState(() {});
  }

  // 批量删除
  void _deleteSelectedTasks() {
    for (var task in _selectedTasks) {
      if (dailyTasks.contains(task)) {
        dailyTasks.remove(task);
      } else if (weeklyTasks.contains(task)) {
        weeklyTasks.remove(task);
      } else if (generalTasks.contains(task)) {
        generalTasks.remove(task);
      }
    }
    _saveTasks();
    _exitSelectMode();
  }

  // 进入多选模式
  void _enterSelectMode() {
    setState(() {
      _isSelecting = true;
      _selectedTasks.clear();
    });
  }

  // 退出多选模式
  void _exitSelectMode() {
    setState(() {
      _isSelecting = false;
      _selectedTasks.clear();
    });
  }

  // 切换选中状态
  void _toggleSelection(TodoItem task) {
    setState(() {
      if (_selectedTasks.contains(task)) {
        _selectedTasks.remove(task);
      } else {
        _selectedTasks.add(task);
      }
    });
  }

  // 全选/取消全选当前列表
  void _toggleSelectAll() {
    final currentList = _getCurrentTaskList();
    if (_selectedTasks.length == currentList.length) {
      _selectedTasks.clear();
    } else {
      _selectedTasks.addAll(currentList);
    }
    setState(() {});
  }

  // 获取当前显示的待办列表（考虑过滤）
  List<TodoItem> _getCurrentTaskList() {
    switch (_currentIndex) {
      case 0:
        return dailyTasks;
      case 1:
        return weeklyTasks;
      case 2:
        return generalTasks;
      default:
        return [];
    }
  }

  // 过滤后的列表
  List<TodoItem> _getFilteredTasks() {
    final all = _getCurrentTaskList();
    if (_searchText.isEmpty) return all;
    return all.where((t) => t.title.toLowerCase().contains(_searchText)).toList();
  }

  // 编辑待办对话框（增加子任务编辑）
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
    bool hasDeadline = task.deadline != null;
    String? selectedSetId = task.setId;

    // 子任务列表
    List<SubTask> subtasks = List.from(task.subtasks);
    final subTaskControllers = <TextEditingController>[];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: const Text('编辑待办'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
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
                        const DropdownMenuItem(value: null, child: Text('无')),
                        ...taskSets.map(
                              (set) => DropdownMenuItem(value: set.id, child: Text(set.name)),
                        ),
                      ],
                      onChanged: (v) => setState(() => selectedSetId = v),
                    ),
                  ],
                  // 每周任务特有：星期选择
                  if (task.weekday != null) ...[
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      value: selectedWeekday,
                      hint: const Text('选择星期几'),
                      isExpanded: true,
                      items: const [
                        'Monday', 'Tuesday', 'Wednesday', 'Thursday',
                        'Friday', 'Saturday', 'Sunday'
                      ].map((day) => DropdownMenuItem(
                        value: day,
                        child: Text(_getChineseWeekday(day)),
                      )).toList(),
                      onChanged: (v) => setState(() => selectedWeekday = v),
                    ),
                  ],
                  // 截止日期（对所有非每日/每周任务显示）
                  if (_currentIndex == 2) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('设置截止日期'),
                        Switch(
                          value: hasDeadline,
                          onChanged: (val) => setState(() {
                            hasDeadline = val;
                            if (val && selectedDate == null) {
                              selectedDate = DateTime.now();
                            }
                          }),
                          activeColor: morandiPurple,
                        ),
                      ],
                    ),
                    if (hasDeadline)
                      ListTile(
                        title: Text(
                          selectedDate == null
                              ? '选择截止日期'
                              : '截止日期: ${DateFormat('yyyy-MM-dd').format(selectedDate!)}',
                        ),
                        trailing: Icon(Icons.calendar_today, color: morandiBlue),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (date != null) setState(() => selectedDate = date);
                        },
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
                            if (val && task.target == null) {
                              currentController.text = '0';
                              targetController.text = '1';
                            } else if (!val) {
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
                  const SizedBox(height: 16),
                  // 子任务列表
                  const Text('子任务', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...subtasks.asMap().entries.map((entry) {
                    int idx = entry.key;
                    SubTask sub = entry.value;
                    if (subTaskControllers.length <= idx) {
                      subTaskControllers.add(TextEditingController(text: sub.title));
                    }
                    return Row(
                      children: [
                        Checkbox(
                          value: sub.isDone,
                          onChanged: (val) {
                            setState(() {
                              sub.isDone = val ?? false;
                            });
                          },
                        ),
                        Expanded(
                          child: TextField(
                            controller: subTaskControllers[idx],
                            decoration: const InputDecoration(hintText: '子任务内容'),
                            onChanged: (val) => sub.title = val,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20),
                          onPressed: () {
                            setState(() {
                              subtasks.removeAt(idx);
                              subTaskControllers.removeAt(idx);
                            });
                          },
                        ),
                      ],
                    );
                  }).toList(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        subtasks.add(SubTask(title: ''));
                        subTaskControllers.add(TextEditingController());
                      });
                    },
                    child: const Text('+ 添加子任务'),
                  ),
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
                onPressed: () {
                  // 删除逻辑
                  _deleteTask(task);
                  Navigator.pop(ctx);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('删除'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  // 保存逻辑（原代码不变）
                  if (titleController.text.isEmpty) return;
                  if (task.weekday != null && selectedWeekday == null) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text('请选择星期几')));
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
                  task.weekday = selectedWeekday;
                  task.deadline = hasDeadline ? selectedDate : null;
                  task.setId = selectedSetId;
                  task.note = noteController.text.isNotEmpty ? noteController.text : null;
                  task.subtasks = subtasks.where((s) => s.title.isNotEmpty).toList();
                  if (task.subtasks.isNotEmpty) {
                    task.isDone = task.subtasks.every((s) => s.isDone);
                  }
                  _saveTasks();
                  Navigator.pop(ctx);
                  setState(() {});
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
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

  // 添加待办对话框
  void _showAddDialog(BuildContext context) {
    final titleController = TextEditingController();
    final currentController = TextEditingController();
    final targetController = TextEditingController();
    final noteController = TextEditingController();
    bool isProgressTask = false;
    String? selectedWeekday;
    DateTime? selectedDate;
    bool hasDeadline = false;
    String? selectedSetId;
    List<SubTask> subtasks = [];
    final subTaskControllers = <TextEditingController>[];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: const Text('添加新待办'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
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
                        const DropdownMenuItem(value: null, child: Text('无')),
                        ...taskSets.map(
                              (set) => DropdownMenuItem(value: set.id, child: Text(set.name)),
                        ),
                      ],
                      onChanged: (v) => setState(() => selectedSetId = v),
                    ),
                  ],
                  // 每周任务特有：星期选择
                  if (_currentIndex == 1) ...[
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      value: selectedWeekday,
                      hint: const Text('选择星期几'),
                      isExpanded: true,
                      items: const [
                        'Monday', 'Tuesday', 'Wednesday', 'Thursday',
                        'Friday', 'Saturday', 'Sunday'
                      ].map((day) => DropdownMenuItem(
                        value: day,
                        child: Text(_getChineseWeekday(day)),
                      )).toList(),
                      onChanged: (v) => setState(() => selectedWeekday = v),
                    ),
                  ],
                  // 待办（合并）特有：截止日期选项
                  if (_currentIndex == 2) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('设置截止日期'),
                        Switch(
                          value: hasDeadline,
                          onChanged: (val) => setState(() {
                            hasDeadline = val;
                            if (val && selectedDate == null) {
                              selectedDate = DateTime.now();
                            }
                          }),
                          activeColor: morandiPurple,
                        ),
                      ],
                    ),
                    if (hasDeadline)
                      ListTile(
                        title: Text(
                          selectedDate == null
                              ? '选择截止日期'
                              : '截止日期: ${DateFormat('yyyy-MM-dd').format(selectedDate!)}',
                        ),
                        trailing: Icon(Icons.calendar_today, color: morandiBlue),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (date != null) setState(() => selectedDate = date);
                        },
                      ),
                  ],
                  // 进度待办开关
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
                  const SizedBox(height: 16),
                  // 子任务列表
                  const Text('子任务', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...subtasks.asMap().entries.map((entry) {
                    int idx = entry.key;
                    SubTask sub = entry.value;
                    if (subTaskControllers.length <= idx) {
                      subTaskControllers.add(TextEditingController(text: sub.title));
                    }
                    return Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: subTaskControllers[idx],
                            decoration: const InputDecoration(hintText: '子任务内容'),
                            onChanged: (val) => sub.title = val,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20),
                          onPressed: () {
                            setState(() {
                              subtasks.removeAt(idx);
                              subTaskControllers.removeAt(idx);
                            });
                          },
                        ),
                      ],
                    );
                  }).toList(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        subtasks.add(SubTask(title: ''));
                        subTaskControllers.add(TextEditingController());
                      });
                    },
                    child: const Text('+ 添加子任务'),
                  ),
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
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
              TextButton(
                onPressed: () {
                  if (titleController.text.isEmpty) return;
                  if (_currentIndex == 1 && selectedWeekday == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请选择星期几')));
                    return;
                  }
                  int? current, target;
                  if (isProgressTask) {
                    current = int.tryParse(currentController.text);
                    target = int.tryParse(targetController.text);
                    if (current == null || target == null || target <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请填写有效的数字')));
                      return;
                    }
                  }
                  // 过滤掉空标题的子任务
                  final validSubtasks = subtasks.where((s) => s.title.isNotEmpty).toList();
                  _addTask(
                    titleController.text,
                    weekday: selectedWeekday,
                    current: current,
                    target: target,
                    deadline: hasDeadline ? selectedDate : null,
                    setId: selectedSetId,
                    note: noteController.text.isNotEmpty ? noteController.text : null,
                    subtasks: validSubtasks,
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

  // 分组每周待办
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
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday', '其他'
    ];
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) => weekOrder.indexOf(a).compareTo(weekOrder.indexOf(b)));
    return Map.fromIterable(sortedKeys, key: (k) => k, value: (k) => grouped[k]!);
  }

  // 构建普通列表（每日、待办）
  Widget _buildSimpleList(List<TodoItem> tasks) {
    final filtered = _getFilteredTasks();
    if (filtered.isEmpty) {
      return Center(
        child: Text(_searchText.isEmpty ? '暂无待办' : '没有匹配的待办'),
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      itemCount: filtered.length,
      itemBuilder: (ctx, index) {
        final task = filtered[index];
        final matchingSets = taskSets.where((set) => set.id == task.setId);
        final taskSet = matchingSets.isNotEmpty ? matchingSets.first : null;

        // 必须为每个 item 提供 Key，这里使用 task.id（确保唯一）
        return TaskTile(
          key: ValueKey(task.id),
          task: task,
          isSelecting: _isSelecting,
          isSelected: _selectedTasks.contains(task),
          onTap: () {
            if (_isSelecting) {
              _toggleSelection(task);
            } else {
              _showEditDialog(context, task);
            }
          },
          onLongPress: () {
            if (!_isSelecting) {
              _enterSelectMode();
              _toggleSelection(task);
            }
          },
          onToggle: () => _toggleTask(task),
          onSubTaskToggle: (subTask) => _toggleSubTask(task, subTask),
          onDelete: () => _deleteTask(task),
          onProgressChanged: (newCurrent) {
            task.current = newCurrent;
            _saveTasks();
            setState(() {});
          },
          taskSet: taskSet,
        );
      },
      onReorder: (int oldIndex, int newIndex) {
        // 处理索引：当 newIndex > oldIndex 时，由于删除操作，newIndex 需要减1
        if (oldIndex < newIndex) {
          newIndex -= 1;
        }

        // 根据当前标签页更新对应的列表
        setState(() {
          final currentList = _getCurrentTaskList();
          final task = currentList.removeAt(oldIndex);
          currentList.insert(newIndex, task);
        });

        // 保存到 Hive
        _saveTasks();
      },
    );
  }

  Widget _buildWeeklyList() {
    final grouped = _groupWeeklyTasks();
    if (grouped.isEmpty) {
      return const Center(child: Text('暂无每周待办'));
    }
    // 过滤每个分组
    final filteredGrouped = <String, List<TodoItem>>{};
    grouped.forEach((key, tasks) {
      final filtered = tasks.where((t) =>
          t.title.toLowerCase().contains(_searchText)).toList();
      if (filtered.isNotEmpty) {
        filteredGrouped[key] = filtered;
      }
    });

    if (filteredGrouped.isEmpty) {
      return Center(child: Text(_searchText.isEmpty ? '暂无每周待办' : '没有匹配的待办'));
    }

    return ListView(
      children: filteredGrouped.entries.map((entry) {
        final chineseTitle = _getChineseWeekday(entry.key) == entry.key
            ? entry.key
            : _getChineseWeekday(entry.key);
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
                key: ValueKey(task.id),
                task: task,
                isSelecting: _isSelecting,
                isSelected: _selectedTasks.contains(task),
                onTap: () {
                  if (_isSelecting) {
                    _toggleSelection(task);
                  } else {
                    _showEditDialog(context, task);
                  }
                },
                onLongPress: () {
                  if (!_isSelecting) {
                    _enterSelectMode();
                    _toggleSelection(task);
                  }
                },
              );
            }).toList(),
          ],
        );
      }).toList(),
    );
  }

  // 日历回调
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
        title: Text(
          _isSelecting
              ? '已选中 ${_selectedTasks.length} 项'
              : ['每日待办', '每周待办', '待办', '待办集', '日历'][_currentIndex],
        ),
        backgroundColor: morandiBlue,
        foregroundColor: Colors.white,
        actions: _isSelecting
            ? [
          IconButton(
            icon: const Icon(Icons.select_all),
            onPressed: _toggleSelectAll,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _selectedTasks.isEmpty ? null : _deleteSelectedTasks,
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _exitSelectMode,
          ),
        ]
            : [
          IconButton(
            icon: const Icon(Icons.add_task),
            onPressed: _currentIndex == 4 ? null : () => _showAddDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.create_new_folder),
            onPressed: () => _showAddTaskSetDialog(context),
          ),
        ],
        bottom: _currentIndex != 4
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
      body: _currentIndex == 4 // 日历
          ? CalendarPage(
        dailyTasks: dailyTasks,
        weeklyTasks: weeklyTasks,
        longTermTasks: [], // 不再使用
        deadlineTasks: generalTasks.where((t) => t.deadline != null).toList(),
        onTaskToggle: _onCalendarTaskToggle,
        onAddTask: _addTaskFromCalendar,
        onTaskEdit: _onCalendarTaskEdit,
      )
          : _currentIndex == 3 // 待办集
          ? TaskSetPage(
        taskSets: taskSets,
        allTasks: [...dailyTasks, ...weeklyTasks, ...generalTasks],
        onTaskToggle: (task) => _toggleTask(task),
        onTaskDelete: _deleteTask,
        onProgressChanged: (task, newCurrent) {
          task.current = newCurrent;
          _saveTasks();
          setState(() {});
        },
        onTaskEdit: _onCalendarTaskEdit,
        onSubTaskToggle: _toggleSubTask, // 新增传入
      )
          : _currentIndex == 1 // 每周
          ? _buildWeeklyList()
          : _buildSimpleList(_getCurrentTaskList()),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 0) _checkDailyReset();
          if (_isSelecting) _exitSelectMode(); // 切换标签页退出多选
        },
        selectedItemColor: morandiPurple,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.today), label: '每日'),
          BottomNavigationBarItem(icon: Icon(Icons.date_range), label: '每周'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: '待办'),
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: '待办集'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: '日历'),
        ],
      ),
    );
  }
}