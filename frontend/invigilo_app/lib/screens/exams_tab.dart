import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'student_exam_screen.dart';

class ExamsTab extends StatefulWidget {
  const ExamsTab({super.key});

  @override
  State<ExamsTab> createState() => _ExamsTabState();
}

class _ExamsTabState extends State<ExamsTab> {
  List<dynamic> _allExams = [];
  Set<String> _attendedIds = {};
  bool _loading = true;
  String? _error;

  // Refresh every 30 seconds so status badges update live
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _refreshTimer =
        Timer.periodic(const Duration(seconds: 30), (_) => _load());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });

    // Load attended exam IDs from local prefs
    final prefs = await SharedPreferences.getInstance();
    final attended =
        prefs.getStringList('attended_exam_ids') ?? [];

    try {
      final exams = await ApiService.getExams();
      if (mounted) {
        setState(() {
          _allExams = exams;
          _attendedIds = attended.toSet();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not load exams.';
          _loading = false;
        });
      }
    }
  }

  /// Parses exam date + time into a DateTime.
  /// date format: "DD/MM/YYYY", time format: "H:MM AM/PM"
  DateTime? _parseExamDateTime(dynamic exam) {
    try {
      final dateParts =
      (exam['date'] as String).split('/'); // ["DD","MM","YYYY"]
      final timeStr = exam['time'] as String; // "5:10 PM"

      final day = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final year = int.parse(dateParts[2]);

      final timeParts = timeStr.split(' '); // ["5:10", "AM/PM"]
      final hm = timeParts[0].split(':');
      int hour = int.parse(hm[0]);
      final minute = int.parse(hm[1]);
      final isPm = timeParts[1].toUpperCase() == 'PM';

      if (isPm && hour != 12) hour += 12;
      if (!isPm && hour == 12) hour = 0;

      return DateTime(year, month, day, hour, minute);
    } catch (_) {
      return null;
    }
  }

  /// Returns the status of an exam relative to now:
  /// - 'upcoming'  : exam start is in the future
  /// - 'open'      : within the 10-min window (can start)
  /// - 'expired'   : window has passed
  _ExamStatus _getStatus(dynamic exam) {
    final examTime = _parseExamDateTime(exam);
    if (examTime == null) return _ExamStatus.upcoming;

    final now = DateTime.now();
    final windowEnd = examTime.add(const Duration(minutes: 10));

    if (now.isBefore(examTime)) return _ExamStatus.upcoming;
    if (now.isAfter(windowEnd)) return _ExamStatus.expired;
    return _ExamStatus.open;
  }

  List<dynamic> get _visibleExams {
    return _allExams.where((exam) {
      final id = exam['_id'] as String;
      // Hide if already attended
      if (_attendedIds.contains(id)) return false;
      // Hide if expired
      if (_getStatus(exam) == _ExamStatus.expired) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF4FC3F7)));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 56, color: Colors.black26),
            const SizedBox(height: 12),
            Text(_error!,
                style: const TextStyle(color: Colors.black45)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final visible = _visibleExams;

    if (visible.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text('No exams available',
                style:
                TextStyle(color: Colors.black45, fontSize: 15)),
            const SizedBox(height: 6),
            const Text(
              'Attended exams appear in Results.\nExpired exams are no longer shown.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black26, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF4FC3F7),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: visible.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final exam = visible[i];
          final status = _getStatus(exam);
          final examTime = _parseExamDateTime(exam);
          return _ExamCard(
            exam: exam,
            status: status,
            examTime: examTime,
            onAttended: () async {
              // Mark as attended in local prefs
              final prefs = await SharedPreferences.getInstance();
              final list =
                  prefs.getStringList('attended_exam_ids') ?? [];
              list.add(exam['_id'] as String);
              await prefs.setStringList('attended_exam_ids', list);
              _load();
            },
          );
        },
      ),
    );
  }
}

// ── Exam status enum ──────────────────────────────────────────────────────────

enum _ExamStatus { upcoming, open, expired }

// ── Exam Card ─────────────────────────────────────────────────────────────────

class _ExamCard extends StatefulWidget {
  final dynamic exam;
  final _ExamStatus status;
  final DateTime? examTime;
  final VoidCallback onAttended;

  const _ExamCard({
    required this.exam,
    required this.status,
    required this.examTime,
    required this.onAttended,
  });

