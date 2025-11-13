# 🔗 Connexion Dashboard ↔ Backend ↔ Apps Mobiles

## ✅ Oui, le dashboard est bien connecté au backend !

Le dashboard admin récupère **toutes les données des applications mobiles** via le backend qui utilise une **base de données PostgreSQL partagée**.

---

## 🏗️ Architecture

```
┌─────────────────┐         ┌──────────────────┐         ┌─────────────────┐
│                 │         │                  │         │                 │
│  App Client iOS │────────▶│                  │         │  App Driver iOS │
│                 │         │                  │         │                 │
└─────────────────┘         │   Backend API    │         └─────────────────┘
                            │  (Node.js/Express)│
┌─────────────────┐         │                  │         ┌─────────────────┐
│                 │         │                  │         │                 │
│  Dashboard Admin│────────▶│                  │         │  Base PostgreSQL│
│   (React/Vite)  │         │                  │◀────────│  (Partagée)     │
│                 │         │                  │         │                 │
└─────────────────┘         └──────────────────┘         └─────────────────┘
```

---

## 🔌 Connexion Dashboard → Backend

### Configuration

**Fichier:** `admin-dashboard/src/services/api.js`

```javascript
const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL || 'http://localhost:3000/api',
  headers: {
    'Content-Type': 'application/json'
  }
})
```

### Authentification

Le dashboard envoie :
- **Token JWT** dans le header `Authorization: Bearer <token>`
- **Clé API Admin** dans le header `X-ADMIN-API-KEY` pour les routes `/api/admin/*`

### Routes Utilisées par le Dashboard

Le dashboard appelle les routes backend suivantes :

| Route Backend | Dashboard Page | Données Récupérées |
|---------------|----------------|-------------------|
| `GET /api/admin/stats` | Dashboard | Statistiques générales (utilisateurs, courses, revenus) |
| `GET /api/admin/rides` | Courses | Liste de toutes les courses |
| `GET /api/admin/drivers` | Conducteurs | Liste des conducteurs |
| `GET /api/admin/drivers/:id` | Conducteurs | Détails d'un conducteur |
| `GET /api/admin/drivers/:id/stats` | Conducteurs | Statistiques d'un conducteur |
| `GET /api/admin/drivers/:id/rides` | Conducteurs | Courses d'un conducteur |
| `GET /api/admin/clients/:id` | Clients | Détails d'un client |
| `GET /api/admin/clients/:id/stats` | Clients | Statistiques d'un client |
| `GET /api/admin/clients/:id/rides` | Clients | Courses d'un client |
| `GET /api/admin/finance/stats` | Finance | Statistiques financières |
| `GET /api/admin/finance/transactions` | Finance | Transactions financières |
| `GET /api/admin/pricing` | Tarification | Configuration des prix |
| `POST /api/admin/pricing` | Tarification | Mise à jour des prix |
| `GET /api/admin/sos` | Alertes SOS | Liste des alertes SOS |
| `GET /api/admin/available_drivers` | Carte | Conducteurs disponibles |
| `GET /api/admin/active_rides` | Carte | Courses actives |
| `GET /api/users` | Utilisateurs | Liste des utilisateurs |
| `GET /api/notifications/all` | Notifications | Toutes les notifications |

---

## 💾 Base de Données Partagée

### PostgreSQL avec PostGIS

**Base de données:** `TshiakaniVTC` (PostgreSQL)

**Tables principales:**
- `users` - Tous les utilisateurs (clients, conducteurs, admins)
- `rides` - Toutes les courses créées par les apps mobile
- `notifications` - Toutes les notifications
- `sos_reports` - Toutes les alertes SOS
- `price_configurations` - Configuration des prix

### Relations

```sql
-- Table users
users (
  id, name, phone_number, role, is_verified,
  driver_info (JSONB), location (PostGIS),
  fcm_token, created_at, updated_at
)

-- Table rides
rides (
  id, client_id → users(id),
  driver_id → users(id),
  pickup_location (PostGIS),
  dropoff_location (PostGIS),
  status, estimated_price, final_price,
  distance_km, duration_min, payment_method,
  rating, comment, created_at, started_at,
  completed_at, cancelled_at
)
```

---

## 📱 Données des Apps Mobiles

### App Client iOS

L'app client crée des courses via :
- `POST /api/rides/create` → Crée une course dans la table `rides`
- `POST /api/location/update` → Met à jour la position dans `users.location`
- `POST /api/auth/signin` → Crée un utilisateur dans `users` (role: 'client')

### App Driver iOS

L'app driver gère les courses via :
- `POST /api/driver/accept_ride/:rideId` → Met à jour `rides.driver_id` et `rides.status`
- `POST /api/driver/location/update` → Met à jour `users.location` et `users.driver_info.isOnline`
- `POST /api/driver/complete_ride/:rideId` → Met à jour `rides.status` et `rides.final_price`
- `POST /api/auth/signin` → Crée un utilisateur dans `users` (role: 'driver')

---

## 🔄 Flux de Données

### 1. Création d'une Course

```
App Client iOS
    ↓
POST /api/rides/create
    ↓
Backend crée une course dans PostgreSQL
    ↓
Dashboard peut voir la course via GET /api/admin/rides
```

