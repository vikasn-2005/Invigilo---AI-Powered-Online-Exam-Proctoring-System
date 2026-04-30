const mongoose = require("mongoose");

const attemptSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    required: true
  },
  examId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Exam",
    required: true
  },
  startTime: {
    type: Date,
    default: Date.now
  },
  endTime: Date,
  score: Number,
  malpracticeCount: {
    type: Number,
    default: 0
  }
});

module.exports = mongoose.model("Attempt", attemptSchema);