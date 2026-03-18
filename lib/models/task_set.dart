import 'package:hive/hive.dart';

part 'task_set.g.dart';

@HiveType(typeId: 0)
class TaskSet {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  DateTime createdAt;

  TaskSet({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
  };

  factory TaskSet.fromJson(Map<String, dynamic> json) {
    return TaskSet(
      id: json['id'],
      name: json['name'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}