### 2. Acceptation d'une Course

```
App Driver iOS
    ↓
POST /api/driver/accept_ride/:rideId
    ↓
Backend met à jour rides.driver_id et rides.status
    ↓
Dashboard peut voir le conducteur assigné via GET /api/admin/rides
```

### 3. Complétion d'une Course

```
App Driver iOS
    ↓
POST /api/driver/complete_ride/:rideId
    ↓
Backend met à jour rides.status = 'completed' et rides.final_price
    ↓
Dashboard peut voir les revenus via GET /api/admin/finance/stats
```

### 4. Mise à jour de Position

```
App Driver iOS
    ↓
POST /api/driver/location/update
    ↓
Backend met à jour users.location (PostGIS)
    ↓
Dashboard peut voir la position via GET /api/admin/available_drivers
```

---

## 📊 Exemple Concret

### Statistiques Dashboard

Quand le dashboard appelle `GET /api/admin/stats`, le backend :

1. **Compte les utilisateurs** depuis `users` :
   ```sql
   SELECT COUNT(*) FROM users;
   SELECT COUNT(*) FROM users WHERE role = 'driver';
   SELECT COUNT(*) FROM users WHERE role = 'driver' AND driver_info->>'isOnline' = 'true';
   ```

2. **Compte les courses** depuis `rides` :
   ```sql
   SELECT COUNT(*) FROM rides;
   SELECT COUNT(*) FROM rides WHERE created_at >= today;
   SELECT COUNT(*) FROM rides WHERE status = 'completed';
   ```

3. **Calcule les revenus** depuis `rides` :
   ```sql
   SELECT SUM(final_price) FROM rides WHERE status = 'completed';
   ```

**Toutes ces données proviennent des apps mobile !** ✅

### Courses Dashboard

Quand le dashboard appelle `GET /api/admin/rides`, le backend :

1. **Récupère toutes les courses** depuis `rides` :
   ```sql
   SELECT * FROM rides
   LEFT JOIN users AS client ON rides.client_id = client.id
   LEFT JOIN users AS driver ON rides.driver_id = driver.id
   ORDER BY rides.created_at DESC;
   ```

2. **Affiche les informations** :
   - Client : `client.name`, `client.phone_number`
   - Conducteur : `driver.name`, `driver.phone_number`
   - Prix : `rides.final_price` ou `rides.estimated_price`
   - Statut : `rides.status`

**Toutes ces courses sont créées par les apps mobile !** ✅

---

## ✅ Vérification de la Connexion

### 1. Vérifier que le Backend est Démarré

```bash
curl http://localhost:3000/health
```

Réponse attendue :
```json
{
  "status": "OK",
  "database": "connected",
  "timestamp": "2024-01-01T00:00:00.000Z"
}
```

### 2. Vérifier que le Dashboard se Connecte

Dans le dashboard, ouvrez la console du navigateur (F12) et vérifiez :
- Les requêtes vers `http://localhost:3000/api/admin/*`
- Les réponses avec les données

### 3. Vérifier les Données dans la Base

```sql
-- Voir les utilisateurs
SELECT id, name, phone_number, role FROM users;

-- Voir les courses
SELECT id, client_id, driver_id, status, final_price FROM rides;

-- Voir les conducteurs en ligne
SELECT id, name, driver_info->>'isOnline' as is_online 
FROM users 
WHERE role = 'driver' AND driver_info->>'isOnline' = 'true';
```

---

## 🔐 Sécurité

### Authentification

1. **Dashboard** → Backend : Token JWT + Clé API Admin
2. **App Client** → Backend : Token JWT
3. **App Driver** → Backend : Token JWT

### Protection des Routes Admin

Toutes les routes `/api/admin/*` sont protégées par :
- `adminAuth` : Vérifie que l'utilisateur est admin
- `adminApiKeyAuth` : Vérifie la clé API admin

---

## 📝 Configuration Requise

### Variables d'Environnement Dashboard

**Fichier:** `admin-dashboard/.env`

```env
VITE_API_URL=http://localhost:3000/api
VITE_ADMIN_API_KEY=votre_cle_api_admin
```

### Variables d'Environnement Backend

**Fichier:** `backend/.env`

```env
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=postgres
DB_NAME=TshiakaniVTC
JWT_SECRET=votre_secret_jwt
ADMIN_API_KEY=votre_cle_api_admin
```

---

## 🎯 Conclusion

### ✅ Le dashboard EST connecté au backend

- Le dashboard appelle les routes backend via `http://localhost:3000/api`
- Le backend récupère les données depuis PostgreSQL
- Les apps mobile écrivent dans la même base PostgreSQL
- Le dashboard voit toutes les données des apps mobile en temps réel

### ✅ Le backend fournit les données des apps

- **Utilisateurs** : Tous les clients et conducteurs créés par les apps
- **Courses** : Toutes les courses créées par l'app client
- **Positions** : Toutes les positions mises à jour par les apps
- **Revenus** : Tous les revenus calculés depuis les courses complétées
- **Statistiques** : Toutes les statistiques calculées depuis les données des apps

### 🚀 Tout est connecté et fonctionnel !

Le dashboard récupère **en temps réel** toutes les données créées par les applications mobiles iOS via le backend PostgreSQL partagé.

