const express = require("express");
const router = express.Router();
const resultController = require("../controllers/resultController");
const auth = require("../middleware/authMiddleware");

router.post("/submit", auth, resultController.submitExam);
router.get("/my", auth, resultController.getMyResults);
router.get("/all", auth, resultController.getAllResults); // admin use

module.exports = router;