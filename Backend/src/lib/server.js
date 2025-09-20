require('express-async-errors');
const express = require("express");
const cors = require('cors');
const morgan = require('morgan');
const cookieParser = require("cookie-parser");
const xss = require('xss-clean');
const hpp = require('hpp');
const bodyParser = require('body-parser');
const rateLimit = require('express-rate-limit');
const helmet = require('helmet');
const swaggerUi = require('swagger-ui-express');
const fileUpload = require("express-fileupload");
const http = require('http');
const { Server } = require('socket.io');
const path = require('path');

const app = express();

const swaggerFile = require('../../swagger-output.json');

const v1routes = require('#routes/v1/v1');
const uploadController = require('../controllers/upload');

// --- Security & middleware (preserve existing behavior) --- //
app.use(helmet({
  crossOriginEmbedderPolicy: false,
}));
app.use(helmet.crossOriginResourcePolicy({ policy: "cross-origin" }));

app.use(cors({ origin: '*' }));

const limiter = rateLimit({
  max: 150,
  windowMs: 60 * 60 * 1000,
  message: 'Too Many Request from this IP, please try again in an hour'
});
app.use('/api', limiter);

app.use(xss());
app.use(hpp());

app.use(express.json());
app.use(bodyParser.json());
app.use(express.urlencoded({ extended: true }));

app.use(cookieParser());

app.use(fileUpload({
  useTempFiles: true,
  tempFileDir: '/tmp/'
}));

app.use(morgan("dev"));

// swagger
app.use('/doc', swaggerUi.serve, swaggerUi.setup(swaggerFile));

// existing routes
app.use('/v1', v1routes);
app.use('/v1/upload', uploadController);

// small health endpoint
app.get('/health', (req, res) => res.json({ ok: true, ts: Date.now() }));

// --- create HTTP server + Socket.io and attach to app --- //
const server = http.createServer(app);

const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST']
  },
  // Add any options here (namespaces, path, etc.)
});

// attach io to app so routes/controllers can access it via req.app.get('io')
app.set('io', io);

// Basic connection logging — you can expand listeners per your UI needs
io.on('connection', (socket) => {
  console.log(`Socket connected: ${socket.id}`);

  // optional: handle basic pings from admin clients
  socket.on('ping', (payload) => {
    socket.emit('pong', { time: Date.now(), payload });
  });

  socket.on('disconnect', (reason) => {
    console.log(`Socket disconnected: ${socket.id} (${reason})`);
  });
});

// If another module starts the server (unlikely in your app), export both app and server
module.exports = { app, server };

// If not imported, start the server here
if (require.main === module) {
  const PORT = process.env.PORT || 4000;
  server.listen(PORT, () => {
    console.log(`API + Socket.io listening on port ${PORT}`);
  });
}
