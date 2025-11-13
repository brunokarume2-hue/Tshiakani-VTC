# Guide de Test - Intégration Backend Complète

## Prérequis

1. PostgreSQL avec PostGIS installé et configuré
2. Base de données `TshiakaniVTC` créée
3. Backend démarré (`npm run dev`)
4. Token JWT valide pour l'authentification

## Étape 1 : Exécuter la Migration

```bash
cd backend
npm run migrate
```

Ou manuellement :
```bash
psql -U postgres -d TshiakaniVTC -f migrations/006_create_new_features_tables.sql
```

Vérifier que les tables ont été créées :
```sql
\dt
-- Devrait afficher : support_messages, support_tickets, favorite_addresses, 
--                    chat_messages, scheduled_rides, shared_rides
```

## Étape 2 : Démarrer le Backend

```bash
cd backend
npm run dev
```

Le serveur devrait démarrer sur `http://localhost:3000` par défaut.

## Étape 3 : Obtenir un Token JWT

### Connexion
```bash
curl -X POST http://localhost:3000/api/auth/signin \
  -H "Content-Type: application/json" \
  -d '{
    "phoneNumber": "+243900000001",
    "password": "password123"
  }'
```

Réponse attendue :
```json
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "name": "John Doe",
    "phoneNumber": "+243900000001",
    "role": "client"
  }
}
```

Copier le `token` pour les requêtes suivantes.

## Étape 4 : Tester les Endpoints

### 4.1 Support - Envoyer un Message

```bash
curl -X POST http://localhost:3000/api/support/message \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <TOKEN>" \
  -d '{
    "message": "J'ai un problème avec ma course"
  }'
```

Réponse attendue :
```json
{
  "success": true,
  "message": {
    "id": "1",
    "message": "J'ai un problème avec ma course",
    "isFromUser": true,
    "timestamp": "2024-01-01T12:00:00.000Z"
  }
}
```

### 4.2 Support - Récupérer les Messages

```bash
curl -X GET http://localhost:3000/api/support/messages \
  -H "Authorization: Bearer <TOKEN>"
```

Réponse attendue :
```json
{
  "success": true,
  "messages": [
    {
      "id": "1",
      "message": "J'ai un problème avec ma course",
      "isFromUser": true,
      "timestamp": "2024-01-01T12:00:00.000Z"
    }
  ]
}
```

### 4.3 Support - Créer un Ticket

```bash
curl -X POST http://localhost:3000/api/support/ticket \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <TOKEN>" \
  -d '{
    "subject": "Problème de paiement",
    "message": "Je n'arrive pas à payer ma course",
    "category": "payment"
  }'
```

### 4.4 Support - Récupérer la FAQ

```bash
curl -X GET http://localhost:3000/api/support/faq \
  -H "Authorization: Bearer <TOKEN>"
```

### 4.5 Favorites - Récupérer les Favoris

```bash
curl -X GET http://localhost:3000/api/favorites \
  -H "Authorization: Bearer <TOKEN>"
```

### 4.6 Favorites - Ajouter un Favori

```bash
curl -X POST http://localhost:3000/api/favorites \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <TOKEN>" \
  -d '{
    "name": "Maison",
    "address": "123 Rue Example, Kinshasa",
    "location": {
      "latitude": -4.3276,
      "longitude": 15.3136
    },
    "icon": "home"
  }'
```

### 4.7 Favorites - Supprimer un Favori

```bash
curl -X DELETE http://localhost:3000/api/favorites/1 \
  -H "Authorization: Bearer <TOKEN>"
```

### 4.8 Chat - Récupérer les Messages d'une Course

```bash
curl -X GET http://localhost:3000/api/chat/1/messages \
  -H "Authorization: Bearer <TOKEN>"
```

### 4.9 Chat - Envoyer un Message

```bash
curl -X POST http://localhost:3000/api/chat/1/messages \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <TOKEN>" \
  -d '{
    "message": "Bonjour, êtes-vous en route ?"
  }'
```

### 4.10 Chat - Marquer un Message comme Lu

```bash
curl -X PUT http://localhost:3000/api/chat/messages/1/read \
  -H "Authorization: Bearer <TOKEN>"
```

### 4.11 Scheduled Rides - Récupérer les Courses Programmées

```bash
curl -X GET http://localhost:3000/api/scheduled-rides \
  -H "Authorization: Bearer <TOKEN>"
```

### 4.12 Scheduled Rides - Créer une Course Programmée

```bash
curl -X POST http://localhost:3000/api/scheduled-rides \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <TOKEN>" \
  -d '{
    "pickupLocation": {
      "latitude": -4.3276,
      "longitude": 15.3136,
      "address": "123 Rue Example, Kinshasa"
    },
    "dropoffLocation": {
      "latitude": -4.3376,
      "longitude": 15.3236,
      "address": "456 Avenue Example, Kinshasa"
    },
    "scheduledDate": "2024-01-15T10:00:00.000Z",
    "vehicleType": "economy",
    "paymentMethod": "cash"
  }'
```

### 4.13 Scheduled Rides - Mettre à jour une Course Programmée

```bash
curl -X PUT http://localhost:3000/api/scheduled-rides/1 \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <TOKEN>" \
  -d '{
    "scheduledDate": "2024-01-15T11:00:00.000Z"
  }'
```

