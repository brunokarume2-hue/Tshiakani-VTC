# 🚀 Implémentation de la Communication Temps Réel pour les Courses

## 📋 Résumé

Système de communication temps réel entre clients, chauffeurs et serveur via Socket.io et Firebase Cloud Messaging (FCM).

## ✅ Fonctionnalités Implémentées

### 1. Communication Socket.io

#### Événements Client → Serveur
- `ride:join` : Le client rejoint la room de sa course
- `ride:leave` : Le client quitte la room de sa course

#### Événements Chauffeur → Serveur
- `ride:accept` : Le chauffeur accepte une course
- `ride:reject` : Le chauffeur refuse une course
- `ride:status:update` : Le chauffeur met à jour le statut de la course

#### Événements Serveur → Client/Chauffeur
- `ride_offer` : Offre de course envoyée aux chauffeurs proches
- `ride_accepted` : Course acceptée (notifie le client)
- `ride_update` : Mise à jour de la course en temps réel
- `ride:unavailable` : Course non disponible (notifie les autres chauffeurs)

### 2. Flux de Communication

```
1. CLIENT crée une course (POST /api/rides/create)
   ↓
2. SERVEUR trouve les chauffeurs proches (rayon de 10 km)
   ↓
3. SERVEUR envoie ride_offer à tous les chauffeurs proches
   - Via Socket.io (si connecté)
   - Via Firebase Cloud Messaging (notification push)
   ↓
4. CHAUFFEUR reçoit ride_offer
   ↓
5. CHAUFFEUR accepte (socket.emit('ride:accept'))
   ↓
6. SERVEUR vérifie la concurrence (premier arrivé, premier servi)
   ↓
7. SERVEUR notifie le CLIENT (ride_accepted)
   - Via Socket.io
   - Via Firebase Cloud Messaging
   ↓
8. SERVEUR notifie les autres chauffeurs (ride:unavailable)
```

### 3. Gestion de la Concurrence

Le système garantit qu'une course ne peut être acceptée qu'une seule fois :

1. **État initial** : `activeRides[rideId] = { accepted: false }`
2. **Chauffeurs notifiés** : `pendingOffers[rideId] = Set<driverId>`
3. **Acceptation** :
   - Vérification atomique : `if (!rideStatus.accepted)`
   - Marquage immédiat : `rideStatus.accepted = true`
   - Mise à jour de la base de données
   - Notification des autres parties

### 4. Notifications Firebase Cloud Messaging

#### Types de notifications
- **ride_offer** : Nouvelle course disponible
- **ride_accepted** : Course acceptée
- **ride_rejected** : Course refusée
- **ride_status_update** : Mise à jour de statut
- **ride_completed** : Course terminée
- **payment_validated** : Paiement validé

#### Configuration
- **Android** : Canal `rides_channel`, priorité haute
- **iOS** : Badge, son, content-available
- **Web** : Icon et badge

## 📁 Structure des Fichiers

```
backend/
├── modules/
│   └── rides/
│       ├── realtimeService.js      # Service principal de communication temps réel
│       └── README.md                # Documentation du module
├── utils/
│   └── notifications.js             # Service Firebase Cloud Messaging amélioré
├── server.postgres.js               # Serveur avec intégration du service temps réel
└── routes.postgres/
    └── rides.js                     # Routes API avec intégration temps réel
```

## 🔧 Configuration

### Variables d'environnement requises

```env
# Firebase Cloud Messaging
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY=your-private-key
FIREBASE_CLIENT_EMAIL=your-client-email

# JWT pour l'authentification Socket.io
JWT_SECRET=your-jwt-secret
```

### Installation

Le service temps réel est automatiquement initialisé au démarrage du serveur, après la connexion à PostgreSQL.

## 🎯 Utilisation

### Dans l'application Client (iOS/Swift)

