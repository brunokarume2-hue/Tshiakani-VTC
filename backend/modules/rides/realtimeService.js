/**
 * Service de communication temps réel pour les courses
 * Gère les événements Socket.io : ride_request, ride_offer, ride_accepted, ride_update
 */

const AppDataSource = require('../../config/database');
const Ride = require('../../entities/Ride');
const User = require('../../entities/User');
const { sendNotification, createNotification } = require('../../utils/notifications');

class RealtimeRideService {
  constructor(io, driverNamespace, clientNamespace = null) {
    this.io = io;
    this.driverNamespace = driverNamespace;
    this.clientNamespace = clientNamespace;
    this.activeRides = new Map(); // Map<rideId, { accepted: boolean, acceptedBy: driverId }>
    this.pendingOffers = new Map(); // Map<rideId, Set<driverId>>
  }

  /**
   * Initialise les handlers Socket.io pour les courses
   */
  initialize() {
    // Note: Les connexions client sont maintenant gérées par le namespace /ws/client
    // dans server.postgres.js. Le handler ci-dessous est conservé pour compatibilité
    // avec les clients se connectant au namespace par défaut.
    // Namespace pour les clients (namespace par défaut - legacy)
    this.io.on('connection', (socket) => {
      this.handleClientConnection(socket);
    });

    // Namespace pour les chauffeurs
    if (this.driverNamespace) {
      this.driverNamespace.on('connection', (socket) => {
        this.handleDriverConnection(socket);
      });
    }

    // Note: Le namespace client (/ws/client) est géré directement dans server.postgres.js
    // et n'a pas besoin d'être initialisé ici car il utilise les mêmes rooms.
  }

  /**
   * Gère les connexions des clients
   */
  handleClientConnection(socket) {
    console.log('🔵 Client connecté:', socket.id);

    // Le client rejoint la room de sa course
    socket.on('ride:join', async (rideId) => {
      socket.join(`ride:${rideId}`);
      console.log(`✅ Client rejoint la course ${rideId}`);
    });

    // Le client quitte la room de sa course
    socket.on('ride:leave', (rideId) => {
      socket.leave(`ride:${rideId}`);
      console.log(`👋 Client quitte la course ${rideId}`);
    });

    socket.on('disconnect', () => {
      console.log('🔴 Client déconnecté:', socket.id);
    });
  }

  /**
   * Gère les connexions des chauffeurs
   */
  handleDriverConnection(socket) {
    const driverId = socket.driverId;
    console.log(`🟢 Chauffeur ${driverId} connecté via WebSocket`);

    // Le chauffeur rejoint sa room personnelle
    socket.join(`driver:${driverId}`);

    // Le chauffeur accepte une course (ride_offer)
    socket.on('ride:accept', async (data) => {
      await this.handleRideAcceptance(driverId, data.rideId, socket);
    });

    // Le chauffeur refuse une course
    socket.on('ride:reject', async (data) => {
      await this.handleRideRejection(driverId, data.rideId);
    });

    // Le chauffeur met à jour le statut de la course
    socket.on('ride:status:update', async (data) => {
      await this.handleRideStatusUpdate(driverId, data.rideId, data.status);
    });

    socket.on('disconnect', () => {
      console.log(`🔴 Chauffeur ${driverId} déconnecté`);
    });
  }

