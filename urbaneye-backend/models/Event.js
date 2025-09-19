const mongoose = require("mongoose");

const EventSchema = new mongoose.Schema({
  type: { type: String, required: true },         // pothole, garbage, theft, etc.
  cctv_id: { type: String },                      // which camera (optional)
  location: {
    lat: { type: Number },
    lng: { type: Number }
  },
  timestamp: { type: Date, default: Date.now },
  image_url: { type: String },                    // URL to image evidence
  confidence: { type: Number },                   // model confidence 0..1
  status: { type: String, default: "new" },       // new, in-progress, resolved
  extra: { type: mongoose.Schema.Types.Mixed }    // any extra JSON
});

module.exports = mongoose.model("Event", EventSchema);
