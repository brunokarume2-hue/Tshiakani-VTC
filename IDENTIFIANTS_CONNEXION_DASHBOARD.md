# 🔐 Identifiants de Connexion - Dashboard Admin Tshiakani VTC

## 📋 Système d'Authentification

Le dashboard utilise une **authentification simplifiée** basée sur le numéro de téléphone.

### Informations Requises

- **Numéro de téléphone** : Requis (format: +243 900 000 000)
- **Mot de passe** : Optionnel (peut être laissé vide pour le développement)

---

## 🔑 Identifiants par Défaut

### Pour la Première Connexion

Le système crée **automatiquement** un compte admin lors de la première connexion.

**Identifiants à utiliser** :

```
Numéro de téléphone : +243900000000
                        (ou n'importe quel numéro valide)

Mot de passe : (laissez vide)
```

### Exemples de Numéros Valides

Vous pouvez utiliser n'importe quel numéro de téléphone congolais :
- `+243900000000`
- `243900000000`
- `+243 900 000 000`
- `+243812345678`
- `+243997654321`

**Note** : Le système normalise automatiquement le numéro (supprime les espaces et les caractères spéciaux).

---

## 🚀 Comment Se Connecter

### Étape 1: Accéder au Dashboard

Ouvrez votre navigateur et allez à :
- **URL principale** : `https://tshiakani-vtc-99cea.web.app`
- **URL alternative** : `https://tshiakani-vtc-99cea.firebaseapp.com`

### Étape 2: Page de Connexion

Vous verrez la page de connexion avec :
- Titre : **"Tshiakani VTC"**
- Sous-titre : **"Dashboard Administrateur"**
- Formulaire de connexion

### Étape 3: Remplir le Formulaire

**Champ "Numéro de téléphone"** :
```
+243900000000
```

**Champ "Mot de passe"** :
```
(laissez vide ou entrez n'importe quoi)
```

### Étape 4: Cliquer sur "Se connecter"

Le système va :
1. ✅ Vérifier si un compte admin existe avec ce numéro
2. ✅ Si non, créer automatiquement un compte admin
3. ✅ Générer un token JWT
4. ✅ Vous connecter au dashboard

---

## 🔍 Fonctionnement Technique

### Route Backend

Le dashboard appelle la route :
```
POST /api/auth/admin/login
```

Avec les données :
```json
{
  "phoneNumber": "+243900000000",
  "password": ""
}
```

### Réponse Attendue

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

### Création Automatique du Compte

Si aucun compte admin n'existe avec le numéro fourni, le backend crée automatiquement :
- **Nom** : "Admin"
- **Numéro** : Le numéro fourni (normalisé)
- **Rôle** : "admin"
- **Statut** : Vérifié (`isVerified: true`)

---

## ⚠️ Problème Actuel

### Route Non Disponible sur le Backend Déployé

La route `/api/auth/admin/login` retourne actuellement une erreur `404` sur le backend Cloud Run.

**Causes possibles** :
1. La route n'est pas déployée sur Cloud Run
2. Le backend déployé utilise une version différente
3. La route nécessite une configuration supplémentaire

### Solutions

#### Option 1: Vérifier le Backend Déployé

Vérifiez que le backend Cloud Run contient bien la route `/api/auth/admin/login` :
```bash
curl -X POST https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/api/auth/admin/login \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber":"+243900000000"}'
```

#### Option 2: Redéployer le Backend

Si la route n'existe pas, redéployez le backend avec la route admin login :
```bash
cd backend
# Vérifier que server.postgres.js contient la route /api/auth
# Redéployer sur Cloud Run
```

#### Option 3: Utiliser un Backend Local (pour test)

Pour tester localement :
```bash
# Démarrer le backend local
cd backend
npm run dev

# Le backend sera accessible sur http://localhost:3000
# Le dashboard communiquera avec le backend local
```

---

