const express = require("express");
const router = express.Router();
const ctrl = require("../controllers/eventController");

// POST a new event (AI or manual)
router.post("/", ctrl.createEvent);

// GET all events
router.get("/", ctrl.getEvents);

// GET single event
router.get("/:id", ctrl.getEventById);

// PATCH update status
router.patch("/:id/status", ctrl.updateStatus);

module.exports = router;
