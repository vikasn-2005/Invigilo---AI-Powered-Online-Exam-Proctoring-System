import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ResultsTab extends StatefulWidget {
  const ResultsTab({super.key});

  @override
  State<ResultsTab> createState() => _ResultsTabState();
}

class _ResultsTabState extends State<ResultsTab> {
  List<dynamic> _results = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await ApiService.getMyResults();
    if (mounted) {
      setState(() {
        _results = data;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF4FC3F7)));
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text('No results yet',
                style: TextStyle(color: Colors.black45, fontSize: 15)),
            const SizedBox(height: 6),
            const Text('Attend an exam to see your results here.',
                style: TextStyle(color: Colors.black26, fontSize: 13)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF4FC3F7),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _results.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _ResultCard(result: _results[i]),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final dynamic result;
  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final examTitle = result['examTitle'] ?? 'Exam';
    final score = result['score'] ?? 0;
    final totalMarks = result['totalMarks'] ?? 0;
    final passingMarks = result['passingMarks'] ?? 0;
    final passed = result['passed'] ?? false;
    final pct =
    totalMarks > 0 ? (score / totalMarks * 100).round() : 0;
    final submittedAt = result['submittedAt'] != null
        ? DateTime.tryParse(result['submittedAt'])
        : null;

    final statusColor =
    passed ? const Color(0xFF66BB6A) : Colors.redAccent;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border:
        Border.all(color: statusColor.withOpacity(0.25), width: 1),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          // Score circle
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: statusColor.withOpacity(0.1),
              border: Border.all(color: statusColor, width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('$pct%',
                    style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(examTitle,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                    '$score / $totalMarks marks  •  Pass: $passingMarks',
                    style: const TextStyle(
                        color: Colors.black45, fontSize: 12)),
                if (submittedAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${submittedAt.day}/${submittedAt.month}/${submittedAt.year}  '
                        '${submittedAt.hour.toString().padLeft(2, '0')}:'
                        '${submittedAt.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                        color: Colors.black38, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              passed ? 'PASSED' : 'FAILED',
              style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}