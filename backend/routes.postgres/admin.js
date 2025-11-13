// Routes admin avec PostgreSQL + PostGIS
const express = require('express');
const AppDataSource = require('../config/database');
const Ride = require('../entities/Ride');
const User = require('../entities/User');
const SOSReport = require('../entities/SOSReport');
const PriceConfiguration = require('../entities/PriceConfiguration');
const { adminAuth } = require('../middlewares.postgres/auth');
const { adminApiKeyAuth } = require('../middlewares.postgres/adminApiKey');

const router = express.Router();

// Appliquer le middleware de sécurité API Key à toutes les routes admin
// Désactivé temporairement en développement
if (process.env.NODE_ENV === 'production') {
  router.use(adminApiKeyAuth);
}

// Statistiques générales
// adminAuth désactivé temporairement
router.get('/stats', async (req, res) => {
  try {
    const userRepository = AppDataSource.getRepository(User);
    const rideRepository = AppDataSource.getRepository(Ride);

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    // Calculer les 7 derniers jours pour le graphique
    const last7Days = [];
    for (let i = 6; i >= 0; i--) {
      const date = new Date(today);
      date.setDate(date.getDate() - i);
      last7Days.push(date);
    }

    const [
      totalUsers,
      totalDrivers,
      activeDrivers,
      totalRides,
      todayRides,
      completedRides,
      totalRevenue,
      ridesByDay
    ] = await Promise.all([
      userRepository.count(),
      userRepository.count({ where: { role: 'driver' } }),
      userRepository
        .createQueryBuilder('user')
        .where('user.role = :role', { role: 'driver' })
        .andWhere("user.driver_info->>'isOnline' = 'true'")
        .getCount(),
      rideRepository.count(),
      rideRepository
        .createQueryBuilder('ride')
        .where('ride.createdAt >= :today', { today })
        .getCount(),
      rideRepository.count({ where: { status: 'completed' } }),
      rideRepository
        .createQueryBuilder('ride')
        .select('SUM(ride.finalPrice)', 'total')
        .where('ride.status = :status', { status: 'completed' })
        .getRawOne(),
      // Récupérer les courses des 7 derniers jours
      Promise.all(
        last7Days.map(async (date) => {
          const startOfDay = new Date(date);
          startOfDay.setHours(0, 0, 0, 0);
          const endOfDay = new Date(date);
          endOfDay.setHours(23, 59, 59, 999);
          
          const count = await rideRepository
            .createQueryBuilder('ride')
            .where('ride.createdAt >= :start', { start: startOfDay })
            .andWhere('ride.createdAt <= :end', { end: endOfDay })
            .getCount();
          
          return count;
        })
      )
    ]);

    res.json({
      users: {
        total: totalUsers || 0,
        drivers: totalDrivers || 0,
        activeDrivers: activeDrivers || 0
      },
      rides: {
        total: totalRides || 0,
        today: todayRides || 0,
        completed: completedRides || 0,
        last7Days: ridesByDay || [0, 0, 0, 0, 0, 0, 0]
      },
      revenue: {
        total: parseFloat(totalRevenue?.total || 0)
      }
    });
  } catch (error) {
    console.error('Erreur statistiques:', error);
    // Retourner des données par défaut en cas d'erreur
    res.json({
      users: {
        total: 0,
        drivers: 0,
        activeDrivers: 0
      },
      rides: {
        total: 0,
        today: 0,
        completed: 0,
        last7Days: [0, 0, 0, 0, 0, 0, 0]
      },
      revenue: {
        total: 0
      }
    });
  }
});

// Obtenir les alertes SOS
// adminAuth désactivé temporairement
router.get('/sos', async (req, res) => {
  try {
    const { status, limit = 50 } = req.query;
    const sosRepository = AppDataSource.getRepository(SOSReport);
    
    const query = sosRepository.createQueryBuilder('sos')
      .leftJoinAndSelect('sos.user', 'user')
      .leftJoinAndSelect('sos.ride', 'ride')
      .orderBy('sos.createdAt', 'DESC')
      .limit(parseInt(limit));

    if (status) {
      query.where('sos.status = :status', { status });
    }

    const sosReports = await query.getMany();
    res.json(sosReports);
  } catch (error) {
    console.error('Erreur récupération SOS:', error);
    res.status(500).json({ error: 'Erreur lors de la récupération' });
  }
});

// Obtenir les conducteurs en ligne (admin)
// adminAuth désactivé temporairement
router.get('/drivers', async (req, res) => {
  try {
    const { latitude, longitude, radius = 10000 } = req.query;
    const userRepository = AppDataSource.getRepository(User);
    
    let query = userRepository.createQueryBuilder('user')
      .where('user.role = :role', { role: 'driver' })
      .andWhere("user.driver_info->>'isOnline' = 'true'");

    // Si des coordonnées sont fournies, filtrer par distance
    if (latitude && longitude) {
      const lat = parseFloat(latitude);
      const lng = parseFloat(longitude);
      const radiusMeters = parseFloat(radius);
      
      query = query
        .andWhere('user.location IS NOT NULL')
        .andWhere(
          `ST_DWithin(
            user.location::geography,
            ST_MakePoint(:longitude, :latitude)::geography,
            :radius
          )`,
          { longitude: lng, latitude: lat, radius: radiusMeters }
        )
        .addSelect(
          `ST_Distance(
            user.location::geography,
            ST_MakePoint(:longitude, :latitude)::geography
          ) / 1000`,
          'distance_km'
        )
        .setParameters({ longitude: lng, latitude: lat })
        .orderBy(
          `user.location <-> ST_MakePoint(:longitude, :latitude)::geography`,
          'ASC'
        );
    }

    const drivers = await query.getMany();

    // Formater la réponse
    const formattedDrivers = drivers.map(driver => ({
      id: driver.id,
      name: driver.name,
      phoneNumber: driver.phoneNumber,
      driverInfo: driver.driverInfo,
      location: driver.location ? {
        latitude: driver.location.coordinates[1],
        longitude: driver.location.coordinates[0]
      } : null
    }));

    res.json(formattedDrivers);
  } catch (error) {
    console.error('Erreur récupération conducteurs:', error);
    res.status(500).json({ error: 'Erreur lors de la récupération' });
  }
});

