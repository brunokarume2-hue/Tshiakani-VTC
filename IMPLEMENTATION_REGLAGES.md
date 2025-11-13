# Implémentation des fonctions de réglages

## Résumé

Toutes les fonctionnalités de l'écran de réglages ont été implémentées avec succès.

## Fonctionnalités implémentées

### 1. Service de gestion des préférences (`UserPreferencesService`)

- **Localisation** : Service centralisé pour gérer les préférences utilisateur
- **Langue** : Gestion du changement de langue (Français, Lingala, Swahili)
- **Notifications** : Préférence pour activer/désactiver les notifications
- **Localisation** : Préférence pour activer/désactiver la localisation
- **Persistance** : Utilise `UserDefaults` pour sauvegarder les préférences

### 2. Gestion des permissions

- **PermissionManager** : Intégration complète pour gérer les permissions iOS
- **Notifications** : Demande de permission avec redirection vers les paramètres système si nécessaire
- **Localisation** : Demande de permission avec redirection vers les paramètres système si nécessaire
- **Vérification automatique** : Les permissions sont vérifiées au chargement de l'écran

### 3. Changement de langue

- **Support multi-langues** : Français, Lingala, Swahili
- **Persistance** : La langue est sauvegardée dans `UserDefaults`
- **Intégration** : Utilise le système `Localizable` existant
- **Mise à jour automatique** : La langue est mise à jour immédiatement lors du changement

### 4. Version de l'application

- **Récupération automatique** : La version est récupérée depuis `Bundle.main.infoDictionary`
- **Format** : Affiche la version et le build number (ex: "1.0 (1)")

### 5. Édition du profil

- **Modification du nom** : L'utilisateur peut modifier son nom
- **Téléphone non modifiable** : Le numéro de téléphone ne peut pas être modifié (identifiant principal)
- **API intégrée** : Utilise la route `/auth/profile` pour mettre à jour le profil
- **Feedback utilisateur** : Affichage d'un message de succès après la mise à jour

### 6. Liens externes

- **Conditions d'utilisation** : Lien vers `https://tshiakanivtc.com/terms`
- **Politique de confidentialité** : Lien vers `https://tshiakanivtc.com/privacy`
- **Gestion d'erreur** : Vérification de la validité de l'URL avant ouverture

### 7. Déconnexion

- **Confirmation** : Affichage d'une alerte de confirmation avant déconnexion
- **Nettoyage complet** : Déconnexion dans `AuthViewModel` et `AuthManager`
- **Redirection** : Retour automatique à l'écran de connexion

## Fichiers créés/modifiés

### Nouveaux fichiers

1. **`Tshiakani VTC/Services/UserPreferencesService.swift`**
   - Service pour gérer les préférences utilisateur
   - Gestion de la langue, notifications, localisation

2. **`Tshiakani VTC/Views/Profile/EditProfileView.swift`**
   - Écran d'édition du profil utilisateur
   - Modification du nom
   - Affichage du téléphone (non modifiable)

### Fichiers modifiés

1. **`Tshiakani VTC/Views/Client/SettingsView.swift`**
   - Implémentation complète de toutes les fonctionnalités
   - Intégration de `PermissionManager` et `UserPreferencesService`
   - Gestion des toggles avec actions réelles
   - Alerts pour les permissions
   - Récupération de la version
   - Liens externes
   - Déconnexion avec confirmation

2. **`Tshiakani VTC/Services/APIService.swift`**
   - Ajout de la méthode `updateProfile(name:)` pour mettre à jour le profil

3. **`Tshiakani VTC/ViewModels/AuthViewModel.swift`**
   - Ajout de la méthode `updateProfile(name:)` pour mettre à jour le profil

## Utilisation

### Accès aux réglages

1. Ouvrir l'application
2. Aller dans "Profil"
3. Cliquer sur "Paramètres"

### Modifier le nom

1. Dans "Paramètres", section "Compte"
2. Cliquer sur "Nom"
3. Modifier le nom dans l'écran d'édition
4. Cliquer sur "Enregistrer"

### Changer la langue

1. Dans "Paramètres", section "Préférences"
2. Sélectionner la langue dans le picker
3. La langue est mise à jour immédiatement

### Activer/Désactiver les notifications

1. Dans "Paramètres", section "Préférences"
2. Basculer le toggle "Notifications"
3. Si la permission n'est pas accordée, une alerte s'affiche pour ouvrir les paramètres système

### Activer/Désactiver la localisation

1. Dans "Paramètres", section "Préférences"
2. Basculer le toggle "Localisation"
3. Si la permission n'est pas accordée, une alerte s'affiche pour ouvrir les paramètres système

### Déconnexion

1. Dans "Paramètres", section "Déconnexion"
2. Cliquer sur "Déconnexion"
3. Confirmer dans l'alerte
4. L'utilisateur est déconnecté et redirigé vers l'écran de connexion

## Notes techniques

### Permissions iOS

- Les permissions sont gérées via `PermissionManager`
- Si une permission est refusée, l'utilisateur est redirigé vers les paramètres système
- Les permissions sont vérifiées au chargement de l'écran

### Préférences utilisateur

- Les préférences sont sauvegardées dans `UserDefaults`
- Les clés utilisées :
  - `app_language` : Langue sélectionnée
  - `notifications_enabled` : État des notifications
  - `location_enabled` : État de la localisation

### API

- La route `/auth/profile` est utilisée pour mettre à jour le profil
- Seul le nom peut être modifié (le téléphone est l'identifiant principal)
- La méthode `updateProfile` dans `APIService` gère la communication avec le backend

## Prochaines étapes (optionnelles)

1. **Support de plus de langues** : Ajouter d'autres langues si nécessaire
2. **Thème sombre/clair** : Ajouter un toggle pour changer le thème
3. **Notifications push** : Implémenter les notifications push avec Firebase
4. **Export des données** : Ajouter une fonctionnalité pour exporter les données utilisateur
5. **Suppression du compte** : Ajouter une option pour supprimer le compte

## Tests

Pour tester les fonctionnalités :

1. **Changer la langue** : Vérifier que l'interface change de langue
2. **Modifier le nom** : Vérifier que le nom est mis à jour dans le profil
3. **Activer les notifications** : Vérifier que la permission est demandée
4. **Activer la localisation** : Vérifier que la permission est demandée
5. **Déconnexion** : Vérifier que l'utilisateur est déconnecté et redirigé

## Conclusion

Toutes les fonctionnalités de l'écran de réglages ont été implémentées avec succès. L'écran est maintenant pleinement fonctionnel et permet à l'utilisateur de :
- Modifier son profil
- Changer la langue
- Gérer les permissions (notifications, localisation)
- Accéder aux conditions d'utilisation et politique de confidentialité
- Se déconnecter

L'application est prête pour le lancement avec un écran de réglages complet et fonctionnel.

