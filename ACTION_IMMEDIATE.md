# Action Immédiate - Tester avec l'Application iOS

## 🎯 Objectif
Tester l'application iOS avec le backend local pour valider toutes les fonctionnalités intégrées.

## ✅ Prérequis Vérifiés

- [x] Backend opérationnel sur `http://localhost:3000`
- [x] Base de données PostgreSQL connectée
- [x] Redis connecté
- [x] Toutes les routes backend créées
- [x] Tous les endpoints APIService implémentés
- [x] Tous les ViewModels connectés

## 🚀 Actions Immédiates

### Étape 1: Vérifier le Backend (2 minutes)

```bash
# Vérifier que le backend fonctionne
curl http://localhost:3000/health

# Réponse attendue:
# {
#   "status": "OK",
#   "database": "connected",
#   "redis": "connected"
# }
```

**Si le backend ne fonctionne pas :**
```bash
cd backend
npm run dev
```

### Étape 2: Ouvrir l'Application iOS (1 minute)

1. Ouvrir Xcode
2. Ouvrir le projet `Tshiakani VTC.xcodeproj`
3. Sélectionner un simulateur iOS (ex: iPhone 15 Pro)
4. Cliquer sur "Run" (⌘R)

### Étape 3: Tester l'Authentification (3 minutes)

1. Dans l'application iOS, aller à l'écran de connexion
2. Entrer un numéro de téléphone : `+243900000001`
3. Entrer un rôle : `client`
4. Appuyer sur "Se connecter"
5. Vérifier dans les logs Xcode que la connexion réussit :
   ```
   🌐 APIService POST: http://localhost:3000/api/auth/signin
   ✅ APIService: Requête réussie
   🔑 Token JWT stocké
   ```

### Étape 4: Tester le Support (5 minutes)

1. Aller à l'écran "Support" ou "Aide"
2. Envoyer un message de support :
   - Taper un message
   - Appuyer sur "Envoyer"
   - Vérifier que le message apparaît
3. Vérifier la FAQ :
   - Aller à l'écran "FAQ"
   - Vérifier que les questions sont affichées
4. Créer un ticket de support :
   - Aller à l'écran "Tickets"
   - Créer un nouveau ticket
   - Vérifier que le ticket est créé

**Vérification dans les logs Xcode :**
```
🌐 APIService POST: http://localhost:3000/api/support/message
✅ APIService: Requête réussie
🌐 APIService GET: http://localhost:3000/api/support/faq
✅ APIService: Requête réussie
```

### Étape 5: Tester les Favorites (5 minutes)

1. Aller à l'écran "Favorites" ou "Adresses favorites"
2. Ajouter une adresse favorite :
   - Appuyer sur "Ajouter"
   - Entrer un nom : "Maison"
   - Entrer une adresse : "123 Rue Example, Kinshasa"
   - Sélectionner une icône : "home"
   - Appuyer sur "Enregistrer"
   - Vérifier que l'adresse apparaît
3. Supprimer une adresse favorite :
   - Swiper sur une adresse
   - Appuyer sur "Supprimer"
   - Vérifier que l'adresse disparaît

**Vérification dans les logs Xcode :**
```
🌐 APIService POST: http://localhost:3000/api/favorites
✅ APIService: Requête réussie
🌐 APIService DELETE: http://localhost:3000/api/favorites/1
✅ APIService: Requête réussie
```

### Étape 6: Tester les Scheduled Rides (5 minutes)

1. Aller à l'écran "Scheduled Rides" ou "Courses programmées"
2. Créer une course programmée :
   - Appuyer sur "Nouvelle course"
   - Sélectionner un point de départ
   - Sélectionner une destination
   - Sélectionner une date et une heure
   - Sélectionner un type de véhicule
   - Appuyer sur "Programmer"
   - Vérifier que la course apparaît
