# 🔐 Guide des Identifiants de Connexion - Dashboard Admin

## 📋 Identifiants à Utiliser

### Pour Se Connecter au Dashboard

```
Numéro de téléphone : +243900000000
                        (ou n'importe quel numéro congolais valide)

Mot de passe : (laissez vide)
```

### Comment ça Fonctionne

1. **Première connexion** : Le système crée automatiquement un compte admin
2. **Connexions suivantes** : Le système utilise le compte admin existant
3. **Format du numéro** : Accepte `+243900000000`, `243900000000`, ou `+243 900 000 000`

---

## 🌐 URL du Dashboard

- **URL principale** : `https://tshiakani-vtc-99cea.web.app`
- **URL alternative** : `https://tshiakani-vtc-99cea.firebaseapp.com`

---

## ⚠️ Problème Actuel

### Route d'Authentification Non Disponible

La route `/api/auth/admin/login` n'est **pas disponible** sur le backend Cloud Run déployé.

**Erreur** : `Cannot POST /api/auth/admin/login`

### Pourquoi ?

Le backend déployé sur Cloud Run ne répond pas aux routes d'authentification. Cela peut être dû à :
1. Backend non mis à jour avec la dernière version
2. Problème de configuration
3. Erreur au démarrage du serveur

---

## ✅ Solutions

### Solution 1: Tester en Local (Recommandé pour Vérifier)

#### Étape 1: Démarrer le Backend Local

```bash
cd "/Users/admin/Documents/Tshiakani VTC/backend"

# Vérifier que PostgreSQL est démarré
pg_isready -h localhost -p 5432

# Démarrer le backend
npm run dev
```

#### Étape 2: Modifier le Dashboard pour Utiliser le Backend Local

**Fichier** : `admin-dashboard/.env.local`

```env
VITE_API_URL=http://localhost:3000/api
VITE_ADMIN_API_KEY=aadf3378b1d5eca1c38398e5ee31ad6f978747762f9d546847173eb54e7637d8
```

#### Étape 3: Démarrer le Dashboard

```bash
cd "/Users/admin/Documents/Tshiakani VTC/admin-dashboard"

# Démarrer le dashboard
npm run dev
```

#### Étape 4: Se Connecter

1. Aller sur `http://localhost:5173`
2. Utiliser les identifiants :
   - Numéro : `+243900000000`
   - Mot de passe : (vide)

### Solution 2: Redéployer le Backend

Voir le document `CORRIGER_ROUTE_AUTH_ADMIN.md` pour les instructions complètes.

---

## 🔍 Vérification

### Tester la Route Localement

```bash
# Démarrer le backend local
cd "/Users/admin/Documents/Tshiakani VTC/backend"
npm run dev

# Dans un autre terminal, tester la route
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

### Tester sur le Backend Déployé

```bash
curl -X POST https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/api/auth/admin/login \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber":"+243900000000"}'
```

**Si ça fonctionne** : Vous recevrez un token JWT
**Si ça ne fonctionne pas** : Redéployer le backend (voir `CORRIGER_ROUTE_AUTH_ADMIN.md`)

---

## 📝 Résumé

### Identifiants

- **Numéro** : `+243900000000` (ou n'importe quel numéro valide)
- **Mot de passe** : (vide)

### URLs

- **Dashboard** : `https://tshiakani-vtc-99cea.web.app`
- **Backend** : `https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app`
- **Route de connexion** : `POST /api/auth/admin/login`

### Statut

- ✅ Dashboard déployé et accessible
- ✅ Code de la route présent dans le backend
- ⚠️ Route non disponible sur le backend déployé
- ✅ Solution : Tester en local ou redéployer le backend

---

**Date** : $(date)

