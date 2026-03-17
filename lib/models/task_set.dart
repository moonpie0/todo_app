class TaskSet {
  String id;
  String name;
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