3. Modifier une course programmée :
   - Appuyer sur une course
   - Modifier les détails
   - Appuyer sur "Enregistrer"
   - Vérifier que la course est mise à jour

**Vérification dans les logs Xcode :**
```
🌐 APIService POST: http://localhost:3000/api/scheduled-rides
✅ APIService: Requête réussie
🌐 APIService PUT: http://localhost:3000/api/scheduled-rides/1
✅ APIService: Requête réussie
```

### Étape 7: Tester le Chat (5 minutes)

**Note :** Le chat nécessite une course active. Créer d'abord une course.

1. Créer une course (ou utiliser une course existante)
2. Aller à l'écran "Chat" de la course
3. Envoyer un message :
   - Taper un message
   - Appuyer sur "Envoyer"
   - Vérifier que le message apparaît
4. Vérifier la réception en temps réel :
   - Ouvrir le chat dans deux appareils différents
   - Envoyer un message depuis un appareil
   - Vérifier que le message apparaît sur l'autre appareil

**Vérification dans les logs Xcode :**
```
🌐 APIService POST: http://localhost:3000/api/chat/1/messages
✅ APIService: Requête réussie
🌐 Socket.io: chat:message reçu
```

### Étape 8: Tester le Share (3 minutes)

**Note :** Le partage nécessite une course active. Créer d'abord une course.

1. Aller à l'écran d'une course active
2. Appuyer sur "Partager"
3. Générer un lien de partage :
   - Appuyer sur "Générer un lien"
   - Vérifier qu'un lien est généré
4. Partager avec des contacts :
   - Sélectionner des contacts
   - Appuyer sur "Partager"
   - Vérifier que la course est partagée

**Vérification dans les logs Xcode :**
```
🌐 APIService GET: http://localhost:3000/api/rides/1/share
✅ APIService: Requête réussie
🌐 APIService POST: http://localhost:3000/api/share/ride
✅ APIService: Requête réussie
```

### Étape 9: Tester le SOS (3 minutes)

1. Aller à l'écran "SOS" ou "Urgence"
2. Activer une alerte SOS :
   - Appuyer sur "Activer l'alerte SOS"
   - Vérifier que l'alerte est activée
3. Désactiver une alerte SOS :
   - Appuyer sur "Désactiver l'alerte SOS"
   - Vérifier que l'alerte est désactivée

**Vérification dans les logs Xcode :**
```
🌐 APIService POST: http://localhost:3000/api/sos/alert
✅ APIService: Requête réussie
🌐 APIService POST: http://localhost:3000/api/sos/deactivate
✅ APIService: Requête réussie
```

## 🔍 Vérification des Logs

### Logs Xcode
Ouvrir la console Xcode et vérifier :
- ✅ Requêtes API réussies : `✅ APIService: Requête réussie`
- ❌ Erreurs : `❌ APIService: Erreur ...`
- 🔑 Authentification : `🔑 Token JWT stocké`
- 🌐 Requêtes : `🌐 APIService POST/GET: ...`

### Logs Backend
Dans le terminal où le backend est démarré, vérifier :
- ✅ Requêtes réussies : `POST /api/support/message 201`
- ❌ Erreurs : `ERROR: ...`
- 🔐 Authentification : `Authenticated user: ...`

## 🐛 Problèmes Courants et Solutions

### Problème 1: Erreur de Connexion iOS

**Symptôme :** L'application iOS ne se connecte pas au backend

**Solution :**
1. Vérifier que le backend fonctionne : `curl http://localhost:3000/health`
2. Vérifier l'URL dans `ConfigurationService.swift` :
   ```swift
   // Pour le simulateur, devrait être:
   return "http://localhost:3000/api"
   ```
3. Vérifier que le simulateur utilise `localhost` (pas `127.0.0.1`)

### Problème 2: Erreur 401 (Unauthorized)

**Symptôme :** Les endpoints retournent 401

