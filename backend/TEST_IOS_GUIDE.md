# Guide de Test avec l'Application iOS

## Prérequis

1. **Backend démarré** sur `http://localhost:3000` (pour tests locaux)
2. **Application iOS** ouverte dans Xcode
3. **Simulateur iOS** ou **appareil réel** configuré
4. **Compte utilisateur** valide (ou créer un compte via l'app)

## Configuration de l'Application iOS

### 1. Configuration pour Tests Locaux (Simulateur)

L'application iOS est déjà configurée pour utiliser `http://localhost:3000` en mode DEBUG sur le simulateur.

**Vérification** : Dans `ConfigurationService.swift`, l'URL par défaut est :
```swift
#if targetEnvironment(simulator)
return "http://localhost:3000/api"
#endif
```

### 2. Configuration pour Tests Locaux (Appareil Réel)

Pour tester sur un appareil réel avec le backend local :

1. **Trouver l'IP locale de votre Mac** :
   ```bash
   ifconfig | grep "inet " | grep -v 127.0.0.1
   ```

2. **Configurer l'URL dans l'application iOS** :
   ```swift
   // Dans ConfigurationService.swift ou via UserDefaults
   UserDefaults.standard.set("http://192.168.1.X:3000/api", forKey: "api_base_url_device")
   ```

3. **Démarrer le backend** sur toutes les interfaces :
   ```bash
   cd backend
   HOST=0.0.0.0 npm run dev
   ```

### 3. Configuration pour Production

L'application iOS est déjà configurée pour utiliser l'URL Cloud Run en production :
```swift
let productionURL = "https://tshiakani-vtc-backend-418102154417.us-central1.run.app/api"
```

## Tests avec l'Application iOS

### 1. Authentification

#### Test de Connexion
1. Ouvrir l'application iOS
2. Aller à l'écran de connexion
3. Entrer un numéro de téléphone (ex: `+243900000001`)
4. Entrer un rôle (ex: `client`)
5. Appuyer sur "Se connecter"
6. Vérifier que le token JWT est reçu et stocké

**Vérification** : Vérifier dans les logs Xcode :
```
🌐 APIService POST: http://localhost:3000/api/auth/signin
✅ APIService: Requête réussie
🔑 Token JWT stocké
```

#### Test de Vérification du Token
1. Après connexion, vérifier que le token est valide
2. Vérifier que l'utilisateur est connecté

### 2. Support

#### Test des Messages de Support
1. Aller à l'écran "Support"
2. Envoyer un message de support
3. Vérifier que le message est envoyé et affiché

**Vérification** : Vérifier dans les logs Xcode :
```
🌐 APIService POST: http://localhost:3000/api/support/message
✅ APIService: Requête réussie
```

#### Test des Tickets de Support
1. Aller à l'écran "Support"
2. Créer un ticket de support
3. Vérifier que le ticket est créé et affiché

#### Test de la FAQ
1. Aller à l'écran "FAQ" ou "Aide"
2. Vérifier que la FAQ est chargée depuis le backend
3. Vérifier que les questions sont affichées

**Vérification** : Vérifier dans les logs Xcode :
```
🌐 APIService GET: http://localhost:3000/api/support/faq
✅ APIService: Requête réussie
```

### 3. Favorites

#### Test d'Ajout de Favori
1. Aller à l'écran "Favorites" ou "Adresses favorites"
2. Ajouter une adresse favorite
3. Vérifier que l'adresse est ajoutée et affichée

**Vérification** : Vérifier dans les logs Xcode :
```
🌐 APIService POST: http://localhost:3000/api/favorites
✅ APIService: Requête réussie
```

#### Test de Suppression de Favori
1. Aller à l'écran "Favorites"
2. Supprimer une adresse favorite
3. Vérifier que l'adresse est supprimée

**Vérification** : Vérifier dans les logs Xcode :
```
🌐 APIService DELETE: http://localhost:3000/api/favorites/1
✅ APIService: Requête réussie
```

#### Test de Récupération des Favoris
1. Aller à l'écran "Favorites"
2. Vérifier que les favoris sont chargés depuis le backend
3. Vérifier que les favoris sont affichés

### 4. Chat

#### Test d'Envoi de Message
1. Créer une course (nécessaire pour avoir un `rideId`)
2. Aller à l'écran "Chat" de la course
3. Envoyer un message
4. Vérifier que le message est envoyé et affiché

**Vérification** : Vérifier dans les logs Xcode :
```
🌐 APIService POST: http://localhost:3000/api/chat/1/messages
✅ APIService: Requête réussie
```

#### Test de Réception de Message
1. Aller à l'écran "Chat" d'une course active
2. Vérifier que les messages sont chargés depuis le backend
3. Vérifier que les messages sont affichés

**Note** : Les messages sont également reçus en temps réel via Socket.io

#### Test de Marquer comme Lu
1. Aller à l'écran "Chat"
2. Ouvrir un message non lu
3. Vérifier que le message est marqué comme lu

### 5. Scheduled Rides

#### Test de Création de Course Programmée
1. Aller à l'écran "Scheduled Rides" ou "Courses programmées"
2. Créer une course programmée
3. Vérifier que la course est créée et affichée

**Vérification** : Vérifier dans les logs Xcode :
```
🌐 APIService POST: http://localhost:3000/api/scheduled-rides
✅ APIService: Requête réussie
```

#### Test de Mise à Jour de Course Programmée
1. Aller à l'écran "Scheduled Rides"
2. Modifier une course programmée
3. Vérifier que la course est mise à jour

#### Test d'Annulation de Course Programmée
1. Aller à l'écran "Scheduled Rides"
2. Annuler une course programmée
3. Vérifier que la course est annulée

### 6. Share

#### Test de Génération de Lien de Partage
1. Aller à l'écran d'une course active
2. Appuyer sur "Partager"
3. Vérifier qu'un lien de partage est généré

**Vérification** : Vérifier dans les logs Xcode :
```
🌐 APIService GET: http://localhost:3000/api/rides/1/share
✅ APIService: Requête réussie
```

#### Test de Partage avec Contacts
1. Aller à l'écran "Partager"
2. Partager une course avec des contacts
3. Vérifier que la course est partagée

### 7. SOS

#### Test d'Activation d'Alerte SOS
1. Aller à l'écran "SOS" ou "Urgence"
2. Activer une alerte SOS
3. Vérifier que l'alerte est activée

**Vérification** : Vérifier dans les logs Xcode :
```
🌐 APIService POST: http://localhost:3000/api/sos/alert
✅ APIService: Requête réussie
```

#### Test de Désactivation d'Alerte SOS
1. Aller à l'écran "SOS"
2. Désactiver une alerte SOS active
3. Vérifier que l'alerte est désactivée

**Vérification** : Vérifier dans les logs Xcode :
```
🌐 APIService POST: http://localhost:3000/api/sos/deactivate
✅ APIService: Requête réussie
```

## Vérification des Logs

### Logs Xcode

Dans Xcode, ouvrir la console et vérifier les logs :

```
🌐 APIService POST: http://localhost:3000/api/...
🔑 APIService: Token JWT ajouté
✅ APIService: Requête réussie
```

### Logs Backend

Dans le terminal où le backend est démarré, vérifier les logs :

```
POST /api/support/message 201
GET /api/support/messages 200
POST /api/favorites 201
GET /api/favorites 200
```

## Problèmes Courants

### Erreur de Connexion

**Symptôme** : L'application ne se connecte pas au backend

**Solutions** :
1. Vérifier que le backend est démarré : `curl http://localhost:3000/health`
2. Vérifier l'URL dans `ConfigurationService.swift`
3. Vérifier les logs Xcode pour les erreurs de connexion
4. Vérifier les logs backend pour les erreurs

### Erreur 401 (Unauthorized)

**Symptôme** : Les endpoints protégés retournent 401

**Solutions** :
1. Vérifier que le token JWT est valide
2. Vérifier que le token est inclus dans le header `Authorization`
3. Vérifier que le token n'est pas expiré
4. Se reconnecter pour obtenir un nouveau token

### Erreur CORS

**Symptôme** : Erreur CORS dans les logs

**Solutions** :
1. Vérifier la configuration CORS dans `server.postgres.js`
2. Vérifier que l'origine de l'application iOS est autorisée
3. Vérifier les logs backend pour les erreurs CORS

### Erreur de Timeout

**Symptôme** : Les requêtes timeout

**Solutions** :
1. Vérifier que le backend répond rapidement
2. Augmenter le timeout dans `ConfigurationService.swift`
3. Vérifier la connexion réseau

## Checklist de Test

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

### Chat
- [ ] Envoi de message (nécessite une course active)
- [ ] Récupération des messages (nécessite une course active)
- [ ] Marquer un message comme lu
- [ ] Réception en temps réel via Socket.io

### Scheduled Rides
- [ ] Création de course programmée
- [ ] Mise à jour de course programmée
- [ ] Annulation de course programmée
- [ ] Récupération des courses programmées

### Share
- [ ] Génération de lien de partage (nécessite une course active)
- [ ] Partage avec contacts
- [ ] Partage de position en temps réel
- [ ] Récupération des courses partagées

### SOS
- [ ] Activation d'alerte SOS
- [ ] Désactivation d'alerte SOS

## Notes

- Tous les endpoints nécessitent une authentification JWT (sauf `/api/auth/signin` et `/api/support/faq`)
- Les tests de chat nécessitent une course active (`rideId` valide)
- Les tests de partage nécessitent une course active (`rideId` valide)
- Les tests SOS nécessitent des coordonnées GPS valides
- Les messages de chat sont persistés en base de données et émis via Socket.io
- L'application iOS utilise déjà l'URL Cloud Run en production

## Conclusion

L'application iOS est configurée pour se connecter au backend. Suivez les étapes ci-dessus pour tester toutes les fonctionnalités avec l'application iOS.

