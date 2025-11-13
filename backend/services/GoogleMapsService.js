//
//  GoogleMapsService.js
//  Tshiakani VTC
//
//  Service pour interagir avec Google Maps Platform APIs
//  - Routes API: Calcul de distance et temps de trajet
//  - Places API: Recherche d'adresses
//  - Geocoding API: Conversion d'adresses en coordonnées
//

const axios = require('axios');
const logger = require('../utils/logger');

/**
 * Service Google Maps Platform
 */
class GoogleMapsService {
  static API_BASE_URL = 'https://routes.googleapis.com';
  static GEOCODING_API_URL = 'https://maps.googleapis.com/maps/api/geocode/json';
  static PLACES_API_URL = 'https://maps.googleapis.com/maps/api/place';

  /**
   * Obtenir la clé API Google Maps
   */
  static getApiKey() {
    const apiKey = process.env.GOOGLE_MAPS_API_KEY;
    if (!apiKey) {
      logger.warn('GOOGLE_MAPS_API_KEY non configurée');
    }
    return apiKey;
  }

  /**
   * Calculer la distance et le temps de trajet avec Google Maps Routes API
   * @param {Object} origin - Point de départ {latitude, longitude}
   * @param {Object} destination - Point d'arrivée {latitude, longitude}
   * @param {Object} options - Options supplémentaires
   * @param {string} options.travelMode - Mode de transport (DRIVE, WALK, BICYCLE, TRANSIT)
   * @param {string} options.routingPreference - Préférence de routage (TRAFFIC_AWARE, TRAFFIC_AWARE_OPTIMAL)
   * @param {string} options.language - Langue de la réponse (fr, en)
   * @returns {Promise<Object>} {distance, duration, distanceText, durationText, polyline}
   */
  static async calculateRoute(origin, destination, options = {}) {
    try {
      const apiKey = this.getApiKey();
      if (!apiKey) {
        throw new Error('GOOGLE_MAPS_API_KEY non configurée');
      }

      const {
        travelMode = 'DRIVE',
        routingPreference = 'TRAFFIC_AWARE',
        language = 'fr',
        avoidTolls = false,
        avoidHighways = false,
        avoidFerries = false
      } = options;

      // Préparer la requête pour Routes API (v2)
      const requestBody = {
        origin: {
          location: {
            latLng: {
              latitude: origin.latitude,
              longitude: origin.longitude
            }
          }
        },
        destination: {
          location: {
            latLng: {
              latitude: destination.latitude,
              longitude: destination.longitude
            }
          }
        },
        travelMode: travelMode,
        routingPreference: routingPreference,
        computeAlternativeRoutes: false,
        languageCode: language,
        units: 'METRIC'
      };

      // Ajouter les restrictions de route
      if (avoidTolls || avoidHighways || avoidFerries) {
        requestBody.routeModifiers = {
          avoidTolls: avoidTolls,
          avoidHighways: avoidHighways,
          avoidFerries: avoidFerries
        };
      }

      // Faire la requête à Routes API
      const response = await axios.post(
        `${this.API_BASE_URL}/directions/v2:computeRoutes`,
        requestBody,
        {
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': apiKey,
            'X-Goog-FieldMask': 'routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline'
          },
          timeout: 10000 // 10 secondes
        }
      );

      if (!response.data || !response.data.routes || response.data.routes.length === 0) {
        throw new Error('Aucun itinéraire trouvé');
      }

      const route = response.data.routes[0];
      
      // La structure peut varier selon l'API utilisée
      // Routes API v2: route.legs[0].distanceMeters, route.legs[0].duration
      // Routes API v1: route.legs[0].distance.value, route.legs[0].duration.value
      let distanceMeters = 0;
      let durationSeconds = 0;

      if (route.legs && route.legs.length > 0) {
        const leg = route.legs[0];
        // Routes API v2
        if (leg.distanceMeters !== undefined) {
          distanceMeters = leg.distanceMeters;
        } else if (leg.distance && leg.distance.value !== undefined) {
          distanceMeters = leg.distance.value;
        }

        // Duration
        if (typeof leg.duration === 'string') {
          durationSeconds = parseInt(leg.duration.replace('s', '')) || 0;
        } else if (leg.duration && leg.duration.seconds !== undefined) {
          durationSeconds = parseInt(leg.duration.seconds) || 0;
        } else if (leg.duration && leg.duration.value !== undefined) {
          durationSeconds = parseInt(leg.duration.value) || 0;
        }
      } else {
        // Fallback: utiliser les valeurs au niveau route
        if (route.distanceMeters !== undefined) {
          distanceMeters = route.distanceMeters;
        }
        if (route.duration) {
          if (typeof route.duration === 'string') {
            durationSeconds = parseInt(route.duration.replace('s', '')) || 0;
          } else if (route.duration.seconds !== undefined) {
            durationSeconds = parseInt(route.duration.seconds) || 0;
          } else if (route.duration.value !== undefined) {
            durationSeconds = parseInt(route.duration.value) || 0;
          }
        }
      }

      // Convertir en unités plus lisibles
      const distanceKm = distanceMeters / 1000;
      const durationMinutes = Math.ceil(durationSeconds / 60);
      const durationHours = Math.floor(durationMinutes / 60);
      const durationMinutesRemainder = durationMinutes % 60;

      // Formater les textes
      let distanceText = '';
      if (distanceKm < 1) {
        distanceText = `${Math.round(distanceMeters)} m`;
      } else {
        distanceText = `${Math.round(distanceKm * 10) / 10} km`;
      }

      let durationText = '';
      if (durationHours > 0) {
        durationText = `${durationHours}h ${durationMinutesRemainder}min`;
      } else {
        durationText = `${durationMinutes}min`;
      }

      return {
        distance: {
          meters: distanceMeters,
          kilometers: Math.round(distanceKm * 100) / 100,
          text: distanceText
        },
        duration: {
          seconds: durationSeconds,
          minutes: durationMinutes,
          hours: durationHours,
          text: durationText
        },
        polyline: route.polyline?.encodedPolyline || null,
        route: route
      };
    } catch (error) {
      logger.error('Erreur calcul itinéraire Google Maps', {
        error: error.message,
        origin,
        destination,
        stack: error.stack
      });

      // Fallback: Calcul approximatif avec formule de Haversine
      return this.calculateDistanceHaversine(origin, destination);
    }
  }

  /**
   * Calcul approximatif de distance avec formule de Haversine (fallback)
   * @param {Object} origin - Point de départ {latitude, longitude}
   * @param {Object} destination - Point d'arrivée {latitude, longitude}
   * @returns {Object} {distance, duration, distanceText, durationText}
   */
  static calculateDistanceHaversine(origin, destination) {
    const R = 6371; // Rayon de la Terre en kilomètres
    const dLat = (destination.latitude - origin.latitude) * Math.PI / 180;
    const dLon = (destination.longitude - origin.longitude) * Math.PI / 180;
    const a = 
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(origin.latitude * Math.PI / 180) * Math.cos(destination.latitude * Math.PI / 180) *
      Math.sin(dLon / 2) * Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    const distanceKm = R * c;

    // Estimation du temps (vitesse moyenne de 30 km/h en ville)
    const averageSpeedKmh = 30;
    const durationMinutes = Math.ceil((distanceKm / averageSpeedKmh) * 60);

    return {
      distance: {
        meters: Math.round(distanceKm * 1000),
        kilometers: Math.round(distanceKm * 100) / 100,
        text: `${Math.round(distanceKm * 10) / 10} km`
      },
      duration: {
        seconds: durationMinutes * 60,
        minutes: durationMinutes,
        hours: 0,
        text: `${durationMinutes}min`
      },
      polyline: null,
      route: null,
      fallback: true // Indique que c'est un calcul approximatif
    };
  }

  /**
   * Géocoder une adresse (adresse -> coordonnées)
   * @param {string} address - Adresse à géocoder
   * @returns {Promise<Object>} {latitude, longitude, formattedAddress}
   */
  static async geocodeAddress(address) {
    try {
      const apiKey = this.getApiKey();
      if (!apiKey) {
        throw new Error('GOOGLE_MAPS_API_KEY non configurée');
      }

      const response = await axios.get(this.GEOCODING_API_URL, {
        params: {
          address: address,
          key: apiKey,
          language: 'fr'
        },
        timeout: 5000
      });

      if (response.data.status !== 'OK' || !response.data.results || response.data.results.length === 0) {
        throw new Error(`Géocodage échoué: ${response.data.status}`);
      }

      const result = response.data.results[0];
      const location = result.geometry.location;

      return {
        latitude: location.lat,
        longitude: location.lng,
        formattedAddress: result.formatted_address,
        placeId: result.place_id,
        addressComponents: result.address_components
      };
    } catch (error) {
      logger.error('Erreur géocodage adresse', {
        error: error.message,
        address
      });
      throw error;
    }
  }

  /**
   * Géocoder inversé (coordonnées -> adresse)
   * @param {number} latitude - Latitude
   * @param {number} longitude - Longitude
   * @returns {Promise<Object>} {formattedAddress, addressComponents}
   */
  static async reverseGeocode(latitude, longitude) {
    try {
      const apiKey = this.getApiKey();
      if (!apiKey) {
        throw new Error('GOOGLE_MAPS_API_KEY non configurée');
      }

      const response = await axios.get(this.GEOCODING_API_URL, {
        params: {
          latlng: `${latitude},${longitude}`,
          key: apiKey,
          language: 'fr'
        },
        timeout: 5000
      });

      if (response.data.status !== 'OK' || !response.data.results || response.data.results.length === 0) {
        throw new Error(`Géocodage inversé échoué: ${response.data.status}`);
      }

      const result = response.data.results[0];

      return {
        formattedAddress: result.formatted_address,
        placeId: result.place_id,
        addressComponents: result.address_components
      };
    } catch (error) {
      logger.error('Erreur géocodage inversé', {
        error: error.message,
        latitude,
        longitude
      });
      throw error;
    }
  }

  /**
   * Rechercher des places (autocomplete)
   * @param {string} query - Requête de recherche
   * @param {Object} location - Position de référence {latitude, longitude}
   * @param {number} radius - Rayon de recherche en mètres
   * @returns {Promise<Array>} Liste des places
   */
  static async searchPlaces(query, location = null, radius = 5000) {
    try {
      const apiKey = this.getApiKey();
      if (!apiKey) {
        throw new Error('GOOGLE_MAPS_API_KEY non configurée');
      }

      const params = {
        input: query,
        key: apiKey,
        language: 'fr',
        types: 'address'
      };

      if (location) {
        params.location = `${location.latitude},${location.longitude}`;
        params.radius = radius;
      }

      const response = await axios.get(`${this.PLACES_API_URL}/autocomplete/json`, {
        params,
        timeout: 5000
      });

      if (response.data.status !== 'OK' && response.data.status !== 'ZERO_RESULTS') {
        throw new Error(`Recherche de places échouée: ${response.data.status}`);
      }

      return (response.data.predictions || []).map(prediction => ({
        placeId: prediction.place_id,
        description: prediction.description,
        mainText: prediction.structured_formatting?.main_text || '',
        secondaryText: prediction.structured_formatting?.secondary_text || ''
      }));
    } catch (error) {
      logger.error('Erreur recherche de places', {
        error: error.message,
        query
      });
      return [];
    }
  }
}

module.exports = GoogleMapsService;

