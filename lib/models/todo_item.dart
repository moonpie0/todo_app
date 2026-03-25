import 'package:hive/hive.dart';

part 'todo_item.g.dart';

@HiveType(typeId: 1)
class TodoItem {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  bool isDone;

  @HiveField(3)
  String? weekday;

  @HiveField(4)
  int? current;

  @HiveField(5)
  int? target;

  @HiveField(6)
  List<String> completedDates;

  @HiveField(7)
  DateTime? deadline;

  @HiveField(8)
  String? setId;

  @HiveField(9)
  String? note;

  @HiveField(10)
  List<SubTask> subtasks;

  @HiveField(11)
  String? timeInfo; // 新增

  TodoItem({
    String? id,
    required this.title,
    this.isDone = false,
    this.weekday,
    this.current,
    this.target,
    List<String>? completedDates,
    this.deadline,
    this.setId,
    this.note,
    List<SubTask>? subtasks,
    this.timeInfo,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString() + (1000 + (DateTime.now().microsecond % 9000)).toString(),
        completedDates = completedDates ?? [],
        subtasks = subtasks ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'isDone': isDone,
    'weekday': weekday,
    'current': current,
    'target': target,
    'completedDates': completedDates,
    'deadline': deadline?.toIso8601String(),
    'setId': setId,
    'note': note,
    'subtasks': subtasks.map((s) => s.toJson()).toList(),
    'timeInfo': timeInfo,
  };

  factory TodoItem.fromJson(Map<String, dynamic> json) {
    return TodoItem(
      id: json['id'],
      title: json['title'],
      isDone: json['isDone'] ?? false,
      weekday: json['weekday'],
      current: json['current'],
      target: json['target'],
      completedDates: List<String>.from(json['completedDates'] ?? []),
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      setId: json['setId'],
      note: json['note'],
      subtasks: (json['subtasks'] as List? ?? [])
          .map((s) => SubTask.fromJson(s))
          .toList(),
      timeInfo: json['timeInfo'],
    );
  }
}

@HiveType(typeId: 2)
class SubTask {
  @HiveField(0)
  String title;

  @HiveField(1)
  bool isDone;

  SubTask({required this.title, this.isDone = false});

  Map<String, dynamic> toJson() => {
    'title': title,
    'isDone': isDone,
  };

  factory SubTask.fromJson(Map<String, dynamic> json) {
    return SubTask(
      title: json['title'],
      isDone: json['isDone'] ?? false,
    );
  }
}