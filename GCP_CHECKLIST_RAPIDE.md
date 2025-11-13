# ✅ Checklist Rapide - Déploiement Backend VTC sur GCP

## 🚀 Actions Immédiates (À faire maintenant)

### 1. Prérequis
- [ ] Compte GCP avec facturation activée
- [ ] Google Cloud SDK (gcloud) installé
- [ ] Docker installé
- [ ] Projet GCP créé

```bash
# Vérifier
gcloud --version
gcloud config get-value project
```

---

### 2. Étape 1 : Cloud SQL (Base de Données)

```bash
# Créer l'instance
./scripts/gcp-create-cloud-sql.sh

# Initialiser la base de données
./scripts/gcp-init-database.sh

# Vérifier
gcloud sql instances describe tshiakani-vtc-db
```

**Vérifications** :
- [ ] Instance créée
- [ ] Tables créées (users, rides)
- [ ] Extension PostGIS activée
- [ ] Test d'inscription réussi

---

### 3. Étape 2 : Redis (Memorystore)

```bash
# Créer l'instance
./scripts/gcp-create-redis.sh

# Vérifier
gcloud redis instances describe tshiakani-vtc-redis --region=us-central1
```

**Vérifications** :
- [ ] Instance créée
- [ ] Connexion Redis fonctionnelle
- [ ] Test de mise à jour de position réussi
- [ ] Test de matching avec Redis réussi

---

### 4. Étape 3 : Cloud Run (Déploiement)

```bash
# Déployer le backend
./scripts/gcp-deploy-backend.sh

# Configurer les variables d'environnement
./scripts/gcp-set-cloud-run-env.sh

# Vérifier
./scripts/gcp-verify-cloud-run.sh
```

**Vérifications** :
- [ ] Service déployé
- [ ] Variables d'environnement configurées
- [ ] Health check fonctionnel
- [ ] Endpoints API fonctionnels

---

### 5. Étape 4 : Google Maps & FCM

```bash
# Activer les APIs
gcloud services enable routes.googleapis.com
gcloud services enable places.googleapis.com
gcloud services enable geocoding.googleapis.com

# Configurer la clé API (via console GCP ou Secret Manager)
```

**Vérifications** :
- [ ] APIs activées
- [ ] Clé API configurée
- [ ] Test de calcul d'itinéraire réussi
- [ ] Test de tarification réussi

---

### 6. Étape 5 : Monitoring

```bash
# Configurer le monitoring
./scripts/gcp-setup-monitoring.sh

# Créer les alertes
./scripts/gcp-create-alerts.sh

# Créer les tableaux de bord
./scripts/gcp-create-dashboard.sh
```

**Vérifications** :
- [ ] Cloud Logging configuré
- [ ] Cloud Monitoring configuré
- [ ] Alertes créées
- [ ] Tableaux de bord créés
- [ ] Test d'alerte réussi (échec paiement)

---

## 🧪 Tests Critiques

### Test 1 : Inscription
```bash
curl -X POST http://localhost:3000/api/auth/signup \
  -d '{"phoneNumber": "+243900000001", "name": "Test", "role": "client"}'
```

### Test 2 : Mise à jour position
```bash
curl -X POST http://localhost:3000/api/driver/location \
  -d '{"latitude": -4.3276, "longitude": 15.3363, "status": "available"}'
```

### Test 3 : Création de course
```bash
curl -X POST http://localhost:3000/api/ride/request \
  -d '{"pickupLocation": {"latitude": -4.3276, "longitude": 15.3363}, ...}'
```

### Test 4 : Échec paiement → Alerte
```bash
curl -X POST $SERVICE_URL/api/payment/process \
  -d '{"rideId": "invalid", "amount": 1000, "paymentToken": "invalid"}'
```

---

## 📚 Documentation

- `GCP_PROCHAINES_ACTIONS.md` - Guide détaillé des actions
- `GCP_5_ETAPES_DEPLOIEMENT.md` - Les 5 étapes de déploiement
- `GCP_ACTIONS_CLES_DETAILLEES.md` - Actions clés détaillées
- `GCP_INDEX_DOCUMENTATION.md` - Index de la documentation

---

**Version**: 1.0.0  
**Dernière mise à jour**: 2025-01-15

