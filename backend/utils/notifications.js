const admin = require('firebase-admin');
const AppDataSource = require('../config/database');
const Notification = require('../entities/Notification');

// Initialiser Firebase Admin (optionnel - seulement si configuré)
let firebaseInitialized = false;

try {
  if (process.env.FIREBASE_PROJECT_ID && process.env.FIREBASE_PRIVATE_KEY) {
    // Vérifier si Firebase est déjà initialisé
    if (!admin.apps.length) {
      admin.initializeApp({
        credential: admin.credential.cert({
          projectId: process.env.FIREBASE_PROJECT_ID,
          privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
          clientEmail: process.env.FIREBASE_CLIENT_EMAIL
        })
      });
    }
    firebaseInitialized = true;
    console.log('✅ Firebase Admin initialisé');
  }
} catch (error) {
  console.warn('⚠️ Firebase Admin non configuré:', error.message);
}

/**
 * Types de notifications supportées
 */
const NOTIFICATION_TYPES = {
  RIDE_OFFER: 'ride_offer',
  RIDE_ACCEPTED: 'ride_accepted',
  RIDE_REJECTED: 'ride_rejected',
  RIDE_STATUS_UPDATE: 'ride_status_update',
  RIDE_COMPLETED: 'ride_completed',
  RIDE_CANCELLED: 'ride_cancelled',
  PAYMENT_VALIDATED: 'payment_validated',
  NO_DRIVER_AVAILABLE: 'no_driver_available'
};

/**
 * Envoyer une notification push via Firebase Cloud Messaging
 * @param {string} fcmToken - Token FCM de l'utilisateur
 * @param {Object} payload - Données de la notification
 * @param {string} payload.title - Titre de la notification
 * @param {string} payload.body - Corps de la notification
 * @param {Object} payload.data - Données supplémentaires (rideId, type, etc.)
 * @param {string} payload.priority - Priorité (normal ou high)
 * @param {Object} payload.apns - Configuration spécifique iOS (optionnel)
 * @returns {Promise<Object>} Résultat de l'envoi
 */
const sendNotification = async (fcmToken, payload) => {
  if (!firebaseInitialized || !fcmToken) {
    return { success: false, message: 'Firebase non configuré ou token manquant' };
  }

  try {
    // Préparer le message de base
    const message = {
      token: fcmToken,
      notification: {
        title: payload.title,
        body: payload.body
      },
      data: {
        // Convertir toutes les valeurs en string (requis par FCM)
        ...Object.fromEntries(
          Object.entries(payload.data || {}).map(([key, value]) => [key, String(value)])
        ),
        timestamp: new Date().toISOString()
      },
      // Configuration pour Android
      android: {
        priority: payload.priority || 'high',
        notification: {
          sound: 'default',
          channelId: 'rides_channel',
          importance: 'high',
          clickAction: 'FLUTTER_NOTIFICATION_CLICK'
        }
      },
      // Configuration pour iOS (APNs)
      apns: {
        payload: {
          aps: {
            alert: {
              title: payload.title,
              body: payload.body
            },
            sound: 'default',
            badge: 1,
            ...payload.apns?.payload?.aps
          }
        },
        ...payload.apns
      },
      // Configuration pour le web
      webpush: {
        notification: {
          title: payload.title,
          body: payload.body,
          icon: '/icon.png',
          badge: '/badge.png'
        }
      }
    };

    // Envoyer la notification
    const response = await admin.messaging().send(message);
    console.log(`✅ Notification envoyée avec succès: ${response}`);
    return { success: true, messageId: response };
  } catch (error) {
    console.error('❌ Erreur envoi notification:', error);
    
    // Gérer les erreurs spécifiques
    if (error.code === 'messaging/invalid-registration-token' || 
        error.code === 'messaging/registration-token-not-registered') {
      // Token invalide, devrait être supprimé de la base de données
      console.warn(`⚠️ Token FCM invalide pour ${fcmToken}, devrait être supprimé`);
    }
    
    return { success: false, error: error.message, code: error.code };
  }
};

/**
 * Envoyer des notifications à plusieurs utilisateurs
 * @param {Array<string>} fcmTokens - Liste des tokens FCM
 * @param {Object} payload - Données de la notification
 * @returns {Promise<Object>} Résultats de l'envoi
 */
