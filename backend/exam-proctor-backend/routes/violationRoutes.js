const express = require("express");
const router = express.Router();
const violationController = require("../controllers/violationController");
const auth = require("../middleware/authMiddleware");

router.post("/report", auth, violationController.reportViolation);
router.get("/my", auth, violationController.getMyViolations);
router.get("/all", auth, violationController.getAllViolations); // admin use

module.exports = router;