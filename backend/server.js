const express = require('express');
const mongoose = require('mongoose');
const http = require('http');
const socketIo = require('socket.io');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
  cors: {
    origin: process.env.CORS_ORIGIN || "*",
    methods: ["GET", "POST"]
  }
});

// Middlewares
app.use(helmet());
app.use(cors({
  origin: process.env.CORS_ORIGIN || "*",
  credentials: true
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Rate limiting
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000,
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100
});
app.use('/api/', limiter);

// Routes
app.use('/api/auth', require('./routes/auth'));
app.use('/api/rides', require('./routes/rides'));
app.use('/api/courses', require('./routes/rides')); // Alias pour compatibilité
app.use('/api/users', require('./routes/users'));
app.use('/api/location', require('./routes/location'));
app.use('/api/notifications', require('./routes/notifications'));
app.use('/api/sos', require('./routes/sos'));
app.use('/api/admin', require('./routes/admin'));

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// Socket.io pour la géolocalisation en temps réel
io.on('connection', (socket) => {
  console.log('Client connecté:', socket.id);

  // Rejoindre la room du conducteur
  socket.on('driver:join', (driverId) => {
    socket.join(`driver:${driverId}`);
    console.log(`Conducteur ${driverId} connecté`);
  });

  // Mise à jour de position du conducteur
  socket.on('driver:location', async (data) => {
    const { driverId, location } = data;
    // Diffuser la position aux clients qui suivent ce conducteur
    io.to(`driver:${driverId}`).emit('driver:location:update', {
      driverId,
      location,
      timestamp: new Date()
    });
  });

  // Rejoindre la room d'une course
  socket.on('ride:join', (rideId) => {
    socket.join(`ride:${rideId}`);
    console.log(`Client rejoint la course ${rideId}`);
  });

  // Mise à jour du statut d'une course
  socket.on('ride:status:update', (data) => {
    const { rideId, status } = data;
    io.to(`ride:${rideId}`).emit('ride:status:changed', {
      rideId,
      status,
      timestamp: new Date()
    });
  });

  socket.on('disconnect', () => {
    console.log('Client déconnecté:', socket.id);
  });
});

// Connexion MongoDB
mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/TshiakaniVTC', {
  useNewUrlParser: true,
  useUnifiedTopology: true
})
.then(() => {
  console.log('✅ Connecté à MongoDB');
  const PORT = process.env.PORT || 3000;
  server.listen(PORT, () => {
    console.log(`🚀 Serveur démarré sur le port ${PORT}`);
  });
})
.catch((error) => {
  console.error('❌ Erreur de connexion MongoDB:', error);
  process.exit(1);
});

module.exports = { app, io };

