import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminResultsTab extends StatefulWidget {
  const AdminResultsTab({super.key});

  @override
  State<AdminResultsTab> createState() => _AdminResultsTabState();
}

class _AdminResultsTabState extends State<AdminResultsTab> {
  // Grouped: examTitle -> list of results
  Map<String, List<dynamic>> _grouped = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await ApiService.getAllResults();
    if (!mounted) return;

    // Group by examTitle
    final Map<String, List<dynamic>> grouped = {};
    for (final r in data) {
      final title = r['examTitle'] ?? 'Unknown Exam';
      grouped.putIfAbsent(title, () => []).add(r);
    }

    setState(() {
      _grouped = grouped;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF4FC3F7)));
    }

    if (_grouped.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_outlined,
                size: 64, color: Colors.white.withOpacity(0.15)),
            const SizedBox(height: 12),
            const Text('No results yet',
                style: TextStyle(color: Colors.white38, fontSize: 15)),
            const SizedBox(height: 6),
            const Text('Results will appear here after students submit exams.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white24, fontSize: 12)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF4FC3F7),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: _grouped.entries
            .map((e) => _ExamResultFolder(
          examTitle: e.key,
          results: e.value,
        ))
            .toList(),
      ),
    );
  }
}

// ── Exam Result Folder ────────────────────────────────────────────────────────

class _ExamResultFolder extends StatefulWidget {
  final String examTitle;
  final List<dynamic> results;

  const _ExamResultFolder({
    required this.examTitle,
    required this.results,
  });

  @override
  State<_ExamResultFolder> createState() => _ExamResultFolderState();
}

class _ExamResultFolderState extends State<_ExamResultFolder> {
  bool _expanded = false;

  int get _passCount =>
      widget.results.where((r) => r['passed'] == true).length;
  int get _failCount => widget.results.length - _passCount;
  double get _passPercent => widget.results.isEmpty
      ? 0
      : (_passCount / widget.results.length * 100);

  double get _avgScore {
    if (widget.results.isEmpty) return 0;
    final total = widget.results.fold<num>(
        0, (sum, r) => sum + (r['score'] ?? 0));
    return total / widget.results.length;
  }

  int get _totalMarks =>
      widget.results.isNotEmpty
          ? (widget.results.first['totalMarks'] ?? 0)
          : 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1B3A5C),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: const Color(0xFF4FC3F7).withOpacity(0.2),
            width: 0.8),
      ),
      child: Column(
        children: [
          // Folder header — tap to expand
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4FC3F7).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.folder_outlined,
                            color: Color(0xFF4FC3F7), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.examTitle,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14)),
                            Text(
                                '${widget.results.length} student${widget.results.length == 1 ? '' : 's'} attended',
                                style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 11)),
                          ],
                        ),
                      ),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Colors.white38,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Stats row
                  Row(
                    children: [
                      _StatPill(
                          label: 'Avg',
                          value:
                          '${_avgScore.toStringAsFixed(1)}/$_totalMarks',
                          color: const Color(0xFF4FC3F7)),
                      const SizedBox(width: 8),
                      _StatPill(
                          label: 'Passed',
                          value: '$_passCount',
                          color: const Color(0xFF66BB6A)),
                      const SizedBox(width: 8),
                      _StatPill(
                          label: 'Failed',
                          value: '$_failCount',
                          color: Colors.redAccent),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Pass/fail bar chart
                  _PassFailBar(
                    passPercent: _passPercent,
                    passCount: _passCount,
                    failCount: _failCount,
                  ),
                ],
              ),
            ),
          ),

          // Student list
          if (_expanded) ...[
            const Divider(
                height: 1, color: Colors.white12, thickness: 0.5),
            ...widget.results.map((r) => _StudentResultRow(result: r)),
          ],
        ],
      ),
    );
  }
}

// ── Pass/Fail Bar ─────────────────────────────────────────────────────────────

class _PassFailBar extends StatelessWidget {
  final double passPercent;
  final int passCount;
  final int failCount;

  const _PassFailBar({
    required this.passPercent,
    required this.passCount,
    required this.failCount,
  });

  @override
  Widget build(BuildContext context) {
    final total = passCount + failCount;
    if (total == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pass rate: ${passPercent.toStringAsFixed(1)}%',
              style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w500),
            ),
            Text(
              '$passCount / $total',
              style: const TextStyle(
                  color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 10,
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                final passWidth =
                    constraints.maxWidth * (passPercent / 100);
                final failWidth =
                    constraints.maxWidth - passWidth;
                return Row(
                  children: [
                    if (passWidth > 0)
                      Container(
                        width: passWidth,
                        color: const Color(0xFF66BB6A),
                      ),
                    if (failWidth > 0)
                      Container(
                        width: failWidth,
                        color: Colors.redAccent,
                      ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _Legend(color: const Color(0xFF66BB6A), label: 'Passed'),
            const SizedBox(width: 16),
            _Legend(color: Colors.redAccent, label: 'Failed'),
          ],
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                color: Colors.white38, fontSize: 10)),
      ],
    );
  }
}

// ── Student Result Row ────────────────────────────────────────────────────────

class _StudentResultRow extends StatelessWidget {
  final dynamic result;
  const _StudentResultRow({required this.result});

  @override
  Widget build(BuildContext context) {
    final name = result['studentName'] ?? 'Unknown';
    final score = result['score'] ?? 0;
    final totalMarks = result['totalMarks'] ?? 0;
    final passed = result['passed'] ?? false;
    final pct =
    totalMarks > 0 ? (score / totalMarks * 100).round() : 0;
    final submittedAt = result['submittedAt'] != null
        ? DateTime.tryParse(result['submittedAt'])
        : null;

    final statusColor =
    passed ? const Color(0xFF66BB6A) : Colors.redAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(
            top: BorderSide(color: Colors.white12, width: 0.5)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: statusColor.withOpacity(0.15),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 13)),
                if (submittedAt != null)
                  Text(
                    '${submittedAt.day}/${submittedAt.month}/${submittedAt.year}',
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 11),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$score/$totalMarks',
                style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
              Text(
                '$pct%  •  ${passed ? 'Pass' : 'Fail'}',
                style: TextStyle(
                    color: statusColor.withOpacity(0.7),
                    fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Stat Pill ─────────────────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
                text: '$label: ',
                style: TextStyle(
                    color: color.withOpacity(0.7), fontSize: 11)),
            TextSpan(
                text: value,
                style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}