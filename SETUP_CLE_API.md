# 🔐 Configuration Rapide - Clé API Admin

## ⚡ Démarrage Rapide

### 1. Backend

```bash
cd backend
cp .env.example .env
# Éditez .env et configurez vos variables (surtout DATABASE_URL et JWT_SECRET)
```

La clé API est déjà configurée dans `.env.example` :
```env
ADMIN_API_KEY=aadf3378b1d5eca1c38398e5ee31ad6f978747762f9d546847173eb54e7637d8
```

### 2. Dashboard

```bash
cd admin-dashboard
cp .env.example .env
```

La clé API est déjà configurée dans `.env.example` :
```env
VITE_ADMIN_API_KEY=aadf3378b1d5eca1c38398e5ee31ad6f978747762f9d546847173eb54e7637d8
```

### 3. Redémarrer les serveurs

```bash
# Backend
cd backend
npm run dev

# Dashboard (dans un autre terminal)
cd admin-dashboard
npm run dev
```

## ✅ Vérification

Les deux clés doivent être **identiques** :
- Backend : `ADMIN_API_KEY` dans `backend/.env`
- Dashboard : `VITE_ADMIN_API_KEY` dans `admin-dashboard/.env`

## 🔒 Sécurité

⚠️ **IMPORTANT** : Changez cette clé en production !

Pour générer une nouvelle clé :
```bash
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

## 📝 Fichiers créés

- ✅ `backend/.env.example` - Configuration backend avec clé API
- ✅ `admin-dashboard/.env.example` - Configuration dashboard avec clé API
- ✅ `CONFIGURATION_CLE_API.md` - Documentation complète

