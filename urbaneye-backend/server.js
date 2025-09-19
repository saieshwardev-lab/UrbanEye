const express = require("express");
const mongoose = require("mongoose");
const dotenv = require("dotenv");
const cors = require("cors");

dotenv.config();
const app = express();
app.use(express.json()); // parse JSON bodies
app.use(cors());        // allow cross-origin requests

// Basic route
app.get("/", (req, res) => res.send("UrbanEye Backend Running 🚀"));

// Connect to MongoDB
mongoose.connect(process.env.MONGO_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true
})
.then(() => console.log("MongoDB Connected ✅"))
.catch(err => {
  console.error("MongoDB connection error:", err.message);
  process.exit(1);
});

// Mount routes (we'll add them next)
const eventRoutes = require("./routes/eventRoutes");
app.use("/api/events", eventRoutes);

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Server listening on port ${PORT}`));
