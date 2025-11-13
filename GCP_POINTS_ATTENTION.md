# ⚠️ Points d'Attention - Déploiement Backend VTC sur GCP

## 🎯 Vue d'Ensemble

Ce document liste tous les points d'attention, pièges à éviter, problèmes courants et bonnes pratiques pour le déploiement du backend Tshiakani VTC sur Google Cloud Platform (GCP).

---

## 🚨 Points d'Attention Critiques

### 1. Dépendances entre les Étapes

#### ⚠️ Problème
Certaines étapes dépendent d'autres étapes et doivent être exécutées dans un ordre spécifique.

#### ✅ Solution
- **Étape 2.3** (Test Redis) doit être effectuée **après Étape 3** (Cloud Run déployé)
- **Étape 4.3** (Test itinéraire) nécessite que **Étape 3** soit terminée
- **Étape 5.6** (Test alertes) nécessite que **Étape 3** et **Étape 5** soient terminées

#### 📋 Checklist
- [ ] Vérifier que Cloud Run est déployé avant de tester Redis
- [ ] Vérifier que les variables d'environnement sont configurées avant de tester les APIs
- [ ] Vérifier que le monitoring est configuré avant de tester les alertes

---

### 2. Temps d'Attente pour les Instances

#### ⚠️ Problème
La création d'instances Cloud SQL et Memorystore peut prendre du temps.

#### ✅ Solution
- **Cloud SQL** : La création peut prendre **5-10 minutes**
- **Memorystore** : La création peut prendre **10-15 minutes**
- **Cloud Run** : Le déploiement peut prendre **5-10 minutes**

#### 📋 Checklist
- [ ] Attendre que l'instance Cloud SQL soit dans l'état `RUNNABLE` avant de continuer
- [ ] Attendre que l'instance Memorystore soit dans l'état `READY` avant de continuer
- [ ] Vérifier le statut avec `gcloud sql instances describe` et `gcloud redis instances describe`

#### 🔍 Commandes de Vérification
```bash
# Vérifier le statut Cloud SQL
gcloud sql instances describe tshiakani-vtc-db \
  --project=tshiakani-vtc \
  --format="value(state)"

# Vérifier le statut Memorystore
gcloud redis instances describe tshiakani-vtc-redis \
  --region=us-central1 \
  --project=tshiakani-vtc \
  --format="value(state)"
```

---

### 3. Permissions IAM

#### ⚠️ Problème
Les permissions IAM sont essentielles pour que Cloud Run puisse accéder aux services GCP.

#### ✅ Solution
- Configurer les permissions **avant** de déployer le backend
- Vérifier que le service account Cloud Run a les permissions nécessaires
- Tester les permissions après configuration

#### 📋 Permissions Requises
- [ ] `roles/cloudsql.client` - Accès à Cloud SQL
- [ ] `roles/redis.editor` - Accès à Memorystore (via VPC)
- [ ] `roles/logging.logWriter` - Écriture de logs
- [ ] `roles/monitoring.metricWriter` - Écriture de métriques
- [ ] `roles/secretmanager.secretAccessor` - Accès aux secrets

#### 🔍 Commandes de Vérification
```bash
# Vérifier les permissions du service account
SERVICE_ACCOUNT=$(gcloud run services describe tshiakani-vtc-backend \
  --region=us-central1 \
  --format="value(spec.template.spec.serviceAccountName)")

gcloud projects get-iam-policy tshiakani-vtc \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:${SERVICE_ACCOUNT}"
```

---

### 4. Variables d'Environnement

#### ⚠️ Problème
Les variables d'environnement doivent être configurées correctement pour que le backend fonctionne.

#### ✅ Solution
- Configurer toutes les variables d'environnement **avant** de tester les endpoints
- Utiliser Secret Manager pour les secrets (clés API, mots de passe)
- Vérifier que les variables sont correctement définies

