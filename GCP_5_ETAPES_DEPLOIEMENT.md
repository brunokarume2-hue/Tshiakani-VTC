# 🚀 Les 5 Étapes pour Déployer Votre Backend VTC sur GCP

## 📊 Vue d'Ensemble

Ce document présente les 5 étapes essentielles pour déployer le backend Tshiakani VTC sur Google Cloud Platform (GCP), avec les services clés et le rôle de chaque composant.

---

## 📋 Tableau Récapitulatif

| Phase | Objectif Principal | Services GCP Clés | Rôle de Cursor |
|-------|-------------------|-------------------|----------------|
| **Étape 1 : Le Socle de Données** | Établir le stockage des données transactionnelles et la persistance des profils. | Cloud SQL (PostgreSQL) | Générer les scripts SQL pour les tables Users, Drivers, et Rides. |
| **Étape 2 : L'Épine Dorsale du Temps Réel** | Créer le mécanisme de suivi des chauffeurs et d'accès ultra-rapide aux données de géolocalisation. | Memorystore (Redis) | Écrire les fonctions du backend pour l'écriture (HSET) et la lecture (HGETALL) de la position des chauffeurs. |
| **Étape 3 : Le Cœur de la Logique** | Déployer votre code Backend monolithique pour qu'il soit évolutif et accessible via API. | Cloud Run & Artifact Registry (Docker) | Finaliser le Dockerfile et la logique métier (authentification, gestion des statuts de course). |
| **Étape 4 : Les Services Clés** | Intégrer la cartographie, l'itinéraire et le système de communication instantanée. | Google Maps Platform APIs (Routes) & Firebase Cloud Messaging (FCM) | Écrire le code de l'API de tarification qui appelle l'API Maps et le code pour l'envoi de notifications via FCM. |
| **Étape 5 : L'Opérabilité et la Mise en Service** | Mettre en place la surveillance et les outils d'administration pour la gestion quotidienne de Kinshasa. | Cloud Logging, Cloud Monitoring | Intégrer les librairies de logging dans votre code backend et définir les métriques de surveillance. |

---

## 🗄️ Étape 1 : Le Socle de Données (Base de Données)

### Objectif Principal
Établir le stockage des données transactionnelles et la persistance des profils utilisateurs, conducteurs et courses.

### Services GCP Clés
- **Cloud SQL (PostgreSQL)** - Base de données relationnelle avec extension PostGIS pour les requêtes géospatiales
- **Cloud SQL Proxy** - Connexion sécurisée depuis Cloud Run

### Rôle de Cursor
- ✅ Générer les scripts SQL pour les tables principales :
  - `Users` (utilisateurs/passagers)
  - `Drivers` (conducteurs avec informations de véhicule)
  - `Rides` (courses avec géolocalisation, statut, prix)
- ✅ Créer les index nécessaires (spatial, composite, partiels)
- ✅ Définir les contraintes d'intégrité référentielle
- ✅ Configurer les migrations TypeORM

### Fichiers Générés
- `scripts/gcp-create-cloud-sql.sh` - Script de création de l'instance Cloud SQL
- `scripts/gcp-init-database.sh` - Script d'initialisation de la base de données
- `backend/migrations/*.sql` - Migrations SQL
- `backend/entities/User.js`, `backend/entities/Ride.js` - Entités TypeORM

### Commandes Clés
```bash
# Créer l'instance Cloud SQL
./scripts/gcp-create-cloud-sql.sh

# Initialiser la base de données
./scripts/gcp-init-database.sh
```

### Documentation
- `GCP_SETUP_ETAPE2.md` - Guide complet de configuration Cloud SQL
- `backend/DATABASE_SCHEMA.md` - Schéma de base de données

---

## 🔴 Étape 2 : L'Épine Dorsale du Temps Réel (Redis)

### Objectif Principal
Créer le mécanisme de suivi des chauffeurs et d'accès ultra-rapide aux données de géolocalisation en temps réel.

### Services GCP Clés
- **Memorystore (Redis)** - Cache en mémoire pour les données temps réel
- **VPC Connector** - Connexion privée entre Cloud Run et Memorystore

### Rôle de Cursor
- ✅ Écrire les fonctions du backend pour :
  - **Écriture (HSET)** : Mise à jour de la position des chauffeurs toutes les 2-3 secondes
  - **Lecture (HGETALL)** : Récupération de la position et du statut des chauffeurs
  - **Recherche géospatiale** : Trouver les chauffeurs disponibles dans un rayon de 5 km
