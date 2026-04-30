const express = require("express");
const router = express.Router();
const questionController = require("../controllers/questionController");
const auth = require("../middleware/authMiddleware");

router.get("/:examId", questionController.getQuestionsByExam);
router.post("/add", auth, questionController.addQuestion);
router.post("/bulk", auth, questionController.bulkAddQuestions);
router.put("/:id", auth, questionController.updateQuestion);
router.delete("/:id", auth, questionController.deleteQuestion);

module.exports = router;