#### 📋 Variables Requises
- [ ] `DATABASE_URL` - Connexion Cloud SQL
- [ ] `REDIS_HOST` - Adresse Redis
- [ ] `REDIS_PORT` - Port Redis
- [ ] `JWT_SECRET` - Secret JWT
- [ ] `GOOGLE_MAPS_API_KEY` - Clé API Google Maps
- [ ] `FIREBASE_PROJECT_ID` - ID projet Firebase
- [ ] `FIREBASE_PRIVATE_KEY` - Clé privée Firebase
- [ ] `STRIPE_SECRET_KEY` - Clé secrète Stripe (si applicable)

#### 🔍 Commandes de Vérification
```bash
# Vérifier les variables d'environnement
gcloud run services describe tshiakani-vtc-backend \
  --region=us-central1 \
  --format="value(spec.template.spec.containers[0].env)"
```

---

### 5. Connexion Cloud SQL depuis Cloud Run

#### ⚠️ Problème
La connexion à Cloud SQL depuis Cloud Run nécessite une configuration spécifique.

#### ✅ Solution
- Utiliser le **Cloud SQL Proxy** ou la **connexion Unix socket**
- Configurer `INSTANCE_CONNECTION_NAME` dans les variables d'environnement
- Vérifier que le VPC Connector est configuré (si nécessaire)

#### 📋 Configuration Requise
- [ ] `INSTANCE_CONNECTION_NAME` configuré (format: `project:region:instance`)
- [ ] Cloud SQL Proxy activé dans Cloud Run
- [ ] VPC Connector configuré (si connexion privée)

#### 🔍 Commandes de Vérification
```bash
# Vérifier la connexion Cloud SQL
gcloud run services describe tshiakani-vtc-backend \
  --region=us-central1 \
  --format="value(spec.template.spec.containers[0].env)" | grep INSTANCE_CONNECTION_NAME

# Tester la connexion depuis Cloud Run
curl https://tshiakani-vtc-backend-xxxxx.run.app/health
```

---

### 6. Connexion Redis depuis Cloud Run

#### ⚠️ Problème
La connexion à Memorystore depuis Cloud Run nécessite un VPC Connector.

#### ✅ Solution
- Créer un **VPC Connector** dans la même région que Memorystore
- Configurer Cloud Run pour utiliser le VPC Connector
- Vérifier que le VPC Connector est accessible depuis Cloud Run

#### 📋 Configuration Requise
- [ ] VPC Connector créé dans la même région que Memorystore
- [ ] Cloud Run configuré pour utiliser le VPC Connector
- [ ] Règles de firewall configurées (si nécessaire)

#### 🔍 Commandes de Vérification
```bash
# Vérifier le VPC Connector
gcloud compute networks vpc-access connectors list \
  --region=us-central1

# Vérifier la configuration Cloud Run
gcloud run services describe tshiakani-vtc-backend \
  --region=us-central1 \
  --format="value(spec.template.spec.vpcAccess)"
```

---

### 7. Quotas et Limites

#### ⚠️ Problème
Les quotas GCP peuvent limiter le nombre d'instances ou de ressources créées.

#### ✅ Solution
- Vérifier les quotas avant de créer les instances
- Demander une augmentation de quota si nécessaire
- Surveiller l'utilisation des ressources