- ✅ Implémenter le service Redis (`RedisService.js`)
- ✅ Configurer le TTL (Time To Live) pour nettoyer les données obsolètes
- ✅ Intégrer Redis dans les routes de localisation

### Structure de Données Redis
```
Clé: driver:<driver_id>
Valeur (Hash):
  - lat: Latitude actuelle
  - lon: Longitude actuelle
  - status: Disponible, En course, Hors ligne
  - last_update: Timestamp de dernière mise à jour
```

### Fichiers Générés
- `scripts/gcp-create-redis.sh` - Script de création de l'instance Memorystore
- `backend/services/RedisService.js` - Service Redis pour la gestion des données temps réel
- `backend/routes.postgres/location.js` - Routes pour la mise à jour de localisation
- `backend/routes.postgres/driver.js` - Routes pour les conducteurs

### Commandes Clés
```bash
# Créer l'instance Memorystore
./scripts/gcp-create-redis.sh

# Tester la connexion Redis
redis-cli -h <redis-host> -p 6379 ping
```

### Documentation
- `GCP_SETUP_ETAPE3.md` - Guide complet de configuration Memorystore
- `backend/REDIS_STRUCTURE.md` - Structure des données Redis

---

## 🚀 Étape 3 : Le Cœur de la Logique (Code & Déploiement)

### Objectif Principal
Déployer votre code Backend monolithique pour qu'il soit évolutif et accessible via API.

### Services GCP Clés
- **Cloud Run** - Service serverless pour héberger le backend
- **Artifact Registry** - Registre Docker pour les images
- **Cloud Build** - Build automatisé des images Docker

### Rôle de Cursor
- ✅ Finaliser le **Dockerfile** pour containeriser l'application
- ✅ Implémenter la **logique métier** :
  - Authentification JWT
  - Gestion des statuts de course (pending, accepted, in_progress, completed, cancelled)
  - Gestion des utilisateurs et conducteurs
  - Gestion des paiements
- ✅ Configurer les **variables d'environnement** pour Cloud Run
- ✅ Configurer les **permissions IAM** pour accès à Cloud SQL et Redis

### Fichiers Générés
- `backend/Dockerfile` - Configuration Docker
- `backend/.dockerignore` - Fichiers à exclure du build
- `scripts/gcp-deploy-backend.sh` - Script de déploiement sur Cloud Run
- `scripts/gcp-set-cloud-run-env.sh` - Script de configuration des variables d'environnement
- `scripts/gcp-verify-cloud-run.sh` - Script de vérification du déploiement

### Commandes Clés
```bash
# Déployer le backend sur Cloud Run
./scripts/gcp-deploy-backend.sh

# Configurer les variables d'environnement
./scripts/gcp-set-cloud-run-env.sh

# Vérifier le déploiement
./scripts/gcp-verify-cloud-run.sh
```

### Documentation
- `GCP_SETUP_ETAPE4.md` - Guide complet de déploiement Cloud Run
- `GCP_DEPLOYMENT_QUICK_START.md` - Démarrage rapide

---

## 🗺️ Étape 4 : Les Services Clés (Géolocalisation & Notifications)

### Objectif Principal
Intégrer la cartographie, l'itinéraire et le système de communication instantanée pour une expérience utilisateur optimale.

### Services GCP Clés
- **Google Maps Platform APIs** - Routes API pour calculer les itinéraires et distances
- **Firebase Cloud Messaging (FCM)** - Notifications push pour les conducteurs et clients

### Rôle de Cursor
- ✅ Écrire le code de l'**API de tarification** qui appelle l'API Maps :
  - Calcul de la distance réelle avec Google Maps Routes API
  - Calcul du temps de trajet
  - Application de la formule de tarification (Base + Kilométrage + Temps)
  - Gestion des multiplicateurs (heure de pointe, nuit, week-end)
  - Gestion du surge pricing (pricing dynamique)
- ✅ Écrire le code pour l'**envoi de notifications via FCM** :
  - Notifications aux conducteurs disponibles pour une course
  - Notifications aux clients pour le statut de leur course
  - Notifications de rappel et d'alerte

### Services Implémentés
- `GoogleMapsService.js` - Service pour Google Maps Routes API
- `PricingService.js` - Service de tarification dynamique
- `DriverMatchingService.js` - Service de matching de conducteurs
- `notifications.js` - Service de notifications FCM