  /**
   * Traite une nouvelle demande de course (ride_request)
   * Trouve les chauffeurs proches et leur envoie ride_offer
   */
  async processRideRequest(ride) {
    try {
      const rideRepository = AppDataSource.getRepository(Ride);
      const userRepository = AppDataSource.getRepository(User);

      // Récupérer la course complète avec relations
      const fullRide = await rideRepository.findOne({
        where: { id: ride.id },
        relations: ['client']
      });

      if (!fullRide) {
        console.error('❌ Course non trouvée:', ride.id);
        return;
      }

      // Extraire les coordonnées de pickup
      const pickupCoords = fullRide.pickupLocation.coordinates;
      const pickupLat = pickupCoords[1];
      const pickupLon = pickupCoords[0];

      // Trouver les chauffeurs proches (rayon de 10 km)
      const nearbyDrivers = await this.findNearbyDrivers(
        pickupLat,
        pickupLon,
        10 // 10 km de rayon
      );

      if (nearbyDrivers.length === 0) {
        console.log('⚠️ Aucun chauffeur proche trouvé pour la course', ride.id);
        
        // Notifier le client qu'aucun chauffeur n'est disponible
        if (fullRide.client?.fcmToken) {
          await sendNotification(fullRide.client.fcmToken, {
            title: 'Recherche de chauffeur',
            body: 'Aucun chauffeur disponible pour le moment. Nous continuons la recherche...',
            data: {
              rideId: ride.id.toString(),
              type: 'no_driver_available'
            }
          });
        }

        // Émettre un événement au client
        this.io.to(`ride:${ride.id}`).emit('ride_update', {
          type: 'no_driver_available',
          rideId: ride.id,
          message: 'Aucun chauffeur disponible pour le moment',
          timestamp: new Date()
        });

        // Émettre aussi vers le namespace client si disponible
        if (this.clientNamespace) {
          this.clientNamespace.to(`ride:${ride.id}`).emit('ride_update', {
            type: 'no_driver_available',
            rideId: ride.id,
            message: 'Aucun chauffeur disponible pour le moment',
            timestamp: new Date()
          });
        }

        return;
      }

      // Préparer les données de la course pour les chauffeurs
      const rideOfferData = {
        type: 'ride_offer',
        ride: {
          id: fullRide.id.toString(),
          pickupAddress: fullRide.pickupAddress,
          dropoffAddress: fullRide.dropoffAddress,
          pickupLocation: {
            latitude: pickupLat,
            longitude: pickupLon
          },
          dropoffLocation: {
            latitude: fullRide.dropoffLocation.coordinates[1],
            longitude: fullRide.dropoffLocation.coordinates[0]
          },
          estimatedDistance: parseFloat(fullRide.distance) || 0,
          estimatedPrice: parseFloat(fullRide.estimatedPrice) || 0,
          passengerName: fullRide.client?.name || 'Passager',
          createdAt: fullRide.createdAt.toISOString()
        },
        timestamp: new Date()
      };

      // Initialiser le suivi de cette course
      this.activeRides.set(ride.id, {
        accepted: false,
        acceptedBy: null,
        createdAt: new Date()
      });
      this.pendingOffers.set(ride.id, new Set());

      // Envoyer ride_offer à tous les chauffeurs proches
      let offersSent = 0;
      for (const driver of nearbyDrivers) {
        // Ajouter le chauffeur à la liste des offres en attente
        this.pendingOffers.get(ride.id).add(driver.id);

        // Envoyer via Socket.io si le chauffeur est connecté
        if (this.driverNamespace) {
          this.driverNamespace.to(`driver:${driver.id}`).emit('ride_offer', rideOfferData);
          offersSent++;
          console.log(`📡 ride_offer envoyé via Socket.io au chauffeur ${driver.id}`);
        }

        // Envoyer une notification push Firebase (même si le chauffeur est connecté via Socket.io)
        // Cela garantit que le chauffeur reçoit la notification même s'il n'est pas sur l'écran de l'app
        if (driver.fcmToken) {
          try {
            await sendNotification(driver.fcmToken, {
              title: 'Nouvelle course disponible 🚗',
              body: `${rideOfferData.ride.pickupAddress} → ${rideOfferData.ride.dropoffAddress}`,
              data: {
                rideId: ride.id.toString(),
                type: 'ride_offer',
                estimatedPrice: rideOfferData.ride.estimatedPrice.toString(),
                estimatedDistance: rideOfferData.ride.estimatedDistance.toString()
              },
              priority: 'high'
            });
            console.log(`📲 Notification push envoyée au chauffeur ${driver.id}`);
          } catch (error) {
            console.error(`❌ Erreur envoi notification push au chauffeur ${driver.id}:`, error);
          }
        } else {
          console.log(`⚠️ Pas de token FCM pour le chauffeur ${driver.id}`);
        }
      }

      console.log(`📨 ${offersSent} offres envoyées pour la course ${ride.id} à ${nearbyDrivers.length} chauffeurs`);

      // Notifier le client que la recherche est en cours
      this.io.to(`ride:${ride.id}`).emit('ride_update', {
        type: 'searching_drivers',
        rideId: ride.id,
        message: `${nearbyDrivers.length} chauffeur(s) notifié(s)`,
        driversNotified: nearbyDrivers.length,
        timestamp: new Date()
      });

      // Émettre aussi vers le namespace client si disponible
      if (this.clientNamespace) {
        this.clientNamespace.to(`ride:${ride.id}`).emit('ride_update', {
          type: 'searching_drivers',
          rideId: ride.id,
          message: `${nearbyDrivers.length} chauffeur(s) notifié(s)`,
          driversNotified: nearbyDrivers.length,
          timestamp: new Date()
        });
      }

    } catch (error) {
      console.error('❌ Erreur traitement ride_request:', error);
    }
  }

