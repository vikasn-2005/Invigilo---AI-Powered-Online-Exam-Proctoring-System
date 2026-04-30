import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

class StudentExamScreen extends StatefulWidget {
  final Map<String, dynamic> exam;

  const StudentExamScreen({super.key, required this.exam});

  @override
  State<StudentExamScreen> createState() => _StudentExamScreenState();
}

class _StudentExamScreenState extends State<StudentExamScreen>
    with WidgetsBindingObserver {
  List<dynamic> _questions = [];
  bool _loading = true;

  // answers: questionId -> { selected: int? (mcq), writtenAnswer: String? }
  final Map<String, Map<String, dynamic>> _answers = {};

  late Timer _timer;
  late int _secondsLeft;
  bool _submitted = false;
  bool _submitting = false;
  Map<String, dynamic>? _result;

  int _violationCount = 0;
  static const int _maxViolations = 3;

  // Safely extract string ID from exam/question object
  String _getId(dynamic obj) {
    if (obj == null) return '';
    final id = obj['_id'];
    if (id == null) return '';
    return id.toString();
  }

  String get _examId => _getId(widget.exam);
  String get _examTitle => widget.exam['title']?.toString() ?? 'Exam';
  int get _durationMinutes =>
      int.tryParse(widget.exam['duration']?.toString() ?? '60') ?? 60;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lockScreen();
    _loadQuestions();
  }

  void _lockScreen() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _unlockScreen() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_submitted &&
        (state == AppLifecycleState.paused ||
            state == AppLifecycleState.inactive)) {
      _recordViolation('app_switch');
    }
  }

  Future<void> _recordViolation(String type) async {
    _violationCount++;

    await ApiService.reportViolation(
      examId: _examId,
      examTitle: _examTitle,
      type: type,
    );

    if (!mounted) return;

    if (_violationCount >= _maxViolations) {
      _showViolationDialog(autoSubmit: true);
    } else {
      _showViolationDialog(autoSubmit: false);
    }
  }

  void _showViolationDialog({required bool autoSubmit}) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1B3A5C),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded,
                color: Colors.redAccent, size: 22),
            SizedBox(width: 8),
            Text('Violation Detected',
                style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: Text(
          autoSubmit
              ? 'You have exceeded the maximum violations ($_maxViolations). Your exam will be submitted automatically.'
              : 'Leaving the exam app is not allowed. Violation $_violationCount/$_maxViolations recorded.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          if (!autoSubmit)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _lockScreen();
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4FC3F7)),
              child: const Text('Return to Exam',
                  style: TextStyle(color: Colors.black87)),
            ),
          if (autoSubmit)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _submitExam(confirmed: true);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent),
              child: const Text('Submit Now'),
            ),
        ],
      ),
    );
  }

  Future<void> _loadQuestions() async {
    final questions = await ApiService.getQuestions(_examId);
    if (!mounted) return;
    setState(() {
      _questions = questions;
      _loading = false;
    });
    _startTimer();
  }

  void _startTimer() {
    _secondsLeft = _durationMinutes * 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          t.cancel();
          _submitExam(confirmed: true);
        }
      });
    });
  }

  String get _timerText {
    final m = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Color get _timerColor {
    if (_secondsLeft <= 60) return Colors.redAccent;
    if (_secondsLeft <= 300) return Colors.orange;
    return const Color(0xFF4FC3F7);
  }

  Future<void> _submitExam({bool confirmed = false}) async {
    if (_submitted || _submitting) return;

    if (!confirmed) {
      final unanswered = _questions.where((q) {
        final qId = _getId(q);
        final ans = _answers[qId];
        if (q['type'] == 'mcq') {
          return ans == null || ans['selected'] == null;
        }
        return ans == null ||
            (ans['writtenAnswer'] as String? ?? '').trim().isEmpty;
      }).length;

      final ok = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF1B3A5C),
          title: const Text('Submit Exam',
              style: TextStyle(color: Colors.white)),
          content: Text(
            unanswered > 0
                ? '$unanswered question${unanswered == 1 ? '' : 's'} unanswered. Submit anyway?'
                : 'Are you sure you want to submit?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4FC3F7)),
              child: const Text('Submit',
                  style: TextStyle(color: Colors.black87)),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }

    _timer.cancel();
    setState(() => _submitting = true);

    // Build answers payload — use string IDs explicitly
    final answersPayload = _questions.map((q) {
      final qId = _getId(q);
      final ans = _answers[qId];
      return {
        'questionId': qId,
        'selected': ans?['selected'],
        'writtenAnswer': ans?['writtenAnswer'],
      };
    }).toList();

    final result = await ApiService.submitExam(
      examId: _examId,
      answers: answersPayload,
    );

    setState(() {
      _submitting = false;
      _submitted = true;
      _result = result;
    });

    _unlockScreen();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (!_submitted) {
      try { _timer.cancel(); } catch (_) {}
    }
    _unlockScreen();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return _ResultScreen(
        result: _result,
        examTitle: _examTitle,
        violationCount: _violationCount,
      );
    }

    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D1B2A),
        body: Center(
            child: CircularProgressIndicator(color: Color(0xFF4FC3F7))),
      );
    }

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          automaticallyImplyLeading: false,
          elevation: 1,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_examTitle,
                  style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              Text(
                  '${_answers.length}/${_questions.length} answered',
                  style: const TextStyle(
                      color: Colors.black45, fontSize: 11)),
            ],
          ),
          actions: [
            if (_violationCount > 0)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: Colors.redAccent.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Colors.redAccent, size: 14),
                    const SizedBox(width: 4),
                    Text('$_violationCount/$_maxViolations',
                        style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _timerColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _timerText,
                style: TextStyle(
                    color: _timerColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15),
              ),
            ),
          ],
        ),
        body: _submitting
            ? const Center(
            child: CircularProgressIndicator(
                color: Color(0xFF4FC3F7)))
            : ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          itemCount: _questions.length,
          separatorBuilder: (_, __) =>
          const SizedBox(height: 16),
          itemBuilder: (_, i) {
            final q = _questions[i];
            final qId = _getId(q);
            if (q['type'] == 'mcq') {
              return _McqCard(
                index: i,
                question: q,
                selectedIndex:
                _answers[qId]?['selected'] as int?,
                onSelect: (val) => setState(
                        () => _answers[qId] = {'selected': val}),
              );
            } else {
              return _AnswerableCard(
                index: i,
                question: q,
                answer: _answers[qId]?['writtenAnswer']
                as String?,
                onChanged: (val) => setState(() =>
                _answers[qId] = {'writtenAnswer': val}),
              );
            }
          },
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed:
                _submitting ? null : () => _submitExam(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4FC3F7),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Submit Exam',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── MCQ Card ──────────────────────────────────────────────────────────────────