### Fichiers Générés
- `backend/services/GoogleMapsService.js` - Intégration Google Maps Routes API
- `backend/services/PricingService.js` - Calcul de tarification dynamique
- `backend/services/DriverMatchingService.js` - Algorithme de matching
- `backend/utils/notifications.js` - Envoi de notifications FCM
- `backend/services/BackendAgentPrincipal.js` - Orchestrateur principal

### Commandes Clés
```bash
# Activer les APIs Google Maps
gcloud services enable routes.googleapis.com
gcloud services enable places.googleapis.com
gcloud services enable geocoding.googleapis.com

# Configurer la clé API Google Maps
gcloud secrets create google-maps-api-key --data-file=-
```

### Documentation
- `backend/ALGORITHME_MATCHING_TARIFICATION.md` - Algorithme de matching et tarification
- `CONFIGURATION_GOOGLE_MAPS.md` - Configuration Google Maps

---

## 📊 Étape 5 : L'Opérabilité et la Mise en Service (Monitoring)

### Objectif Principal
Mettre en place la surveillance et les outils d'administration pour la gestion quotidienne de Kinshasa.

### Services GCP Clés
- **Cloud Logging** - Centralisation des logs d'application
- **Cloud Monitoring** - Métriques et alertes pour la surveillance
- **Cloud Alerting** - Notifications en cas d'incidents

### Rôle de Cursor
- ✅ Intégrer les **librairies de logging** dans votre code backend :
  - `@google-cloud/logging` - Envoi des logs à Cloud Logging
  - Winston - Logging structuré local
- ✅ Définir les **métriques de surveillance** :
  - Latence de l'API (p50, p95, p99)
  - Taux d'erreurs HTTP (4xx, 5xx)
  - Nombre de requêtes par seconde
  - Utilisation CPU et mémoire
  - Taux d'erreurs de paiement
  - Taux d'erreurs de matching
  - Nombre de courses créées/complétées
- ✅ Créer les **alertes** pour les incidents critiques
- ✅ Configurer les **tableaux de bord** pour visualiser les métriques

### Services Implémentés
- `cloud-logging.js` - Service de logging Cloud Logging
- `cloud-monitoring.js` - Service de monitoring Cloud Monitoring
- `monitoring.js` - Middleware de monitoring pour les requêtes API

### Fichiers Générés
- `backend/utils/cloud-logging.js` - Service Cloud Logging
- `backend/utils/cloud-monitoring.js` - Service Cloud Monitoring
- `backend/middlewares.postgres/monitoring.js` - Middleware de monitoring
- `scripts/gcp-setup-monitoring.sh` - Script de configuration du monitoring
- `scripts/gcp-create-alerts.sh` - Script de création des alertes
- `scripts/gcp-create-dashboard.sh` - Script de création des tableaux de bord

### Métriques Surveillées
- **Latence API** : Temps de réponse des endpoints (objectif: < 500ms p95)
- **Taux d'erreurs** : Pourcentage d'erreurs HTTP 5xx (objectif: < 1%)
- **Utilisation ressources** : CPU et mémoire Cloud Run (objectif: < 80%)
- **Utilisation base de données** : CPU et mémoire Cloud SQL (objectif: < 80%)
- **Erreurs de paiement** : Nombre d'erreurs de paiement (objectif: < 10/jour)
- **Erreurs de matching** : Nombre d'erreurs de matching (objectif: < 10/jour)
- **Courses** : Nombre de courses créées/complétées par jour

### Commandes Clés
```bash
# Configurer le monitoring
./scripts/gcp-setup-monitoring.sh

# Créer les alertes
./scripts/gcp-create-alerts.sh

# Créer les tableaux de bord
./scripts/gcp-create-dashboard.sh
```

### Documentation
- `GCP_SETUP_ETAPE5.md` - Guide complet de configuration du monitoring
- `backend/MONITORING_INTEGRATION.md` - Intégration du monitoring
- `GCP_MONITORING_DASHBOARD.md` - Configuration des tableaux de bord

---

## 🎯 Checklist de Déploiement

### Étape 1 : Base de Données
- [ ] Instance Cloud SQL créée
- [ ] Extension PostGIS activée
- [ ] Tables créées (Users, Drivers, Rides)
- [ ] Index créés
- [ ] Migrations exécutées
- [ ] Connexion testée depuis Cloud Run

### Étape 2 : Redis
- [ ] Instance Memorystore créée
- [ ] VPC Connector configuré
- [ ] Service Redis implémenté
- [ ] Routes de localisation créées
- [ ] Test d'écriture (HSET) réussi
- [ ] Test de lecture (HGETALL) réussi

