# Documentation Routes Backend - Classification MVP

## Vue d'ensemble

Ce document classe toutes les routes backend en trois catégories selon leur utilisation dans le MVP simplifié :
- **Routes MVP** : Utilisées actuellement par l'application iOS simplifiée
- **Routes Futures** : Disponibles mais non utilisées dans le MVP (réservées pour futures versions)
- **Routes à Développer** : Routes à créer pour les futures fonctionnalités

---

## Routes MVP (Utilisées actuellement)

Ces routes sont actives et utilisées par l'application iOS dans sa version MVP simplifiée.

### Authentification (`/api/auth`)

| Route | Méthode | Description | Statut |
|-------|---------|-------------|--------|
| `/api/auth/register` | POST | Inscription avec mot de passe | ✅ MVP |
| `/api/auth/login` | POST | Connexion avec mot de passe | ✅ MVP |
| `/api/auth/verify` | GET | Vérifier le token JWT | ✅ MVP |
| `/api/auth/forgot-password` | POST | Demande de réinitialisation de mot de passe | ✅ MVP |
| `/api/auth/reset-password` | POST | Réinitialisation de mot de passe avec OTP | ✅ MVP |
| `/api/auth/change-password` | POST | Changer le mot de passe (authentifié) | ✅ MVP |
| `/api/auth/set-password` | POST | Définir un mot de passe pour utilisateurs existants | ✅ MVP |

### Courses Client (`/api/v1/client`)

| Route | Méthode | Description | Statut |
|-------|---------|-------------|--------|
| `/api/v1/client/estimate` | POST | Estimation de prix et distance | ✅ MVP |
| `/api/v1/client/command/request` | POST | Créer une demande de course | ✅ MVP |
| `/api/v1/client/command/status/:ride_id` | GET | Récupérer le statut d'une course | ✅ MVP |
| `/api/v1/client/command/cancel/:ride_id` | POST | Annuler une course | ✅ MVP |
| `/api/v1/client/history` | GET | Historique des courses du client | ✅ MVP |
| `/api/v1/client/rate/:ride_id` | POST | Évaluer un chauffeur après la course | ✅ MVP |
| `/api/v1/client/driver/location/:driver_id` | GET | Position GPS du chauffeur | ✅ MVP |

### Suivi Temps Réel (`/api/client`)

| Route | Méthode | Description | Statut |
|-------|---------|-------------|--------|
| `/api/client/track_driver/:rideId` | GET | Suivre la position du chauffeur en temps réel | ✅ MVP |

### Profil Utilisateur (`/api/users`)

| Route | Méthode | Description | Statut |
|-------|---------|-------------|--------|
| `/api/users/me` | GET | Récupérer le profil de l'utilisateur connecté | ✅ MVP |

### Paiements (`/api/paiements`)

| Route | Méthode | Description | Statut |
|-------|---------|-------------|--------|
| `/api/paiements/preauthorize` | POST | Pré-autoriser un paiement Stripe | ✅ MVP |
| `/api/paiements/confirm` | POST | Confirmer un paiement pré-autorisé | ✅ MVP |

### Courses Legacy (`/api/rides`)

Ces routes sont maintenues pour compatibilité avec l'ancien code frontend.

| Route | Méthode | Description | Statut |
|-------|---------|-------------|--------|
| `/api/rides/estimate-price` | POST | Estimation de prix (legacy) | ✅ MVP (Legacy) |
| `/api/rides/create` | POST | Créer une course (legacy) | ✅ MVP (Legacy) |
| `/api/rides/history/:userId` | GET | Historique des courses (legacy) | ✅ MVP (Legacy) |
| `/api/rides/:rideId/rate` | POST | Évaluer une course (legacy) | ✅ MVP (Legacy) |

---

## Routes Futures (Disponibles mais non utilisées dans MVP)

Ces routes sont implémentées et fonctionnelles, mais ne sont pas utilisées dans la version MVP simplifiée. Elles sont disponibles pour les futures versions.

### Authentification (`/api/auth`)

