class LocalExam {
  final String id;
  final String name;
  final String subject;
  final String date;
  final String time;
  final String duration;
  final int passingMarks;
  final int totalMarks;
  final List<LocalQuestion> questions;

  LocalExam({
    required this.id,
    required this.name,
    required this.subject,
    required this.date,
    required this.time,
    required this.duration,
    required this.passingMarks,
    required this.totalMarks,
    required this.questions,
  });

  LocalExam copyWith({
    List<LocalQuestion>? questions,
    int? passingMarks,
    int? totalMarks,
  }) {
    return LocalExam(
      id: id,
      name: name,
      subject: subject,
      date: date,
      time: time,
      duration: duration,
      passingMarks: passingMarks ?? this.passingMarks,
      totalMarks: totalMarks ?? this.totalMarks,
      questions: questions ?? this.questions,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'subject': subject,
    'date': date,
    'time': time,
    'duration': duration,
    'passingMarks': passingMarks,
    'totalMarks': totalMarks,
    'questions': questions.map((e) => e.toJson()).toList(),
  };

  factory LocalExam.fromJson(Map<String, dynamic> json) {
    return LocalExam(
      id: json['id'],
      name: json['name'],
      subject: json['subject'],
      date: json['date'],
      time: json['time'],
      duration: json['duration'],
      passingMarks: json['passingMarks'] ?? 0,
      totalMarks: json['totalMarks'] ?? 0,
      questions: (json['questions'] as List)
          .map((e) => LocalQuestion.fromJson(e))
          .toList(),
    );
  }
}

class LocalQuestion {
  final String id;
  final String text;
  final String type;
  final List<String>? options;
  final int? correctOptionIndex;
  final String? modelAnswer;
  final int marks;

  LocalQuestion({
    required this.id,
    required this.text,
    required this.type,
    this.options,
    this.correctOptionIndex,
    this.modelAnswer,
    required this.marks,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'type': type,
    'options': options,
    'correctOptionIndex': correctOptionIndex,
    'modelAnswer': modelAnswer,
    'marks': marks,
  };

  factory LocalQuestion.fromJson(Map<String, dynamic> json) {
    return LocalQuestion(
      id: json['id'],
      text: json['text'],
      type: json['type'],
      options: json['options'] != null
          ? List<String>.from(json['options'])
          : null,
      correctOptionIndex: json['correctOptionIndex'],
      modelAnswer: json['modelAnswer'],
      marks: json['marks'] ?? 1,
    );
  }
}