class Exam {
  final String id;
  final String title;
  final int duration;

  Exam({
    required this.id,
    required this.title,
    required this.duration,
  });

  factory Exam.fromJson(Map<String, dynamic> json) {
    return Exam(
      id: json['_id'],
      title: json['title'],
      duration: json['duration'],
    );
  }
}