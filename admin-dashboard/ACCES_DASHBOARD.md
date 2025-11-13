# 🚀 Guide d'Accès au Dashboard Admin

## 📋 Prérequis

1. **Node.js** installé (version 18+)
2. **MongoDB** en cours d'exécution
3. **Backend** démarré et accessible

## 🔧 Étapes pour accéder au dashboard

### 1. Démarrer le Backend

```bash
cd backend
npm install  # Si pas encore fait
npm run dev
```

Le backend sera accessible sur **http://localhost:3000**

### 2. Démarrer le Dashboard Admin

```bash
cd admin-dashboard
npm install  # Si pas encore fait
npm run dev
```

Le dashboard sera accessible sur **http://localhost:3001**

### 3. Accéder au Dashboard

Ouvrez votre navigateur et allez à :
```
http://localhost:3001
```

### 4. Se connecter

**Pour le développement**, la connexion est simplifiée :

- **Numéro de téléphone** : Entrez n'importe quel numéro (ex: `+243900000000`)
- **Mot de passe** : Laissez vide ou entrez n'importe quoi (optionnel pour le développement)

Le système créera automatiquement un compte admin si aucun n'existe avec ce numéro.

**Exemple de connexion :**
- Téléphone : `+243900000000`
- Mot de passe : (vide)

## 🔐 Création d'un compte admin manuel

Si vous voulez créer un compte admin manuellement dans MongoDB :

```javascript
// Dans MongoDB
use wewa_taxi

db.users.insertOne({
  name: "Admin",
  phoneNumber: "+243900000000",
  role: "admin",
  isVerified: true,
  createdAt: new Date(),
  updatedAt: new Date()
})
```

## 📱 Pages disponibles

Une fois connecté, vous aurez accès à :

- **📊 Tableau de bord** : Statistiques générales
- **🚗 Courses** : Historique et gestion des courses
- **👥 Utilisateurs** : Gestion des clients et conducteurs
- **🗺️ Carte** : Visualisation en temps réel
- **🚨 Alertes SOS** : Suivi des alertes d'urgence

## ⚠️ Dépannage

### Le dashboard ne se charge pas

1. Vérifiez que le backend est démarré : `http://localhost:3000/health`
2. Vérifiez que MongoDB est en cours d'exécution
3. Vérifiez les erreurs dans la console du navigateur (F12)

### Erreur de connexion

1. Vérifiez que le backend écoute sur le port 3000
2. Vérifiez l'URL de l'API dans `admin-dashboard/src/services/api.js`
3. Vérifiez les logs du backend pour voir les erreurs

### Erreur CORS

Le backend doit avoir CORS configuré. Vérifiez `backend/server.js` :
```javascript
app.use(cors({
  origin: process.env.CORS_ORIGIN || "http://localhost:3001",
  credentials: true
}));
```

## 🔄 Variables d'environnement

Créez un fichier `.env` dans `admin-dashboard/` si nécessaire :
```
VITE_API_URL=http://localhost:3000/api
```

Par défaut, le dashboard utilise `http://localhost:3000/api`.