### Étape 3 : Déploiement Backend
- [ ] Dockerfile créé
- [ ] Image Docker buildée
- [ ] Image poussée vers Artifact Registry
- [ ] Service Cloud Run créé
- [ ] Variables d'environnement configurées
- [ ] Permissions IAM configurées
- [ ] Health check fonctionnel
- [ ] API testée

### Étape 4 : Services Clés
- [ ] Google Maps API activée
- [ ] Clé API configurée
- [ ] Service Google Maps implémenté
- [ ] Service de tarification implémenté
- [ ] Service de matching implémenté
- [ ] Firebase configuré
- [ ] Notifications FCM fonctionnelles
- [ ] Test de création de course réussi

### Étape 5 : Monitoring
- [ ] Cloud Logging configuré
- [ ] Cloud Monitoring configuré
- [ ] Métriques enregistrées
- [ ] Alertes créées
- [ ] Tableaux de bord créés
- [ ] Notifications d'alertes configurées
- [ ] Tests de monitoring réussis

---

## 🚀 Guide de Démarrage Rapide

### 1. Initialiser GCP
```bash
# Activer les APIs nécessaires
gcloud services enable run.googleapis.com
gcloud services enable sqladmin.googleapis.com
gcloud services enable redis.googleapis.com
gcloud services enable routes.googleapis.com
gcloud services enable logging.googleapis.com
gcloud services enable monitoring.googleapis.com
```

### 2. Créer les Ressources
```bash
# Étape 1: Cloud SQL
./scripts/gcp-create-cloud-sql.sh
./scripts/gcp-init-database.sh

# Étape 2: Redis
./scripts/gcp-create-redis.sh

# Étape 3: Déployer le backend
./scripts/gcp-deploy-backend.sh
./scripts/gcp-set-cloud-run-env.sh

# Étape 4: Configurer Google Maps (manuel)
# - Activer les APIs Google Maps
# - Créer une clé API
# - Configurer les restrictions

# Étape 5: Configurer le monitoring
./scripts/gcp-setup-monitoring.sh
./scripts/gcp-create-alerts.sh
```

### 3. Vérifier le Déploiement
```bash
# Vérifier Cloud Run
./scripts/gcp-verify-cloud-run.sh

# Tester l'API
curl https://tshiakani-vtc-backend-xxxxx.run.app/health

# Vérifier les logs
gcloud logging read "resource.type=cloud_run_revision" --limit 10

# Vérifier les métriques
gcloud monitoring time-series list --limit 10
```

---

## 📚 Documentation Complète

### Guides par Étape
- `GCP_SETUP_ETAPE1.md` - Initialisation GCP
- `GCP_SETUP_ETAPE2.md` - Cloud SQL (Base de données)
- `GCP_SETUP_ETAPE3.md` - Memorystore (Redis)
- `GCP_SETUP_ETAPE4.md` - Cloud Run (Déploiement)
- `GCP_SETUP_ETAPE5.md` - Monitoring (Observabilité)

### Guides Techniques
- `backend/ALGORITHME_MATCHING_TARIFICATION.md` - Algorithme de matching
- `backend/MONITORING_INTEGRATION.md` - Intégration monitoring
- `backend/REDIS_STRUCTURE.md` - Structure Redis
- `backend/DATABASE_SCHEMA.md` - Schéma de base de données

### Guides de Déploiement
- `GCP_DEPLOYMENT_QUICK_START.md` - Démarrage rapide
- `PROCHAINES_ETAPES.md` - Prochaines étapes
- `ROADMAP_COMPLET.md` - Roadmap complète

---

## 🎉 Résumé

### Ce qui a été fait
- ✅ **Étape 1** : Cloud SQL configuré avec tables et index
- ✅ **Étape 2** : Memorystore Redis configuré pour le temps réel
- ✅ **Étape 3** : Backend déployé sur Cloud Run
- ✅ **Étape 4** : Google Maps et FCM intégrés
- ✅ **Étape 5** : Monitoring et observabilité configurés

### Prochaines Étapes
- ⏳ Tests end-to-end
- ⏳ Déploiement du dashboard admin
- ⏳ Configuration des applications iOS
- ⏳ Optimisations de performance
- ⏳ Lancement en production

---

**Date de création**: 2025-01-15  
**Version**: 1.0.0  
**Statut**: Documentation complète des 5 étapes de déploiement

