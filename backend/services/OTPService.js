// Service pour l'envoi et la vérification de codes OTP
// Supporte WhatsApp via Twilio et SMS via Twilio
// Utilise Redis (Memorystore) pour le stockage avec expiration automatique

const twilio = require('twilio');
const crypto = require('crypto');
const { getRedisService } = require('../server.postgres');
const logger = require('../utils/logger');

// Stockage temporaire des codes OTP (fallback si Redis n'est pas disponible)
const otpStore = new Map();

// Cache pour le formatage de numéro de téléphone (TTL: 1 heure)
const phoneFormatCache = new Map();
const PHONE_CACHE_TTL = 60 * 60 * 1000; // 1 heure en millisecondes

class OTPService {
  constructor() {
    // Initialiser Twilio si les credentials sont disponibles
    this.twilioClient = null;
    if (process.env.TWILIO_ACCOUNT_SID && process.env.TWILIO_AUTH_TOKEN) {
      this.twilioClient = twilio(
        process.env.TWILIO_ACCOUNT_SID,
        process.env.TWILIO_AUTH_TOKEN
      );
    }
    
    this.whatsappFrom = process.env.TWILIO_WHATSAPP_FROM || 'whatsapp:+14155238886';
    this.smsFrom = process.env.TWILIO_PHONE_NUMBER || null;
  }

  /**
   * Génère un code OTP à 6 chiffres
   * @returns {string} Code OTP
   */
  generateOTP() {
    return crypto.randomInt(100000, 999999).toString();
  }

  /**
   * Stocke un code OTP dans Redis avec expiration
   * @param {string} phoneNumber - Numéro de téléphone
   * @param {string} code - Code OTP
   * @param {number} expiresIn - Durée d'expiration en secondes (défaut: 600 = 10 minutes)
   * @returns {Promise<boolean>} Succès
   */
  async storeOTP(phoneNumber, code, expiresIn = 600) {
    try {
      const redisService = getRedisService();
      
      if (redisService && redisService.isReady()) {
        const key = `otp:${phoneNumber}`;
        const otpData = {
          code: code,
          attempts: '0',
          createdAt: new Date().toISOString()
        };
        
        // Stocker dans Redis avec expiration
        await redisService.client.hSet(key, otpData);
        await redisService.client.expire(key, expiresIn);
        
        logger.debug('OTP stored in Redis', { phoneNumber, expiresIn });
        return true;
      } else {
        // Fallback vers Map en mémoire si Redis n'est pas disponible
        logger.warn('Redis not available, using in-memory storage for OTP');
        otpStore.set(phoneNumber, {
          code,
          attempts: 0,
          createdAt: new Date(),
          expiresAt: new Date(Date.now() + expiresIn * 1000)
        });
        return true;
      }
    } catch (error) {
      logger.error('Error storing OTP in Redis', { error: error.message, phoneNumber });
      // Fallback vers Map
      otpStore.set(phoneNumber, {
        code,
        attempts: 0,
        createdAt: new Date(),
        expiresAt: new Date(Date.now() + expiresIn * 1000)
      });
      return true;
    }
  }

  /**
   * Récupère un code OTP depuis Redis
   * @param {string} phoneNumber - Numéro de téléphone
   * @returns {Promise<Object|null>} Données OTP ou null
   */
  async getOTP(phoneNumber) {
    try {
      const redisService = getRedisService();
      
      if (redisService && redisService.isReady()) {
        const key = `otp:${phoneNumber}`;
        const otpData = await redisService.client.hGetAll(key);
        
        if (!otpData || Object.keys(otpData).length === 0) {
          return null;
        }
        
        return {
          code: otpData.code,
          attempts: parseInt(otpData.attempts || '0'),
          createdAt: new Date(otpData.createdAt),
          expiresAt: null // Redis gère l'expiration automatiquement via TTL
        };
      } else {
        // Fallback vers Map
        return otpStore.get(phoneNumber) || null;
      }
    } catch (error) {
      logger.error('Error getting OTP from Redis', { error: error.message, phoneNumber });
      return otpStore.get(phoneNumber) || null;
    }
  }

