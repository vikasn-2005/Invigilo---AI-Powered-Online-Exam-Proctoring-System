const Exam = require("../models/Exam");

exports.createExam = async (req, res) => {
  try {
    const { title, subject, duration, date, time, passingMarks, totalMarks } = req.body;

    const exam = new Exam({
      title,
      subject,
      duration,
      date,
      time,
      passingMarks,
      totalMarks,
      createdBy: req.user.id,
    });

    await exam.save();
    res.json(exam);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.getAllExams = async (req, res) => {
  try {
    const exams = await Exam.find().sort({ createdAt: -1 });
    res.json(exams);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.updateExam = async (req, res) => {
  try {
    const exam = await Exam.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!exam) return res.status(404).json({ message: "Exam not found" });
    res.json(exam);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.deleteExam = async (req, res) => {
  try {
    await Exam.findByIdAndDelete(req.params.id);
    res.json({ message: "Exam deleted" });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};