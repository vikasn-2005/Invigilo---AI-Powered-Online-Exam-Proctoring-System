import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/local_exam_model.dart';

class LocalExamService {
  static const String _key = 'local_exams_v1';

  static Future<List<LocalExam>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => LocalExam.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(LocalExam exam) async {
    final exams = await getAll();
    final idx = exams.indexWhere((e) => e.id == exam.id);
    if (idx >= 0) {
      exams[idx] = exam;
    } else {
      exams.add(exam);
    }
    await _persist(exams);
  }

  static Future<void> delete(String id) async {
    final exams = await getAll();
    exams.removeWhere((e) => e.id == id);
    await _persist(exams);
  }

  static Future<void> _persist(List<LocalExam> exams) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(exams.map((e) => e.toJson()).toList()),
    );
  }
}