### 4.14 Scheduled Rides - Annuler une Course Programmée

```bash
curl -X DELETE http://localhost:3000/api/scheduled-rides/1 \
  -H "Authorization: Bearer <TOKEN>"
```

### 4.15 Share - Générer un Lien de Partage

```bash
curl -X GET http://localhost:3000/api/rides/1/share \
  -H "Authorization: Bearer <TOKEN>"
```

Réponse attendue :
```json
{
  "shareLink": "https://tshiakanivtc.com/share/1-abc123..."
}
```

### 4.16 Share - Partager une Course

```bash
curl -X POST http://localhost:3000/api/share/ride \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <TOKEN>" \
  -d '{
    "rideId": "1",
    "contacts": ["+243900000002", "+243900000003"],
    "link": "https://tshiakanivtc.com/share/1-abc123..."
  }'
```

### 4.17 Share - Partager une Position

```bash
curl -X POST http://localhost:3000/api/share/location \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <TOKEN>" \
  -d '{
    "rideId": "1",
    "location": {
      "latitude": -4.3276,
      "longitude": 15.3136
    }
  }'
```

### 4.18 Share - Récupérer les Courses Partagées

```bash
curl -X GET http://localhost:3000/api/share/rides \
  -H "Authorization: Bearer <TOKEN>"
```

### 4.19 SOS - Activer une Alerte SOS

```bash
curl -X POST http://localhost:3000/api/sos/alert \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <TOKEN>" \
  -d '{
    "latitude": -4.3276,
    "longitude": 15.3136,
    "message": "Besoin d'aide urgente"
  }'
```

### 4.20 SOS - Désactiver une Alerte SOS

```bash
curl -X POST http://localhost:3000/api/sos/deactivate \
  -H "Authorization: Bearer <TOKEN>"
```

## Étape 5 : Tester avec l'Application iOS

1. **Démarrer l'application iOS**
2. **Se connecter** avec un compte valide
3. **Tester chaque fonctionnalité** :
   - Support : Envoyer un message, créer un ticket, consulter la FAQ
   - Favorites : Ajouter/supprimer des favoris
   - Chat : Envoyer/recevoir des messages (nécessite une course active)
   - Scheduled Rides : Créer/modifier/annuler une course programmée
   - Share : Générer un lien de partage, partager une course
   - SOS : Activer/désactiver une alerte SOS

## Étape 6 : Vérifier les Logs

### Logs Backend
Vérifier les logs du serveur pour les erreurs éventuelles :
```bash
# Les logs devraient s'afficher dans la console
# Rechercher les erreurs : "❌" ou "ERROR"
```

### Logs iOS
Vérifier les logs de l'application iOS dans Xcode :
- Ouvrir la console Xcode
- Rechercher les erreurs : "❌" ou "Erreur"
- Vérifier les requêtes API : "🌐 APIService"

## Étape 7 : Vérifier la Base de Données

### Vérifier les Tables
```sql
-- Se connecter à PostgreSQL
psql -U postgres -d TshiakaniVTC

-- Vérifier les tables
\dt

-- Vérifier les données
SELECT * FROM support_messages;
SELECT * FROM support_tickets;
SELECT * FROM favorite_addresses;
SELECT * FROM chat_messages;
SELECT * FROM scheduled_rides;
SELECT * FROM shared_rides;
```

## Checklist de Test

### Support
- [ ] Envoyer un message de support
- [ ] Récupérer les messages de support
- [ ] Créer un ticket de support
- [ ] Récupérer les tickets de support
- [ ] Récupérer la FAQ
- [ ] Signaler un problème

### Favorites
- [ ] Récupérer les adresses favorites
- [ ] Ajouter une adresse favorite
- [ ] Supprimer une adresse favorite
- [ ] Mettre à jour une adresse favorite

### Chat
- [ ] Récupérer les messages d'une course
- [ ] Envoyer un message
- [ ] Marquer un message comme lu

### Scheduled Rides
- [ ] Récupérer les courses programmées
- [ ] Créer une course programmée
- [ ] Mettre à jour une course programmée
- [ ] Annuler une course programmée

### Share
- [ ] Générer un lien de partage
- [ ] Partager une course avec des contacts
- [ ] Partager une position en temps réel
- [ ] Récupérer les courses partagées

### SOS
- [ ] Activer une alerte SOS
- [ ] Désactiver une alerte SOS

## Problèmes Courants

### Erreur 401 (Unauthorized)
- Vérifier que le token JWT est valide
- Vérifier que le token est inclus dans le header `Authorization`
- Vérifier que le token n'est pas expiré

### Erreur 404 (Not Found)
- Vérifier que la route existe dans `server.postgres.js`
- Vérifier que l'URL est correcte
- Vérifier que le serveur est démarré

### Erreur 500 (Server Error)
- Vérifier les logs du serveur
- Vérifier que la base de données est accessible
- Vérifier que les migrations ont été exécutées

### Erreur de Connexion
- Vérifier que PostgreSQL est démarré
- Vérifier les credentials dans `.env`
- Vérifier que la base de données existe

## Notes

- Tous les endpoints nécessitent une authentification JWT (sauf `/api/auth/signin`)
- Tous les endpoints nécessitent que l'utilisateur soit connecté
- Les timestamps sont au format ISO 8601
- Les coordonnées géographiques sont au format WGS84 (latitude, longitude)

