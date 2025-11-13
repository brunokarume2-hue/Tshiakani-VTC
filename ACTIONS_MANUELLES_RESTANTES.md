# 📋 Actions Manuelles Restantes

## 🎯 Vue d'Ensemble

Ce document liste toutes les **actions manuelles** à effectuer pour finaliser le déploiement du backend Tshiakani VTC sur GCP.

---

## ✅ Actions Prioritaires

### 1. 🔑 Créer la Clé API Google Maps

**Pourquoi** : Nécessaire pour le calcul des distances, itinéraires et tarification.

**Étapes** :

1. **Aller sur la console GCP** :
   - https://console.cloud.google.com/apis/credentials?project=tshiakani-vtc-477711

2. **Créer une clé API** :
   - Cliquer sur "Créer des identifiants" → "Clé API"
   - Copier la clé API générée

3. **Restreindre la clé API** (recommandé) :
   - Cliquer sur la clé créée
   - Sous "Restrictions d'application", sélectionner "Applications HTTP"
   - Ajouter l'URL : `https://tshiakani-vtc-backend-418102154417.us-central1.run.app`
   - Sous "Restrictions d'API", sélectionner :
     - Routes API
     - Places API
     - Geocoding API

4. **Stocker dans Secret Manager** :
   ```bash
   cd "/Users/admin/Documents/Tshiakani VTC"
   export GCP_PROJECT_ID=tshiakani-vtc-477711
   
   # Remplacer YOUR_API_KEY par votre clé API
   echo -n 'YOUR_API_KEY' | gcloud secrets create google-maps-api-key \
     --data-file=- \
     --project=tshiakani-vtc-477711
   ```

5. **Donner accès au service account** :
   ```bash
   SERVICE_ACCOUNT=$(gcloud run services describe tshiakani-vtc-backend \
     --region=us-central1 \
     --project=tshiakani-vtc-477711 \
     --format="value(spec.template.spec.serviceAccountName)")
   
   gcloud secrets add-iam-policy-binding google-maps-api-key \
     --member="serviceAccount:${SERVICE_ACCOUNT}" \
     --role="roles/secretmanager.secretAccessor" \
     --project=tshiakani-vtc-477711
   ```

6. **Mettre à jour la variable d'environnement** :
   ```bash
   gcloud run services update tshiakani-vtc-backend \
     --region=us-central1 \
     --project=tshiakani-vtc-477711 \
     --update-env-vars="GOOGLE_MAPS_API_KEY=$(gcloud secrets versions access latest --secret=google-maps-api-key --project=tshiakani-vtc-477711)"
   ```

**⏱️ Temps estimé** : 10-15 minutes

---

### 2. 🔥 Configurer Firebase Cloud Messaging (FCM)

**Pourquoi** : Nécessaire pour envoyer des notifications push aux chauffeurs et clients.

**Étapes** :

1. **Aller sur Firebase Console** :
   - https://console.firebase.google.com

2. **Créer ou sélectionner un projet** :
   - Si nouveau projet : Créer un projet Firebase
   - Si projet existant : Sélectionner le projet `tshiakani-vtc-477711`

3. **Activer Cloud Messaging** :
   - Aller dans "Paramètres du projet" → "Cloud Messaging"
   - Activer Cloud Messaging (FCM)

4. **Télécharger le fichier de configuration** :
   - Aller dans "Paramètres du projet" → "Comptes de service"
   - Cliquer sur "Générer une nouvelle clé privée"
   - Télécharger le fichier JSON

5. **Placer le fichier dans le projet** :
   ```bash
   cd "/Users/admin/Documents/Tshiakani VTC/backend"
   
   # Copier le fichier téléchargé
   cp ~/Downloads/tshiakani-vtc-477711-*.json firebase-service-account.json
   
   # Ou stocker dans Secret Manager (recommandé pour production)
   gcloud secrets create firebase-service-account \
     --data-file=firebase-service-account.json \
     --project=tshiakani-vtc-477711
   ```

6. **Mettre à jour le code backend** pour utiliser Secret Manager (si nécessaire)

**⏱️ Temps estimé** : 15-20 minutes

---

### 3. 📊 Créer les Alertes Cloud Monitoring

**Pourquoi** : Pour être alerté en cas de problème (latence élevée, erreurs, etc.).

**Étapes** :

```bash
cd "/Users/admin/Documents/Tshiakani VTC"
export GCP_PROJECT_ID=tshiakani-vtc-477711

# Créer les alertes
chmod +x scripts/gcp-create-alerts.sh
./scripts/gcp-create-alerts.sh
```

**Alertes créées** :
- ⚠️ Latence API élevée (> 2 secondes)
- ⚠️ Taux d'erreur élevé (> 5%)
- ⚠️ Utilisation CPU élevée (> 80%)
- ⚠️ Utilisation mémoire élevée (> 80%)
- ⚠️ Erreurs de base de données
- ⚠️ Erreurs Redis

**⏱️ Temps estimé** : 5-10 minutes

---

### 4. 📈 Créer les Tableaux de Bord Cloud Monitoring

**Pourquoi** : Pour visualiser les métriques et performances en temps réel.

**Étapes** :

```bash
cd "/Users/admin/Documents/Tshiakani VTC"
export GCP_PROJECT_ID=tshiakani-vtc-477711

# Créer les dashboards
chmod +x scripts/gcp-create-dashboard.sh
./scripts/gcp-create-dashboard.sh
```

**Dashboards créés** :
- 📊 Vue d'ensemble du service
- 📊 Métriques API (latence, requêtes, erreurs)
- 📊 Métriques de base de données
- 📊 Métriques Redis
- 📊 Métriques de matching et tarification

