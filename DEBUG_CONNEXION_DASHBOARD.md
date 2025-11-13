# 🔍 Debug Connexion Dashboard

## 📋 Date : 2025-01-15

---

## 🐛 Problème

L'utilisateur ne peut pas se connecter au dashboard malgré les corrections.

---

## ✅ Vérifications Effectuées

### 1. Test API Backend Direct

```bash
curl -X POST https://tshiakani-vtc-backend-418102154417.us-central1.run.app/api/auth/admin/login \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber":"+243820098808","password":"Nyota9090"}'
```

**Résultat** : ✅ **200 OK** - Token retourné correctement

### 2. Configuration Dashboard

- ✅ `.env.production` existe avec la bonne URL
- ✅ `AuthContext.jsx` corrigé pour appeler l'API
- ✅ Dashboard reconstruit et redéployé

---

## 🔧 Actions Correctives Appliquées

1. ✅ **AuthContext.jsx** : Fonction `login` corrigée pour appeler l'API
2. ✅ **.env.production** : URL backend configurée
3. ✅ **Dashboard** : Reconstruit avec les bonnes variables
4. ✅ **Déploiement** : Dashboard redéployé sur Firebase

---

## 🧪 Tests à Effectuer

### Test 1 : Ouvrir la Console du Navigateur

1. Ouvrir : https://tshiakani-vtc-99cea.web.app
2. Ouvrir la console (F12)
3. Aller dans l'onglet "Console"
4. Tenter de se connecter
5. Vérifier les messages dans la console :
   - `🔧 Configuration API:` - Doit afficher la bonne URL
   - `🔐 Tentative de connexion...` - Doit apparaître
   - Erreurs éventuelles

### Test 2 : Vérifier les Requêtes Réseau

1. Ouvrir la console (F12)
2. Aller dans l'onglet "Network" (Réseau)
3. Tenter de se connecter
4. Chercher la requête vers `/api/auth/admin/login`
5. Vérifier :
   - **Status** : Doit être 200 (OK) ou 401 (Unauthorized)
   - **Request URL** : Doit être `https://tshiakani-vtc-backend-418102154417.us-central1.run.app/api/auth/admin/login`
   - **Response** : Doit contenir un token ou une erreur

### Test 3 : Vérifier CORS

Si vous voyez une erreur CORS dans la console :
- Le backend doit autoriser `https://tshiakani-vtc-99cea.web.app`
- Vérifier que `CORS_ORIGIN` contient cette URL

---

## 🔍 Erreurs Possibles

### Erreur 1 : "Network Error" ou "Failed to fetch"

**Cause** : L'URL du backend n'est pas correcte dans le build

**Solution** :
1. Vérifier que `.env.production` contient la bonne URL
2. Reconstruire le dashboard : `cd admin-dashboard && npm run build`
3. Redéployer : `./deploy-dashboard.sh`

### Erreur 2 : "CORS policy"

**Cause** : Le backend n'autorise pas l'origine Firebase

**Solution** :
1. Vérifier que `CORS_ORIGIN` contient `https://tshiakani-vtc-99cea.web.app`
2. Redéployer le backend si nécessaire

### Erreur 3 : "401 Unauthorized"

**Cause** : Mot de passe incorrect ou compte admin n'existe pas

**Solution** :
1. Vérifier les identifiants : `+243820098808` / `Nyota9090`
2. Vérifier que le compte admin existe dans Cloud SQL

### Erreur 4 : "404 Not Found"

**Cause** : La route `/api/auth/admin/login` n'existe pas

**Solution** :
1. Vérifier que le backend est bien déployé
2. Tester la route directement avec curl

---

## 📝 Informations de Debug

### Identifiants Admin

- **Numéro** : `+243820098808`
- **Mot de passe** : `Nyota9090`

### URLs

- **Dashboard** : https://tshiakani-vtc-99cea.web.app
- **Backend** : https://tshiakani-vtc-backend-418102154417.us-central1.run.app

### Configuration API Dashboard

Le dashboard utilise :
```javascript
const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:3000/api'
```

En production, `VITE_API_URL` doit être défini dans `.env.production` et injecté lors du build.

---

## 🔧 Commandes de Debug

### Vérifier la Configuration API dans le Build

```bash
cd admin-dashboard
grep -r "tshiakani-vtc-backend" dist/ | head -5
```

### Tester l'API Directement

```bash
curl -X POST https://tshiakani-vtc-backend-418102154417.us-central1.run.app/api/auth/admin/login \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber":"+243820098808","password":"Nyota9090"}'
```

### Vérifier les Logs Cloud Run

```bash
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=tshiakani-vtc-backend" \
  --limit 20 \
  --project tshiakani-vtc-477711
```

---

## ✅ Checklist de Résolution

- [ ] Ouvrir la console du navigateur (F12)
- [ ] Vérifier les messages dans la console
- [ ] Vérifier les requêtes réseau
- [ ] Vérifier l'URL de la requête
- [ ] Vérifier le status de la réponse
- [ ] Vérifier le contenu de la réponse
- [ ] Vérifier les erreurs CORS
- [ ] Tester l'API directement avec curl

---

**Date** : 2025-01-15  
**Statut** : 🔍 **EN COURS DE DEBUG**