// Endpoint pour obtenir les chauffeurs disponibles (pour le dashboard)
// adminAuth désactivé temporairement
router.get('/available_drivers', async (req, res) => {
  try {
    const userRepository = AppDataSource.getRepository(User);
    
    // Récupérer tous les chauffeurs en ligne (disponibles ou en_course)
    const drivers = await userRepository
      .createQueryBuilder('user')
      .where('user.role = :role', { role: 'driver' })
      .andWhere(
        "(user.driver_info->>'isOnline' = 'true' OR user.driver_info->>'status' = 'en_course')"
      )
      .andWhere('user.location IS NOT NULL')
      .getMany();

    // Formater la réponse avec PostGIS
    const formattedDrivers = drivers.map(driver => {
      const isOnline = driver.driverInfo?.isOnline === true;
      const status = driver.driverInfo?.status || (isOnline ? 'disponible' : 'hors_ligne');
      
      return {
        id: driver.id,
        name: driver.name,
        phoneNumber: driver.phoneNumber,
        status: status,
        location: driver.location ? {
          latitude: driver.location.coordinates[1],
          longitude: driver.location.coordinates[0]
        } : null,
        driverInfo: {
          rating: driver.driverInfo?.rating || 0,
          totalRides: driver.driverInfo?.totalRides || 0,
          isOnline: isOnline
        }
      };
    });

    res.json(formattedDrivers);
  } catch (error) {
    console.error('Erreur récupération chauffeurs disponibles:', error);
    res.status(500).json({ error: 'Erreur lors de la récupération' });
  }
});

// Endpoint pour obtenir les courses actives (pour le dashboard)
// adminAuth désactivé temporairement
router.get('/active_rides', async (req, res) => {
  try {
    const rideRepository = AppDataSource.getRepository(Ride);
    
    // Récupérer toutes les courses actives (statut différent de 'completed' ou 'cancelled')
    const activeRides = await rideRepository
      .createQueryBuilder('ride')
      .leftJoinAndSelect('ride.client', 'client')
      .leftJoinAndSelect('ride.driver', 'driver')
      .where('ride.status NOT IN (:...statuses)', { 
        statuses: ['completed', 'cancelled'] 
      })
      .orderBy('ride.createdAt', 'DESC')
      .getMany();

    // Formater la réponse
    const formattedRides = activeRides.map(ride => ({
      id: ride.id,
      client: {
        id: ride.client?.id,
        name: ride.client?.name,
        phoneNumber: ride.client?.phoneNumber
      },
      driver: ride.driver ? {
        id: ride.driver.id,
        name: ride.driver.name,
        phoneNumber: ride.driver.phoneNumber
      } : null,
      status: ride.status,
      pickupLocation: ride.pickupLocation ? {
        latitude: ride.pickupLocation.coordinates[1],
        longitude: ride.pickupLocation.coordinates[0]
      } : null,
      dropoffLocation: ride.dropoffLocation ? {
        latitude: ride.dropoffLocation.coordinates[1],
        longitude: ride.dropoffLocation.coordinates[0]
      } : null,
      pickupAddress: ride.pickupAddress,
      dropoffAddress: ride.dropoffAddress,
      estimatedPrice: parseFloat(ride.estimatedPrice) || 0,
      distance: ride.distance ? parseFloat(ride.distance) : null,
      createdAt: ride.createdAt,
      startedAt: ride.startedAt
    }));

    res.json(formattedRides);
  } catch (error) {
    console.error('Erreur récupération courses actives:', error);
    res.status(500).json({ error: 'Erreur lors de la récupération' });
  }
});