**⏱️ Temps estimé** : 5-10 minutes

---

### 5. 🗄️ Initialiser les Tables de la Base de Données

**Pourquoi** : Créer les tables nécessaires pour le fonctionnement de l'application.

**Étapes** :

1. **Installer psql** (si pas déjà installé) :
   ```bash
   brew install postgresql
   ```

2. **Initialiser la base de données** :
   ```bash
   cd "/Users/admin/Documents/Tshiakani VTC"
   export GCP_PROJECT_ID=tshiakani-vtc-477711
   export DB_PASSWORD='H38TYjMcJfTudmFmSVzvWZk45'
   
   chmod +x scripts/gcp-init-database.sh
   ./scripts/gcp-init-database.sh
   ```

**Alternative : Utiliser Cloud SQL Proxy** :

```bash
# Télécharger Cloud SQL Proxy
curl -o cloud-sql-proxy https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/v2.8.0/cloud-sql-proxy.darwin.arm64
chmod +x cloud-sql-proxy

# Démarrer le proxy (dans un terminal séparé)
./cloud-sql-proxy tshiakani-vtc-477711:us-central1:tshiakani-vtc-db

# Dans un autre terminal, se connecter
psql -h 127.0.0.1 -U postgres -d TshiakaniVTC

# Exécuter les migrations
\i backend/migrations/001_init_postgis_cloud_sql.sql
```

**⏱️ Temps estimé** : 10-15 minutes

---

### 6. 🔌 Créer le VPC Connector (si nécessaire)

**Pourquoi** : Pour permettre à Cloud Run d'accéder à Memorystore Redis.

**Étapes** :

```bash
cd "/Users/admin/Documents/Tshiakani VTC"
export GCP_PROJECT_ID=tshiakani-vtc-477711

gcloud compute networks vpc-access connectors create tshiakani-vtc-connector \
  --region=us-central1 \
  --network=default \
  --range=10.8.0.0/28 \
  --project=tshiakani-vtc-477711
```

**Note** : Le backend peut fonctionner sans Redis (utilise PostgreSQL comme fallback), mais Redis améliore les performances.

**⏱️ Temps estimé** : 5-10 minutes

---

## 📋 Checklist Complète

### Actions Prioritaires (À faire maintenant)
- [ ] Créer la clé API Google Maps
- [ ] Configurer Firebase (FCM)
- [ ] Initialiser les tables de la base de données

### Actions Secondaires (Peuvent être faites plus tard)
- [ ] Créer les alertes Cloud Monitoring
- [ ] Créer les tableaux de bord Cloud Monitoring
- [ ] Créer le VPC Connector (si nécessaire)

---

## 🚀 Commandes Rapides

### Tout configurer en une fois

```bash
cd "/Users/admin/Documents/Tshiakani VTC"
export GCP_PROJECT_ID=tshiakani-vtc-477711
export DB_PASSWORD='H38TYjMcJfTudmFmSVzvWZk45'

# 1. Créer les alertes
./scripts/gcp-create-alerts.sh

# 2. Créer les dashboards
./scripts/gcp-create-dashboard.sh

# 3. Initialiser la base de données (si psql installé)
brew install postgresql 2>/dev/null || true
./scripts/gcp-init-database.sh

# 4. Créer le VPC Connector
gcloud compute networks vpc-access connectors create tshiakani-vtc-connector \
  --region=us-central1 \
  --network=default \
  --range=10.8.0.0/28 \
  --project=tshiakani-vtc-477711 \
  --quiet 2>/dev/null || echo "VPC Connector existe déjà ou erreur"
```

---

## 📝 Notes Importantes

### Google Maps API
- ⚠️ **Coûts** : Les APIs Google Maps sont payantes après le quota gratuit
- 💡 **Astuce** : Configurez des quotas et des alertes de facturation
- 🔒 **Sécurité** : Restreignez la clé API aux domaines autorisés

### Firebase FCM
- ⚠️ **Limites** : 10 000 messages/jour en gratuit
- 💡 **Astuce** : Utilisez des notifications groupées pour économiser
- 🔒 **Sécurité** : Stockez le fichier de configuration dans Secret Manager

### Base de Données
- ⚠️ **Important** : Le backend peut créer les tables automatiquement au premier démarrage
- 💡 **Astuce** : Initialisez les tables manuellement pour un meilleur contrôle
- 🔒 **Sécurité** : Changez le mot de passe par défaut en production

---

## 🎯 Ordre Recommandé d'Exécution

1. **Initialiser les tables** (nécessaire pour le fonctionnement)
2. **Configurer Google Maps** (nécessaire pour la tarification)
3. **Configurer Firebase** (nécessaire pour les notifications)
4. **Créer les alertes** (pour le monitoring)
5. **Créer les dashboards** (pour la visualisation)
6. **Créer le VPC Connector** (optionnel, pour Redis)

---

## 📚 Documentation

- **Console GCP** : https://console.cloud.google.com?project=tshiakani-vtc-477711
- **Cloud Run** : https://console.cloud.google.com/run?project=tshiakani-vtc-477711
- **Cloud SQL** : https://console.cloud.google.com/sql?project=tshiakani-vtc-477711
- **Memorystore** : https://console.cloud.google.com/memorystore?project=tshiakani-vtc-477711
- **Monitoring** : https://console.cloud.google.com/monitoring?project=tshiakani-vtc-477711
- **Firebase** : https://console.firebase.google.com

---

**Date de création** : 2025-01-15  
**Version** : 1.0.0  
**Statut** : Actions manuelles à effectuer

