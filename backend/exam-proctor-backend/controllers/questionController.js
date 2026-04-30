const Question = require("../models/Question");

exports.addQuestion = async (req, res) => {
  try {
    const { examId, question, type, options, correctAnswer, modelAnswer, marks } = req.body;

    const newQuestion = new Question({
      examId,
      question,
      type,
      options,
      correctAnswer,
      modelAnswer,
      marks,
    });

    await newQuestion.save();
    res.json(newQuestion);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.getQuestionsByExam = async (req, res) => {
  try {
    const questions = await Question.find({ examId: req.params.examId });
    res.json(questions);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.updateQuestion = async (req, res) => {
  try {
    const question = await Question.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!question) return res.status(404).json({ message: "Question not found" });
    res.json(question);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.deleteQuestion = async (req, res) => {
  try {
    await Question.findByIdAndDelete(req.params.id);
    res.json({ message: "Question deleted" });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.bulkAddQuestions = async (req, res) => {
  try {
    const { questions } = req.body; // array of question objects
    const saved = await Question.insertMany(questions);
    res.json(saved);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};