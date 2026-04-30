const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");
const path = require("path");
require("dotenv").config();

const app = express();

app.use(cors());
app.use(express.json());

// Serve uploaded profile images as static files
// Access via: http://10.0.2.2:5000/uploads/profiles/<filename>
app.use("/uploads", express.static(path.join(__dirname, "uploads")));

// Routes
app.use("/api/auth", require("./routes/authRoutes"));
app.use("/api/exams", require("./routes/examRoutes"));
app.use("/api/questions", require("./routes/questionRoutes"));
app.use("/api/results", require("./routes/resultRoutes"));
app.use("/api/violations", require("./routes/violationRoutes"));

app.get("/", (req, res) => {
  res.send("Exam Proctoring API Running");
});

mongoose
  .connect(process.env.MONGO_URI)
  .then(() => {
    console.log("MongoDB Connected");
    const PORT = process.env.PORT || 5000;
    app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
  })
  .catch((err) => console.log(err));