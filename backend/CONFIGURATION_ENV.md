# 🔧 Configuration du fichier .env

## ⚡ Configuration Rapide

### Option 1 : Script automatique (recommandé)

```bash
cd backend
./configure-env.sh
```

Ce script va :
- ✅ Créer le fichier `.env` depuis `.env.example` si nécessaire
- ✅ Générer et configurer un `JWT_SECRET` sécurisé
- ✅ Vous rappeler les variables à configurer manuellement

### Option 2 : Configuration manuelle

Éditez le fichier `backend/.env` et configurez :

```env
# Base de données PostgreSQL (OBLIGATOIRE)
DATABASE_URL=postgresql://username:password@localhost:5432/tshiakani_vtc
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=votre_mot_de_passe_postgres
DB_NAME=tshiakani_vtc

# JWT Secret (DÉJÀ GÉNÉRÉ ✅)
JWT_SECRET=ac6dcf4a79db19cffc2c71166699ff4ead6ec0fe259b3f77c67de9543ad99ec4a7e9818c6e4013467eaaf6b12545c34c8ce77b73141df9e28437179971e99eab

# Clé API Admin (DÉJÀ CONFIGURÉE ✅)
ADMIN_API_KEY=aadf3378b1d5eca1c38398e5ee31ad6f978747762f9d546847173eb54e7637d8

# Port du serveur
PORT=3000

# CORS
CORS_ORIGIN=http://localhost:3001,http://localhost:5173
```

## 📝 Variables à configurer

### Obligatoires

1. **DB_PASSWORD** - Mot de passe PostgreSQL
   ```env
   DB_PASSWORD=mon_mot_de_passe
   ```

2. **DB_USER** - Utilisateur PostgreSQL (généralement `postgres`)
   ```env
   DB_USER=postgres
   ```

3. **DB_NAME** - Nom de la base de données
   ```env
   DB_NAME=tshiakani_vtc
   ```

### Optionnelles (valeurs par défaut)

- `DB_HOST=localhost` (par défaut)
- `DB_PORT=5432` (par défaut)
- `PORT=3000` (par défaut)
- `CORS_ORIGIN=http://localhost:3001,http://localhost:5173` (par défaut)

## ✅ Vérification

Après configuration, vérifiez que :

1. Le fichier `.env` existe dans `backend/`
2. `DB_PASSWORD` est configuré
3. `JWT_SECRET` est présent (généré automatiquement)
4. `ADMIN_API_KEY` est présent

## 🚀 Démarrer le serveur

```bash
cd backend
npm run dev
```

Vous devriez voir :
```
✅ Connecté à PostgreSQL avec PostGIS
✅ PostGIS version: ...
🚀 Serveur démarré sur le port 3000
```

## 🔍 Dépannage

### Erreur "Cannot connect to database"

Vérifiez que :
- PostgreSQL est démarré : `brew services start postgresql` (macOS) ou `sudo systemctl start postgresql` (Linux)
- Les identifiants dans `.env` sont corrects
- La base de données existe : `createdb tshiakani_vtc`

### Erreur "JWT_SECRET is not defined"

Exécutez le script de configuration :
```bash
./configure-env.sh
```

### Erreur "ADMIN_API_KEY is not defined"

Vérifiez que le fichier `.env` contient :
```env
ADMIN_API_KEY=aadf3378b1d5eca1c38398e5ee31ad6f978747762f9d546847173eb54e7637d8
```

