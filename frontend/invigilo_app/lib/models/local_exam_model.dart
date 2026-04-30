class LocalQuestion {
  final String id;
  final String text;
  final String type; // 'mcq' or 'answerable'
  final List<String>? options; // 4 options for MCQ
  final int? correctOptionIndex; // 0-3
  final String? modelAnswer; // for answerable (admin reference)
  final int marks;

  LocalQuestion({
    required this.id,
    required this.text,
    required this.type,
    this.options,
    this.correctOptionIndex,
    this.modelAnswer,
    this.marks = 1,
  });

  LocalQuestion copyWith({
    String? text,
    String? type,
    List<String>? options,
    int? correctOptionIndex,
    String? modelAnswer,
    int? marks,
    bool clearMcq = false,
    bool clearAnswer = false,
  }) =>
      LocalQuestion(
        id: id,
        text: text ?? this.text,
        type: type ?? this.type,
        options: clearMcq ? null : (options ?? this.options),
        correctOptionIndex:
        clearMcq ? null : (correctOptionIndex ?? this.correctOptionIndex),
        modelAnswer: clearAnswer ? null : (modelAnswer ?? this.modelAnswer),
        marks: marks ?? this.marks,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'type': type,
    'options': options,
    'correctOptionIndex': correctOptionIndex,
    'modelAnswer': modelAnswer,
    'marks': marks,
  };

  factory LocalQuestion.fromJson(Map<String, dynamic> json) => LocalQuestion(
    id: json['id'] ?? '',
    text: json['text'] ?? '',
    type: json['type'] ?? 'answerable',
    options: json['options'] != null
        ? List<String>.from(json['options'])
        : null,
    correctOptionIndex: json['correctOptionIndex'],
    modelAnswer: json['modelAnswer'],
    marks: json['marks'] ?? 1,
  );
}

class LocalExam {
  final String id;
  final String name;
  final String date;
  final String time;
  final String duration;
  final String subject;
  final List<LocalQuestion> questions;
  final String createdAt;
  final int passingMarks;
  final int totalMarks;

  LocalExam({
    required this.id,
    required this.name,
    required this.date,
    required this.time,
    required this.duration,
    required this.subject,
    required this.questions,
    required this.createdAt,
    this.passingMarks = 0,
    this.totalMarks = 0,
  });

  LocalExam copyWith({
    String? name,
    String? date,
    String? time,
    String? duration,
    String? subject,
    List<LocalQuestion>? questions,
    int? passingMarks,
    int? totalMarks,
  }) =>
      LocalExam(
        id: id,
        name: name ?? this.name,
        date: date ?? this.date,
        time: time ?? this.time,
        duration: duration ?? this.duration,
        subject: subject ?? this.subject,
        questions: questions ?? this.questions,
        createdAt: createdAt,
        passingMarks: passingMarks ?? this.passingMarks,
        totalMarks: totalMarks ?? this.totalMarks,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'date': date,
    'time': time,
    'duration': duration,
    'subject': subject,
    'questions': questions.map((q) => q.toJson()).toList(),
    'createdAt': createdAt,
    'passingMarks': passingMarks,
    'totalMarks': totalMarks,
  };

  factory LocalExam.fromJson(Map<String, dynamic> json) => LocalExam(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    date: json['date'] ?? '',
    time: json['time'] ?? '',
    duration: json['duration'] ?? '',
    subject: json['subject'] ?? '',
    questions: json['questions'] != null
        ? (json['questions'] as List)
        .map((q) => LocalQuestion.fromJson(q))
        .toList()
        : [],
    createdAt: json['createdAt'] ?? '',
    passingMarks: json['passingMarks'] ?? 0,
    totalMarks: json['totalMarks'] ?? 0,
  );
}