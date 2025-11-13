# 🚀 Prochaines Étapes - Déploiement Complet

## 📋 Date : 2025-01-15

---

## ✅ Ce qui est DÉJÀ Fait

### Infrastructure GCP
- ✅ Cloud SQL (PostgreSQL + PostGIS) déployé
- ✅ Memorystore Redis déployé
- ✅ Cloud Run backend déployé
- ✅ Base de données initialisée avec toutes les tables

### Applications
- ✅ Backend déployé et opérationnel
- ✅ Dashboard déployé sur Firebase
- ✅ Apps iOS configurées avec les bonnes URLs

### Configuration
- ✅ Variables d'environnement backend configurées
- ✅ Google Maps API Key configuré
- ✅ Dashboard `.env.production` créé

---

## 🎯 Prochaines Étapes (Par Priorité)

### 🔴 PRIORITÉ 1 : Configuration CORS (Critique - 5 min)

**Objectif** : Autoriser le dashboard à communiquer avec le backend

**Commande** :
```bash
gcloud run services update tshiakani-vtc-backend \
  --update-env-vars CORS_ORIGIN="https://tshiakani-vtc-99cea.web.app,https://tshiakani-vtc-99cea.firebaseapp.com,capacitor://localhost,ionic://localhost,http://localhost:3001,http://localhost:5173" \
  --region us-central1 \
  --project tshiakani-vtc-477711
```

**Vérification** :
```bash
# Tester depuis le dashboard
curl -H "Origin: https://tshiakani-vtc-99cea.web.app" \
  https://tshiakani-vtc-backend-418102154417.us-central1.run.app/health
```

---

### 🟡 PRIORITÉ 2 : Configuration Twilio (Important - 15 min)

**Objectif** : Activer l'envoi de codes OTP via WhatsApp/SMS

**Étapes** :

1. **Créer un compte Twilio** (si pas déjà fait)
   - Aller sur https://www.twilio.com
   - Créer un compte
   - Noter le `Account SID` et `Auth Token`

2. **Configurer dans Cloud Run** :
```bash
gcloud run services update tshiakani-vtc-backend \
  --update-env-vars="TWILIO_ACCOUNT_SID=votre_account_sid,TWILIO_AUTH_TOKEN=votre_auth_token" \
  --region us-central1 \
  --project tshiakani-vtc-477711
```

3. **Configurer le numéro WhatsApp** (optionnel) :
```bash
gcloud run services update tshiakani-vtc-backend \
  --update-env-vars="TWILIO_WHATSAPP_FROM=whatsapp:+14155238886" \
  --region us-central1 \
  --project tshiakani-vtc-477711
```

**Vérification** :
```bash
# Tester l'envoi d'OTP
curl -X POST https://tshiakani-vtc-backend-418102154417.us-central1.run.app/api/auth/send-otp \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber": "+243900000001"}'
```

---

### 🟡 PRIORITÉ 3 : Configuration Firebase FCM (Important - 15 min)

**Objectif** : Activer les notifications push pour les apps iOS

**Étapes** :

1. **Télécharger la clé de service Firebase** :
   - Aller sur https://console.firebase.google.com/project/tshiakani-vtc-99cea/settings/serviceaccounts/adminsdk
   - Cliquer sur "Générer une nouvelle clé privée"
   - Télécharger le fichier JSON

2. **Stocker dans Secret Manager** :
```bash
gcloud secrets create firebase-service-account \
  --data-file=~/Downloads/tshiakani-vtc-99cea-*.json \
  --project tshiakani-vtc-477711
```

3. **Configurer dans Cloud Run** :
```bash
gcloud run services update tshiakani-vtc-backend \
  --set-secrets="FIREBASE_SERVICE_ACCOUNT=firebase-service-account:latest" \
  --region us-central1 \
  --project tshiakani-vtc-477711
```

**Vérification** :
- Les notifications push fonctionneront automatiquement dans les apps iOS

---

### 🟢 PRIORITÉ 4 : Tests d'Intégration (Recommandé - 30 min)

**Objectif** : Vérifier que tout fonctionne ensemble

#### Test 1 : Dashboard ↔ Backend

1. Ouvrir https://tshiakani-vtc-99cea.web.app
2. Se connecter avec les identifiants admin
3. Vérifier que les statistiques se chargent
4. Tester les différentes pages

**Vérification** :
- Console navigateur (F12) : Pas d'erreurs CORS
- Données affichées correctement
- Requêtes vers `/api/admin/*` réussissent

#### Test 2 : App Client iOS ↔ Backend

1. Lancer l'app client iOS
2. Tenter de se connecter (avec OTP si Twilio configuré)
3. Créer une course de test
4. Vérifier les logs Cloud Run

**Vérification** :
- Connexion réussie
- Course créée en base de données
- Notifications reçues (si FCM configuré)

#### Test 3 : App Driver iOS ↔ Backend

1. Lancer l'app driver iOS
2. Se connecter en tant que chauffeur
3. Mettre à jour la position GPS
4. Accepter une course

**Vérification** :
- Position mise à jour dans Redis
- Course acceptée
- Notifications envoyées

---

### 🟢 PRIORITÉ 5 : Monitoring et Alertes (Optionnel - 20 min)

