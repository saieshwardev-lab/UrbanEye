// src/routes/v1/jobs.js
const express = require('express');
const router = express.Router();
const ProcessingJob = require('#models/processingJob');
const Incident = require('#models/incident');

// worker posts result for jobId
router.post('/:id/result', async (req, res) => {
  try {
    const jobId = req.params.id;
    const { status = 'done', resultJson = {}, outputUrl } = req.body;

    const job = await ProcessingJob.findById(jobId);
    if (!job) return res.status(404).json({ error: 'job not found' });

    job.status = status;
    job.resultJson = resultJson;
    if (outputUrl) job.outputUrl = outputUrl;
    await job.save();

    // Optionally update incident status if job done
    if (status === 'done') {
      await Incident.findByIdAndUpdate(job.incidentId, { status: 'processing' });
    }

    // Emit job:updated (so frontend updates)
    const io = req.app && req.app.get('io');
    if (io) io.emit('job:updated', { job });

    res.json({ ok: true, job });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'server error' });
  }
});

module.exports = router;
