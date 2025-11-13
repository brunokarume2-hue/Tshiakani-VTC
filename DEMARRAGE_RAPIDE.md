# 🚀 Démarrage Rapide - Tshiakani VTC

## ✅ Configuration Terminée

- ✅ Fichiers `.env` créés (backend et dashboard)
- ✅ Clé API Admin configurée et synchronisée
- ✅ JWT_SECRET généré et configuré automatiquement

## 📝 Dernière Étape : Configurer PostgreSQL

Éditez `backend/.env` et configurez votre mot de passe PostgreSQL :

```bash
cd backend
nano .env
# ou
code .env
```

**Variables à modifier :**
```env
DB_PASSWORD=votre_mot_de_passe_postgres
DB_USER=postgres  # Si différent
DB_NAME=tshiakani_vtc  # Si différent
```

## 🚀 Démarrer les Serveurs

### Option 1 : Script automatique (recommandé)

```bash
./demarrer-serveurs.sh
```

Ce script démarre automatiquement :
- Backend sur `http://localhost:3000`
- Dashboard sur `http://localhost:5173`

### Option 2 : Démarrage manuel

**Terminal 1 - Backend :**
```bash
cd backend
npm run dev
```

**Terminal 2 - Dashboard :**
```bash
cd admin-dashboard
npm run dev
```

## ✅ Vérification

### Backend
Vous devriez voir :
```
✅ Connecté à PostgreSQL avec PostGIS
✅ PostGIS version: ...
🚀 Serveur démarré sur le port 3000
```

### Dashboard
Ouvrez `http://localhost:5173` dans votre navigateur

## 🔍 Dépannage

### PostgreSQL n'est pas démarré

**macOS :**
```bash
brew services start postgresql
```

**Linux :**
```bash
sudo systemctl start postgresql
```

### Base de données n'existe pas

```bash
createdb tshiakani_vtc
```

### Erreur de connexion

Vérifiez que :
1. PostgreSQL est démarré
2. Le mot de passe dans `.env` est correct
3. La base de données existe

## 📚 Documentation

- `backend/CONFIGURATION_ENV.md` - Guide de configuration détaillé
- `CONFIGURATION_CLE_API.md` - Guide de la clé API
- `VERIFICATION_CONNEXIONS.md` - Vérification des connexions

## 🎯 Résumé des Fichiers

- ✅ `backend/.env` - Configuration backend (JWT_SECRET configuré)
- ✅ `admin-dashboard/.env` - Configuration dashboard
- ✅ `backend/configure-env.sh` - Script de configuration
- ✅ `demarrer-serveurs.sh` - Script de démarrage automatique

**Il ne reste plus qu'à configurer DB_PASSWORD dans backend/.env !** 🎉

