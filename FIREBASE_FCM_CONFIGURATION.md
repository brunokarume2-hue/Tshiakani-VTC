# 🔥 Configuration Firebase Cloud Messaging (FCM)

## 📋 Vue d'Ensemble

Ce guide vous aide à configurer Firebase Cloud Messaging (FCM) pour envoyer des notifications push aux chauffeurs et clients.

---

## 🚀 Étapes de Configuration

### Étape 1 : Créer ou Lier un Projet Firebase

1. **Aller sur Firebase Console** :
   - https://console.firebase.google.com

2. **Créer ou sélectionner un projet** :
   - Si nouveau projet :
     - Cliquer sur "Ajouter un projet"
     - Nom : `Tshiakani VTC` (ou `tshiakani-vtc-477711`)
     - Lier au projet GCP existant : `tshiakani-vtc-477711`
   - Si projet existant :
     - Sélectionner le projet `tshiakani-vtc-477711`

3. **Activer Google Analytics** (optionnel mais recommandé) :
   - Choisir un compte Analytics ou en créer un nouveau

---

### Étape 2 : Activer Cloud Messaging (FCM)

1. **Dans Firebase Console** :
   - Aller dans "Paramètres du projet" (icône ⚙️ en haut à gauche)
   - Cliquer sur l'onglet "Cloud Messaging"

2. **Activer FCM** :
   - Si pas encore activé, cliquer sur "Activer"
   - Noter le **Server Key** (sera utilisé plus tard)

---

### Étape 3 : Créer un Compte de Service

1. **Dans Firebase Console** :
   - Aller dans "Paramètres du projet" → "Comptes de service"

2. **Générer une nouvelle clé privée** :
   - Cliquer sur "Générer une nouvelle clé privée"
   - Télécharger le fichier JSON (ex: `tshiakani-vtc-477711-xxxxx.json`)

3. **Sauvegarder le fichier** :
   - Le fichier contient les credentials nécessaires pour FCM

---

### Étape 4 : Stocker dans Secret Manager (Recommandé)

Une fois le fichier téléchargé, stockez-le dans Secret Manager :

```bash
cd "/Users/admin/Documents/Tshiakani VTC"
export GCP_PROJECT_ID=tshiakani-vtc-477711

# Remplacer par le chemin de votre fichier téléchargé
FIREBASE_KEY_FILE="~/Downloads/tshiakani-vtc-477711-xxxxx.json"

# Stocker dans Secret Manager
gcloud secrets create firebase-service-account \
  --data-file="$FIREBASE_KEY_FILE" \
  --project=tshiakani-vtc-477711
```

**Ou créer le secret directement** :

```bash
# Si vous avez le contenu du fichier
cat "$FIREBASE_KEY_FILE" | gcloud secrets create firebase-service-account \
  --data-file=- \
  --project=tshiakani-vtc-477711
```

---

### Étape 5 : Configurer les Permissions IAM

```bash
cd "/Users/admin/Documents/Tshiakani VTC"
export GCP_PROJECT_ID=tshiakani-vtc-477711

# Récupérer le service account de Cloud Run
SERVICE_ACCOUNT=$(gcloud run services describe tshiakani-vtc-backend \
  --region=us-central1 \
  --project=tshiakani-vtc-477711 \
  --format="value(spec.template.spec.serviceAccountName)")

# Donner accès au secret
gcloud secrets add-iam-policy-binding firebase-service-account \
  --member="serviceAccount:${SERVICE_ACCOUNT}" \
  --role="roles/secretmanager.secretAccessor" \
  --project=tshiakani-vtc-477711
```

---

### Étape 6 : Mettre à Jour le Code Backend (si nécessaire)

Le backend doit être configuré pour utiliser Firebase. Vérifiez que le code utilise `firebase-admin` correctement.

**Fichier de configuration** : `backend/utils/notifications.js`

---

### Étape 7 : Mettre à Jour les Variables d'Environnement

```bash
cd "/Users/admin/Documents/Tshiakani VTC"
export GCP_PROJECT_ID=tshiakani-vtc-477711

# Mettre à jour Cloud Run avec le projet Firebase
gcloud run services update tshiakani-vtc-backend \
  --region=us-central1 \
  --project=tshiakani-vtc-477711 \
  --update-env-vars="FIREBASE_PROJECT_ID=tshiakani-vtc-477711"
```

---

## 🧪 Test de Configuration

### Tester FCM depuis le Backend

```bash
# Tester via l'API du backend
curl -X POST https://tshiakani-vtc-backend-418102154417.us-central1.run.app/api/notifications/test \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{
    "token": "FCM_TOKEN_DU_CHAUFFEUR",
    "title": "Test Notification",
    "body": "Ceci est un test"
  }'
```

---

## 📝 Informations Importantes

### Server Key FCM

Le **Server Key** se trouve dans :
- Firebase Console → Paramètres du projet → Cloud Messaging
- Ou dans le fichier JSON du compte de service

### FCM Tokens

Les tokens FCM sont générés par les applications mobiles (iOS/Android) et doivent être stockés dans la base de données lors de l'inscription/connexion des utilisateurs.

### Limites FCM

- **Gratuit** : 10 000 messages/jour
- **Payant** : Illimité (facturé par message)

---

## 🔒 Sécurité

### Bonnes Pratiques

1. **Ne jamais exposer le Server Key** dans le code client
2. **Utiliser Secret Manager** pour stocker les credentials
3. **Restreindre les permissions** IAM au minimum nécessaire
4. **Valider les tokens FCM** avant d'envoyer des notifications

---

## 📚 Documentation

- **Firebase Console** : https://console.firebase.google.com
- **Documentation FCM** : https://firebase.google.com/docs/cloud-messaging
- **firebase-admin SDK** : https://firebase.google.com/docs/admin/setup

---

## ✅ Checklist

- [ ] Projet Firebase créé/linké
- [ ] Cloud Messaging activé
- [ ] Compte de service créé
- [ ] Fichier JSON téléchargé
- [ ] Secret créé dans Secret Manager
- [ ] Permissions IAM configurées
- [ ] Variables d'environnement mises à jour
- [ ] Code backend vérifié
- [ ] Test de notification effectué

---

**Date de création** : 2025-01-15  
**Version** : 1.0.0  
**Statut** : Guide de configuration

