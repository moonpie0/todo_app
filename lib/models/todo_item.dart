class TodoItem {
  String title;
  bool isDone;
  String? weekday;
  int? current;
  int? target;
  List<String> completedDates;
  DateTime? deadline;
  String? setId;
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