| Route | Méthode | Description | Statut |
|-------|---------|-------------|--------|
| `/api/auth/profile` | PUT | Mettre à jour le profil (nom, fcmToken) | 🔮 Future |
| `/api/auth/google` | POST | Authentification avec Google | 🔮 Future |
| `/api/auth/signin` | POST | Inscription/Connexion legacy (OTP) | 🔮 Future |
| `/api/auth/admin/login` | POST | Connexion admin | 🔮 Future (Admin) |

### Notifications (`/api/notifications`)

| Route | Méthode | Description | Statut |
|-------|---------|-------------|--------|
| `/api/notifications` | GET | Récupérer les notifications | 🔮 Future |
| `/api/notifications/:notificationId/read` | PATCH | Marquer une notification comme lue | 🔮 Future |
| `/api/notifications/read-all` | PATCH | Marquer toutes les notifications comme lues | 🔮 Future |

### SOS (`/api/sos`)

| Route | Méthode | Description | Statut |
|-------|---------|-------------|--------|
| `/api/sos` | POST | Créer une alerte SOS | 🔮 Future |
| `/api/sos` | GET | Liste des alertes SOS (admin) | 🔮 Future (Admin) |
| `/api/sos/:sosId/resolve` | PATCH | Résoudre une alerte SOS | 🔮 Future (Admin) |

### Utilisateurs (`/api/users`)

| Route | Méthode | Description | Statut |
|-------|---------|-------------|--------|
| `/api/users` | GET | Liste des utilisateurs (admin) | 🔮 Future (Admin) |
| `/api/users/:userId/ban` | POST | Bannir un utilisateur (admin) | 🔮 Future (Admin) |

### Documents (`/api/documents`)

| Route | Méthode | Description | Statut |
|-------|---------|-------------|--------|
| `/api/documents/upload` | POST | Uploader un document | 🔮 Future |
| `/api/documents/url/:filePath` | GET | Obtenir l'URL d'un document | 🔮 Future |
| `/api/documents/:userId` | GET | Récupérer les documents d'un utilisateur | 🔮 Future |
| `/api/documents/:filePath` | DELETE | Supprimer un document | 🔮 Future |

### Location (`/api/location`)

| Route | Méthode | Description | Statut |
|-------|---------|-------------|--------|
| `/api/location/update` | POST | Mettre à jour la position | 🔮 Future |
| `/api/location/drivers/nearby` | GET | Chauffeurs à proximité | 🔮 Future |
| `/api/location/online` | POST | Activer/désactiver disponibilité | 🔮 Future |

---

## Routes à Développer (Pour futures fonctionnalités)

Ces routes doivent être développées pour supporter les fonctionnalités avancées prévues dans les futures versions.

### Gestion des Méthodes de Paiement Sauvegardées

| Route | Méthode | Description | Priorité |
|-------|---------|-------------|----------|
| `/api/payment-methods` | GET | Liste des méthodes de paiement sauvegardées | 🔴 Moyenne |
| `/api/payment-methods` | POST | Ajouter une méthode de paiement | 🔴 Moyenne |
| `/api/payment-methods/:id` | DELETE | Supprimer une méthode de paiement | 🔴 Moyenne |
| `/api/payment-methods/:id/set-default` | PUT | Définir comme méthode par défaut | 🔴 Moyenne |

### Gestion des Adresses Sauvegardées

| Route | Méthode | Description | Priorité |
|-------|---------|-------------|----------|
| `/api/addresses` | GET | Liste des adresses sauvegardées | 🔴 Moyenne |
| `/api/addresses` | POST | Ajouter une adresse sauvegardée | 🔴 Moyenne |
| `/api/addresses/:id` | PUT | Mettre à jour une adresse | 🔴 Moyenne |
| `/api/addresses/:id` | DELETE | Supprimer une adresse | 🔴 Moyenne |
| `/api/addresses/:id/set-default` | PUT | Définir comme adresse par défaut | 🔴 Moyenne |

### Préférences Utilisateur Avancées

| Route | Méthode | Description | Priorité |
|-------|---------|-------------|----------|
| `/api/preferences` | GET | Récupérer les préférences utilisateur | 🔴 Faible |
| `/api/preferences` | PUT | Mettre à jour les préférences | 🔴 Faible |
| `/api/preferences/language` | PUT | Changer la langue | 🔴 Faible |
| `/api/preferences/notifications` | PUT | Préférences de notifications | 🔴 Faible |