  /**
   * Traite l'acceptation d'une course par un chauffeur
   * Gère la concurrence : seul le premier qui accepte gagne
   */
  async handleRideAcceptance(driverId, rideId, socket) {
    try {
      const rideRepository = AppDataSource.getRepository(Ride);
      const userRepository = AppDataSource.getRepository(User);

      // Vérifier si la course existe encore et est disponible
      const ride = await rideRepository.findOne({
        where: { id: parseInt(rideId) },
        relations: ['client', 'driver']
      });

      if (!ride) {
        socket.emit('ride:error', {
          type: 'ride_not_found',
          message: 'Course non trouvée'
        });
        return;
      }

      // Vérifier le statut de la course (concurrence)
      const rideStatus = this.activeRides.get(parseInt(rideId));
      
      if (!rideStatus) {
        socket.emit('ride:error', {
          type: 'ride_expired',
          message: 'Cette course n\'est plus disponible'
        });
        return;
      }

      if (rideStatus.accepted) {
        socket.emit('ride:error', {
          type: 'ride_already_accepted',
          message: 'Cette course a déjà été acceptée par un autre chauffeur'
        });
        return;
      }

      if (ride.status !== 'pending') {
        socket.emit('ride:error', {
          type: 'ride_not_available',
          message: 'Cette course n\'est plus disponible'
        });
        return;
      }

      // Vérifier que le chauffeur est dans la liste des chauffeurs notifiés
      const pendingSet = this.pendingOffers.get(parseInt(rideId));
      if (!pendingSet || !pendingSet.has(driverId)) {
        socket.emit('ride:error', {
          type: 'not_authorized',
          message: 'Vous n\'avez pas reçu cette offre de course'
        });
        return;
      }

      // ✅ ACCEPTATION : Marquer comme acceptée (atomic)
      rideStatus.accepted = true;
      rideStatus.acceptedBy = driverId;
      rideStatus.acceptedAt = new Date();

      // Mettre à jour la course dans la base de données
      ride.driverId = driverId;
      ride.status = 'accepted';
      await rideRepository.save(ride);

      // Mettre à jour le statut du chauffeur
      const driver = await userRepository.findOne({ where: { id: driverId } });
      if (driver) {
        const driverInfo = driver.driverInfo || {};
        driverInfo.status = 'en_route_to_pickup';
        driverInfo.currentRideId = ride.id;
        driverInfo.isOnline = true;
        
        await AppDataSource.query(
          `UPDATE users 
           SET driver_info = $1::jsonb, updated_at = NOW()
           WHERE id = $2`,
          [JSON.stringify(driverInfo), driver.id]
        );
      }

      // Préparer les données de réponse
      const rideAcceptedData = {
        type: 'ride_accepted',
        rideId: ride.id.toString(),
        driverId: driverId.toString(),
        driverName: driver?.name || 'Chauffeur',
        timestamp: new Date()
      };

      // 🔔 Notifier le client via Socket.io (namespace principal et namespace client)
      this.io.to(`ride:${ride.id}`).emit('ride_update', {
        ...rideAcceptedData,
        ride: {
          id: ride.id,
          status: 'accepted',
          driverId: driverId,
          driverName: driver?.name || 'Chauffeur',
          pickupAddress: ride.pickupAddress,
          dropoffAddress: ride.dropoffAddress,
          estimatedPrice: parseFloat(ride.estimatedPrice)
        }
      });

      // Émettre aussi vers le namespace client si disponible
      if (this.clientNamespace) {
        this.clientNamespace.to(`ride:${ride.id}`).emit('ride_update', {
          ...rideAcceptedData,
          ride: {
            id: ride.id,
            status: 'accepted',
            driverId: driverId,
            driverName: driver?.name || 'Chauffeur',
            pickupAddress: ride.pickupAddress,
            dropoffAddress: ride.dropoffAddress,
            estimatedPrice: parseFloat(ride.estimatedPrice)
          }
        });
      }

      // 🔔 Notifier le client via Firebase Cloud Messaging
      if (ride.client?.fcmToken) {
        await sendNotification(ride.client.fcmToken, {
          title: 'Course acceptée ! 🎉',
          body: `${driver?.name || 'Votre chauffeur'} a accepté votre course`,
          data: {
            rideId: ride.id.toString(),
            type: 'ride_accepted',
            driverId: driverId.toString(),
            driverName: driver?.name || 'Chauffeur'
          }
        });
      }

      // 🔔 Confirmer au chauffeur que l'acceptation a réussi
      socket.emit('ride:accepted', {
        success: true,
        ride: {
          id: ride.id,
          status: 'accepted',
          clientName: ride.client?.name || 'Client',
          pickupAddress: ride.pickupAddress,
          dropoffAddress: ride.dropoffAddress,
          estimatedPrice: parseFloat(ride.estimatedPrice)
        },
        timestamp: new Date()
      });

      // 🔔 Notifier les autres chauffeurs que la course a été acceptée
      if (this.driverNamespace) {
        this.driverNamespace.emit('ride:unavailable', {
          type: 'ride_accepted_by_other',
          rideId: ride.id.toString(),
          message: 'Cette course a été acceptée par un autre chauffeur'
        });
      }

      // Nettoyer les données de suivi
      this.pendingOffers.delete(parseInt(rideId));

      console.log(`✅ Course ${rideId} acceptée par le chauffeur ${driverId}`);

      // Créer une notification dans la base de données
      await createNotification(ride.clientId, 'ride_accepted', 'Course acceptée', `Votre course a été acceptée par ${driver?.name || 'un chauffeur'}`, ride.id);

    } catch (error) {
      console.error('❌ Erreur acceptation course:', error);
      socket.emit('ride:error', {
        type: 'acceptance_failed',
        message: 'Erreur lors de l\'acceptation de la course'
      });
    }
  }