class _McqCard extends StatelessWidget {
  final int index;
  final dynamic question;
  final int? selectedIndex;
  final ValueChanged<int> onSelect;

  const _McqCard({
    required this.index,
    required this.question,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final options = List<String>.from(question['options'] ?? []);
    final marks = question['marks'] ?? 1;
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: selectedIndex != null
                      ? const Color(0xFF4FC3F7)
                      : const Color(0xFFE1F5FE),
                  child: Text('${index + 1}',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: selectedIndex != null
                              ? Colors.white
                              : const Color(0xFF4FC3F7))),
                ),
                const SizedBox(width: 8),
                const Text('MCQ',
                    style: TextStyle(
                        color: Color(0xFF4FC3F7),
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                      '$marks mark${marks == 1 ? '' : 's'}',
                      style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(question['question'] ?? '',
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.black87)),
            const SizedBox(height: 12),
            ...List.generate(options.length, (i) {
              const labels = ['A', 'B', 'C', 'D'];
              final label =
              i < labels.length ? labels[i] : '${i + 1}';
              final isSelected = selectedIndex == i;
              return GestureDetector(
                onTap: () => onSelect(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFE1F5FE)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF4FC3F7)
                          : Colors.grey.shade200,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? const Color(0xFF4FC3F7)
                              : Colors.white,
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF4FC3F7)
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(label,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(options[i],
                            style: TextStyle(
                                color: isSelected
                                    ? const Color(0xFF0277BD)
                                    : Colors.black87,
                                fontWeight: isSelected
                                    ? FontWeight.w500
                                    : FontWeight.normal)),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Answerable Card ───────────────────────────────────────────────────────────

class _AnswerableCard extends StatefulWidget {
  final int index;
  final dynamic question;
  final String? answer;
  final ValueChanged<String> onChanged;

  const _AnswerableCard({
    required this.index,
    required this.question,
    required this.answer,
    required this.onChanged,
  });

  @override
  State<_AnswerableCard> createState() => _AnswerableCardState();
}

class _AnswerableCardState extends State<_AnswerableCard> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.answer ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasText = (widget.answer ?? '').trim().isNotEmpty;
    final marks = widget.question['marks'] ?? 1;
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: hasText
                      ? const Color(0xFF66BB6A)
                      : const Color(0xFFE8F5E9),
                  child: Text('${widget.index + 1}',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: hasText
                              ? Colors.white
                              : const Color(0xFF66BB6A))),
                ),
                const SizedBox(width: 8),
                const Text('Answerable',
                    style: TextStyle(
                        color: Color(0xFF66BB6A),
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                      '$marks mark${marks == 1 ? '' : 's'}',
                      style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(widget.question['question'] ?? '',
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.black87)),
            const SizedBox(height: 12),
            TextField(
              controller: _ctrl,
              maxLines: 4,
              onChanged: widget.onChanged,
              decoration: InputDecoration(
                hintText: 'Type your answer here...',
                hintStyle:
                const TextStyle(color: Colors.black26),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                  BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                      color: Color(0xFF66BB6A)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Result Screen ─────────────────────────────────────────────────────────────

class _ResultScreen extends StatelessWidget {
  final Map<String, dynamic>? result;
  final String examTitle;
  final int violationCount;

  const _ResultScreen({
    required this.result,
    required this.examTitle,
    required this.violationCount,
  });

  @override
  Widget build(BuildContext context) {
    if (result == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 64, color: Colors.redAccent),
              const SizedBox(height: 16),
              const Text('Failed to submit exam.',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Please contact your admin.',
                  style: TextStyle(color: Colors.black45)),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.of(context)
                    .popUntil((r) => r.isFirst),
                child: const Text('Back to Dashboard'),
              ),
            ],
          ),
        ),
      );
    }

