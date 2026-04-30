const express = require("express");
const router = express.Router();
const authController = require("../controllers/authController");
const auth = require("../middleware/authMiddleware");
const upload = require("../middleware/uploadMiddleware");

router.post("/register", authController.register);
router.post("/login", authController.login);
router.get("/profile", auth, authController.getProfile);
router.get("/students", auth, authController.getStudents);
router.post(
  "/upload-profile",
  auth,
  upload.single("profileImage"),
  authController.uploadProfileImage
);

module.exports = router;