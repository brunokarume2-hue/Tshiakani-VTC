# 🧪 Tester l'Authentification en Local

## 📋 Objectif

Tester l'authentification admin du dashboard en local pour vérifier que tout fonctionne avant de redéployer sur Cloud Run.

---

## 🔧 Étape 1: Démarrer le Backend Local

### Prérequis

1. **PostgreSQL** doit être installé et démarré
2. **Base de données** créée avec PostGIS
3. **Variables d'environnement** configurées dans `backend/.env`

### Démarrer le Backend

```bash
cd "/Users/admin/Documents/Tshiakani VTC/backend"

# Vérifier que PostgreSQL est démarré
# (Si PostgreSQL n'est pas démarré, le backend ne pourra pas se connecter)

# Démarrer le backend
npm run dev
```

**Résultat attendu** :
```
✅ Connecté à PostgreSQL avec PostGIS
🚀 Serveur démarré sur le port 3000
🌐 API disponible sur http://0.0.0.0:3000/api
```

---

## 🔧 Étape 2: Configurer le Dashboard pour le Backend Local

### Créer un fichier `.env.local`

**Fichier** : `admin-dashboard/.env.local`

```env
VITE_API_URL=http://localhost:3000/api
VITE_ADMIN_API_KEY=aadf3378b1d5eca1c38398e5ee31ad6f978747762f9d546847173eb54e7637d8
VITE_SOCKET_URL=http://localhost:3000
```

### Démarrer le Dashboard

```bash
cd "/Users/admin/Documents/Tshiakani VTC/admin-dashboard"

# Démarrer le dashboard en mode développement
npm run dev
```

**Résultat attendu** :
```
  VITE v5.x.x  ready in xxx ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
```

---

## 🔧 Étape 3: Tester l'Authentification

### Tester la Route Backend

```bash
# Dans un terminal séparé
curl -X POST http://localhost:3000/api/auth/admin/login \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber":"+243900000000"}'
```

**Résultat attendu** :
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "name": "Admin",
    "phoneNumber": "243900000000",
    "role": "admin"
  }
}
```

### Tester depuis le Dashboard

1. **Ouvrir le navigateur** : `http://localhost:5173`
2. **Remplir le formulaire** :
   - Numéro : `+243900000000`
   - Mot de passe : (vide)
3. **Cliquer sur "Se connecter"**

**Résultat attendu** : Connexion réussie et redirection vers le tableau de bord

---

## ✅ Vérification

### Vérifier que le Compte Admin est Créé

```bash
# Se connecter à PostgreSQL
psql -U postgres -d tshiakani_vtc

# Vérifier les utilisateurs admin
SELECT id, name, phone_number, role, is_verified 
FROM users 
WHERE role = 'admin';
```

**Résultat attendu** : Au moins un utilisateur avec `role = 'admin'`

---

## 📝 Résumé

### Identifiants

- **Numéro** : `+243900000000`
- **Mot de passe** : (vide)

### URLs Locales

- **Backend** : `http://localhost:3000`
- **Dashboard** : `http://localhost:5173`
- **Route de connexion** : `POST http://localhost:3000/api/auth/admin/login`

### Statut

- ✅ Backend local fonctionnel
- ✅ Route admin/login disponible
- ✅ Dashboard peut se connecter
- ✅ Compte admin créé automatiquement

---

**Date** : $(date)

