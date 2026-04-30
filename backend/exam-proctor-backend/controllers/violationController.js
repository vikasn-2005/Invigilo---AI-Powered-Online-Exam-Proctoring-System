const Violation = require("../models/Violation");
const User = require("../models/User");

exports.reportViolation = async (req, res) => {
  try {
    const { examId, examTitle, type } = req.body;
    const user = await User.findById(req.user.id);

    const violation = new Violation({
      studentId: req.user.id,
      studentName: user.name,
      examId,
      examTitle,
      type,
    });

    await violation.save();
    res.json({ message: "Violation recorded" });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.getMyViolations = async (req, res) => {
  try {
    const violations = await Violation.find({
      studentId: req.user.id,
    }).sort({ timestamp: -1 });
    res.json(violations);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Admin: get all violations — filter by studentId if provided
exports.getAllViolations = async (req, res) => {
  try {
    const filter = {};
    if (req.query.studentId) filter.studentId = req.query.studentId;
    const violations = await Violation.find(filter).sort({
      timestamp: -1,
    });
    res.json(violations);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};