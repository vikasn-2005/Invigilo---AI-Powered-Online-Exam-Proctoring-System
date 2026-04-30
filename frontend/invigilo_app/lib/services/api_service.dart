import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = "http://10.0.2.2:5000/api";
  static const String staticUrl = "http://10.0.2.2:5000";

  // ── Helpers ────────────────────────────────────────────────────────────────

  static Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Map<String, String> _authHeaders(String token) => {
    "Authorization": "Bearer $token",
    "Content-Type": "application/json",
  };

  /// Returns full URL for a profile image filename.
  /// Pass the filename stored in user.profileImage
  static String profileImageUrl(String filename) =>
      "$staticUrl/uploads/profiles/$filename";

  // ── Auth ───────────────────────────────────────────────────────────────────

  static Future<String?> signUp(
      String name, String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/auth/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(
            {"name": name, "email": email, "password": password}),
      );
      if (res.statusCode == 200 || res.statusCode == 201) return null;
      try {
        final body = jsonDecode(res.body);
        return body['message'] ?? 'Sign up failed (${res.statusCode})';
      } catch (_) {
        return 'Sign up failed (${res.statusCode})';
      }
    } catch (e) {
      return 'Network error: $e';
    }
  }

  static Future<bool> login(String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/auth/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token'] ?? '');
        final user = data['user'];
        if (user != null) {
          await prefs.setString(
              'user_id', user['_id']?.toString() ?? '');
          await prefs.setString('user_name', user['name'] ?? '');
          await prefs.setString('user_email', user['email'] ?? '');
          await prefs.setString(
              'user_role', user['role'] ?? 'student');
          await prefs.setString(
              'user_profile_image', user['profileImage'] ?? '');
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/auth/profile"),
        headers: {"Authorization": "Bearer $token"},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        // Keep local cache in sync
        await prefs.setString(
            'user_profile_image', data['profileImage'] ?? '');
        return data;
      }
    } catch (_) {}
    // Fallback to cached values
    return {
      'name': prefs.getString('user_name'),
      'email': prefs.getString('user_email'),
      'profileImage': prefs.getString('user_profile_image'),
    };
  }

  /// Upload a profile image file. Returns the new filename on success, null on failure.
  static Future<String?> uploadProfileImage(File imageFile) async {
    try {
      final token = await _token();
      final uri = Uri.parse("$baseUrl/auth/upload-profile");
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(await http.MultipartFile.fromPath(
          'profileImage',
          imageFile.path,
        ));

      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final filename = data['profileImage'] as String?;
        if (filename != null) {
          // Update local cache
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_profile_image', filename);
        }
        return filename;
      }
    } catch (_) {}
    return null;
  }

  static Future<List<dynamic>> getStudents() async {
    try {
      final token = await _token();
      final res = await http.get(
        Uri.parse("$baseUrl/auth/students"),
        headers: {"Authorization": "Bearer $token"},
      );
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (_) {}
    return [];
  }

  // ── Exams ──────────────────────────────────────────────────────────────────

  static Future<List<dynamic>> getExams() async {
    try {
      final token = await _token();
      final res = await http
          .get(
        Uri.parse("$baseUrl/exams"),
        headers: {"Authorization": "Bearer $token"},
      )
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (_) {}
    return [];
  }

  static Future<Map<String, dynamic>?> createExam({
    required String title,
    required String subject,
    required int duration,
    required String date,
    required String time,
    required int passingMarks,
    required int totalMarks,
  }) async {
    try {
      final token = await _token();
      final res = await http.post(
        Uri.parse("$baseUrl/exams/create"),
        headers: _authHeaders(token!),
        body: jsonEncode({
          "title": title,
          "subject": subject,
          "duration": duration,
          "date": date,
          "time": time,
          "passingMarks": passingMarks,
          "totalMarks": totalMarks,
        }),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        return jsonDecode(res.body);
      }
    } catch (_) {}
    return null;
  }

  static Future<bool> deleteExam(String examId) async {
    try {
      final token = await _token();
      final res = await http.delete(
        Uri.parse("$baseUrl/exams/$examId"),
        headers: {"Authorization": "Bearer $token"},
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── Questions ──────────────────────────────────────────────────────────────

  static Future<List<dynamic>> getQuestions(String examId) async {
    try {
      final token = await _token();
      final res = await http.get(
        Uri.parse("$baseUrl/questions/$examId"),
        headers: {"Authorization": "Bearer $token"},
      );
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (_) {}
    return [];
  }

  static Future<bool> bulkAddQuestions(
      List<Map<String, dynamic>> questions) async {
    try {
      final token = await _token();
      final res = await http.post(
        Uri.parse("$baseUrl/questions/bulk"),
        headers: _authHeaders(token!),
        body: jsonEncode({"questions": questions}),
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> deleteQuestion(String questionId) async {
    try {
      final token = await _token();
      final res = await http.delete(
        Uri.parse("$baseUrl/questions/$questionId"),
        headers: {"Authorization": "Bearer $token"},
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── Results ────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> submitExam({
    required String examId,
    required List<Map<String, dynamic>> answers,
  }) async {
    try {
      final token = await _token();
      final res = await http.post(
        Uri.parse("$baseUrl/results/submit"),
        headers: _authHeaders(token!),
        body: jsonEncode({"examId": examId, "answers": answers}),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        return jsonDecode(res.body);
      }
    } catch (_) {}
    return null;
  }

  static Future<List<dynamic>> getMyResults() async {
    try {
      final token = await _token();
      final res = await http.get(
        Uri.parse("$baseUrl/results/my"),
        headers: {"Authorization": "Bearer $token"},
      );
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (_) {}
    return [];
  }

  static Future<List<dynamic>> getAllResults(
      {String? examId, String? studentId}) async {
    try {
      final token = await _token();
      final params = <String, String>{};
      if (examId != null) params['examId'] = examId;
      if (studentId != null) params['studentId'] = studentId;
      final uri = Uri.parse("$baseUrl/results/all")
          .replace(queryParameters: params.isNotEmpty ? params : null);
      final res = await http.get(uri,
          headers: {"Authorization": "Bearer $token"});
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (_) {}
    return [];
  }

  // ── Violations ─────────────────────────────────────────────────────────────

  static Future<void> reportViolation({
    required String examId,
    required String examTitle,
    required String type,
  }) async {
    try {
      final token = await _token();
      await http.post(
        Uri.parse("$baseUrl/violations/report"),
        headers: _authHeaders(token!),
        body: jsonEncode({
          "examId": examId,
          "examTitle": examTitle,
          "type": type,
        }),
      );
    } catch (_) {}
  }

  static Future<List<dynamic>> getMyViolations() async {
    try {
      final token = await _token();
      final res = await http.get(
        Uri.parse("$baseUrl/violations/my"),
        headers: {"Authorization": "Bearer $token"},
      );
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (_) {}
    return [];
  }

  static Future<List<dynamic>> getAllViolations(
      {String? studentId}) async {
    try {
      final token = await _token();
      final params = <String, String>{};
      if (studentId != null) params['studentId'] = studentId;
      final uri = Uri.parse("$baseUrl/violations/all")
          .replace(queryParameters: params.isNotEmpty ? params : null);
      final res = await http.get(uri,
          headers: {"Authorization": "Bearer $token"});
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (_) {}
    return [];
  }
}