# ⚠️ Configuration CORS - Limitation gcloud CLI

## 🔍 Problème Identifié

La commande `gcloud run services update` avec `--update-env-vars` ou `--set-env-vars` a des **difficultés avec les caractères spéciaux** dans les URLs (deux-points `:`, slashes `/`, etc.).

Même avec Python et échappement, la commande échoue car gcloud interprète les virgules dans `CORS_ORIGIN` comme des séparateurs de variables.

---

## ✅ Solution : Console GCP (Recommandée)

### 🎯 Méthode la Plus Simple et Fiable

**Lien Direct** :
```
https://console.cloud.google.com/run/detail/us-central1/tshiakani-vtc-backend?project=tshiakani-vtc-477711
```

### 📋 Étapes (2 minutes)

1. **Cliquez sur le lien ci-dessus**
2. **Cliquez sur "MODIFIER ET DÉPLOYER UNE NOUVELLE RÉVISION"**
3. **Onglet "Variables d'environnement"**
4. **Ajoutez/Modifiez** :
   - Nom : `CORS_ORIGIN`
   - Valeur : `https://tshiakani-vtc-99cea.web.app,https://tshiakani-vtc-99cea.firebaseapp.com,capacitor://localhost,ionic://localhost,http://localhost:3001,http://localhost:5173`
5. **Cliquez sur "DÉPLOYER"**

**C'est tout !** ✅

---

## 🔧 Alternative : API REST (Avancé)

Si vous préférez utiliser l'API REST directement :

```bash
# Obtenir le token d'accès
ACCESS_TOKEN=$(gcloud auth print-access-token)

# Obtenir la configuration actuelle
curl -X GET \
  "https://run.googleapis.com/v1/projects/tshiakani-vtc-477711/locations/us-central1/services/tshiakani-vtc-backend" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" > service_config.json

# Modifier le JSON pour ajouter CORS_ORIGIN
# (nécessite un script Python/Node.js pour modifier le JSON)

# Mettre à jour
curl -X PUT \
  "https://run.googleapis.com/v1/projects/tshiakani-vtc-477711/locations/us-central1/services/tshiakani-vtc-backend" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d @service_config.json
```

**Note** : Cette méthode est complexe et nécessite de manipuler du JSON. La Console GCP est beaucoup plus simple.

---

## 📝 Valeur Exacte CORS_ORIGIN

Copiez cette valeur exactement :

```
https://tshiakani-vtc-99cea.web.app,https://tshiakani-vtc-99cea.firebaseapp.com,capacitor://localhost,ionic://localhost,http://localhost:3001,http://localhost:5173
```

Ou depuis le fichier : `VALEUR_CORS.txt`

---

## ✅ Vérification Après Configuration

### Test 1 : Dashboard

```bash
# Ouvrir le dashboard
open https://tshiakani-vtc-99cea.web.app

# Dans la console du navigateur (F12), vérifier :
# - Pas d'erreurs CORS
# - Les requêtes vers /api/admin/* fonctionnent
```

### Test 2 : Backend

```bash
curl -H "Origin: https://tshiakani-vtc-99cea.web.app" \
  https://tshiakani-vtc-backend-418102154417.us-central1.run.app/health
```

---

## 🎯 Recommandation Finale

**Utilisez la Console GCP** - C'est la méthode la plus simple, la plus fiable, et prend seulement 2 minutes.

---

**Date** : 2025-01-15  
**Statut** : ⚠️ Configuration manuelle requise via Console GCP

