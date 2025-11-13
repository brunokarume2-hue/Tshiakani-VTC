const express = require('express');
const Ride = require('../models/Ride');
const User = require('../models/User');
const { adminAuth } = require('../middlewares/auth');

const router = express.Router();

// Statistiques générales
router.get('/stats', adminAuth, async (req, res) => {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const [
      totalUsers,
      totalDrivers,
      activeDrivers,
      totalRides,
      todayRides,
      completedRides,
      totalRevenue
    ] = await Promise.all([
      User.countDocuments(),
      User.countDocuments({ role: 'driver' }),
      User.countDocuments({ role: 'driver', 'driverInfo.isOnline': true }),
      Ride.countDocuments(),
      Ride.countDocuments({ createdAt: { $gte: today } }),
      Ride.countDocuments({ status: 'completed' }),
      Ride.aggregate([
        { $match: { status: 'completed' } },
        { $group: { _id: null, total: { $sum: '$finalPrice' } } }
      ])
    ]);

    res.json({
      users: {
        total: totalUsers,
        drivers: totalDrivers,
        activeDrivers
      },
      rides: {
        total: totalRides,
        today: todayRides,
        completed: completedRides
      },
      revenue: {
        total: totalRevenue[0]?.total || 0
      }
    });
  } catch (error) {
    console.error('Erreur statistiques:', error);
    res.status(500).json({ error: 'Erreur lors de la récupération des statistiques' });
  }
});

// Obtenir les alertes SOS
router.get('/sos', adminAuth, async (req, res) => {
  try {
    const SOSReport = require('../models/SOSReport');
    const { status, limit = 50 } = req.query;
    const query = status ? { status } : {};

    const sosReports = await SOSReport.find(query)
      .sort({ createdAt: -1 })
      .limit(parseInt(limit))
      .populate('userId', 'name phoneNumber')
      .populate('rideId');

    res.json(sosReports);
  } catch (error) {
    console.error('Erreur récupération SOS:', error);
    res.status(500).json({ error: 'Erreur lors de la récupération' });
  }
});

// Obtenir toutes les courses avec filtres
router.get('/rides', adminAuth, async (req, res) => {
  try {
    const { status, startDate, endDate, page = 1, limit = 50 } = req.query;
    const query = {};

    if (status) query.status = status;
    if (startDate || endDate) {
      query.createdAt = {};
      if (startDate) query.createdAt.$gte = new Date(startDate);
      if (endDate) query.createdAt.$lte = new Date(endDate);
    }

    const rides = await Ride.find(query)
      .sort({ createdAt: -1 })
      .limit(parseInt(limit))
      .skip((parseInt(page) - 1) * parseInt(limit))
      .populate('clientId', 'name phoneNumber')
      .populate('driverId', 'name phoneNumber');

    const total = await Ride.countDocuments(query);

    res.json({
      rides,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit))
      }
    });
  } catch (error) {
    console.error('Erreur récupération courses:', error);
    res.status(500).json({ error: 'Erreur lors de la récupération' });
  }
});

module.exports = router;

