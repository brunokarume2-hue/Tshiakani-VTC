const mongoose = require('mongoose');

const rideSchema = new mongoose.Schema({
  clientId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  driverId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  pickupLocation: {
    latitude: { type: Number, required: true },
    longitude: { type: Number, required: true },
    address: String
  },
  dropoffLocation: {
    latitude: { type: Number, required: true },
    longitude: { type: Number, required: true },
    address: String
  },
  status: {
    type: String,
    enum: ['pending', 'accepted', 'driverArriving', 'inProgress', 'completed', 'cancelled'],
    default: 'pending'
  },
  estimatedPrice: {
    type: Number,
    required: true
  },
  finalPrice: Number,
  paymentMethod: {
    type: String,
    enum: ['cash', 'mobile_money', 'card'],
    default: 'cash'
  },
  distance: Number, // en kilomètres
  duration: Number, // en minutes
  rating: {
    type: Number,
    min: 1,
    max: 5
  },
  comment: String,
  createdAt: {
    type: Date,
    default: Date.now
  },
  startedAt: Date,
  completedAt: Date,
  cancelledAt: Date,
  cancellationReason: String
});

// Index pour les recherches
rideSchema.index({ clientId: 1, createdAt: -1 });
rideSchema.index({ driverId: 1, createdAt: -1 });
rideSchema.index({ status: 1 });
rideSchema.index({ createdAt: -1 });
rideSchema.index({ 'pickupLocation': '2dsphere' });

module.exports = mongoose.model('Ride', rideSchema);