  /**
   * Supprime un code OTP de Redis
   * @param {string} phoneNumber - Numéro de téléphone
   */
  async deleteOTP(phoneNumber) {
    try {
      const redisService = getRedisService();
      
      if (redisService && redisService.isReady()) {
        const key = `otp:${phoneNumber}`;
        await redisService.client.del(key);
        logger.debug('OTP deleted from Redis', { phoneNumber });
      } else {
        // Fallback vers Map
        otpStore.delete(phoneNumber);
      }
    } catch (error) {
      logger.error('Error deleting OTP from Redis', { error: error.message, phoneNumber });
      otpStore.delete(phoneNumber);
    }
  }

  /**
   * Incrémente le nombre de tentatives pour un OTP
   * @param {string} phoneNumber - Numéro de téléphone
   */
  async incrementOTPAttempts(phoneNumber) {
    try {
      const redisService = getRedisService();
      
      if (redisService && redisService.isReady()) {
        const key = `otp:${phoneNumber}`;
        const currentAttempts = await redisService.client.hGet(key, 'attempts');
        const newAttempts = (parseInt(currentAttempts || '0') + 1).toString();
        await redisService.client.hSet(key, 'attempts', newAttempts);
      } else {
        // Fallback vers Map
        const stored = otpStore.get(phoneNumber);
        if (stored) {
          stored.attempts++;
          otpStore.set(phoneNumber, stored);
        }
      }
    } catch (error) {
      logger.error('Error incrementing OTP attempts', { error: error.message, phoneNumber });
      const stored = otpStore.get(phoneNumber);
      if (stored) {
        stored.attempts++;
        otpStore.set(phoneNumber, stored);
      }
    }
  }

  /**
   * Envoie un code OTP via WhatsApp
   * @param {string} phoneNumber - Numéro de téléphone (format international: +243900000000)
   * @param {string} code - Code OTP à envoyer
   * @returns {Promise<Object>} Résultat de l'envoi
   */
  async sendOTPViaWhatsApp(phoneNumber, code) {
    if (!this.twilioClient) {
      throw new Error('Twilio non configuré. Veuillez définir TWILIO_ACCOUNT_SID et TWILIO_AUTH_TOKEN');
    }

    // Formater le numéro pour WhatsApp (doit commencer par whatsapp:)
    const whatsappNumber = phoneNumber.startsWith('whatsapp:') 
      ? phoneNumber 
      : `whatsapp:${phoneNumber}`;

    try {
      // Utiliser body pour les messages texte simples
      const message = await this.twilioClient.messages.create({
        from: this.whatsappFrom,
        to: whatsappNumber,
        body: `🔐 Votre code de vérification Tshiakani VTC est: ${code}\n\nCe code expire dans 10 minutes.`
      });

      return {
        success: true,
        messageId: message.sid,
        channel: 'whatsapp'
      };
    } catch (error) {
      logger.error('Erreur envoi WhatsApp', { error: error.message, phoneNumber });
      throw new Error(`Erreur lors de l'envoi WhatsApp: ${error.message}`);
    }
  }

