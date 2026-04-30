import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ViolationsTab extends StatefulWidget {
  const ViolationsTab({super.key});

  @override
  State<ViolationsTab> createState() => _ViolationsTabState();
}

class _ViolationsTabState extends State<ViolationsTab> {
  List<dynamic> _violations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await ApiService.getMyViolations();
    if (mounted) setState(() { _violations = data; _loading = false; });
  }

  String _formatType(String type) {
    switch (type) {
      case 'app_switch':
        return 'App Switch / Minimized';
      default:
        return type.replaceAll('_', ' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF4FC3F7)));
    }

    if (_violations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_outlined,
                size: 64, color: Colors.green.shade300),
            const SizedBox(height: 12),
            const Text('No violations recorded',
                style: TextStyle(
                    color: Color(0xFF66BB6A),
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            const Text('Keep it up!',
                style:
                TextStyle(color: Colors.black38, fontSize: 13)),
          ],
        ),
      );
    }

    // Group violations by exam
    final Map<String, List<dynamic>> grouped = {};
    for (final v in _violations) {
      final title = v['examTitle'] ?? 'Unknown Exam';
      grouped.putIfAbsent(title, () => []).add(v);
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF4FC3F7),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary banner
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: Colors.redAccent.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Colors.redAccent, size: 20),
                const SizedBox(width: 10),
                Text(
                  '${_violations.length} violation${_violations.length == 1 ? '' : 's'} recorded across ${grouped.length} exam${grouped.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

          // Grouped by exam
          ...grouped.entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Exam header
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 3,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.key,
                          style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${entry.value.length} violation${entry.value.length == 1 ? '' : 's'}',
                          style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

                // Violations for this exam
                ...entry.value.map((v) {
                  final ts = v['timestamp'] != null
                      ? DateTime.tryParse(v['timestamp'])
                      : null;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.redAccent.withOpacity(0.2),
                          width: 0.8),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 4),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.redAccent,
                              size: 16),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(_formatType(v['type'] ?? ''),
                                  style: const TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                              if (ts != null)
                                Text(
                                  '${ts.day}/${ts.month}/${ts.year}  '
                                      '${ts.hour.toString().padLeft(2, '0')}:'
                                      '${ts.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(
                                      color: Colors.black38,
                                      fontSize: 11),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 12),
              ],
            );
          }),
        ],
      ),
    );
  }
}