### Programme de Fidélité

| Route | Méthode | Description | Priorité |
|-------|---------|-------------|----------|
| `/api/loyalty/points` | GET | Points de fidélité | 🔴 Faible |
| `/api/loyalty/rewards` | GET | Liste des récompenses disponibles | 🔴 Faible |
| `/api/loyalty/rewards/:id/redeem` | POST | Échanger une récompense | 🔴 Faible |
| `/api/loyalty/history` | GET | Historique des points | 🔴 Faible |

### Chat en Temps Réel

| Route | Méthode | Description | Priorité |
|-------|---------|-------------|----------|
| `/api/chat/rides/:rideId/messages` | GET | Récupérer les messages d'une course | 🔴 Moyenne |
| `/api/chat/rides/:rideId/messages` | POST | Envoyer un message | 🔴 Moyenne |
| `/api/chat/support` | GET | Récupérer les messages de support | 🔴 Moyenne |
| `/api/chat/support` | POST | Envoyer un message de support | 🔴 Moyenne |

### Réservations Programmées

| Route | Méthode | Description | Priorité |
|-------|---------|-------------|----------|
| `/api/scheduled-rides` | GET | Liste des réservations programmées | 🔴 Haute |
| `/api/scheduled-rides` | POST | Créer une réservation programmée | 🔴 Haute |
| `/api/scheduled-rides/:id` | PUT | Modifier une réservation | 🔴 Haute |
| `/api/scheduled-rides/:id` | DELETE | Annuler une réservation | 🔴 Haute |

### Partage de Trajet

| Route | Méthode | Description | Priorité |
|-------|---------|-------------|----------|
| `/api/rides/:rideId/share` | POST | Partager un trajet | 🔴 Faible |
| `/api/rides/:rideId/join` | POST | Rejoindre un trajet partagé | 🔴 Faible |
| `/api/rides/:rideId/passengers` | GET | Liste des passagers | 🔴 Faible |

### Statistiques Personnelles

| Route | Méthode | Description | Priorité |
|-------|---------|-------------|----------|
| `/api/stats/personal` | GET | Statistiques personnelles | 🔴 Faible |
| `/api/stats/rides` | GET | Statistiques des courses | 🔴 Faible |
| `/api/stats/spending` | GET | Statistiques de dépenses | 🔴 Faible |

### Parrainage/Invitation

| Route | Méthode | Description | Priorité |
|-------|---------|-------------|----------|
| `/api/referral/code` | GET | Récupérer le code de parrainage | 🔴 Faible |
| `/api/referral/invite` | POST | Inviter un ami | 🔴 Faible |
| `/api/referral/rewards` | GET | Récompenses de parrainage | 🔴 Faible |

---

## Notes Importantes

### Compatibilité Legacy

Les routes legacy (`/api/rides/*`) sont maintenues pour assurer la compatibilité avec l'ancien code frontend. Il est recommandé d'utiliser les routes v1 (`/api/v1/client/*`) pour les nouvelles implémentations.

### Routes Admin

Les routes admin sont documentées mais ne sont pas utilisées dans l'application client iOS. Elles sont destinées au dashboard admin (React/Vite).

### WebSocket

Le système utilise Socket.io pour la communication en temps réel. Les événements WebSocket sont documentés dans `API_CLIENT_V1.md`.

### Sécurité

Toutes les routes (sauf `/api/auth/register`, `/api/auth/login`, `/api/auth/forgot-password`, `/api/auth/reset-password`, `/api/auth/set-password`) nécessitent une authentification JWT via le header `Authorization: Bearer <token>`.

---

## Références

- `API_CLIENT_V1.md` - Documentation complète de l'API Client v1
- `VERIFICATION_COMPLETUDE_BACKEND.md` - Vérification de complétude du backend
- `MAPPING_FRONTEND_BACKEND.md` - Mapping frontend/backend
- `README.md` - Documentation principale du backend

---

## Mise à Jour

Dernière mise à jour : Janvier 2025

Ce document doit être mis à jour à chaque ajout ou modification de routes backend.

