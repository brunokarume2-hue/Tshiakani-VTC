# 📋 Instructions Complètes - Configuration Finale

## ✅ État Actuel

- ✅ Projet renommé : **Tshiakani VTC**
- ✅ Bundle Identifier : **com.bruno.tshiakaniVTC**
- ✅ Fichier .env créé/mis à jour
- ✅ Documentation mise à jour

## 🚀 Actions à Effectuer

### 1. Ouvrir le Projet dans Xcode

```bash
cd "/Users/admin/Documents/wewa taxi"
open "Tshiakani VTC.xcodeproj"
```

**Dans Xcode :**
1. Vérifier le Bundle Identifier : `com.bruno.tshiakaniVTC`
2. Product > Clean Build Folder (⇧⌘K)
3. Product > Build (⌘B)
4. Vérifier qu'il n'y a pas d'erreurs

### 2. Mettre à Jour les Certificats Apple

**Voir le guide détaillé** : `GUIDE_CERTIFICATS_APPLE.md`

**Résumé rapide :**
1. Aller sur [developer.apple.com](https://developer.apple.com)
2. Créer un nouvel App ID : `com.bruno.tshiakaniVTC`
3. Créer un nouveau certificat de développement
4. Créer un nouveau provisioning profile
5. Télécharger dans Xcode : Preferences > Accounts > Download Manual Profiles

### 3. Configurer la Base de Données PostgreSQL

**Option A - Script Automatique :**
```bash
cd "/Users/admin/Documents/wewa taxi"
./SCRIPT_SETUP_BDD.sh
```

**Option B - Manuel :**

```bash
# Se connecter à PostgreSQL
psql -U postgres

# Option 1 : Renommer la base existante
ALTER DATABASE wewa_taxi RENAME TO tshiakani_vtc;
\c tshiakani_vtc

# Option 2 : Créer une nouvelle base
CREATE DATABASE tshiakani_vtc;
\c tshiakani_vtc

# Activer PostGIS
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

# Quitter psql
\q

# Exécuter les migrations
psql -U postgres -d tshiakani_vtc -f backend/migrations/001_init_postgis.sql
```

### 4. Vérifier le Fichier .env

Le fichier `backend/.env` a été créé/mis à jour avec :
```env
DB_NAME=tshiakani_vtc
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=votre_mot_de_passe
```

**⚠️ Important :** Modifiez `DB_PASSWORD` avec votre mot de passe PostgreSQL réel.

## ✅ Checklist Finale

### iOS App
- [ ] Projet ouvert dans Xcode
- [ ] Bundle Identifier vérifié : `com.bruno.tshiakaniVTC`
- [ ] Projet compile sans erreurs
- [ ] Certificats configurés
- [ ] Application testée sur simulateur/appareil

### Backend
- [ ] Base de données créée/renommée : `tshiakani_vtc`
- [ ] PostGIS activé
- [ ] Migrations exécutées
- [ ] Fichier .env configuré
- [ ] Backend démarre sans erreurs

### Frontend
- [ ] Admin dashboard fonctionne
- [ ] Connexion au backend fonctionne

## 🎉 Une Fois Tout Configuré

Vous pouvez continuer le développement du projet **Tshiakani VTC** !

---

**Fichiers de référence :**
- `GUIDE_CERTIFICATS_APPLE.md` - Guide détaillé pour les certificats
- `SCRIPT_SETUP_BDD.sh` - Script pour configurer la base de données
- `VÉRIFICATION_FINALE_PROJET.md` - Rapport de vérification complet