**Objectif** : Configurer le monitoring pour la production

#### Créer les Alertes Cloud Monitoring

```bash
cd "/Users/admin/Documents/Tshiakani VTC"
./scripts/gcp-create-alerts.sh
```

#### Créer le Dashboard Cloud Monitoring

```bash
./scripts/gcp-create-dashboard.sh
```

**Métriques à surveiller** :
- Latence API (< 500ms)
- Taux d'erreur (< 1%)
- Utilisation CPU/Mémoire
- Nombre de courses créées
- Nombre de chauffeurs actifs

---

### 🟢 PRIORITÉ 6 : Optimisations Finales (Optionnel)

#### 1. Configurer VPC Connector pour Redis

Si vous voulez utiliser Redis depuis Cloud Run (actuellement en mode dégradé) :

```bash
# Créer le VPC Connector
gcloud compute networks vpc-access connectors create tshiakani-vpc-connector \
  --region=us-central1 \
  --subnet=default \
  --subnet-project=tshiakani-vtc-477711 \
  --min-instances=2 \
  --max-instances=3

# Configurer Cloud Run pour utiliser le VPC Connector
gcloud run services update tshiakani-vtc-backend \
  --vpc-connector=tshiakani-vpc-connector \
  --vpc-egress=all-traffic \
  --region us-central1 \
  --project tshiakani-vtc-477711
```

#### 2. Configurer un Domaine Personnalisé

Pour le dashboard :
- Firebase Hosting > Domaines personnalisés
- Ajouter votre domaine (ex: admin.tshiakani-vtc.com)

Pour le backend :
- Cloud Run > Domaines personnalisés
- Mapper votre domaine

---

## 📊 Checklist Complète

### Configuration Immédiate
- [ ] Configurer CORS pour le dashboard
- [ ] Tester le dashboard déployé
- [ ] Vérifier la connexion dashboard ↔ backend

### Services Externes
- [ ] Configurer Twilio (OTP)
- [ ] Tester l'envoi d'OTP
- [ ] Configurer Firebase FCM
- [ ] Tester les notifications push

### Tests d'Intégration
- [ ] Tester Dashboard ↔ Backend
- [ ] Tester App Client ↔ Backend
- [ ] Tester App Driver ↔ Backend
- [ ] Tester le flux complet (création de course)

### Monitoring
- [ ] Créer les alertes Cloud Monitoring
- [ ] Créer le dashboard Cloud Monitoring
- [ ] Configurer les notifications d'alerte

### Optimisations
- [ ] Configurer VPC Connector (si nécessaire)
- [ ] Configurer domaines personnalisés (si nécessaire)
- [ ] Optimiser les performances

---

## 🎯 Ordre d'Exécution Recommandé

### Phase 1 : Configuration Critique (30 min)
1. ✅ Configurer CORS
2. ✅ Tester le dashboard
3. ✅ Configurer Twilio
4. ✅ Tester OTP

### Phase 2 : Services Complémentaires (30 min)
1. ✅ Configurer Firebase FCM
2. ✅ Tester les notifications
3. ✅ Tests d'intégration complets

### Phase 3 : Monitoring (20 min)
1. ✅ Créer les alertes
2. ✅ Créer le dashboard
3. ✅ Configurer les notifications

### Phase 4 : Optimisations (Optionnel)
1. ✅ VPC Connector
2. ✅ Domaines personnalisés
3. ✅ Optimisations de performance

---

## 📝 Commandes Rapides

### Configurer CORS
```bash
gcloud run services update tshiakani-vtc-backend \
  --update-env-vars CORS_ORIGIN="https://tshiakani-vtc-99cea.web.app,https://tshiakani-vtc-99cea.firebaseapp.com,capacitor://localhost,ionic://localhost,http://localhost:3001,http://localhost:5173" \
  --region us-central1 \
  --project tshiakani-vtc-477711
```

### Configurer Twilio
```bash
gcloud run services update tshiakani-vtc-backend \
  --update-env-vars="TWILIO_ACCOUNT_SID=votre_sid,TWILIO_AUTH_TOKEN=votre_token" \
  --region us-central1 \
  --project tshiakani-vtc-477711
```

### Vérifier les Logs
```bash
gcloud run services logs read tshiakani-vtc-backend \
  --region us-central1 \
  --project tshiakani-vtc-477711 \
  --limit 50
```

### Tester le Backend
```bash
curl https://tshiakani-vtc-backend-418102154417.us-central1.run.app/health
```

### Tester le Dashboard
```bash
curl -I https://tshiakani-vtc-99cea.web.app
```

---

## 🎉 Résumé

### ✅ Déjà Fait
- Infrastructure GCP complète
- Backend déployé
- Dashboard déployé
- Apps iOS configurées

### ⚠️ À Faire (Priorité)
1. **CORS** (5 min) - Pour que le dashboard fonctionne
2. **Twilio** (15 min) - Pour l'authentification OTP
3. **Firebase FCM** (15 min) - Pour les notifications push

### 🎯 Temps Total Estimé
- **Configuration minimale** : 35 minutes
- **Configuration complète** : 1h30

---

**Date** : 2025-01-15  
**Statut** : ✅ Prêt pour les configurations finales