  @override
  State<_ExamCard> createState() => _ExamCardState();
}

class _ExamCardState extends State<_ExamCard> {
  Timer? _countdownTimer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    // Tick every second for countdown
    _countdownTimer =
        Timer.periodic(const Duration(seconds: 1), (_) {
          if (mounted) setState(() => _updateRemaining());
        });
  }

  void _updateRemaining() {
    if (widget.examTime == null) return;
    final now = DateTime.now();
    if (now.isBefore(widget.examTime!)) {
      _remaining = widget.examTime!.difference(now);
    } else {
      final windowEnd =
      widget.examTime!.add(const Duration(minutes: 10));
      if (now.isBefore(windowEnd)) {
        _remaining = windowEnd.difference(now);
      } else {
        _remaining = Duration.zero;
      }
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  String get _countdownText {
    if (_remaining == Duration.zero) return '';
    final h = _remaining.inHours;
    final m = _remaining.inMinutes % 60;
    final s = _remaining.inSeconds % 60;
    if (h > 0) {
      return '${h}h ${m.toString().padLeft(2, '0')}m';
    }
    if (m > 0) {
      return '${m}m ${s.toString().padLeft(2, '0')}s';
    }
    return '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final exam = widget.exam;
    final title = exam['title'] ?? '';
    final subject = exam['subject'] ?? '';
    final date = exam['date'] ?? '';
    final time = exam['time'] ?? '';
    final duration = exam['duration'] ?? 0;
    final totalMarks = exam['totalMarks'] ?? 0;
    final passingMarks = exam['passingMarks'] ?? 0;

    final isOpen = widget.status == _ExamStatus.open;
    final isUpcoming = widget.status == _ExamStatus.upcoming;

    return Card(
      elevation: 2,
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row + status badge
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFE1F5FE),
                  child:
                  Icon(Icons.assignment, color: Color(0xFF4FC3F7)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                      Text(subject,
                          style: const TextStyle(
                              color: Color(0xFF4FC3F7), fontSize: 12)),
                    ],
                  ),
                ),
                _StatusBadge(status: widget.status),
              ],
            ),
            const SizedBox(height: 12),

            // Info chips
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _Tag(
                    icon: Icons.calendar_today_outlined, label: date),
                _Tag(icon: Icons.access_time_outlined, label: time),
                _Tag(
                    icon: Icons.timer_outlined,
                    label: '$duration mins'),
                _Tag(
                    icon: Icons.star_outline,
                    label: '$totalMarks marks'),
                _Tag(
                    icon: Icons.check_circle_outline,
                    label: 'Pass: $passingMarks'),
              ],
            ),
            const SizedBox(height: 12),

            // Countdown / info line
            if (isUpcoming && _countdownText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    const Icon(Icons.schedule,
                        size: 14, color: Colors.orange),
                    const SizedBox(width: 6),
                    Text(
                      'Starts in $_countdownText',
                      style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),

            if (isOpen && _countdownText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    const Icon(Icons.timer,
                        size: 14, color: Color(0xFF66BB6A)),
                    const SizedBox(width: 6),
                    Text(
                      'Window closes in $_countdownText',
                      style: const TextStyle(
                          color: Color(0xFF66BB6A),
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),

            // Start button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isOpen
                    ? () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          StudentExamScreen(exam: exam),
                    ),
                  );
                  // After returning from exam, mark as attended
                  widget.onAttended();
                }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isOpen
                      ? const Color(0xFF4FC3F7)
                      : Colors.grey.shade200,
                  foregroundColor:
                  isOpen ? Colors.white : Colors.black38,
                  disabledBackgroundColor: Colors.grey.shade100,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  isOpen
                      ? 'Start Exam'
                      : isUpcoming
                      ? 'Not Started Yet'
                      : 'Expired',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Status Badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final _ExamStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status == _ExamStatus.open
        ? const Color(0xFF66BB6A)
        : status == _ExamStatus.upcoming
        ? Colors.orange
        : Colors.grey;

    final label = status == _ExamStatus.open
        ? 'OPEN'
        : status == _ExamStatus.upcoming
        ? 'UPCOMING'
        : 'EXPIRED';

    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold)),
    );
  }
}

// ── Small widgets ─────────────────────────────────────────────────────────────

class _Tag extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Tag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.grey),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.black54, fontSize: 11)),
        ],
      ),
    );
  }
}