import 'package:hive/hive.dart';

part 'todo_item.g.dart';

@HiveType(typeId: 1)
class TodoItem {
  @HiveField(0)
  String title;

  @HiveField(1)
  bool isDone;

  @HiveField(2)
  String? weekday;

  @HiveField(3)
  int? current;

  @HiveField(4)
  int? target;

  @HiveField(5)
  List<String> completedDates;

  @HiveField(6)
  DateTime? deadline;

  @HiveField(7)
  String? setId;

  @HiveField(8)
  String? note;

  TodoItem({
    required this.title,
    this.isDone = false,
    this.weekday,
    this.current,
    this.target,
    List<String>? completedDates,
    this.deadline,
    this.setId,
    this.note,
  }) : completedDates = completedDates ?? [];

  Map<String, dynamic> toJson() => {
    'title': title,
    'isDone': isDone,
    'weekday': weekday,
    'current': current,
    'target': target,
    'completedDates': completedDates,
    'deadline': deadline?.toIso8601String(),
    'setId': setId,
    'note': note,
  };

  factory TodoItem.fromJson(Map<String, dynamic> json) {
    return TodoItem(
      title: json['title'],
      isDone: json['isDone'] ?? false,
      weekday: json['weekday'],
      current: json['current'],
      target: json['target'],
      completedDates: List<String>.from(json['completedDates'] ?? []),
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      setId: json['setId'],
      note: json['note'],
    );
  }
}