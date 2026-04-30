const Question = require("../models/Question");
const Result = require("../models/Result");
const Exam = require("../models/Exam");
const User = require("../models/User");

exports.submitExam = async (req, res) => {
  try {
    const { examId, answers } = req.body;
    const exam = await Exam.findById(examId);
    if (!exam) return res.status(404).json({ message: "Exam not found" });
    const user = await User.findById(req.user.id);

    let score = 0;
    for (const ans of answers) {
      const question = await Question.findById(ans.questionId);
      if (!question) continue;
      if (
        question.type === "mcq" &&
        ans.selected !== undefined &&
        ans.selected !== null
      ) {
        if (question.correctAnswer === ans.selected) {
          score += question.marks;
        }
      }
    }

    const passed = score >= exam.passingMarks;

    const result = new Result({
      studentId: req.user.id,
      studentName: user.name,
      examId,
      examTitle: exam.title,
      answers,
      score,
      totalMarks: exam.totalMarks,
      passingMarks: exam.passingMarks,
      passed,
    });

    await result.save();

    res.json({
      message: "Exam submitted",
      score,
      totalMarks: exam.totalMarks,
      passingMarks: exam.passingMarks,
      passed,
      examTitle: exam.title,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.getMyResults = async (req, res) => {
  try {
    const results = await Result.find({ studentId: req.user.id }).sort({
      submittedAt: -1,
    });
    res.json(results);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Admin: filter by examId and/or studentId
exports.getAllResults = async (req, res) => {
  try {
    const filter = {};
    if (req.query.examId) filter.examId = req.query.examId;
    if (req.query.studentId) filter.studentId = req.query.studentId;
    const results = await Result.find(filter).sort({ submittedAt: -1 });
    res.json(results);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};