  /**
   * Traite le rejet d'une course par un chauffeur
   */
  async handleRideRejection(driverId, rideId) {
    try {
      const pendingSet = this.pendingOffers.get(parseInt(rideId));
      if (pendingSet) {
        pendingSet.delete(driverId);
      }

      console.log(`🚫 Chauffeur ${driverId} a refusé la course ${rideId}`);

      // Si tous les chauffeurs ont refusé, on peut proposer à d'autres ou annuler
      if (pendingSet && pendingSet.size === 0) {
        const rideStatus = this.activeRides.get(parseInt(rideId));
        if (rideStatus && !rideStatus.accepted) {
          // Tous les chauffeurs ont refusé, notifier le client
          this.io.to(`ride:${rideId}`).emit('ride_update', {
            type: 'all_drivers_rejected',
            rideId: rideId.toString(),
            message: 'Aucun chauffeur n\'a accepté votre course. Nous recherchons d\'autres options...',
            timestamp: new Date()
          });

          // Émettre aussi vers le namespace client si disponible
          if (this.clientNamespace) {
            this.clientNamespace.to(`ride:${rideId}`).emit('ride_update', {
              type: 'all_drivers_rejected',
              rideId: rideId.toString(),
              message: 'Aucun chauffeur n\'a accepté votre course. Nous recherchons d\'autres options...',
              timestamp: new Date()
            });
          }
        }
      }
    } catch (error) {
      console.error('❌ Erreur rejet course:', error);
    }
  }