const sendMulticastNotification = async (fcmTokens, payload) => {
  if (!firebaseInitialized || !fcmTokens || fcmTokens.length === 0) {
    return { success: false, message: 'Firebase non configuré ou tokens manquants' };
  }

  try {
    const message = {
      notification: {
        title: payload.title,
        body: payload.body
      },
      data: {
        ...Object.fromEntries(
          Object.entries(payload.data || {}).map(([key, value]) => [key, String(value)])
        ),
        timestamp: new Date().toISOString()
      },
      android: {
        priority: payload.priority || 'high',
        notification: {
          sound: 'default',
          channelId: 'rides_channel',
          importance: 'high'
        }
      },
      apns: {
        payload: {
          aps: {
            alert: {
              title: payload.title,
              body: payload.body
            },
            sound: 'default',
            badge: 1
          }
        }
      },
      tokens: fcmTokens
    };

    const response = await admin.messaging().sendMulticast(message);
    console.log(`✅ ${response.successCount} notifications envoyées sur ${fcmTokens.length}`);
    
    // Supprimer les tokens invalides
    if (response.failureCount > 0) {
      const invalidTokens = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          if (resp.error?.code === 'messaging/invalid-registration-token' ||
              resp.error?.code === 'messaging/registration-token-not-registered') {
            invalidTokens.push(fcmTokens[idx]);
          }
        }
      });
      
      if (invalidTokens.length > 0) {
        console.warn(`⚠️ ${invalidTokens.length} tokens invalides détectés`);
      }
    }

    return {
      success: true,
      successCount: response.successCount,
      failureCount: response.failureCount,
      responses: response.responses
    };
  } catch (error) {
    console.error('❌ Erreur envoi notifications multiples:', error);
    return { success: false, error: error.message };
  }
};

// Créer une notification dans la base de données
const createNotification = async (userId, type, title, message, rideId = null) => {
  try {
    const notificationRepository = AppDataSource.getRepository(Notification);
    const notification = notificationRepository.create({
      userId,
      type,
      title,
      message,
      rideId: rideId ? parseInt(rideId) : null
    });

    await notificationRepository.save(notification);
    return notification;
  } catch (error) {
    console.error('Erreur création notification:', error);
    return null;
  }
};

/**
 * Envoyer une notification pour une nouvelle course (ride_offer)
 */
const sendRideOfferNotification = async (fcmToken, rideData) => {
  return await sendNotification(fcmToken, {
    title: 'Nouvelle course disponible 🚗',
    body: `${rideData.pickupAddress} → ${rideData.dropoffAddress}`,
    data: {
      type: NOTIFICATION_TYPES.RIDE_OFFER,
      rideId: rideData.rideId.toString(),
      estimatedPrice: rideData.estimatedPrice.toString(),
      estimatedDistance: rideData.estimatedDistance.toString()
    },
    priority: 'high',
    apns: {
      payload: {
        aps: {
          sound: 'default',
          badge: 1,
          'content-available': 1
        }
      }
    }
  });
};

/**
 * Envoyer une notification pour une course acceptée (ride_accepted)
 */
const sendRideAcceptedNotification = async (fcmToken, rideData) => {
  return await sendNotification(fcmToken, {
    title: 'Course acceptée ! 🎉',
    body: `${rideData.driverName} a accepté votre course`,
    data: {
      type: NOTIFICATION_TYPES.RIDE_ACCEPTED,
      rideId: rideData.rideId.toString(),
      driverId: rideData.driverId.toString(),
      driverName: rideData.driverName
    },
    priority: 'high'
  });
};

/**
 * Envoyer une notification pour un paiement validé
 */
const sendPaymentValidatedNotification = async (fcmToken, paymentData) => {
  return await sendNotification(fcmToken, {
    title: 'Paiement validé ✅',
    body: `Votre paiement de ${paymentData.amount} ${paymentData.currency || 'CDF'} a été validé`,
    data: {
      type: NOTIFICATION_TYPES.PAYMENT_VALIDATED,
      rideId: paymentData.rideId.toString(),
      amount: paymentData.amount.toString(),
      currency: paymentData.currency || 'CDF',
      transactionId: paymentData.transactionId.toString()
    },
    priority: 'high'
  });
};

module.exports = {
  sendNotification,
  sendMulticastNotification,
  sendRideOfferNotification,
  sendRideAcceptedNotification,
  sendPaymentValidatedNotification,
  createNotification,
  NOTIFICATION_TYPES
};

