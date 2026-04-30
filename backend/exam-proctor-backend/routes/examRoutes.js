const express = require("express");
const router = express.Router();
const examController = require("../controllers/examController");
const auth = require("../middleware/authMiddleware");

router.get("/", examController.getAllExams);
router.post("/create", auth, examController.createExam);
router.put("/:id", auth, examController.updateExam);
router.delete("/:id", auth, examController.deleteExam);

module.exports = router;