  /**
   * Traite la mise à jour du statut d'une course
   */
  async handleRideStatusUpdate(driverId, rideId, status) {
    try {
      const rideRepository = AppDataSource.getRepository(Ride);
      const ride = await rideRepository.findOne({
        where: { id: parseInt(rideId) },
        relations: ['client', 'driver']
      });

      if (!ride || ride.driverId !== driverId) {
        return;
      }

      // Mettre à jour le statut dans la base de données
      ride.status = status;
      
      if (status === 'inProgress') {
        ride.startedAt = new Date();
      } else if (status === 'completed') {
        ride.completedAt = new Date();
        ride.finalPrice = ride.finalPrice || ride.estimatedPrice;
      }

      await rideRepository.save(ride);

      // Préparer les données de mise à jour
      const updateData = {
        type: 'ride_update',
        rideId: ride.id.toString(),
        status: status,
        timestamp: new Date(),
        ride: {
          id: ride.id,
          status: status,
          driverId: ride.driverId,
          pickupAddress: ride.pickupAddress,
          dropoffAddress: ride.dropoffAddress,
          estimatedPrice: parseFloat(ride.estimatedPrice),
          finalPrice: ride.finalPrice ? parseFloat(ride.finalPrice) : null
        }
      };

      // 🔔 Notifier le client via Socket.io (namespace principal et namespace client)
      this.io.to(`ride:${rideId}`).emit('ride_update', updateData);
      
      // Émettre aussi vers le namespace client si disponible
      if (this.clientNamespace) {
        this.clientNamespace.to(`ride:${rideId}`).emit('ride_update', updateData);
      }

      // 🔔 Notifier le chauffeur via Socket.io
      if (this.driverNamespace) {
        this.driverNamespace.to(`driver:${driverId}`).emit('ride_update', updateData);
      }

      // 🔔 Notifier le client via Firebase Cloud Messaging
      if (ride.client?.fcmToken) {
        const statusMessages = {
          driverArriving: 'Votre chauffeur arrive',
          inProgress: 'Trajet en cours',
          completed: 'Trajet terminé',
          cancelled: 'Course annulée'
        };

        await sendNotification(ride.client.fcmToken, {
          title: statusMessages[status] || 'Mise à jour de course',
          body: `Le statut de votre course a été mis à jour`,
          data: {
            rideId: ride.id.toString(),
            type: 'ride_status_update',
            status: status
          }
        });
      }

      console.log(`📊 Course ${rideId} mise à jour: ${status}`);

    } catch (error) {
      console.error('❌ Erreur mise à jour statut:', error);
    }
  }

