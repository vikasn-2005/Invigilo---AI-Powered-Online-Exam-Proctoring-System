import 'package:flutter/material.dart';
import '../models/local_exam_model.dart';
import '../services/api_service.dart';
import '../widgets/exam_form_widgets.dart';

class AddQuestionsScreen extends StatefulWidget {
  final LocalExam exam;

  const AddQuestionsScreen({super.key, required this.exam});

  @override
  State<AddQuestionsScreen> createState() => _AddQuestionsScreenState();
}

class _AddQuestionsScreenState extends State<AddQuestionsScreen> {
  late List<LocalQuestion> _questions;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _questions = List.from(widget.exam.questions);
  }

  int get _totalMarks =>
      _questions.fold(0, (sum, q) => sum + q.marks);

  void _openQuestionForm({LocalQuestion? existing}) async {
    final result = await showModalBottomSheet<LocalQuestion>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D1B2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _QuestionFormSheet(existing: existing),
    );

    if (result != null) {
      setState(() {
        final idx = _questions.indexWhere((q) => q.id == result.id);
        if (idx >= 0) {
          _questions[idx] = result;
        } else {
          _questions.add(result);
        }
      });
    }
  }

  void _deleteQuestion(String id) {
    setState(() => _questions.removeWhere((q) => q.id == id));
  }

  Future<void> _createExam() async {
    if (_questions.isEmpty) {
      _snack('Add at least one question before creating the exam.',
          Colors.redAccent);
      return;
    }

    final passingMarks = widget.exam.passingMarks;
    if (passingMarks > _totalMarks) {
      _snack(
          'Passing marks ($passingMarks) cannot exceed total marks ($_totalMarks).',
          Colors.orange);
      return;
    }

    setState(() => _saving = true);

    // Parse duration — strip non-numeric chars, default 60
    final durationInt = int.tryParse(
        widget.exam.duration.replaceAll(RegExp(r'[^0-9]'), '')) ??
        60;

    // 1. Create exam on backend
    final createdExam = await ApiService.createExam(
      title: widget.exam.name,
      subject: widget.exam.subject,
      duration: durationInt,
      date: widget.exam.date,
      time: widget.exam.time,
      passingMarks: passingMarks,
      totalMarks: _totalMarks,
    );

    if (createdExam == null) {
      setState(() => _saving = false);
      _snack('Failed to create exam. Check your connection.', Colors.redAccent);
      return;
    }

    // 2. Bulk add questions to backend
    final examId = createdExam['_id'];
    final questionsPayload = _questions
        .map((q) => {
      'examId': examId,
      'question': q.text,
      'type': q.type,
      'options': q.options,
      'correctAnswer': q.correctOptionIndex,
      'modelAnswer': q.modelAnswer,
      'marks': q.marks,
    })
        .toList();

    final ok = await ApiService.bulkAddQuestions(questionsPayload);
    setState(() => _saving = false);

    if (!ok) {
      _snack('Exam created but questions failed to save.', Colors.orange);
      return;
    }

    _snack('Exam created successfully!', const Color(0xFF66BB6A));
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) Navigator.of(context).pop(true);
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add Questions',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            Text(widget.exam.name,
                style:
                const TextStyle(color: Colors.white54, fontSize: 11)),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                const ExamStepIndicator(step: 2, label: 'Questions'),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Total: $_totalMarks marks',
                      style: const TextStyle(
                          color: Color(0xFF4FC3F7),
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                    Text(
                      'Passing: ${widget.exam.passingMarks} marks',
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 11),
                    ),
                    Text(
                      '${_questions.length} question${_questions.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (widget.exam.passingMarks > _totalMarks &&
              _questions.isNotEmpty)
            Container(
              margin:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border:
                Border.all(color: Colors.orange.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_outlined,
                      color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Passing marks (${widget.exam.passingMarks}) exceed current total ($_totalMarks).',
                      style: const TextStyle(
                          color: Colors.orange, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: _questions.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.quiz_outlined,
                      size: 64,
                      color: Colors.white.withOpacity(0.15)),
                  const SizedBox(height: 12),
                  const Text('No questions yet',
                      style: TextStyle(
                          color: Colors.white38, fontSize: 15)),
                  const SizedBox(height: 6),
                  const Text('Tap "+" to add your first question',
                      style: TextStyle(
                          color: Colors.white24, fontSize: 12)),
                ],
              ),
            )
                : ListView.separated(
              padding:
              const EdgeInsets.fromLTRB(16, 8, 16, 120),
              itemCount: _questions.length,
              separatorBuilder: (_, __) =>
              const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final q = _questions[i];
                return _QuestionCard(
                  index: i + 1,
                  question: q,
                  onEdit: () => _openQuestionForm(existing: q),
                  onDelete: () => _deleteQuestion(q.id),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openQuestionForm(),
        backgroundColor: const Color(0xFF4FC3F7),
        foregroundColor: Colors.black87,
        icon: const Icon(Icons.add),
        label: const Text('Add Question',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: SizedBox(
            height: 50,
            child: _saving
                ? const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFF66BB6A)))
                : ElevatedButton.icon(
              onPressed: _createExam,
              icon: const Icon(Icons.cloud_upload_outlined),
              label: const Text(
                'Create Exam',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF66BB6A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Question Card ─────────────────────────────────────────────────────────────

class _QuestionCard extends StatelessWidget {
  final int index;
  final LocalQuestion question;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _QuestionCard({
    required this.index,
    required this.question,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isMcq = question.type == 'mcq';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1B3A5C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isMcq
                ? const Color(0xFF4FC3F7).withOpacity(0.3)
                : const Color(0xFF66BB6A).withOpacity(0.3),
            width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isMcq
                      ? const Color(0xFF4FC3F7)
                      : const Color(0xFF66BB6A))
                      .withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Q$index • ${isMcq ? 'MCQ' : 'Answerable'}',
                  style: TextStyle(
                    color: isMcq
                        ? const Color(0xFF4FC3F7)
                        : const Color(0xFF66BB6A),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${question.marks} mark${question.marks == 1 ? '' : 's'}',
                  style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.edit_outlined,
                    color: Colors.white54, size: 18),
                onPressed: onEdit,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: Colors.redAccent, size: 18),
                onPressed: onDelete,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(question.text,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 14)),
          if (isMcq && question.options != null) ...[
            const SizedBox(height: 10),
            ...List.generate(question.options!.length, (i) {
              final isCorrect = i == question.correctOptionIndex;
              final label = ['A', 'B', 'C', 'D'][i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCorrect
                            ? const Color(0xFF66BB6A).withOpacity(0.2)
                            : Colors.white.withOpacity(0.07),
                        border: Border.all(
                          color: isCorrect
                              ? const Color(0xFF66BB6A)
                              : Colors.white24,
                        ),
                      ),
                      child: Text(label,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isCorrect
                                  ? const Color(0xFF66BB6A)
                                  : Colors.white38)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        question.options![i],
                        style: TextStyle(
                          color: isCorrect
                              ? const Color(0xFF66BB6A)
                              : Colors.white60,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (isCorrect)
                      const Icon(Icons.check_circle,
                          color: Color(0xFF66BB6A), size: 14),
                  ],
                ),
              );
            }),
          ],
          if (!isMcq &&
              question.modelAnswer != null &&
              question.modelAnswer!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.lightbulb_outline,
                    color: Colors.amber, size: 13),
                const SizedBox(width: 4),
                Expanded(
                  child: Text('Model answer: ${question.modelAnswer}',
                      style: const TextStyle(
                          color: Colors.amber, fontSize: 12)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Question Form Bottom Sheet ────────────────────────────────────────────────

class _QuestionFormSheet extends StatefulWidget {
  final LocalQuestion? existing;
  const _QuestionFormSheet({this.existing});

  @override
  State<_QuestionFormSheet> createState() => _QuestionFormSheetState();
}

class _QuestionFormSheetState extends State<_QuestionFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _questionCtrl = TextEditingController();
  final _modelAnswerCtrl = TextEditingController();
  final _marksCtrl = TextEditingController(text: '1');
  final List<TextEditingController> _optionCtrls =
  List.generate(4, (_) => TextEditingController());

  String _type = 'mcq';
  int _correctIndex = 0;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final q = widget.existing!;
      _questionCtrl.text = q.text;
      _type = q.type;
      _marksCtrl.text = '${q.marks}';
      if (q.type == 'mcq' && q.options != null) {
        for (int i = 0; i < q.options!.length && i < 4; i++) {
          _optionCtrls[i].text = q.options![i];
        }
        _correctIndex = q.correctOptionIndex ?? 0;
      }
      if (q.type == 'answerable' && q.modelAnswer != null) {
        _modelAnswerCtrl.text = q.modelAnswer!;
      }
    }
  }

  @override
  void dispose() {
    _questionCtrl.dispose();
    _modelAnswerCtrl.dispose();
    _marksCtrl.dispose();
    for (final c in _optionCtrls) c.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final question = LocalQuestion(
      id: _isEdit
          ? widget.existing!.id
          : DateTime.now().microsecondsSinceEpoch.toString(),
      text: _questionCtrl.text.trim(),
      type: _type,
      marks: int.tryParse(_marksCtrl.text.trim()) ?? 1,
      options: _type == 'mcq'
          ? _optionCtrls.map((c) => c.text.trim()).toList()
          : null,
      correctOptionIndex: _type == 'mcq' ? _correctIndex : null,
      modelAnswer: _type == 'answerable' &&
          _modelAnswerCtrl.text.trim().isNotEmpty
          ? _modelAnswerCtrl.text.trim()
          : null,
    );

    Navigator.pop(context, question);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _isEdit ? 'Edit Question' : 'Add Question',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              DarkTextField(
                controller: _questionCtrl,
                label: 'Question *',
                icon: Icons.help_outline,
                maxLines: 3,
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),

              DarkTextField(
                controller: _marksCtrl,
                label: 'Marks *',
                icon: Icons.star_outline,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  final n = int.tryParse(v.trim());
                  if (n == null || n < 1) return 'Enter a valid number ≥ 1';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              const Text('Question Type',
                  style:
                  TextStyle(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _TypeChip(
                    label: 'MCQ',
                    icon: Icons.radio_button_checked,
                    selected: _type == 'mcq',
                    onTap: () => setState(() => _type = 'mcq'),
                  ),
                  const SizedBox(width: 12),
                  _TypeChip(
                    label: 'Answerable',
                    icon: Icons.text_fields,
                    selected: _type == 'answerable',
                    onTap: () => setState(() => _type = 'answerable'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (_type == 'mcq') ...[
                const Text('Options & Correct Answer',
                    style: TextStyle(
                        color: Colors.white54, fontSize: 13)),
                const Text(
                  '(Select the radio button for the correct answer)',
                  style: TextStyle(color: Colors.white24, fontSize: 11),
                ),
                const SizedBox(height: 10),
                ...List.generate(4, (i) {
                  final label = ['A', 'B', 'C', 'D'][i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Radio<int>(
                          value: i,
                          groupValue: _correctIndex,
                          activeColor: const Color(0xFF66BB6A),
                          onChanged: (v) =>
                              setState(() => _correctIndex = v!),
                        ),
                        Expanded(
                          child: TextFormField(
                            controller: _optionCtrls[i],
                            style:
                            const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Option $label *',
                              labelStyle: const TextStyle(
                                  color: Colors.white54),
                              prefixText: '$label. ',
                              prefixStyle: TextStyle(
                                color: i == _correctIndex
                                    ? const Color(0xFF66BB6A)
                                    : const Color(0xFF4FC3F7),
                                fontWeight: FontWeight.bold,
                              ),
                              filled: true,
                              fillColor: i == _correctIndex
                                  ? const Color(0xFF66BB6A)
                                  .withOpacity(0.1)
                                  : const Color(0xFF1B3A5C),
                              border: OutlineInputBorder(
                                  borderRadius:
                                  BorderRadius.circular(8),
                                  borderSide: BorderSide.none),
                              focusedBorder: OutlineInputBorder(
                                borderRadius:
                                BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: i == _correctIndex
                                      ? const Color(0xFF66BB6A)
                                      : const Color(0xFF4FC3F7),
                                ),
                              ),
                              errorStyle: const TextStyle(
                                  color: Colors.redAccent),
                            ),
                            validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Required'
                                : null,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color:
                    const Color(0xFF66BB6A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: const Color(0xFF66BB6A)
                            .withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_outline,
                          color: Color(0xFF66BB6A), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Correct answer (Option ${['A', 'B', 'C', 'D'][_correctIndex]}) is hidden from students',
                          style: const TextStyle(
                              color: Color(0xFF66BB6A), fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (_type == 'answerable') ...[
                DarkTextField(
                  controller: _modelAnswerCtrl,
                  label: 'Model Answer (optional, admin only)',
                  icon: Icons.lightbulb_outline,
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.amber, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Students will type their answer. Model answer is admin-only.',
                          style: TextStyle(
                              color: Colors.amber, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4FC3F7),
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    _isEdit ? 'Update Question' : 'Add Question',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF4FC3F7).withOpacity(0.15)
              : const Color(0xFF1B3A5C),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color:
            selected ? const Color(0xFF4FC3F7) : Colors.white24,
            width: selected ? 1.5 : 0.8,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 16,
                color: selected
                    ? const Color(0xFF4FC3F7)
                    : Colors.white38),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: selected
                        ? const Color(0xFF4FC3F7)
                        : Colors.white38,
                    fontWeight: selected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }
}