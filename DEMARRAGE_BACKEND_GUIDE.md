# 🚀 Guide de Démarrage du Backend

## 📋 Méthodes de Démarrage

### Méthode 1 : Script de Démarrage (Recommandé)

```bash
./demarrer-backend.sh
```

Ce script :
- ✅ Vérifie les prérequis (Node.js, npm)
- ✅ Vérifie la configuration (.env)
- ✅ Vérifie que le port 3000 est disponible
- ✅ Démarre le serveur en mode développement

### Méthode 2 : Commande npm Directe

```bash
cd backend
npm run dev    # Mode développement (avec rechargement automatique)
# ou
npm start      # Mode production
```

## ✅ Vérification du Démarrage

### 1. Vérifier que le serveur est en cours d'exécution

```bash
# Vérifier le processus
ps aux | grep "node.*server.postgres" | grep -v grep

# Vérifier le port
lsof -i :3000
```

### 2. Tester le Health Check

```bash
curl http://localhost:3000/health
```

Réponse attendue :
```json
{
  "status": "OK",
  "database": "connected",
  "timestamp": "2025-01-XX..."
}
```

### 3. Vérifier les Logs

Le serveur affiche les logs suivants lors du démarrage réussi :
```
✅ Connecté à PostgreSQL avec PostGIS
✅ PostGIS version: X.X.X
🚀 Serveur démarré sur le port 3000
📡 WebSocket namespace /ws/driver disponible
📡 WebSocket namespace /ws/client disponible
🌐 API disponible sur http://0.0.0.0:3000/api
⚡ Service temps réel des courses activé
```

## 🔧 Configuration Requise

### Fichier .env

Le fichier `backend/.env` doit contenir au minimum :

```env
# Base de données PostgreSQL
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=votre_mot_de_passe
DB_NAME=tshiakani_vtc

# JWT Secret
JWT_SECRET=votre_jwt_secret_ici

# Port du serveur
PORT=3000
```

### Prérequis

1. **Node.js 18+** et **npm**
2. **PostgreSQL 14+** avec **PostGIS**
3. Base de données créée et PostGIS activé

## 🚨 Problèmes Courants

### Problème 1 : Port 3000 déjà utilisé

**Solution** :
```bash
# Trouver le processus
lsof -ti:3000

# Arrêter le processus
kill -9 $(lsof -ti:3000)

# Ou changer le port dans .env
PORT=3001
```

### Problème 2 : Erreur de connexion PostgreSQL

**Symptôme** :
```
❌ Erreur de connexion PostgreSQL: ...
```

**Solutions** :
1. Vérifier que PostgreSQL est en cours d'exécution
2. Vérifier les credentials dans `.env`
3. Vérifier que la base de données existe
4. Vérifier que PostGIS est activé

### Problème 3 : Module non trouvé

**Symptôme** :
```
Error: Cannot find module '...'
```

**Solution** :
```bash
cd backend
npm install
```

## 📊 Commandes Utiles

### Démarrer le backend
```bash
cd backend
npm run dev
```

### Arrêter le backend
```bash
# Trouver le processus
ps aux | grep "node.*server.postgres"

# Arrêter le processus
kill -9 <PID>
```

### Vérifier les logs
```bash
# Les logs s'affichent dans le terminal où le serveur est démarré
# Pour rediriger vers un fichier :
npm run dev > backend.log 2>&1
```

### Tester la connexion
```bash
# Health check
curl http://localhost:3000/health

# Test authentification
curl -X POST http://localhost:3000/api/auth/signin \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber": "+243900000001", "role": "driver"}'
```

## 🔍 Vérification Post-Démarrage

Après le démarrage, vérifiez :

1. ✅ Le serveur écoute sur le port 3000
2. ✅ La base de données est connectée
3. ✅ PostGIS est activé
4. ✅ Les routes API sont accessibles
5. ✅ WebSocket namespaces sont disponibles

## 📝 Notes

- Le mode développement (`npm run dev`) utilise **nodemon** pour le rechargement automatique
- Le mode production (`npm start`) utilise **node** directement
- Les logs s'affichent dans la console où le serveur est démarré
- Le serveur écoute sur `0.0.0.0:3000` pour être accessible depuis toutes les interfaces (nécessaire pour Cloud Run)

---

**Date de création** : $(date)
**Statut** : ✅ Guide de démarrage créé
