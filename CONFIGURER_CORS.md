# 🌐 Configuration CORS - Guide

## ⚠️ Problème

La commande `gcloud run services update` avec `--update-env-vars` a des difficultés avec les caractères spéciaux dans les URLs.

## ✅ Solution : Configuration via Console GCP

### Méthode 1 : Via Console GCP (Recommandé)

1. **Aller dans Cloud Run Console** :
   - URL : https://console.cloud.google.com/run/detail/us-central1/tshiakani-vtc-backend?project=tshiakani-vtc-477711

2. **Modifier le Service** :
   - Cliquer sur "MODIFIER ET DÉPLOYER UNE NOUVELLE RÉVISION"
   - Aller dans l'onglet "Variables d'environnement"
   - Ajouter ou modifier `CORS_ORIGIN`
   - Valeur : `https://tshiakani-vtc-99cea.web.app,https://tshiakani-vtc-99cea.firebaseapp.com,capacitor://localhost,ionic://localhost,http://localhost:3001,http://localhost:5173`
   - Cliquer sur "DÉPLOYER"

### Méthode 2 : Via gcloud avec fichier YAML

1. **Créer un fichier env.yaml** :
```yaml
CORS_ORIGIN: "https://tshiakani-vtc-99cea.web.app,https://tshiakani-vtc-99cea.firebaseapp.com,capacitor://localhost,ionic://localhost,http://localhost:3001,http://localhost:5173"
```

2. **Utiliser --env-vars-file** :
```bash
gcloud run services update tshiakani-vtc-backend \
  --env-vars-file=env.yaml \
  --region us-central1 \
  --project tshiakani-vtc-477711
```

### Méthode 3 : Commande Directe (Peut échouer)

```bash
gcloud run services update tshiakani-vtc-backend \
  --update-env-vars="CORS_ORIGIN=https://tshiakani-vtc-99cea.web.app,https://tshiakani-vtc-99cea.firebaseapp.com,capacitor://localhost,ionic://localhost,http://localhost:3001,http://localhost:5173" \
  --region us-central1 \
  --project tshiakani-vtc-477711
```

---

## 🎯 Recommandation

**Utilisez la Console GCP** (Méthode 1) - C'est la plus simple et la plus fiable.

---

**Date** : 2025-01-15