#### 📋 Quotas à Vérifier
- [ ] Quota Cloud SQL (nombre d'instances)
- [ ] Quota Memorystore (nombre d'instances)
- [ ] Quota Cloud Run (nombre de services)
- [ ] Quota Artifact Registry (taille des images)

#### 🔍 Commandes de Vérification
```bash
# Vérifier les quotas
gcloud compute project-info describe \
  --project=tshiakani-vtc \
  --format="value(quotas)"

# Vérifier les quotas spécifiques
gcloud compute project-info describe \
  --project=tshiakani-vtc \
  --format="get(quotas[].limit,quotas[].usage)"
```

---

### 8. Sécurité des Clés API

#### ⚠️ Problème
Les clés API (Google Maps, Firebase) doivent être sécurisées.

#### ✅ Solution
- Utiliser **Secret Manager** pour stocker les clés API
- Configurer les restrictions d'API (IP, référent, application)
- Ne jamais commiter les clés API dans le code

#### 📋 Bonnes Pratiques
- [ ] Clés API stockées dans Secret Manager
- [ ] Restrictions d'API configurées
- [ ] Service account a accès aux secrets
- [ ] Clés API jamais committées dans le code

#### 🔍 Commandes de Vérification
```bash
# Vérifier les secrets
gcloud secrets list

# Vérifier les permissions sur les secrets
gcloud secrets get-iam-policy google-maps-api-key
```

---

### 9. Coûts GCP

#### ⚠️ Problème
Les services GCP peuvent générer des coûts importants.

#### ✅ Solution
- Surveiller les coûts régulièrement
- Configurer des budgets et alertes de coûts
- Optimiser l'utilisation des ressources

#### 📋 Coûts à Surveiller
- [ ] Cloud SQL (instance, stockage, réseau)
- [ ] Memorystore (instance, réseau)
- [ ] Cloud Run (requêtes, CPU, mémoire)
- [ ] Google Maps API (requêtes)
- [ ] Artifact Registry (stockage)

#### 🔍 Commandes de Vérification
```bash
# Vérifier les coûts
gcloud billing accounts list

# Vérifier l'utilisation des ressources
gcloud compute instances list
gcloud sql instances list
gcloud redis instances list
```

---

### 10. Monitoring et Alertes

#### ⚠️ Problème
Le monitoring et les alertes doivent être configurés correctement pour détecter les problèmes.

#### ✅ Solution
- Configurer Cloud Logging et Cloud Monitoring
- Créer des alertes pour les métriques critiques
- Configurer les notifications d'alertes

#### 📋 Alertes à Configurer
- [ ] Latence API élevée (> 2000ms)
- [ ] Taux d'erreurs élevé (> 5%)
- [ ] Utilisation mémoire élevée (> 80%)
- [ ] Utilisation CPU élevée (> 80%)
- [ ] Erreurs de paiement (> 10 erreurs)
- [ ] Erreurs de matching (> 10 erreurs)

#### 🔍 Commandes de Vérification
```bash
# Vérifier les alertes
gcloud alpha monitoring policies list \
  --project=tshiakani-vtc

# Vérifier les métriques
gcloud monitoring time-series list \
  --filter='metric.type="custom.googleapis.com/api/latency"' \
  --project=tshiakani-vtc
```

---

## 🐛 Problèmes Courants et Solutions

### Problème 1 : Instance Cloud SQL non accessible

#### Symptômes
- Erreur de connexion à Cloud SQL
- Timeout lors de la connexion
- Erreur "Connection refused"

#### Solutions
1. Vérifier que l'instance est dans l'état `RUNNABLE`
2. Vérifier que `INSTANCE_CONNECTION_NAME` est correctement configuré
3. Vérifier que les permissions IAM sont correctes
4. Vérifier que le VPC Connector est configuré (si connexion privée)

#### Commandes de Diagnostic
```bash
# Vérifier le statut de l'instance
gcloud sql instances describe tshiakani-vtc-db

# Vérifier les permissions
gcloud projects get-iam-policy tshiakani-vtc \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:tshiakani-vtc-backend@tshiakani-vtc.iam.gserviceaccount.com"

# Tester la connexion
gcloud sql connect tshiakani-vtc-db --user=postgres
```

---

### Problème 2 : Instance Memorystore non accessible

#### Symptômes
- Erreur de connexion à Redis
- Timeout lors de la connexion
- Erreur "Connection refused"

#### Solutions
1. Vérifier que l'instance est dans l'état `READY`
2. Vérifier que le VPC Connector est créé et configuré
3. Vérifier que Cloud Run est configuré pour utiliser le VPC Connector
4. Vérifier que les règles de firewall permettent la connexion

#### Commandes de Diagnostic
```bash
# Vérifier le statut de l'instance
gcloud redis instances describe tshiakani-vtc-redis --region=us-central1

# Vérifier le VPC Connector
gcloud compute networks vpc-access connectors list --region=us-central1

# Vérifier la configuration Cloud Run
gcloud run services describe tshiakani-vtc-backend \
  --region=us-central1 \
  --format="value(spec.template.spec.vpcAccess)"
```

---

### Problème 3 : Déploiement Cloud Run échoué

#### Symptômes
- Erreur lors du déploiement
- Service non accessible
- Erreur "Image not found"

#### Solutions
1. Vérifier que l'image Docker est buildée et poussée
2. Vérifier que Artifact Registry est configuré
3. Vérifier que les permissions IAM sont correctes
4. Vérifier les logs de build

#### Commandes de Diagnostic
```bash
# Vérifier les images
gcloud artifacts docker images list us-central1-docker.pkg.dev/tshiakani-vtc/tshiakani-vtc-repo

# Vérifier les logs de build
gcloud builds list --limit=5

# Vérifier les logs du service
gcloud run services describe tshiakani-vtc-backend \
  --region=us-central1 \
  --format="value(status.conditions)"
```

---

### Problème 4 : Erreur de calcul d'itinéraire Google Maps

#### Symptômes
- Erreur lors du calcul d'itinéraire
- Erreur "API key not valid"
- Erreur "Quota exceeded"

#### Solutions
1. Vérifier que la clé API est correctement configurée
2. Vérifier que les APIs sont activées
3. Vérifier que les quotas ne sont pas dépassés
4. Vérifier que les restrictions d'API sont correctes

#### Commandes de Diagnostic
```bash
# Vérifier la clé API
gcloud secrets versions access latest --secret=google-maps-api-key

# Vérifier les APIs activées
gcloud services list --enabled \
  --filter="name:routes OR name:places OR name:geocoding"

# Vérifier les quotas
gcloud services list --enabled \
  --filter="name:routes"
```

---

### Problème 5 : Alertes non déclenchées

#### Symptômes
- Alertes non déclenchées malgré des erreurs
- Notifications non reçues
- Métriques non enregistrées

#### Solutions
1. Vérifier que Cloud Monitoring est configuré
2. Vérifier que les métriques sont enregistrées
3. Vérifier que les alertes sont correctement configurées
4. Vérifier que les notifications sont configurées

#### Commandes de Diagnostic
```bash
# Vérifier les métriques
gcloud monitoring time-series list \
  --filter='metric.type="custom.googleapis.com/api/latency"' \
  --project=tshiakani-vtc

# Vérifier les alertes
gcloud alpha monitoring policies list \
  --project=tshiakani-vtc

# Vérifier les notifications
gcloud alpha monitoring channels list \
  --project=tshiakani-vtc
```

---

## ✅ Bonnes Pratiques

### 1. Gestion des Secrets

#### ✅ Bonnes Pratiques
- Utiliser Secret Manager pour tous les secrets
- Ne jamais commiter les secrets dans le code
- Utiliser des variables d'environnement pour les secrets
- Roter les secrets régulièrement

#### ❌ À Éviter
- Commiter les secrets dans le code
- Stocker les secrets en clair dans les variables d'environnement
- Partager les secrets par email ou chat

---

### 2. Gestion des Variables d'Environnement

#### ✅ Bonnes Pratiques
- Utiliser des variables d'environnement pour la configuration
- Documenter toutes les variables d'environnement
- Utiliser des valeurs par défaut quand c'est possible
- Valider les variables d'environnement au démarrage

#### ❌ À Éviter
- Hardcoder les valeurs de configuration
- Utiliser des variables d'environnement non documentées
- Ignorer les erreurs de validation

---

### 3. Gestion des Erreurs

#### ✅ Bonnes Pratiques
- Logger toutes les erreurs
- Envoyer les erreurs à Cloud Logging
- Créer des alertes pour les erreurs critiques
- Documenter les erreurs courantes

#### ❌ À Éviter
- Ignorer les erreurs
- Logger les erreurs sans contexte
- Ne pas créer d'alertes pour les erreurs critiques

---

### 4. Gestion des Performances

#### ✅ Bonnes Pratiques
- Surveiller la latence des APIs
- Optimiser les requêtes de base de données
- Utiliser le cache (Redis) pour les données fréquentes
- Configurer la mise à l'échelle automatique

#### ❌ À Éviter
- Ignorer les problèmes de performance
- Ne pas optimiser les requêtes
- Ne pas utiliser le cache
- Ne pas configurer la mise à l'échelle

---

### 5. Gestion des Coûts

#### ✅ Bonnes Pratiques
- Surveiller les coûts régulièrement
- Configurer des budgets et alertes de coûts
- Optimiser l'utilisation des ressources
- Utiliser les instances les plus petites possibles

#### ❌ À Éviter
- Ignorer les coûts
- Utiliser des instances trop grandes
- Ne pas surveiller l'utilisation des ressources
- Ne pas configurer de budgets

---

## 📋 Checklist de Vérification

### Avant le Déploiement
- [ ] Tous les prérequis sont installés
- [ ] Toutes les APIs sont activées
- [ ] Tous les quotas sont vérifiés
- [ ] Tous les secrets sont configurés

### Pendant le Déploiement
- [ ] Chaque étape est vérifiée avant de passer à la suivante
- [ ] Les temps d'attente sont respectés
- [ ] Les erreurs sont corrigées immédiatement
- [ ] Les logs sont surveillés

### Après le Déploiement
- [ ] Tous les endpoints API sont testés
- [ ] Toutes les fonctionnalités sont testées
- [ ] Le monitoring est configuré
- [ ] Les alertes sont testées

---

## 🚨 Alertes Critiques

### Alertes à Configurer Immédiatement
1. **Latence API élevée** (> 2000ms)
2. **Taux d'erreurs élevé** (> 5%)
3. **Utilisation mémoire élevée** (> 80%)
4. **Utilisation CPU élevée** (> 80%)
5. **Erreurs de paiement** (> 10 erreurs)
6. **Erreurs de matching** (> 10 erreurs)

### Alertes à Configurer Secondairement
1. **Coûts élevés** (> budget défini)
2. **Quotas atteints** (> 80% du quota)
3. **Instances non disponibles** (> 5 minutes)
4. **Connexions échouées** (> 10 échecs)

---

## 📚 Documentation de Référence

### Guides par Étape
- `GCP_SETUP_ETAPE1.md` - Initialisation GCP
- `GCP_SETUP_ETAPE2.md` - Cloud SQL
- `GCP_SETUP_ETAPE3.md` - Memorystore
- `GCP_SETUP_ETAPE4.md` - Cloud Run
- `GCP_SETUP_ETAPE5.md` - Monitoring

### Guides de Déploiement
- `GCP_ORDRE_EXECUTION.md` - Ordre d'exécution
- `GCP_PROCHAINES_ACTIONS.md` - Actions à effectuer
- `GCP_CHECKLIST_RAPIDE.md` - Checklist rapide

---

## 🎯 Résumé

### Points d'Attention Critiques
1. **Dépendances entre les étapes** - Respecter l'ordre d'exécution
2. **Temps d'attente** - Attendre que les instances soient prêtes
3. **Permissions IAM** - Configurer correctement les permissions
4. **Variables d'environnement** - Configurer toutes les variables
5. **Connexions** - Vérifier les connexions Cloud SQL et Redis

### Problèmes Courants
1. **Instance Cloud SQL non accessible** - Vérifier le statut et les permissions
2. **Instance Memorystore non accessible** - Vérifier le VPC Connector
3. **Déploiement Cloud Run échoué** - Vérifier l'image et les permissions
4. **Erreur de calcul d'itinéraire** - Vérifier la clé API et les quotas
5. **Alertes non déclenchées** - Vérifier le monitoring et les alertes

### Bonnes Pratiques
1. **Gestion des secrets** - Utiliser Secret Manager
2. **Gestion des variables d'environnement** - Documenter et valider
3. **Gestion des erreurs** - Logger et alerter
4. **Gestion des performances** - Surveiller et optimiser
5. **Gestion des coûts** - Surveiller et optimiser

---

**Date de création**: 2025-01-15  
**Version**: 1.0.0  
**Statut**: Points d'attention pour le déploiement

