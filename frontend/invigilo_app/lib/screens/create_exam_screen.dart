import 'package:flutter/material.dart';
import '../models/local_exam_model.dart';
import '../widgets/exam_form_widgets.dart';
import 'add_questions_screen.dart';

class CreateExamScreen extends StatefulWidget {
  final LocalExam? existingExam;

  const CreateExamScreen({super.key, this.existingExam});

  @override
  State<CreateExamScreen> createState() => _CreateExamScreenState();
}

class _CreateExamScreenState extends State<CreateExamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _passingMarksCtrl = TextEditingController();

  bool get _isEdit => widget.existingExam != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _nameCtrl.text = widget.existingExam!.name;
      _dateCtrl.text = widget.existingExam!.date;
      _timeCtrl.text = widget.existingExam!.time;
      _durationCtrl.text = widget.existingExam!.duration;
      _subjectCtrl.text = widget.existingExam!.subject;
      _passingMarksCtrl.text =
          widget.existingExam!.passingMarks.toString();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dateCtrl.dispose();
    _timeCtrl.dispose();
    _durationCtrl.dispose();
    _subjectCtrl.dispose();
    _passingMarksCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF4FC3F7),
            surface: Color(0xFF1B3A5C),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      _dateCtrl.text =
      '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF4FC3F7),
            surface: Color(0xFF1B3A5C),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      final hour =
      picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
      final minute = picked.minute.toString().padLeft(2, '0');
      final period =
      picked.period == DayPeriod.am ? 'AM' : 'PM';
      _timeCtrl.text = '$hour:$minute $period';
    }
  }

  Future<void> _next() async {
    if (!_formKey.currentState!.validate()) return;

    final passingMarks =
        int.tryParse(_passingMarksCtrl.text.trim()) ?? 0;

    final exam = _isEdit
        ? widget.existingExam!.copyWith(
      name: _nameCtrl.text.trim(),
      date: _dateCtrl.text.trim(),
      time: _timeCtrl.text.trim(),
      duration: _durationCtrl.text.trim(),
      subject: _subjectCtrl.text.trim(),
      passingMarks: passingMarks,
    )
        : LocalExam(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text.trim(),
      date: _dateCtrl.text.trim(),
      time: _timeCtrl.text.trim(),
      duration: _durationCtrl.text.trim(),
      subject: _subjectCtrl.text.trim(),
      questions: const [],
      createdAt: DateTime.now().toIso8601String(),
      passingMarks: passingMarks,
      totalMarks: 0,
    );

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) => AddQuestionsScreen(exam: exam)),
    );
    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        title: Text(
          _isEdit ? 'Edit Exam' : 'Create Exam',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
          const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ExamStepIndicator(step: 1, label: 'Exam Details'),
                const SizedBox(height: 24),

                DarkTextField(
                  controller: _nameCtrl,
                  label: 'Exam Name *',
                  icon: Icons.assignment_outlined,
                  validator: (v) =>
                  (v == null || v.trim().isEmpty)
                      ? 'Required'
                      : null,
                ),
                const SizedBox(height: 16),

                DarkTextField(
                  controller: _subjectCtrl,
                  label: 'Subject *',
                  icon: Icons.book_outlined,
                  validator: (v) =>
                  (v == null || v.trim().isEmpty)
                      ? 'Required'
                      : null,
                ),
                const SizedBox(height: 16),

                GestureDetector(
                  onTap: _pickDate,
                  child: AbsorbPointer(
                    child: DarkTextField(
                      controller: _dateCtrl,
                      label: 'Date of Exam *',
                      icon: Icons.calendar_today_outlined,
                      validator: (v) =>
                      (v == null || v.trim().isEmpty)
                          ? 'Required'
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                GestureDetector(
                  onTap: _pickTime,
                  child: AbsorbPointer(
                    child: DarkTextField(
                      controller: _timeCtrl,
                      label: 'Time of Exam *',
                      icon: Icons.access_time_outlined,
                      validator: (v) =>
                      (v == null || v.trim().isEmpty)
                          ? 'Required'
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                DarkTextField(
                  controller: _durationCtrl,
                  label: 'Duration (e.g. 60 mins) *',
                  icon: Icons.timer_outlined,
                  validator: (v) =>
                  (v == null || v.trim().isEmpty)
                      ? 'Required'
                      : null,
                ),
                const SizedBox(height: 16),

                DarkTextField(
                  controller: _passingMarksCtrl,
                  label: 'Passing Marks *',
                  icon: Icons.check_circle_outline,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Required';
                    }
                    if (int.tryParse(v.trim()) == null) {
                      return 'Enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 36),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _next,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4FC3F7),
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Next — Add Questions',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}