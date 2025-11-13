# 🚀 Actions Immédiates - Configuration App Client

## ✅ Configuration Terminée

L'application client iOS est maintenant configurée pour se connecter au backend Cloud Run.

---

## 🎯 Actions à Effectuer MAINTENANT

### 1. Tester le Backend Cloud Run (5 minutes)

```bash
# Exécuter le script de test
./scripts/test-backend-cloud-run.sh
```

**Ce que le script vérifie**:
- ✅ Backend accessible
- ✅ Authentification fonctionnelle
- ✅ Routes API disponibles
- ✅ Estimation de prix fonctionnelle

**Si le test échoue**: Vérifier les logs et la configuration CORS.

---

### 2. Vérifier CORS sur Cloud Run (5 minutes)

```bash
# Vérifier la configuration CORS actuelle
gcloud run services describe tshiakani-driver-backend \
  --region us-central1 \
  --format "value(spec.template.spec.containers[0].env)" | grep CORS
```

**Si CORS n'est pas configuré**, le configurer :

```bash
# Option 1: Accepter toutes les origines (pour test)
gcloud run services update tshiakani-driver-backend \
  --region us-central1 \
  --update-env-vars "CORS_ORIGIN=*"

# Option 2: Origines spécifiques (recommandé pour production)
gcloud run services update tshiakani-driver-backend \
  --region us-central1 \
  --update-env-vars "CORS_ORIGIN=https://tshiakani-vtc.firebaseapp.com,https://tshiakani-vtc.web.app"
```

---

### 3. Tester l'Application iOS (15 minutes)

#### 3.1 Builder en Mode RELEASE

1. Ouvrir Xcode
2. Sélectionner le schéma **Release**
3. Builder l'application (⌘ + B)
4. Installer sur un appareil ou simulateur

#### 3.2 Tester les Fonctionnalités

1. **Authentification**
   - Se connecter avec un numéro de téléphone
   - Vérifier que le token JWT est reçu

2. **Création de Course**
   - Créer une course
   - Vérifier que la course est créée en base de données

3. **WebSockets**
   - Vérifier que la connexion WebSocket est établie
   - Vérifier que les événements sont reçus

4. **Suivi du Driver**
   - Si un driver accepte la course, vérifier le suivi

---

### 4. Vérifier les Logs (10 minutes)

#### 4.1 Logs du Backend

```bash
# Voir les logs en temps réel
gcloud run services logs tail tshiakani-driver-backend \
  --region us-central1

# Voir les logs récents
gcloud run services logs read tshiakani-driver-backend \
  --region us-central1 \
  --limit 50
```

#### 4.2 Logs de l'App iOS

Dans Xcode :
1. Ouvrir la console (⌘ + ⇧ + Y)
2. Filtrer les logs pour voir :
   - Connexions API
   - Erreurs de connexion
   - Erreurs WebSocket
   - Erreurs d'authentification

---

## 🔍 Vérifications Spécifiques

### Vérification 1: URLs Utilisées

Dans les logs de l'app iOS, vérifier que :
- ✅ API URL: `https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/api`
- ✅ WebSocket URL: `https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app`
- ✅ Namespace Client: `/ws/client`

### Vérification 2: Routes API

Tester manuellement les routes :

```bash
# Health check
curl https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/health

# Authentification
curl -X POST https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/api/auth/signin \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber": "+243900000001", "role": "client"}'
```

### Vérification 3: WebSocket

Vérifier que Socket.io est configuré sur le backend et que les namespaces sont disponibles :
- `/ws/client` - Pour les clients
- `/ws/driver` - Pour les drivers

---

## 🛠️ Dépannage Rapide

### Problème: Backend non accessible

**Solution**:
```bash
# Vérifier que le service est déployé
gcloud run services list --region us-central1

# Vérifier les logs
gcloud run services logs read tshiakani-driver-backend --region us-central1 --limit 20
```

### Problème: Erreurs CORS

**Solution**:
```bash
# Mettre à jour CORS
gcloud run services update tshiakani-driver-backend \
  --region us-central1 \
  --update-env-vars "CORS_ORIGIN=*"
```

### Problème: WebSocket ne se connecte pas

**Solution**:
1. Vérifier que l'URL WebSocket utilise `https://` (pas `wss://`)
2. Vérifier que Socket.io est configuré sur le backend
3. Vérifier les logs du backend pour les erreurs

### Problème: Routes API non trouvées (404)

**Solution**:
1. Vérifier que l'URL API se termine par `/api` (pas `/api/v1`)
2. Vérifier que les routes sont montées correctement dans `server.postgres.js`

---

## 📊 Checklist Complète

### Configuration
- [x] Info.plist configuré avec les bonnes URLs
- [x] ConfigurationService.swift corrigé
- [x] URLs cohérentes entre Info.plist et ConfigurationService.swift
- [x] Namespace WebSocket client ajouté

### Backend
- [ ] Backend testé (script de test)
- [ ] CORS vérifié et configuré
- [ ] Routes API vérifiées
- [ ] WebSocket vérifié

### Application iOS
- [ ] App testée en mode RELEASE
- [ ] Authentification testée
- [ ] Création de course testée
- [ ] WebSockets testés
- [ ] Suivi du driver testé

### Monitoring
- [ ] Logs du backend vérifiés
- [ ] Logs de l'app iOS vérifiés
- [ ] Erreurs identifiées et corrigées

---

## 🎯 Prochaines Étapes Après Tests

Une fois les tests réussis :

1. **Déployer en Production**
   - Configurer CORS avec des origines spécifiques
   - Vérifier la sécurité
   - Monitorer les performances

2. **Optimisations**
   - Optimiser les requêtes API
   - Améliorer la gestion des erreurs
   - Ajouter du caching si nécessaire

3. **Monitoring**
   - Configurer les alertes
   - Monitorer les performances
   - Surveiller les erreurs

---

## 📚 Ressources

- [Prochaines Étapes Détaillées](./PROCHAINES_ETAPES_CONFIGURATION.md)
- [Configuration Client Cloud Run](./CONFIGURATION_CLIENT_CLOUD_RUN.md)
- [Guide de Configuration](./GUIDE_CONFIGURATION_CLIENT_GCLOUD.md)
- [Script de Test](./scripts/test-backend-cloud-run.sh)

---

## ✅ Résumé

**Configuration**: ✅ Terminée  
**Tests**: ⚠️ À effectuer  
**Déploiement**: ✅ Backend déployé  
**Statut**: 🚀 Prêt pour tests

**Actions immédiates**:
1. Tester le backend (5 min)
2. Vérifier CORS (5 min)
3. Tester l'app iOS (15 min)
4. Vérifier les logs (10 min)

**Total estimé**: ~35 minutes

---

**Date**: $(date)  
**Prochaine étape**: Exécuter `./scripts/test-backend-cloud-run.sh`