  /**
   * Valide et formate un numéro de téléphone pour Twilio
   * @param {string} phoneNumber - Numéro de téléphone
   * @returns {string} Numéro formaté
   */
  formatPhoneNumberForTwilio(phoneNumber) {
    // OPTIMISATION: Vérifier le cache d'abord
    const cacheKey = phoneNumber.trim();
    const cached = phoneFormatCache.get(cacheKey);
    if (cached && (Date.now() - cached.timestamp) < PHONE_CACHE_TTL) {
      return cached.formatted;
    }

    // Nettoyer le numéro (garder le +)
    let cleaned = phoneNumber.replace(/\s+/g, '').replace(/[\-()]/g, '');
    
    // S'assurer qu'il commence par +
    if (!cleaned.startsWith('+')) {
      // Si c'est un numéro congolais sans le +, ajouter +243
      if (cleaned.startsWith('243')) {
        cleaned = '+' + cleaned;
      } else if (cleaned.length === 9 && (cleaned.startsWith('8') || cleaned.startsWith('9'))) {
        // Numéro congolais sans indicatif (9 chiffres commençant par 8 ou 9)
        cleaned = '+243' + cleaned;
      } else {
        // Autre format, ajouter +
        cleaned = '+' + cleaned;
      }
    }
    
    // Valider le format E.164 (max 15 chiffres après le +)
    const e164Regex = /^\+[1-9]\d{1,14}$/;
    if (!e164Regex.test(cleaned)) {
      throw new Error(`Format de numéro invalide: ${phoneNumber}. Format attendu: +243XXXXXXXXX`);
    }
    
    // OPTIMISATION: Mettre en cache le résultat
    phoneFormatCache.set(cacheKey, {
      formatted: cleaned,
      timestamp: Date.now()
    });
    
    // Nettoyer le cache périodiquement (garder seulement les 1000 dernières entrées)
    if (phoneFormatCache.size > 1000) {
      const now = Date.now();
      for (const [key, value] of phoneFormatCache.entries()) {
        if (now - value.timestamp > PHONE_CACHE_TTL) {
          phoneFormatCache.delete(key);
        }
      }
    }
    
    return cleaned;
  }

  /**
   * Envoie un code OTP via SMS avec retry
   * @param {string} phoneNumber - Numéro de téléphone (format international)
   * @param {string} code - Code OTP à envoyer
   * @param {number} maxRetries - Nombre maximum de tentatives (défaut: 3)
   * @returns {Promise<Object>} Résultat de l'envoi
   */
  async sendOTPViaSMS(phoneNumber, code, maxRetries = 3) {
    if (!this.twilioClient || !this.smsFrom) {
      const errorMsg = 'Twilio SMS non configuré. Veuillez définir TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN et TWILIO_PHONE_NUMBER';
      logger.error(errorMsg, { 
        hasTwilioClient: !!this.twilioClient, 
        hasSmsFrom: !!this.smsFrom,
        twilioAccountSid: process.env.TWILIO_ACCOUNT_SID ? 'SET' : 'MISSING',
        twilioAuthToken: process.env.TWILIO_AUTH_TOKEN ? 'SET' : 'MISSING',
        twilioPhoneNumber: process.env.TWILIO_PHONE_NUMBER || 'MISSING'
      });
      throw new Error(errorMsg);
    }

    // Valider et formater le numéro
    let formattedPhone;
    try {
      formattedPhone = this.formatPhoneNumberForTwilio(phoneNumber);
    } catch (error) {
      logger.error('Erreur formatage numéro', { error: error.message, phoneNumber });
      throw error;
    }

    // Tentatives avec backoff exponentiel
    let lastError;
    for (let attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        logger.info('Tentative envoi SMS', { 
          attempt, 
          maxRetries, 
          phoneNumber: formattedPhone,
          from: this.smsFrom
        });

        const message = await this.twilioClient.messages.create({
          from: this.smsFrom,
          to: formattedPhone,
          body: `Votre code de vérification Tshiakani VTC est: ${code}. Ce code expire dans 10 minutes.`
        });

        logger.info('SMS envoyé avec succès', { 
          messageId: message.sid, 
          phoneNumber: formattedPhone,
          status: message.status
        });

        return {
          success: true,
          messageId: message.sid,
          channel: 'sms',
          status: message.status
        };
      } catch (error) {
        lastError = error;
        
        // Log détaillé de l'erreur
        const errorDetails = {
          attempt,
          maxRetries,
          phoneNumber: formattedPhone,
          errorCode: error.code,
          errorMessage: error.message,
          errorStatus: error.status,
          errorMoreInfo: error.moreInfo
        };
        
        logger.error('Erreur envoi SMS (tentative)', errorDetails);

        // Gérer les erreurs spécifiques de Twilio (ne pas retry pour ces erreurs)
        if (error.code === 21211 || error.code === 21408) {
          // Numéro invalide ou non autorisé - ne pas retry
          throw new Error(`Numéro de téléphone invalide: ${formattedPhone}. Veuillez vérifier le numéro.`);
        } else if (error.code === 21614) {
          // Numéro non vérifié (compte trial) - ne pas retry
          throw new Error(`Le numéro ${formattedPhone} n'est pas vérifié. Veuillez le vérifier dans votre compte Twilio (compte trial).`);
        } else if (error.code === 21608) {
          // Numéro non autorisé - ne pas retry
          throw new Error(`Le numéro ${formattedPhone} n'est pas autorisé. Veuillez vérifier votre compte Twilio.`);
        }

        // Si ce n'est pas la dernière tentative, attendre avant de réessayer
        if (attempt < maxRetries) {
          const delay = Math.pow(2, attempt) * 1000; // Backoff exponentiel: 2s, 4s, 8s
          logger.info(`Attente avant retry`, { delay, attempt });
          await new Promise(resolve => setTimeout(resolve, delay));
        }
      }
    }

