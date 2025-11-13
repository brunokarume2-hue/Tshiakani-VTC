# 📝 Guide d'Édition du fichier .env

## 🔍 Contenu actuel du fichier .env

Le fichier `.env` contient déjà :

### ✅ Déjà configuré

```env
# Clé API Admin
ADMIN_API_KEY=aadf3378b1d5eca1c38398e5ee31ad6f978747762f9d546847173eb54e7637d8

# JWT Secret
JWT_SECRET=ac6dcf4a79db19cffc2c71166699ff4ead6ec0fe259b3f77c67de9543ad99ec4a7e9818c6e4013467eaaf6b12545c34c8ce77b73141df9e28437179971e99eab
```

### ⚠️ À modifier

```env
# Base de données PostgreSQL
DB_PASSWORD=votre_mot_de_passe_postgres  # ← CHANGEZ CETTE LIGNE
DB_USER=postgres                          # ← Vérifiez si correct
DB_NAME=tshiakani_vtc                     # ← Vérifiez si correct
```

## 📝 Instructions pour nano

1. **Ouvrir le fichier :**
   ```bash
   cd backend
   nano .env
   ```

2. **Navigation dans nano :**
   - Utilisez les flèches pour naviguer
   - `Ctrl + W` : Rechercher
   - `Ctrl + O` : Sauvegarder
   - `Ctrl + X` : Quitter

3. **Modifier DB_PASSWORD :**
   - Trouvez la ligne : `DB_PASSWORD=your_password`
   - Remplacez `your_password` par votre vrai mot de passe PostgreSQL

4. **Sauvegarder et quitter :**
   - `Ctrl + O` puis `Enter` (sauvegarder)
   - `Ctrl + X` (quitter)

## 🔍 Exemple de configuration

```env
# Base de données PostgreSQL
DATABASE_URL=postgresql://postgres:mon_mot_de_passe@localhost:5432/tshiakani_vtc
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=mon_mot_de_passe          # ← Votre mot de passe ici
DB_NAME=tshiakani_vtc

# JWT Secret (déjà configuré ✅)
JWT_SECRET=ac6dcf4a79db19cffc2c71166699ff4ead6ec0fe259b3f77c67de9543ad99ec4a7e9818c6e4013467eaaf6b12545c34c8ce77b73141df9e28437179971e99eab

# Clé API Admin (déjà configurée ✅)
ADMIN_API_KEY=aadf3378b1d5eca1c38398e5ee31ad6f978747762f9d546847173eb54e7637d8

# Port du serveur
PORT=3000

# CORS
CORS_ORIGIN=http://localhost:3001,http://localhost:5173
```

## ✅ Après modification

1. **Vérifier la configuration :**
   ```bash
   grep "DB_PASSWORD" .env
   ```

2. **Tester la connexion :**
   ```bash
   npm run dev
   ```

3. **Vérifier les logs :**
   Vous devriez voir :
   ```
   ✅ Connecté à PostgreSQL avec PostGIS
   ```

## 🆘 Si vous n'avez pas de mot de passe PostgreSQL

### Créer un utilisateur PostgreSQL

```bash
# Se connecter à PostgreSQL
psql postgres

# Créer un utilisateur (si nécessaire)
CREATE USER postgres WITH PASSWORD 'votre_nouveau_mot_de_passe';

# Créer la base de données
CREATE DATABASE tshiakani_vtc;

# Quitter
\q
```

### Ou utiliser le mot de passe par défaut

Si PostgreSQL est installé via Homebrew (macOS), le mot de passe peut être vide ou votre nom d'utilisateur système.

Essayez :
```env
DB_PASSWORD=
# ou
DB_PASSWORD=votre_nom_utilisateur_systeme
```