```swift
// Se connecter à Socket.io
let socket = SocketManager(socketURL: URL(string: "http://localhost:3000")!)
socket.connect()

// Rejoindre une course
socket.emit("ride:join", with: [rideId])

// Écouter les mises à jour
socket.on("ride_update") { data, ack in
    if let update = data[0] as? [String: Any] {
        let type = update["type"] as? String
        switch type {
        case "searching_drivers":
            // Afficher "Recherche de chauffeur..."
        case "ride_accepted":
            // Afficher les informations du chauffeur
        case "ride_update":
            // Mettre à jour le statut de la course
        default:
            break
        }
    }
}
```

### Dans l'application Driver (iOS/Swift)

```swift
// Se connecter au namespace driver
let socket = SocketManager(
    socketURL: URL(string: "http://localhost:3000/ws/driver")!,
    config: [.log(true), .forceWebsockets(true)]
)

// Authentification
socket.connect(withAuth: ["token": driverToken])

// Écouter les offres de course
socket.on("ride_offer") { data, ack in
    if let offer = data[0] as? [String: Any],
       let ride = offer["ride"] as? [String: Any] {
        // Afficher l'offre de course
        let rideId = ride["id"] as? String
        let pickupAddress = ride["pickupAddress"] as? String
        let estimatedPrice = ride["estimatedPrice"] as? Double
    }
}

// Accepter une course
socket.emit("ride:accept", with: [["rideId": rideId]])

// Refuser une course
socket.emit("ride:reject", with: [["rideId": rideId]])

// Mettre à jour le statut
socket.emit("ride:status:update", with: [[
    "rideId": rideId,
    "status": "driverArriving" // ou "inProgress", "completed"
]])
```

## 🧪 Tests

### Tester la création d'une course

```bash
curl -X POST http://localhost:3000/api/rides/create \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_CLIENT_TOKEN" \
  -d '{
    "pickupLocation": {
      "latitude": -4.3276,
      "longitude": 15.3136,
      "address": "Avenue de la Justice, Kinshasa"
    },
    "dropoffLocation": {
      "latitude": -4.3317,
      "longitude": 15.3131,
      "address": "Avenue du Port, Kinshasa"
    }
  }'
```

### Vérifier les logs

Le serveur affiche des logs détaillés :
- `📨 X offres envoyées pour la course Y à Z chauffeurs`
- `✅ Course X acceptée par le chauffeur Y`
- `📊 Course X mise à jour: status`
- `📲 Notification push envoyée au chauffeur X`

## 🐛 Dépannage

### Les chauffeurs ne reçoivent pas les offres

1. Vérifier que les chauffeurs sont en ligne : `driver_info->>'isOnline' = 'true'`
2. Vérifier que les chauffeurs ont une localisation : `location IS NOT NULL`
3. Vérifier que les chauffeurs sont dans le rayon de 10 km
4. Vérifier les logs du serveur pour les erreurs

### Les notifications push ne fonctionnent pas

1. Vérifier la configuration Firebase dans `.env`
2. Vérifier que les tokens FCM sont enregistrés dans la base de données
3. Vérifier les logs Firebase pour les erreurs d'envoi
4. Vérifier que les tokens FCM ne sont pas expirés

### La concurrence ne fonctionne pas

1. Vérifier que `activeRides` est correctement initialisé
2. Vérifier que les vérifications atomiques fonctionnent
3. Vérifier les logs pour les tentatives d'acceptation multiples

## 📝 Notes

- Le système fonctionne même si Firebase n'est pas configuré (les notifications push seront simplement ignorées)
- Les notifications Socket.io fonctionnent en temps réel
- Les notifications FCM fonctionnent même si l'app est en arrière-plan
- La gestion de la concurrence garantit qu'une course ne peut être acceptée qu'une seule fois
- Les courses expirées (plus de 10 minutes sans acceptation) sont nettoyées automatiquement toutes les 5 minutes

## 🔮 Améliorations Futures

- [ ] Ajouter un système de file d'attente pour les courses non acceptées
- [ ] Implémenter un système de relance automatique des chauffeurs
- [ ] Ajouter des statistiques en temps réel (temps de réponse, taux d'acceptation)
- [ ] Implémenter un système de notation en temps réel
- [ ] Ajouter un système de chat en temps réel entre client et chauffeur

