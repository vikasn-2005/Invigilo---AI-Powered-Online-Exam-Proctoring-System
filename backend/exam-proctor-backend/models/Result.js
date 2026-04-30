const mongoose = require("mongoose");

const resultSchema = new mongoose.Schema({
  studentId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
  studentName: { type: String, required: true },
  examId: { type: mongoose.Schema.Types.ObjectId, ref: "Exam", required: true },
  examTitle: { type: String, required: true },
  answers: [
    {
      questionId: String,
      selected: Number,       // for MCQ: option index
      writtenAnswer: String,  // for answerable
    },
  ],
  score: { type: Number, required: true },
  totalMarks: { type: Number, required: true },
  passingMarks: { type: Number, required: true },
  passed: { type: Boolean, required: true },
  submittedAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model("Result", resultSchema);