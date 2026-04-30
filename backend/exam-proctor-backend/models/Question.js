const mongoose = require("mongoose");

const questionSchema = new mongoose.Schema({
  examId: { type: mongoose.Schema.Types.ObjectId, ref: "Exam", required: true },
  question: { type: String, required: true },
  type: { type: String, enum: ["mcq", "answerable"], default: "mcq" },
  options: [{ type: String }], // for MCQ only
  correctAnswer: { type: Number }, // index 0-3, for MCQ only
  modelAnswer: { type: String }, // for answerable, admin reference only
  marks: { type: Number, required: true, default: 1 },
});

module.exports = mongoose.model("Question", questionSchema);