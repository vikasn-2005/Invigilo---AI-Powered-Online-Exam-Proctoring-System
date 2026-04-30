const mongoose = require("mongoose");

const userSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
  },
  email: {
    type: String,
    required: true,
    unique: true,
  },
  password: {
    type: String,
    required: true,
  },
  role: {
    type: String,
    enum: ["student", "admin"],
    default: "student",
  },
  profileImage: {
    type: String,
    default: null, // stores filename e.g. "profile-64abc123.jpg"
  },
});

module.exports = mongoose.model("User", userSchema);