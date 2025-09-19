const Event = require("../models/Event");

// Create (POST /api/events)
exports.createEvent = async (req, res) => {
  try {
    const { type, cctv_id, location, image_url, confidence, extra } = req.body;
    const ev = new Event({ type, cctv_id, location, image_url, confidence, extra });
    const saved = await ev.save();
    return res.status(201).json(saved);
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: "Server error" });
  }
};

// List (GET /api/events)
exports.getEvents = async (req, res) => {
  try {
    const events = await Event.find().sort({ timestamp: -1 }).limit(200);
    return res.json(events);
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: "Server error" });
  }
};

// Get single (GET /api/events/:id)
exports.getEventById = async (req, res) => {
  try {
    const ev = await Event.findById(req.params.id);
    if (!ev) return res.status(404).json({ message: "Not found" });
    return res.json(ev);
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: "Server error" });
  }
};

// Update status (PATCH /api/events/:id/status)
exports.updateStatus = async (req, res) => {
  try {
    const { status } = req.body;
    const ev = await Event.findByIdAndUpdate(req.params.id, { status }, { new: true });
    if (!ev) return res.status(404).json({ message: "Not found" });
    return res.json(ev);
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: "Server error" });
  }
};