## 📝 Création Manuelle d'un Compte Admin

### Via PostgreSQL

Si vous avez accès à la base de données PostgreSQL :

```sql
-- Se connecter à la base de données
psql -U postgres -d tshiakani_vtc

-- Insérer un utilisateur admin
INSERT INTO users (name, phone_number, role, is_verified, created_at, updated_at)
VALUES (
  'Admin',
  '243900000000',
  'admin',
  true,
  NOW(),
  NOW()
);
```

### Via l'API Backend (si disponible)

```bash
curl -X POST https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/api/auth/admin/login \
  -H "Content-Type: application/json" \
  -d '{
    "phoneNumber": "+243900000000",
    "password": ""
  }'
```

---

## 🔧 Configuration du Dashboard

### Variables d'Environnement

Le dashboard est configuré pour communiquer avec :
- **Backend URL** : `https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/api`
- **Route de connexion** : `/api/auth/admin/login`

### Fichier de Configuration

**Fichier** : `admin-dashboard/.env.production`

```env
VITE_API_URL=https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/api
VITE_ADMIN_API_KEY=aadf3378b1d5eca1c38398e5ee31ad6f978747762f9d546847173eb54e7637d8
```

---

## 🆘 Dépannage

### Erreur: "Erreur de connexion"

**Causes possibles** :
1. Backend non accessible
2. Route `/api/auth/admin/login` non disponible
3. Problème de CORS
4. Backend non démarré

**Solutions** :
1. Vérifier que le backend est accessible : `https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/health`
2. Vérifier que la route existe : `curl -X POST https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/api/auth/admin/login -H "Content-Type: application/json" -d '{"phoneNumber":"+243900000000"}'`
3. Vérifier les logs du backend
4. Vérifier la console du navigateur (F12) pour les erreurs

### Erreur: "404 Not Found"

**Cause** : La route `/api/auth/admin/login` n'existe pas sur le backend déployé.

**Solution** : Vérifier que le backend est déployé avec la route admin login, ou redéployer le backend.

### Erreur: "CORS policy"

**Cause** : Le backend n'autorise pas les requêtes depuis Firebase.

**Solution** : Configurer CORS dans le backend pour autoriser :
```
https://tshiakani-vtc-99cea.web.app
https://tshiakani-vtc-99cea.firebaseapp.com
```

### Erreur: "Network Error"

**Cause** : Le backend n'est pas accessible ou l'URL est incorrecte.

**Solution** : Vérifier que l'URL du backend est correcte dans `.env.production`.

---

## ✅ Checklist de Connexion

- [ ] Backend accessible (`/health` retourne 200)
- [ ] Route `/api/auth/admin/login` disponible
- [ ] CORS configuré dans le backend
- [ ] Dashboard accessible sur Firebase
- [ ] Numéro de téléphone préparé
- [ ] Connexion testée

---

## 📊 Résumé

### Identifiants

```
Numéro de téléphone : +243900000000
                        (ou n'importe quel numéro valide)

Mot de passe : (laissez vide)
```

### URLs

- **Dashboard** : `https://tshiakani-vtc-99cea.web.app`
- **Backend** : `https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app`
- **Route de connexion** : `POST /api/auth/admin/login`

### Fonctionnement

1. Le dashboard envoie une requête POST à `/api/auth/admin/login`
2. Le backend vérifie si un admin existe avec ce numéro
3. Si non, le backend crée automatiquement un compte admin
4. Le backend retourne un token JWT
5. Le dashboard stocke le token et connecte l'utilisateur

---

## 🎯 Prochaines Étapes

1. **Vérifier que la route existe** sur le backend Cloud Run
2. **Tester la connexion** avec les identifiants
3. **Vérifier CORS** dans le backend
4. **Tester les fonctionnalités** du dashboard après connexion

---

**Date** : $(date)
**Statut** : ⚠️ Route à vérifier sur le backend déployé
