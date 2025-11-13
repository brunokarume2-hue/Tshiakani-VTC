# 🔗 Guide d'Intégration du Dashboard Admin

Ce document explique comment le dashboard admin s'intègre avec le backend.

## 📋 Configuration

### Variables d'environnement

Le dashboard utilise les variables d'environnement suivantes (optionnelles, avec valeurs par défaut) :

```env
VITE_API_URL=http://localhost:3000/api
VITE_SOCKET_URL=http://localhost:3000
```

**Note** : Si vous ne créez pas de fichier `.env`, le dashboard utilisera les valeurs par défaut ci-dessus.

### Configuration CORS du Backend

Le backend doit autoriser les requêtes depuis le dashboard. Par défaut, le backend accepte les requêtes depuis :
- `http://localhost:3001` (port du dashboard en développement)
- `http://localhost:5173` (port Vite par défaut)

Pour personnaliser, définissez la variable d'environnement `CORS_ORIGIN` dans le backend.

## 🔌 Endpoints Utilisés

### Authentification

- `POST /api/auth/admin/login` - Connexion admin
- `GET /api/auth/verify` - Vérification du token

### Statistiques

- `GET /api/admin/stats` - Statistiques générales (utilisateurs, courses, revenus)

### Utilisateurs

- `GET /api/users` - Liste des utilisateurs (avec filtres)
- `POST /api/users/:userId/ban` - Bannir un utilisateur

### Courses

- `GET /api/admin/rides` - Liste des courses (avec filtres de statut et dates)

### Conducteurs

- `GET /api/admin/drivers` - Liste des conducteurs en ligne (avec filtres de localisation)

### Alertes SOS

- `GET /api/admin/sos` - Liste des alertes SOS (avec filtres de statut)
- `PATCH /api/sos/:sosId/resolve` - Résoudre une alerte SOS

## 🔐 Authentification

Le dashboard utilise JWT pour l'authentification :

1. Le token est stocké dans `localStorage` sous la clé `admin_token`
2. Le token est automatiquement ajouté aux requêtes via un intercepteur Axios
3. En cas d'erreur 401, l'utilisateur est redirigé vers la page de connexion

## 📡 Socket.io

Le dashboard se connecte à Socket.io pour recevoir les mises à jour en temps réel :

- **URL** : `http://localhost:3000` (ou `VITE_SOCKET_URL`)
- **Événements écoutés** :
  - `driver:location:update` - Mise à jour de la position d'un conducteur

## 🗂️ Structure des Données

### Utilisateur

```javascript
{
  id: number,
  name: string,
  phoneNumber: string,
  role: 'client' | 'driver' | 'admin',
  isVerified: boolean,
  driverInfo?: {
    isOnline: boolean,
    currentLocation?: {
      latitude: number,
      longitude: number,
      address: string
    }
  }
}
```

### Course

```javascript
{
  id: number,
  client: User,
  driver?: User,
  status: 'pending' | 'accepted' | 'inProgress' | 'completed' | 'cancelled',
  finalPrice?: number,
  estimatedPrice?: number,
  pickupAddress?: string,
  dropoffAddress?: string,
  createdAt: string
}
```

### Alerte SOS

```javascript
{
  id: number,
  user: User,
  ride?: Ride,
  location: {
    latitude: number,
    longitude: number,
    address?: string
  },
  status: 'active' | 'resolved' | 'false_alarm',
  createdAt: string
}
```

## 🚀 Démarrage

1. **Démarrer le backend** :
   ```bash
   cd backend
   npm run dev
   ```

2. **Démarrer le dashboard** :
   ```bash
   cd admin-dashboard
   npm run dev
   ```

3. **Accéder au dashboard** :
   Ouvrir http://localhost:3001

## 🔧 Dépannage

### Erreur CORS

Si vous voyez des erreurs CORS, vérifiez que :
1. Le backend autorise les requêtes depuis `http://localhost:3001`
2. La variable `CORS_ORIGIN` est correctement configurée

### Erreur 401 (Non autorisé)

1. Vérifiez que vous êtes connecté
2. Vérifiez que le token dans `localStorage` est valide
3. Vérifiez que le backend utilise le même `JWT_SECRET`

### Erreur de connexion Socket.io

1. Vérifiez que le backend est démarré
2. Vérifiez que Socket.io est correctement configuré dans le backend
3. Vérifiez l'URL Socket.io dans `MapView.jsx`

## 📝 Notes

- Le dashboard utilise React Router pour la navigation
- Les composants utilisent Tailwind CSS pour le style
- Chart.js est utilisé pour les graphiques dans le tableau de bord
- Les dates sont formatées avec `date-fns`