    final score = result!['score'] ?? 0;
    final totalMarks = result!['totalMarks'] ?? 0;
    final passingMarks = result!['passingMarks'] ?? 0;
    final passed = result!['passed'] ?? false;
    final pct =
    totalMarks > 0 ? (score / totalMarks * 100).round() : 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 0,
        title: const Text('Exam Submitted',
            style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 12),
            CircleAvatar(
              radius: 48,
              backgroundColor: (passed
                  ? const Color(0xFF66BB6A)
                  : Colors.redAccent)
                  .withOpacity(0.12),
              child: Icon(
                passed ? Icons.check_circle : Icons.cancel,
                size: 52,
                color: passed
                    ? const Color(0xFF66BB6A)
                    : Colors.redAccent,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              passed ? 'Well Done!' : 'Better Luck Next Time',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: passed
                      ? const Color(0xFF66BB6A)
                      : Colors.redAccent),
            ),
            const SizedBox(height: 6),
            Text(examTitle,
                style: const TextStyle(
                    color: Colors.black45, fontSize: 14)),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Text('$score / $totalMarks',
                      style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4FC3F7))),
                  Text('Score ($pct%)',
                      style: const TextStyle(
                          color: Colors.black45, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text('Passing marks: $passingMarks',
                      style: const TextStyle(
                          color: Colors.black38, fontSize: 12)),
                ],
              ),
            ),
            if (violationCount > 0) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: Colors.redAccent.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Colors.redAccent, size: 18),
                    const SizedBox(width: 8),
                    Text(
                        '$violationCount violation${violationCount == 1 ? '' : 's'} recorded during this exam.',
                        style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 13)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context)
                    .popUntil((r) => r.isFirst),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4FC3F7),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Back to Dashboard',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}