// Obtenir toutes les courses avec filtres
// adminAuth désactivé temporairement
router.get('/rides', async (req, res) => {
  try {
    const { status, startDate, endDate, page = 1, limit = 50 } = req.query;
    const rideRepository = AppDataSource.getRepository(Ride);
    
    const query = rideRepository.createQueryBuilder('ride')
      .leftJoinAndSelect('ride.client', 'client')
      .leftJoinAndSelect('ride.driver', 'driver')
      .orderBy('ride.createdAt', 'DESC')
      .skip((parseInt(page) - 1) * parseInt(limit))
      .take(parseInt(limit));

    if (status) {
      query.where('ride.status = :status', { status });
    }

    if (startDate || endDate) {
      if (startDate) {
        query.andWhere('ride.createdAt >= :startDate', { startDate: new Date(startDate) });
      }
      if (endDate) {
        query.andWhere('ride.createdAt <= :endDate', { endDate: new Date(endDate) });
      }
    }

    const [rides, total] = await query.getManyAndCount();

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

// Obtenir les détails d'un conducteur
// adminAuth désactivé temporairement
router.get('/drivers/:driverId', async (req, res) => {
  try {
    const userRepository = AppDataSource.getRepository(User);
    const rideRepository = AppDataSource.getRepository(Ride);
    
    const driver = await userRepository.findOne({
      where: { 
        id: parseInt(req.params.driverId),
        role: 'driver'
      }
    });

    if (!driver) {
      return res.status(404).json({ error: 'Conducteur non trouvé' });
    }

    // Charger les statistiques
    const stats = await getDriverStats(driver.id, rideRepository);
    
    // Charger les courses
    const rides = await rideRepository.find({
      where: { driverId: driver.id },
      relations: ['client'],
      order: { createdAt: 'DESC' },
      take: 50
    });

    res.json({
      ...driver,
      stats,
      rides
    });
  } catch (error) {
    console.error('Erreur récupération conducteur:', error);
    res.status(500).json({ error: 'Erreur lors de la récupération' });
  }
});

// Mettre à jour les informations d'un conducteur
// adminAuth désactivé temporairement
router.patch('/drivers/:driverId', async (req, res) => {
  try {
    const userRepository = AppDataSource.getRepository(User);
    const driverId = parseInt(req.params.driverId);
    
    const driver = await userRepository.findOne({
      where: { id: driverId, role: 'driver' }
    });

    if (!driver) {
      return res.status(404).json({ error: 'Conducteur non trouvé' });
    }

    // Mettre à jour les champs de base
    if (req.body.name !== undefined) driver.name = req.body.name;
    if (req.body.email !== undefined) driver.email = req.body.email;
    if (req.body.phoneNumber !== undefined) driver.phoneNumber = req.body.phoneNumber;
    if (req.body.isVerified !== undefined) driver.isVerified = req.body.isVerified;

    // Mettre à jour driverInfo si fourni
    if (req.body.driverInfo) {
      const currentDriverInfo = driver.driverInfo || {};
      driver.driverInfo = {
        ...currentDriverInfo,
        ...req.body.driverInfo,
        // Préserver les champs critiques
        isOnline: currentDriverInfo.isOnline,
        status: currentDriverInfo.status,
        currentRideId: currentDriverInfo.currentRideId
      };
    }

    await userRepository.save(driver);

    res.json({ message: 'Informations mises à jour avec succès', driver });
  } catch (error) {
    console.error('Erreur mise à jour conducteur:', error);
    res.status(500).json({ error: 'Erreur lors de la mise à jour' });
  }
});

// Mettre à jour les informations du véhicule d'un conducteur
// adminAuth désactivé temporairement
router.patch('/drivers/:driverId/vehicle', async (req, res) => {
  try {
    const userRepository = AppDataSource.getRepository(User);
    const driverId = parseInt(req.params.driverId);
    
    const driver = await userRepository.findOne({
      where: { id: driverId, role: 'driver' }
    });

    if (!driver) {
      return res.status(404).json({ error: 'Conducteur non trouvé' });
    }

    const currentDriverInfo = driver.driverInfo || {};
    const currentVehicle = currentDriverInfo.vehicle || {};

    // Mettre à jour les informations du véhicule
    const updatedVehicle = {
      ...currentVehicle,
      ...req.body
    };

    // Mettre à jour aussi licensePlate et vehicleType au niveau racine de driverInfo si fournis
    driver.driverInfo = {
      ...currentDriverInfo,
      vehicle: updatedVehicle,
      licensePlate: req.body.licensePlate || currentDriverInfo.licensePlate,
      vehicleType: req.body.vehicleType || currentDriverInfo.vehicleType
    };

    await userRepository.save(driver);

    res.json({ message: 'Informations du véhicule mises à jour avec succès', driver });
  } catch (error) {
    console.error('Erreur mise à jour véhicule:', error);
    res.status(500).json({ error: 'Erreur lors de la mise à jour' });
  }
});

// Statistiques d'un conducteur
// adminAuth désactivé temporairement
router.get('/drivers/:driverId/stats', async (req, res) => {
  try {
    const rideRepository = AppDataSource.getRepository(Ride);
    const stats = await getDriverStats(parseInt(req.params.driverId), rideRepository);
    res.json(stats);
  } catch (error) {
    console.error('Erreur statistiques conducteur:', error);
    res.status(500).json({ error: 'Erreur lors de la récupération' });
  }
});

// Courses d'un conducteur
// adminAuth désactivé temporairement
router.get('/drivers/:driverId/rides', async (req, res) => {
  try {
    const rideRepository = AppDataSource.getRepository(Ride);
    const rides = await rideRepository.find({
      where: { driverId: parseInt(req.params.driverId) },
      relations: ['client'],
      order: { createdAt: 'DESC' },
      take: 100
    });

    res.json({ rides });
  } catch (error) {
    console.error('Erreur récupération courses:', error);
    res.status(500).json({ error: 'Erreur lors de la récupération' });
  }
});

// Valider les documents d'un conducteur
// adminAuth désactivé temporairement
router.post('/drivers/:driverId/validate-documents', async (req, res) => {
  try {
    const userRepository = AppDataSource.getRepository(User);
    const driver = await userRepository.findOne({
      where: { 
        id: parseInt(req.params.driverId),
        role: 'driver'
      }
    });

    if (!driver) {
      return res.status(404).json({ error: 'Conducteur non trouvé' });
    }

    const driverInfo = driver.driverInfo || {};
    const documents = driverInfo.documents || {};
    
    // Marquer tous les documents comme validés
    Object.keys(documents).forEach(key => {
      if (documents[key]) {
        documents[key].status = 'validated';
        documents[key].validatedAt = new Date();
        documents[key].validatedBy = 1; // Admin ID par défaut
      }
    });

    driverInfo.documentsStatus = 'validated';
    driver.driverInfo = driverInfo;
    driver.isVerified = true;
    
    await userRepository.save(driver);

    res.json({ success: true, driver });
  } catch (error) {
    console.error('Erreur validation documents:', error);
    res.status(500).json({ error: 'Erreur lors de la validation' });
  }
});

// Valider un document spécifique
// adminAuth désactivé temporairement
router.post('/drivers/:driverId/validate-document', async (req, res) => {
  try {
    const { documentType } = req.body;
    const userRepository = AppDataSource.getRepository(User);
    const driver = await userRepository.findOne({
      where: { 
        id: parseInt(req.params.driverId),
        role: 'driver'
      }
    });

    if (!driver) {
      return res.status(404).json({ error: 'Conducteur non trouvé' });
    }

    const driverInfo = driver.driverInfo || {};
    const documents = driverInfo.documents || {};
    
    if (documents[documentType]) {
      documents[documentType].status = 'validated';
      documents[documentType].validatedAt = new Date();
      documents[documentType].validatedBy = 1; // Admin ID par défaut
    }

    driverInfo.documents = documents;
    driver.driverInfo = driverInfo;
    
    await userRepository.save(driver);

    res.json({ success: true });
  } catch (error) {
    console.error('Erreur validation document:', error);
    res.status(500).json({ error: 'Erreur lors de la validation' });
  }
});

// Rejeter un document spécifique
// adminAuth désactivé temporairement
router.post('/drivers/:driverId/reject-document', async (req, res) => {
  try {
    const { documentType } = req.body;
    const userRepository = AppDataSource.getRepository(User);
    const driver = await userRepository.findOne({
      where: { 
        id: parseInt(req.params.driverId),
        role: 'driver'
      }
    });

    if (!driver) {
      return res.status(404).json({ error: 'Conducteur non trouvé' });
    }

    const driverInfo = driver.driverInfo || {};
    const documents = driverInfo.documents || {};
    
    if (documents[documentType]) {
      documents[documentType].status = 'rejected';
      documents[documentType].rejectedAt = new Date();
      documents[documentType].rejectedBy = 1; // Admin ID par défaut
    }

    driverInfo.documents = documents;
    driver.driverInfo = driverInfo;
    
    await userRepository.save(driver);

    res.json({ success: true });
  } catch (error) {
    console.error('Erreur rejet document:', error);
    res.status(500).json({ error: 'Erreur lors du rejet' });
  }
});

// Obtenir les détails d'un client
// adminAuth désactivé temporairement
router.get('/clients/:clientId', async (req, res) => {
  try {
    const userRepository = AppDataSource.getRepository(User);
    const rideRepository = AppDataSource.getRepository(Ride);
    
    const client = await userRepository.findOne({
      where: { 
        id: parseInt(req.params.clientId),
        role: 'client'
      }
    });

    if (!client) {
      return res.status(404).json({ error: 'Client non trouvé' });
    }

    // Charger les statistiques
    const stats = await getClientStats(client.id, rideRepository);
    
    // Charger les courses
    const rides = await rideRepository.find({
      where: { clientId: client.id },
      relations: ['driver'],
      order: { createdAt: 'DESC' },
      take: 100
    });

    res.json({
      ...client,
      stats,
      rides
    });
  } catch (error) {
    console.error('Erreur récupération client:', error);
    res.status(500).json({ error: 'Erreur lors de la récupération' });
  }
});

// Statistiques d'un client
// adminAuth désactivé temporairement
router.get('/clients/:clientId/stats', async (req, res) => {
  try {
    const rideRepository = AppDataSource.getRepository(Ride);
    const stats = await getClientStats(parseInt(req.params.clientId), rideRepository);
    res.json(stats);
  } catch (error) {
    console.error('Erreur statistiques client:', error);
    res.status(500).json({ error: 'Erreur lors de la récupération' });
  }
});

// Courses d'un client
// adminAuth désactivé temporairement
router.get('/clients/:clientId/rides', async (req, res) => {
  try {
    const rideRepository = AppDataSource.getRepository(Ride);
    const rides = await rideRepository.find({
      where: { clientId: parseInt(req.params.clientId) },
      relations: ['driver'],
      order: { createdAt: 'DESC' },
      take: 100
    });

    res.json({ rides });
  } catch (error) {
    console.error('Erreur récupération courses:', error);
    res.status(500).json({ error: 'Erreur lors de la récupération' });
  }
});

// Statistiques financières
// adminAuth désactivé temporairement
router.get('/finance/stats', async (req, res) => {
  try {
    const { startDate, endDate } = req.query;
    const rideRepository = AppDataSource.getRepository(Ride);
    const userRepository = AppDataSource.getRepository(User);

    // Construire la requête de base pour les courses complétées
    let whereConditions = "status = 'completed'";
    const params = [];
    let paramIndex = 1;

    if (startDate) {
      whereConditions += ` AND completed_at >= $${paramIndex}`;
      params.push(new Date(startDate));
      paramIndex++;
    }
    if (endDate) {
      whereConditions += ` AND completed_at <= $${paramIndex}`;
      params.push(new Date(endDate));
      paramIndex++;
    }

    // Revenus totaux
    const totalRevenueQuery = `
      SELECT COALESCE(SUM(final_price), 0) as total
      FROM rides
      WHERE ${whereConditions}
    `;
    const totalRevenueResult = await AppDataSource.query(totalRevenueQuery, params);
    const totalRevenue = parseFloat(totalRevenueResult[0]?.total || 0);

    // Commissions (20% par défaut)
    const commissionRate = 0.20;
    const totalCommissions = totalRevenue * commissionRate;

    // Revenus par jour (PostgreSQL utilise DATE_TRUNC ou CAST)
    let dailyRevenueParams = [];
    let dailyRevenueWhere = "status = 'completed'";
    let dailyParamIndex = 1;

    if (startDate) {
      dailyRevenueWhere += ` AND completed_at >= $${dailyParamIndex}`;
      dailyRevenueParams.push(new Date(startDate));
      dailyParamIndex++;
    }
    if (endDate) {
      dailyRevenueWhere += ` AND completed_at <= $${dailyParamIndex}`;
      dailyRevenueParams.push(new Date(endDate));
      dailyParamIndex++;
    }

    const dailyRevenueQuery = `
      SELECT 
        DATE(completed_at) as date,
        COALESCE(SUM(final_price), 0) as amount
      FROM rides
      WHERE ${dailyRevenueWhere}
      GROUP BY DATE(completed_at)
      ORDER BY DATE(completed_at) ASC
    `;
    const dailyRevenue = await AppDataSource.query(dailyRevenueQuery, dailyRevenueParams);

    // Top 10 conducteurs avec leurs revenus
    let topDriversWhere = "r.status = 'completed'";
    const topDriversParams = [];
    let topDriversParamIndex = 1;

    if (startDate) {
      topDriversWhere += ` AND r.completed_at >= $${topDriversParamIndex}`;
      topDriversParams.push(new Date(startDate));
      topDriversParamIndex++;
    }
    if (endDate) {
      topDriversWhere += ` AND r.completed_at <= $${topDriversParamIndex}`;
      topDriversParams.push(new Date(endDate));
      topDriversParamIndex++;
    }

    const topDriversQuery = `
      SELECT 
        u.id,
        u.name,
        COALESCE(SUM(r.final_price), 0) as earnings
      FROM rides r
      LEFT JOIN users u ON r.driver_id = u.id
      WHERE ${topDriversWhere}
      GROUP BY u.id, u.name
      ORDER BY SUM(r.final_price) DESC
      LIMIT 10
    `;
    const topDrivers = await AppDataSource.query(topDriversQuery, topDriversParams);

    // Retraits en attente (calculer depuis driverInfo)
    const pendingWithdrawalsQuery = `
      SELECT COALESCE(SUM((driver_info->>'pendingWithdrawal')::numeric), 0) as total
      FROM users
      WHERE role = 'driver' AND driver_info->>'pendingWithdrawal' IS NOT NULL
    `;
    const pendingWithdrawalsResult = await AppDataSource.query(pendingWithdrawalsQuery);
    const pendingWithdrawals = parseFloat(pendingWithdrawalsResult[0]?.total || 0);

    res.json({
      totalRevenue,
      totalCommissions,
      netRevenue: totalRevenue - totalCommissions,
      pendingWithdrawals,
      dailyRevenue: dailyRevenue.map(d => ({
        date: d.date ? new Date(d.date).toISOString().split('T')[0] : null,
        amount: parseFloat(d.amount || 0)
      })),
      topDrivers: topDrivers.map(d => ({
        id: d.id,
        name: d.name || 'Conducteur inconnu',
        earnings: parseFloat(d.earnings || 0)
      }))
    });
  } catch (error) {
    console.error('Erreur statistiques financières:', error);
    // Retourner des données par défaut en cas d'erreur
    res.json({
      totalRevenue: 0,
      totalCommissions: 0,
      netRevenue: 0,
      pendingWithdrawals: 0,
      dailyRevenue: [],
      topDrivers: []
    });
  }
});

// Transactions financières
// adminAuth désactivé temporairement
router.get('/finance/transactions', async (req, res) => {
  try {
    const { startDate, endDate, type } = req.query;
    const rideRepository = AppDataSource.getRepository(Ride);

    // Construire la requête avec filtres
    let whereConditions = "r.status = 'completed'";
    const params = [];
    let paramIndex = 1;

    if (startDate) {
      whereConditions += ` AND r.completed_at >= $${paramIndex}`;
      params.push(new Date(startDate));
      paramIndex++;
    }
    if (endDate) {
      whereConditions += ` AND r.completed_at <= $${paramIndex}`;
      params.push(new Date(endDate));
      paramIndex++;
    }

    // Requête SQL pour récupérer les courses avec les conducteurs
    const ridesQuery = `
      SELECT 
        r.id,
        r.final_price,
        r.estimated_price,
        r.completed_at,
        r.created_at,
        r.payment_method,
        u.id as driver_id,
        u.name as driver_name,
        u.phone_number as driver_phone
      FROM rides r
      LEFT JOIN users u ON r.driver_id = u.id
      WHERE ${whereConditions}
      ORDER BY r.completed_at DESC, r.created_at DESC
      LIMIT 100
    `;
    const rides = await AppDataSource.query(ridesQuery, params);

    // Transformer les courses en transactions
    const transactions = [];
    const commissionRate = 0.20;

    rides.forEach(ride => {
      const amount = parseFloat(ride.final_price || ride.estimated_price || 0);
      const commission = amount * commissionRate;
      const driverEarnings = amount - commission;

      // Transaction revenu (total de la course)
      if (!type || type === 'revenue') {
        transactions.push({
          id: `revenue-${ride.id}`,
          type: 'revenue',
          amount: amount,
          driver: ride.driver_id ? {
            id: ride.driver_id,
            name: ride.driver_name,
            phoneNumber: ride.driver_phone
          } : null,
          status: 'completed',
          createdAt: ride.completed_at || ride.created_at,
          paymentMethod: ride.payment_method,
          rideId: ride.id
        });
      }

      // Transaction commission (si demandée)
      if ((!type || type === 'commission') && ride.driver_id) {
        transactions.push({
          id: `commission-${ride.id}`,
          type: 'commission',
          amount: commission,
          driver: {
            id: ride.driver_id,
            name: ride.driver_name,
            phoneNumber: ride.driver_phone
          },
          status: 'completed',
          createdAt: ride.completed_at || ride.created_at,
          paymentMethod: ride.payment_method,
          rideId: ride.id,
          driverEarnings: driverEarnings
        });
      }
    });

    // Trier par date décroissante
    transactions.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

    res.json({ 
      transactions: transactions.slice(0, 100),
      total: transactions.length
    });
  } catch (error) {
    console.error('Erreur récupération transactions:', error);
    res.json({ transactions: [], total: 0 });
  }
});

// Fonctions utilitaires
async function getDriverStats(driverId, rideRepository) {
  const totalRides = await rideRepository.count({
    where: { driverId, status: 'completed' }
  });

  const ratingResult = await rideRepository
    .createQueryBuilder('ride')
    .select('AVG(ride.rating)', 'avg')
    .where('ride.driverId = :driverId', { driverId })
    .andWhere('ride.rating IS NOT NULL')
    .getRawOne();

  const earningsResult = await rideRepository
    .createQueryBuilder('ride')
    .select('SUM(ride.finalPrice)', 'total')
    .where('ride.driverId = :driverId', { driverId })
    .andWhere('ride.status = :status', { status: 'completed' })
    .getRawOne();

  const monthStart = new Date();
  monthStart.setDate(1);
  monthStart.setHours(0, 0, 0, 0);
  
  const monthlyRides = await rideRepository
    .createQueryBuilder('ride')
    .where('ride.driverId = :driverId', { driverId })
    .andWhere('ride.status = :status', { status: 'completed' })
    .andWhere('ride.completedAt >= :monthStart', { monthStart })
    .getCount();

  const monthlyEarningsResult = await rideRepository
    .createQueryBuilder('ride')
    .select('SUM(ride.finalPrice)', 'total')
    .where('ride.driverId = :driverId', { driverId })
    .andWhere('ride.status = :status', { status: 'completed' })
    .andWhere('ride.completedAt >= :monthStart', { monthStart })
    .getRawOne();

  const cancelledRides = await rideRepository.count({
    where: { driverId, status: 'cancelled' }
  });

  return {
    totalRides,
    averageRating: ratingResult ? parseFloat(ratingResult.avg) : null,
    totalEarnings: earningsResult ? parseFloat(earningsResult.total) : 0,
    monthlyRides,
    monthlyEarnings: monthlyEarningsResult ? parseFloat(monthlyEarningsResult.total) : 0,
    cancellationRate: totalRides > 0 ? (cancelledRides / (totalRides + cancelledRides)) * 100 : 0
  };
}

async function getClientStats(clientId, rideRepository) {
  const totalRides = await rideRepository.count({
    where: { clientId, status: 'completed' }
  });

  const spendingResult = await rideRepository
    .createQueryBuilder('ride')
    .select('SUM(ride.finalPrice)', 'total')
    .where('ride.clientId = :clientId', { clientId })
    .andWhere('ride.status = :status', { status: 'completed' })
    .getRawOne();

  const ratingResult = await rideRepository
    .createQueryBuilder('ride')
    .select('AVG(ride.rating)', 'avg')
    .where('ride.clientId = :clientId', { clientId })
    .andWhere('ride.rating IS NOT NULL')
    .getRawOne();

  const monthStart = new Date();
  monthStart.setDate(1);
  monthStart.setHours(0, 0, 0, 0);
  
  const monthlyRides = await rideRepository
    .createQueryBuilder('ride')
    .where('ride.clientId = :clientId', { clientId })
    .andWhere('ride.status = :status', { status: 'completed' })
    .andWhere('ride.completedAt >= :monthStart', { monthStart })
    .getCount();

  const monthlySpendingResult = await rideRepository
    .createQueryBuilder('ride')
    .select('SUM(ride.finalPrice)', 'total')
    .where('ride.clientId = :clientId', { clientId })
    .andWhere('ride.status = :status', { status: 'completed' })
    .andWhere('ride.completedAt >= :monthStart', { monthStart })
    .getRawOne();

  const cancelledRides = await rideRepository.count({
    where: { clientId, status: 'cancelled' }
  });

  return {
    totalRides,
    totalSpending: spendingResult ? parseFloat(spendingResult.total) : 0,
    averageRatingGiven: ratingResult ? parseFloat(ratingResult.avg) : null,
    monthlyRides,
    monthlySpending: monthlySpendingResult ? parseFloat(monthlySpendingResult.total) : 0,
    cancellationRate: totalRides > 0 ? (cancelledRides / (totalRides + cancelledRides)) * 100 : 0
  };
}

// Obtenir la configuration de tarification
// adminAuth désactivé temporairement
router.get('/pricing', async (req, res) => {
  try {
    const configRepository = AppDataSource.getRepository(PriceConfiguration);
    const config = await configRepository.findOne({
      where: { isActive: true },
      order: { updatedAt: 'DESC' }
    });

    if (!config) {
      // Retourner des valeurs par défaut
      return res.json({
        basePrice: 1000,
        pricePerKm: 500,
        pricePerMinute: 100,
        minimumPrice: 1500,
        surgeMultiplier: 1.5,
        nightSurcharge: 0.2,
        vehicleTypes: {
          standard: { multiplier: 1.0, name: 'Standard' },
          premium: { multiplier: 1.5, name: 'Premium' },
          luxury: { multiplier: 2.0, name: 'Luxury' }
        }
      });
    }

    // Convertir la configuration en format simplifié pour le dashboard
    res.json({
      basePrice: parseFloat(config.basePrice) || 1000,
      pricePerKm: parseFloat(config.pricePerKm) || 500,
      pricePerMinute: 100, // Non stocké dans la config actuelle
      minimumPrice: 1500, // Non stocké dans la config actuelle
      surgeMultiplier: parseFloat(config.surgeHighMultiplier) || 1.5,
      nightSurcharge: parseFloat(config.nightMultiplier) - 1 || 0.2,
      vehicleTypes: {
        standard: { multiplier: 1.0, name: 'Standard' },
        premium: { multiplier: 1.5, name: 'Premium' },
        luxury: { multiplier: 2.0, name: 'Luxury' }
      }
    });
  } catch (error) {
    console.error('Erreur récupération tarification:', error);
    res.status(500).json({ error: 'Erreur lors de la récupération' });
  }
});

// Mettre à jour la configuration de tarification
// adminAuth désactivé temporairement
router.post('/pricing', async (req, res) => {
  try {
    const configRepository = AppDataSource.getRepository(PriceConfiguration);
    
    // Trouver ou créer la configuration active
    let config = await configRepository.findOne({
      where: { isActive: true },
      order: { updatedAt: 'DESC' }
    });

    if (!config) {
      config = configRepository.create({
        basePrice: req.body.basePrice || 1000,
        pricePerKm: req.body.pricePerKm || 500,
        rushHourMultiplier: 1.5,
        nightMultiplier: 1 + (req.body.nightSurcharge || 0.2),
        weekendMultiplier: 1.2,
        surgeLowDemandMultiplier: 0.9,
        surgeNormalMultiplier: 1.0,
        surgeHighMultiplier: req.body.surgeMultiplier || 1.5,
        surgeVeryHighMultiplier: 1.4,
        surgeExtremeMultiplier: 1.6,
        isActive: true
      });
    } else {
      // Mettre à jour les valeurs
      if (req.body.basePrice !== undefined) config.basePrice = req.body.basePrice;
      if (req.body.pricePerKm !== undefined) config.pricePerKm = req.body.pricePerKm;
      if (req.body.surgeMultiplier !== undefined) config.surgeHighMultiplier = req.body.surgeMultiplier;
      if (req.body.nightSurcharge !== undefined) config.nightMultiplier = 1 + req.body.nightSurcharge;
    }

    await configRepository.save(config);

    // Invalider le cache du PricingService
    const PricingService = require('../services/PricingService');
    PricingService.invalidateCache();

    res.json({ success: true, config });
  } catch (error) {
    console.error('Erreur mise à jour tarification:', error);
    res.status(500).json({ error: 'Erreur lors de la mise à jour' });
  }
});

// ==================== AGENT PRINCIPAL ====================

/**
 * GET /api/admin/agent-principal/stats
 * Obtenir les métriques détaillées de l'agent principal
 * Note: Cette route est accessible sans adminApiKeyAuth en développement
 */
router.get('/agent-principal/stats', async (req, res) => {
  try {
    // Utiliser BackendAgentPrincipal directement pour éviter les dépendances circulaires
    const BackendAgentPrincipal = require('../services/BackendAgentPrincipal');
    // Créer une instance temporaire pour accéder aux méthodes statiques ou utiliser getStatistics
    // Note: getStatistics ne nécessite pas d'instance car elle utilise AppDataSource directement
    const rideRepository = AppDataSource.getRepository(Ride);
    const userRepository = AppDataSource.getRepository(User);
    
    // Créer une instance minimale pour getStatistics
    const backendAgent = new BackendAgentPrincipal();

    // 1. Statistiques générales de l'agent principal
    const generalStats = await backendAgent.getStatistics();

    // 2. Statistiques de matching (24 dernières heures)
    const last24Hours = new Date();
    last24Hours.setHours(last24Hours.getHours() - 24);

    const [
      totalRidesCreated,
      ridesWithDriver,
      ridesWithoutDriver,
      averageMatchingTime,
      matchingStats
    ] = await Promise.all([
      // Total de courses créées dans les 24h
      rideRepository
        .createQueryBuilder('ride')
        .where('ride.createdAt >= :last24Hours', { last24Hours })
        .getCount(),
      // Courses avec conducteur assigné
      rideRepository
        .createQueryBuilder('ride')
        .where('ride.createdAt >= :last24Hours', { last24Hours })
        .andWhere('ride.driverId IS NOT NULL')
        .getCount(),
      // Courses sans conducteur (pending)
      rideRepository
        .createQueryBuilder('ride')
        .where('ride.createdAt >= :last24Hours', { last24Hours })
        .andWhere('ride.status = :status', { status: 'pending' })
        .getCount(),
      // Temps moyen de matching (approximation basée sur started_at - created_at)
      // Utiliser une requête SQL brute pour éviter les problèmes de mapping TypeORM
      AppDataSource.query(
        `SELECT AVG(EXTRACT(EPOCH FROM (started_at - created_at))) as "avgTime"
         FROM rides
         WHERE driver_id IS NOT NULL
           AND created_at >= $1
           AND started_at IS NOT NULL`,
        [last24Hours]
      ).then(result => result[0] || { avgTime: null })
       .catch(() => ({ avgTime: null })), // En cas d'erreur, retourner null
      // Statistiques par statut
      // Utiliser une requête SQL brute pour éviter les problèmes de mapping TypeORM
      AppDataSource.query(
        `SELECT status, COUNT(*) as count
         FROM rides
         WHERE created_at >= $1
         GROUP BY status`,
        [last24Hours]
      ).catch(error => {
        console.error('Erreur stats par statut:', error);
        return [];
      })
    ]);

    // 3. Statistiques de performance (7 derniers jours)
    const last7Days = [];
    for (let i = 6; i >= 0; i--) {
      const date = new Date();
      date.setDate(date.getDate() - i);
      date.setHours(0, 0, 0, 0);
      last7Days.push(date);
    }

    const ridesByDay = await Promise.all(
      last7Days.map(async (date) => {
        const startOfDay = new Date(date);
        startOfDay.setHours(0, 0, 0, 0);
        const endOfDay = new Date(date);
        endOfDay.setHours(23, 59, 59, 999);

        const [total, completed, withDriver] = await Promise.all([
          rideRepository
            .createQueryBuilder('ride')
            .where('ride.createdAt >= :start', { start: startOfDay })
            .andWhere('ride.createdAt <= :end', { end: endOfDay })
            .getCount(),
          rideRepository
            .createQueryBuilder('ride')
            .where('ride.createdAt >= :start', { start: startOfDay })
            .andWhere('ride.createdAt <= :end', { end: endOfDay })
            .andWhere('ride.status = :status', { status: 'completed' })
            .getCount(),
          rideRepository
            .createQueryBuilder('ride')
            .where('ride.createdAt >= :start', { start: startOfDay })
            .andWhere('ride.createdAt <= :end', { end: endOfDay })
            .andWhere('ride.driverId IS NOT NULL')
            .getCount()
        ]);

        return {
          date: date.toISOString().split('T')[0],
          total,
          completed,
          withDriver,
          matchingRate: total > 0 ? (withDriver / total) * 100 : 0,
          completionRate: total > 0 ? (completed / total) * 100 : 0
        };
      })
    );

    // 4. Statistiques de pricing
    // Utiliser une requête SQL brute pour éviter les problèmes de mapping TypeORM
    const pricingStats = await AppDataSource.query(
      `SELECT 
        AVG(estimated_price) as "avgEstimatedPrice",
        AVG(final_price) as "avgFinalPrice",
        SUM(final_price) as "totalRevenue"
       FROM rides
       WHERE created_at >= $1
         AND status = $2`,
      [last24Hours, 'completed']
    ).then(result => result[0] || { avgEstimatedPrice: null, avgFinalPrice: null, totalRevenue: null })
     .catch(error => {
       console.error('Erreur pricing stats:', error);
       return { avgEstimatedPrice: null, avgFinalPrice: null, totalRevenue: null };
     });

    // 5. Conducteurs actifs
    const activeDriversCount = await userRepository
      .createQueryBuilder('user')
      .where('user.role = :role', { role: 'driver' })
      .andWhere("user.driver_info->>'isOnline' = 'true'")
      .getCount();

    // 6. Taux de succès
    const matchingRate = totalRidesCreated > 0 
      ? (ridesWithDriver / totalRidesCreated) * 100 
      : 0;

    const averageMatchingTimeSeconds = averageMatchingTime?.avgTime 
      ? parseFloat(averageMatchingTime.avgTime) 
      : 0;

    res.json({
      general: generalStats,
      matching: {
        totalRides24h: totalRidesCreated,
        ridesWithDriver,
        ridesWithoutDriver,
        matchingRate: Math.round(matchingRate * 100) / 100,
        averageMatchingTimeSeconds: Math.round(averageMatchingTimeSeconds * 10) / 10,
        statsByStatus: matchingStats
      },
      performance: {
        last7Days: ridesByDay,
        activeDrivers: activeDriversCount
      },
      pricing: {
        averageEstimatedPrice: parseFloat(pricingStats?.avgEstimatedPrice || 0),
        averageFinalPrice: parseFloat(pricingStats?.avgFinalPrice || 0),
        totalRevenue24h: parseFloat(pricingStats?.totalRevenue || 0)
      },
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Erreur récupération stats agent principal:', error);
    console.error('Stack:', error.stack);
    res.status(500).json({ 
      error: 'Erreur lors de la récupération des statistiques',
      details: error.message,
      stack: process.env.NODE_ENV !== 'production' ? error.stack : undefined
    });
  }
});

module.exports = router;