    // Toutes les tentatives ont échoué
    logger.error('Échec envoi SMS après toutes les tentatives', { 
      phoneNumber: formattedPhone,
      lastError: lastError?.message,
      lastErrorCode: lastError?.code
    });
    
    throw new Error(`Impossible d'envoyer le SMS après ${maxRetries} tentatives. ${lastError?.message || 'Erreur inconnue'}`);
  }

  /**
   * Envoie un code OTP (essaie WhatsApp d'abord, puis SMS en fallback)
   * @param {string} phoneNumber - Numéro de téléphone
   * @param {string} preferredChannel - 'whatsapp' ou 'sms' (défaut: 'whatsapp')
   * @returns {Promise<Object>} Code OTP et résultat de l'envoi
   */
  async sendOTP(phoneNumber, preferredChannel = 'whatsapp') {
    let formattedPhone;
    try {
      // Valider et formater le numéro
      formattedPhone = this.formatPhoneNumberForTwilio(phoneNumber);
      logger.info('Envoi OTP demandé', { phoneNumber, formattedPhone, preferredChannel });
    } catch (error) {
      logger.error('Erreur formatage numéro dans sendOTP', { error: error.message, phoneNumber });
      throw error;
    }

    // Générer le code OTP
    const code = this.generateOTP();
    const expiresIn = 600; // 10 minutes en secondes

    logger.info('Code OTP généré', { phoneNumber: formattedPhone, codeLength: code.length });

    // Stocker le code OTP dans Redis (avec fallback vers Map) AVANT l'envoi
    // Cela permet de garder le code même si l'envoi échoue temporairement
    const stored = await this.storeOTP(formattedPhone, code, expiresIn);
    if (!stored) {
      logger.error('Impossible de stocker le code OTP', { phoneNumber: formattedPhone });
      throw new Error('Impossible de stocker le code OTP. Veuillez réessayer.');
    }

    // Envoyer le code
    let result;
    let sendError = null;
    
    try {
      if (preferredChannel === 'whatsapp') {
        logger.info('Tentative envoi WhatsApp', { phoneNumber: formattedPhone });
        try {
          result = await this.sendOTPViaWhatsApp(formattedPhone, code);
          logger.info('WhatsApp envoyé avec succès', { phoneNumber: formattedPhone, result });
        } catch (whatsappError) {
          logger.warn('WhatsApp échoué, tentative SMS en fallback', { 
            phoneNumber: formattedPhone, 
            error: whatsappError.message 
          });
          sendError = whatsappError;
          // Essayer SMS en fallback
          result = await this.sendOTPViaSMS(formattedPhone, code);
          logger.info('SMS envoyé avec succès (fallback)', { phoneNumber: formattedPhone, result });
        }
      } else {
        logger.info('Tentative envoi SMS', { phoneNumber: formattedPhone });
        result = await this.sendOTPViaSMS(formattedPhone, code);
        logger.info('SMS envoyé avec succès', { phoneNumber: formattedPhone, result });
      }
    } catch (error) {
      sendError = error;
      logger.error('Échec envoi OTP', { 
        phoneNumber: formattedPhone, 
        preferredChannel,
        error: error.message,
        errorCode: error.code,
        errorStack: error.stack
      });
      
      // NE PAS supprimer le code du store si l'envoi échoue
      // Le code reste valide et l'utilisateur peut demander un nouveau code
      // qui écrasera l'ancien
      
      // Lancer une erreur avec un message utilisateur-friendly
      let userMessage = 'Impossible d\'envoyer le code de vérification.';
      
      if (error.message.includes('non vérifié')) {
        userMessage = 'Votre numéro n\'est pas vérifié dans notre système. Veuillez contacter le support.';
      } else if (error.message.includes('invalide')) {
        userMessage = 'Le numéro de téléphone est invalide. Veuillez vérifier le numéro et réessayer.';
      } else if (error.message.includes('non autorisé')) {
        userMessage = 'Le numéro de téléphone n\'est pas autorisé. Veuillez contacter le support.';
      } else if (error.message.includes('tentatives')) {
        userMessage = 'Service temporairement indisponible. Veuillez réessayer dans quelques instants.';
      }
      
      throw new Error(userMessage);
    }

    logger.info('OTP envoyé avec succès', { 
      phoneNumber: formattedPhone, 
      channel: result.channel,
      messageId: result.messageId
    });

    return {
      ...result,
      code: code, // Pour les tests uniquement (ne pas exposer en production)
      expiresIn: 600, // 10 minutes en secondes
      phoneNumber: formattedPhone
    };
  }

  /**
   * Vérifie un code OTP
   * @param {string} phoneNumber - Numéro de téléphone
   * @param {string} code - Code OTP à vérifier
   * @returns {Promise<Object>} {valid: boolean, error?: string}
   */
  async verifyOTP(phoneNumber, code) {
    // Normaliser le numéro de téléphone
    const normalizedPhone = phoneNumber.replace(/\s+/g, '').replace(/[+\-]/g, '');
    const fullPhoneNumber = normalizedPhone.startsWith('+') 
      ? normalizedPhone 
      : `+${normalizedPhone}`;

    logger.debug('Vérification OTP', { phoneNumber, fullPhoneNumber, codeLength: code?.length });
    
    const stored = await this.getOTP(fullPhoneNumber);

    logger.debug('OTP récupéré', { stored: stored ? 'found' : 'not found', hasCode: !!stored?.code });

    if (!stored) {
      logger.warn('OTP non trouvé', { fullPhoneNumber });
      return { valid: false, error: 'Code non trouvé ou expiré. Veuillez demander un nouveau code.' };
    }

    // Vérifier l'expiration (pour le fallback Map uniquement)
    if (stored.expiresAt && Date.now() > stored.expiresAt.getTime()) {
      await this.deleteOTP(fullPhoneNumber);
      return { valid: false, error: 'Code expiré. Veuillez demander un nouveau code.' };
    }

    // Vérifier les tentatives (max 5)
    if (stored.attempts >= 5) {
      await this.deleteOTP(fullPhoneNumber);
      return { valid: false, error: 'Trop de tentatives. Veuillez demander un nouveau code.' };
    }

    // Vérifier le code
    if (stored.code !== code) {
      await this.incrementOTPAttempts(fullPhoneNumber);
      const updatedStored = await this.getOTP(fullPhoneNumber);
      const remainingAttempts = 5 - (updatedStored?.attempts || stored.attempts + 1);
      return { 
        valid: false, 
        error: `Code incorrect. Tentatives restantes: ${remainingAttempts}` 
      };
    }

    // Code valide - supprimer du store
    await this.deleteOTP(fullPhoneNumber);
    return { valid: true };
  }

  /**
   * Nettoie les codes expirés (à appeler périodiquement)
   * Note: Redis gère automatiquement l'expiration via TTL, donc cette fonction
   * nettoie uniquement le fallback Map en mémoire
   */
  cleanupExpiredCodes() {
    const now = Date.now();
    for (const [phoneNumber, data] of otpStore.entries()) {
      if (data.expiresAt && now > data.expiresAt.getTime()) {
        otpStore.delete(phoneNumber);
      }
    }
  }
}

// Nettoyer les codes expirés toutes les 5 minutes
const otpService = new OTPService();
setInterval(() => {
  otpService.cleanupExpiredCodes();
}, 5 * 60 * 1000);

module.exports = otpService;

