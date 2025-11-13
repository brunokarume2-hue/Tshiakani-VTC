const mongoose = require('mongoose');

const sosReportSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  location: {
    latitude: { type: Number, required: true },
    longitude: { type: Number, required: true },
    address: String,
    timestamp: { type: Date, default: Date.now }
  },
  rideId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Ride'
  },
  message: {
    type: String,
    default: 'Signalement d\'urgence'
  },
  status: {
    type: String,
    enum: ['active', 'resolved', 'false_alarm'],
    default: 'active'
  },
  resolvedAt: Date,
  resolvedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

sosReportSchema.index({ userId: 1, createdAt: -1 });
sosReportSchema.index({ status: 1 });
sosReportSchema.index({ 'location': '2dsphere' });

module.exports = mongoose.model('SOSReport', sosReportSchema);

