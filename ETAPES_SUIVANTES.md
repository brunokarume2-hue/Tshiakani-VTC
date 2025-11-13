# ✅ Configuration Terminée - Étapes Suivantes

## 📋 Fichiers créés

- ✅ `backend/.env` - Fichier de configuration backend créé
- ✅ `admin-dashboard/.env` - Fichier de configuration dashboard créé
- ✅ Clés API configurées et synchronisées

## ⚙️ Configuration à compléter

### Backend (`backend/.env`)

**À éditer avec vos vraies valeurs :**

```env
# Base de données PostgreSQL (OBLIGATOIRE)
DATABASE_URL=postgresql://username:password@localhost:5432/tshiakani_vtc
DB_HOST=localhost
DB_PORT=5432
DB_USERNAME=postgres
DB_PASSWORD=votre_mot_de_passe
DB_NAME=tshiakani_vtc

# JWT Secret (OBLIGATOIRE - générez-en un nouveau)
JWT_SECRET=votre_jwt_secret_ici_changez_moi

# Clé API Admin (DÉJÀ CONFIGURÉE ✅)
ADMIN_API_KEY=aadf3378b1d5eca1c38398e5ee31ad6f978747762f9d546847173eb54e7637d8
```

**Pour générer un JWT_SECRET sécurisé :**
```bash
node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
```

### Dashboard (`admin-dashboard/.env`)

**Déjà configuré ✅ :**
```env
VITE_API_URL=http://localhost:3000/api
VITE_SOCKET_URL=http://localhost:3000
VITE_ADMIN_API_KEY=aadf3378b1d5eca1c38398e5ee31ad6f978747762f9d546847173eb54e7637d8
```

## 🚀 Démarrer les serveurs

### 1. Backend

```bash
cd backend
npm install  # Si pas encore fait
npm run dev
```

Le serveur démarrera sur `http://localhost:3000`

### 2. Dashboard (dans un autre terminal)

```bash
cd admin-dashboard
npm install  # Si pas encore fait
npm run dev
```

Le dashboard sera accessible sur `http://localhost:5173` (ou le port indiqué)

## ✅ Vérification

### 1. Vérifier que le backend démarre

Vous devriez voir :
```
✅ Connecté à PostgreSQL avec PostGIS
✅ PostGIS version: ...
🚀 Serveur démarré sur le port 3000
```

### 2. Vérifier que le dashboard se connecte

1. Ouvrez `http://localhost:5173`
2. Connectez-vous avec vos identifiants admin
3. Vérifiez que la page MapView charge les données

### 3. Tester la clé API

```bash
# Test sans clé (doit échouer)
curl -X GET "http://localhost:3000/api/admin/stats" \
  -H "Authorization: Bearer <token>"

# Test avec clé (doit réussir)
curl -X GET "http://localhost:3000/api/admin/stats" \
  -H "Authorization: Bearer <token>" \
  -H "X-ADMIN-API-KEY: aadf3378b1d5eca1c38398e5ee31ad6f978747762f9d546847173eb54e7637d8"
```

## 🔍 Dépannage

### Erreur de connexion PostgreSQL

Vérifiez que :
- PostgreSQL est démarré
- Les identifiants dans `.env` sont corrects
- La base de données `tshiakani_vtc` existe

### Erreur "Clé API admin invalide"

Vérifiez que :
- `ADMIN_API_KEY` (backend) = `VITE_ADMIN_API_KEY` (dashboard)
- Les deux fichiers `.env` sont bien chargés
- Redémarrez les serveurs après modification

### Le dashboard ne charge pas les données

Vérifiez que :
- Le backend est démarré sur le port 3000
- `VITE_API_URL` dans le dashboard pointe vers le bon serveur
- Les headers `X-ADMIN-API-KEY` sont bien envoyés (voir DevTools)

## 📚 Documentation

- `CONFIGURATION_CLE_API.md` - Guide complet de la clé API
- `VERIFICATION_CONNEXIONS.md` - Vérification des connexions
- `SETUP_CLE_API.md` - Guide de démarrage rapide

## 🎯 Prochaines étapes

1. ✅ Fichiers `.env` créés
2. ⏳ Éditer `backend/.env` avec vos vraies valeurs
3. ⏳ Démarrer le backend
4. ⏳ Démarrer le dashboard
5. ⏳ Tester les connexions

Bon développement ! 🚀