**Solution :**
1. Vérifier que le token JWT est stocké : `UserDefaults.standard.string(forKey: "auth_token")`
2. Vérifier que le token est inclus dans les requêtes :
   ```
   🔑 APIService: Token JWT ajouté
   ```
3. Se reconnecter pour obtenir un nouveau token

### Problème 3: Erreur CORS

**Symptôme :** Erreur CORS dans les logs backend

**Solution :**
1. Vérifier la configuration CORS dans `server.postgres.js`
2. Vérifier que l'origine de l'application iOS est autorisée
3. Vérifier les logs backend pour les erreurs CORS

### Problème 4: Erreur de Timeout

**Symptôme :** Les requêtes timeout

**Solution :**
1. Vérifier que le backend répond rapidement
2. Augmenter le timeout dans `ConfigurationService.swift`
3. Vérifier la connexion réseau

### Problème 5: Chat ne fonctionne pas

**Symptôme :** Les messages ne sont pas reçus en temps réel

**Solution :**
1. Vérifier que Socket.io est connecté :
   ```
   🌐 Socket.io: Connecté
   ```
2. Vérifier que le backend émet les messages via Socket.io
3. Vérifier que l'application iOS écoute les événements Socket.io

## ✅ Checklist de Validation

### Authentification
- [ ] Connexion réussie
- [ ] Token JWT stocké
- [ ] Vérification du token réussie
- [ ] Déconnexion réussie

### Support
- [ ] Envoi de message de support
- [ ] Récupération des messages de support
- [ ] Création de ticket de support
- [ ] Récupération des tickets de support
- [ ] Récupération de la FAQ

### Favorites
- [ ] Ajout d'adresse favorite
- [ ] Suppression d'adresse favorite
- [ ] Mise à jour d'adresse favorite
- [ ] Récupération des adresses favorites

### Scheduled Rides
- [ ] Création de course programmée
- [ ] Mise à jour de course programmée
- [ ] Annulation de course programmée
- [ ] Récupération des courses programmées

### Chat
- [ ] Envoi de message (nécessite une course active)
- [ ] Récupération des messages (nécessite une course active)
- [ ] Marquer un message comme lu
- [ ] Réception en temps réel via Socket.io

### Share
- [ ] Génération de lien de partage (nécessite une course active)
- [ ] Partage avec contacts
- [ ] Partage de position en temps réel
- [ ] Récupération des courses partagées

### SOS
- [ ] Activation d'alerte SOS
- [ ] Désactivation d'alerte SOS

## 📊 Résultats Attendus

### Backend
- Toutes les requêtes retournent des codes de statut 200/201
- Toutes les réponses JSON sont correctes
- Aucune erreur dans les logs

### iOS
- Toutes les fonctionnalités fonctionnent
- Toutes les requêtes API réussissent
- Toutes les données sont correctement affichées
- Aucune erreur dans les logs Xcode

## 🎯 Prochaines Étapes

Une fois tous les tests réussis :

1. **Documenter les problèmes rencontrés** (s'il y en a)
2. **Corriger les erreurs identifiées**
3. **Tester à nouveau les fonctionnalités corrigées**
4. **Déployer en production** (voir `backend/DEPLOYMENT_GUIDE.md`)

## 📚 Ressources

- **TEST_IOS_GUIDE.md** - Guide de test détaillé avec l'application iOS
- **DEPLOYMENT_GUIDE.md** - Guide de déploiement en production
- **IOS_CONFIGURATION.md** - Configuration iOS pour production
- **NEXT_STEPS_FINAL.md** - Checklist complète des prochaines étapes

## ✅ Conclusion

Suivez les étapes ci-dessus pour tester toutes les fonctionnalités avec l'application iOS. Si toutes les fonctionnalités fonctionnent correctement, vous pouvez procéder au déploiement en production.

**Temps estimé :** 30-40 minutes

**Priorité :** Haute

**Statut :** Prêt à tester
