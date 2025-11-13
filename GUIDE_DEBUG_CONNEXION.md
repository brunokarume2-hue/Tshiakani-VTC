# 🔍 Guide de Debug - Connexion Dashboard

## ✅ Corrections Appliquées

1. ✅ **AuthContext.jsx** : Fonction `login` corrigée pour appeler l'API
2. ✅ **.env.production** : URL backend configurée
3. ✅ **Dépendances** : Réinstallées
4. ✅ **Build** : Reconstruit avec les bonnes variables
5. ✅ **Déploiement** : Dashboard redéployé sur Firebase

---

## 🧪 Test de l'API Backend

L'API backend fonctionne correctement :

```bash
curl -X POST https://tshiakani-vtc-backend-418102154417.us-central1.run.app/api/auth/admin/login \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber":"+243820098808","password":"Nyota9090"}'
```

**Résultat** : ✅ Retourne un token JWT valide

---

## 🔍 Comment Débugger

### Étape 1 : Ouvrir la Console du Navigateur

1. Ouvrir : https://tshiakani-vtc-99cea.web.app
2. Appuyer sur **F12** (ou Cmd+Option+I sur Mac)
3. Aller dans l'onglet **"Console"**

### Étape 2 : Vérifier les Messages

Vous devriez voir ces messages dans la console :

```
🔧 Configuration API: {
  API_URL: "https://tshiakani-vtc-backend-418102154417.us-central1.run.app/api",
  env: "https://tshiakani-vtc-99cea.web.app/api",
  mode: "production",
  dev: false
}
```

**Si l'URL est incorrecte** : Le build n'a pas utilisé les bonnes variables.

### Étape 3 : Tenter la Connexion

1. Entrer les identifiants :
   - Numéro : `+243820098808`
   - Mot de passe : `Nyota9090`
2. Cliquer sur "Se connecter"
3. Vérifier les messages dans la console :
   - `🔐 Tentative de connexion...` doit apparaître
   - `✅ Connexion réussie` ou `❌ Erreur de connexion` doit apparaître

### Étape 4 : Vérifier les Requêtes Réseau

1. Aller dans l'onglet **"Network"** (Réseau)
2. Tenter de se connecter
3. Chercher la requête vers `/api/auth/admin/login`
4. Vérifier :
   - **Status** : 200 (OK) ou 401 (Unauthorized) ou autre
   - **Request URL** : Doit être `https://tshiakani-vtc-backend-418102154417.us-central1.run.app/api/auth/admin/login`
   - **Response** : Cliquer sur la requête → onglet "Response" → voir le contenu

---

## 🐛 Erreurs Possibles

### Erreur 1 : "Network Error" ou "Failed to fetch"

**Symptômes** :
- Message dans la console : `❌ Erreur de connexion: Network Error`
- Status dans Network : (failed) ou 0

**Causes possibles** :
1. L'URL du backend n'est pas correcte dans le build
2. Problème de CORS
3. Le backend n'est pas accessible

**Solution** :
1. Vérifier que l'URL dans la console est correcte
2. Tester l'API directement avec curl (voir ci-dessus)
3. Vérifier CORS dans le backend

### Erreur 2 : "CORS policy"

**Symptômes** :
- Message dans la console : `Access to XMLHttpRequest at '...' from origin '...' has been blocked by CORS policy`

**Solution** :
1. Vérifier que `CORS_ORIGIN` contient `https://tshiakani-vtc-99cea.web.app`
2. Redéployer le backend si nécessaire

### Erreur 3 : "401 Unauthorized"

**Symptômes** :
- Status : 401
- Response : `{"error": "Numéro de téléphone ou mot de passe incorrect"}`

**Causes possibles** :
1. Mot de passe incorrect
2. Numéro de téléphone incorrect
3. Le compte admin n'existe pas dans la base de données

**Solution** :
1. Vérifier les identifiants : `+243820098808` / `Nyota9090`
2. Tester l'API directement avec curl
3. Vérifier que le compte admin existe dans Cloud SQL

### Erreur 4 : "404 Not Found"

**Symptômes** :
- Status : 404
- Response : `Cannot POST /api/auth/admin/login`

**Solution** :
1. Vérifier que le backend est bien déployé
2. Tester la route directement avec curl
3. Vérifier les logs Cloud Run

---

## 📝 Informations à Me Fournir

Si la connexion ne fonctionne toujours pas, envoyez-moi :

1. **Messages de la console** (F12 → Console) :
   - Copier tous les messages, surtout ceux qui commencent par 🔧, 🔐, ✅, ou ❌

2. **Requête réseau** (F12 → Network) :
   - Cliquer sur la requête `/api/auth/admin/login`
   - Copier :
     - **Status** (200, 401, 404, etc.)
     - **Request URL**
     - **Request Headers**
     - **Response** (le contenu de la réponse)

3. **Erreurs éventuelles** :
   - Toute erreur affichée dans la console ou dans l'interface

---

## ✅ Checklist de Vérification

- [ ] L'API backend fonctionne (testé avec curl)
- [ ] Le dashboard est accessible
- [ ] La console du navigateur est ouverte (F12)
- [ ] Les messages de la console sont vérifiés
- [ ] Les requêtes réseau sont vérifiées
- [ ] Les identifiants sont corrects : `+243820098808` / `Nyota9090`

---

## 🔑 Identifiants Admin

- **URL Dashboard** : https://tshiakani-vtc-99cea.web.app
- **Numéro** : `+243820098808`
- **Mot de passe** : `Nyota9090`

---

**Date** : 2025-01-15  
**Statut** : ✅ **DASHBOARD RECONSTRUIT ET REDÉPLOYÉ**

