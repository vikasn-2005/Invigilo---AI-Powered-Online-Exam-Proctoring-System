import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalResultService {
  static const key = "results";

  static Future<void> save(
      Map<String, dynamic> result) async {
    final prefs =
    await SharedPreferences.getInstance();
    final list = prefs.getStringList(key) ?? [];

    list.add(jsonEncode(result));

    await prefs.setStringList(key, list);
  }

  static Future<List<dynamic>>
  getAll() async {
    final prefs =
    await SharedPreferences.getInstance();
    final list = prefs.getStringList(key) ?? [];

    return list.map((e) => jsonDecode(e)).toList();
  }
}