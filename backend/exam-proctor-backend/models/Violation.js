const mongoose = require("mongoose");

const violationSchema = new mongoose.Schema({
  studentId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
  studentName: { type: String, required: true },
  examId: { type: mongoose.Schema.Types.ObjectId, ref: "Exam", required: true },
  examTitle: { type: String, required: true },
  type: { type: String, required: true }, // e.g. "app_switch", "screenshot_attempt"
  timestamp: { type: Date, default: Date.now },
});

module.exports = mongoose.model("Violation", violationSchema);