  /**
   * Trouve les chauffeurs proches d'un point géographique
   */
  async findNearbyDrivers(latitude, longitude, radiusKm = 10) {
    try {
      // Utiliser une requête SQL directe pour récupérer les chauffeurs proches avec leurs tokens FCM
      const radiusMeters = radiusKm * 1000;
      const drivers = await AppDataSource.query(
        `SELECT 
          u.id,
          u.name,
          u.phone_number,
          u.driver_info,
          u.fcm_token,
          ST_Distance(
            u.location::geography,
            ST_MakePoint($2, $1)::geography
          ) / 1000 AS distance_km,
          ST_Y(u.location::geometry) AS location_lat,
          ST_X(u.location::geometry) AS location_lon
        FROM users u
        WHERE u.role = 'driver'
          AND u.driver_info->>'isOnline' = 'true'
          AND u.location IS NOT NULL
          AND ST_DWithin(
            u.location::geography,
            ST_MakePoint($2, $1)::geography,
            $3
          )
        ORDER BY u.location <-> ST_MakePoint($2, $1)::geography
        LIMIT 20`,
        [latitude, longitude, radiusMeters]
      );

      // Convertir les résultats en format User
      return drivers.map(driver => ({
        id: driver.id,
        name: driver.name,
        phoneNumber: driver.phone_number,
        driverInfo: driver.driver_info,
        location: driver.location_lat && driver.location_lon ? {
          coordinates: [driver.location_lon, driver.location_lat],
          type: 'Point'
        } : null,
        distance_km: parseFloat(driver.distance_km) || 0,
        fcmToken: driver.fcm_token || null
      }));
    } catch (error) {
      console.error('❌ Erreur recherche chauffeurs proches:', error);
      // Fallback: utiliser TypeORM QueryBuilder
      try {
        const userRepository = AppDataSource.getRepository(User);
        const radiusMeters = radiusKm * 1000;
        
        const drivers = await userRepository
          .createQueryBuilder('user')
          .where('user.role = :role', { role: 'driver' })
          .andWhere('user.driver_info->>\'isOnline\' = :isOnline', { isOnline: 'true' })
          .andWhere('user.location IS NOT NULL')
          .andWhere(
            `ST_DWithin(
              user.location::geography,
              ST_MakePoint(:longitude, :latitude)::geography,
              :radius
            )`,
            { longitude, latitude, radius: radiusMeters }
          )
          .setParameters({ longitude, latitude })
          .orderBy(
            `user.location <-> ST_MakePoint(:longitude, :latitude)::geography`,
            'ASC'
          )
          .limit(20)
          .getMany();

        // Calculer la distance pour chaque chauffeur
        return await Promise.all(drivers.map(async (driver) => {
          let distance_km = 0;
          if (driver.location) {
            try {
              const distanceResult = await AppDataSource.query(
                `SELECT ST_Distance(
                  $1::geography,
                  ST_MakePoint($2, $3)::geography
                ) / 1000 AS distance_km`,
                [
                  `POINT(${driver.location.coordinates[0]} ${driver.location.coordinates[1]})`,
                  longitude,
                  latitude
                ]
              );
              distance_km = parseFloat(distanceResult[0]?.distance_km || 0);
            } catch (err) {
              console.error('Erreur calcul distance:', err);
            }
          }
          
          return {
            id: driver.id,
            name: driver.name,
            phoneNumber: driver.phoneNumber,
            driverInfo: driver.driverInfo,
            location: driver.location,
            distance_km: distance_km,
            fcmToken: driver.fcmToken || null
          };
        }));
      } catch (fallbackError) {
        console.error('❌ Erreur fallback recherche chauffeurs:', fallbackError);
        return [];
      }
    }
  }

  /**
   * Nettoie les courses expirées (plus de 10 minutes sans acceptation)
   */
  cleanupExpiredRides() {
    const now = new Date();
    const expirationTime = 10 * 60 * 1000; // 10 minutes

    for (const [rideId, rideStatus] of this.activeRides.entries()) {
      if (!rideStatus.accepted && (now - rideStatus.createdAt) > expirationTime) {
        this.activeRides.delete(rideId);
        this.pendingOffers.delete(rideId);
        console.log(`🧹 Course ${rideId} expirée et nettoyée`);
      }
    }
  }
}

module.exports = RealtimeRideService;

