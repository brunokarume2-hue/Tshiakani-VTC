# 📱 Guide : Mise à Jour des Certificats Apple

## 🎯 Objectif
Configurer les certificats et provisioning profiles pour le nouveau Bundle Identifier `com.bruno.tshiakaniVTC`.

## 📋 Étapes Détaillées

### 1. Créer un Nouvel App ID

1. Aller sur [developer.apple.com](https://developer.apple.com)
2. Se connecter avec votre compte développeur
3. Cliquer sur **"Certificates, Identifiers & Profiles"**
4. Dans le menu de gauche, cliquer sur **"Identifiers"**
5. Cliquer sur le bouton **"+"** en haut à droite
6. Sélectionner **"App IDs"** et cliquer sur **"Continue"**
7. Sélectionner **"App"** et cliquer sur **"Continue"**
8. Remplir les informations :
   - **Description** : `Tshiakani VTC`
   - **Bundle ID** : `com.bruno.tshiakaniVTC`
   - Cocher les **Capabilities** nécessaires :
     - ✅ Push Notifications
     - ✅ ✅ Location Services
     - ✅ ✅ Background Modes
9. Cliquer sur **"Continue"** puis **"Register"**

### 2. Créer un Certificat de Développement

1. Dans le menu de gauche, cliquer sur **"Certificates"**
2. Cliquer sur le bouton **"+"** en haut à droite
3. Sélectionner **"iOS App Development"** et cliquer sur **"Continue"**
4. Suivre les instructions pour créer une **Certificate Signing Request (CSR)** :
   - Ouvrir **Keychain Access** sur votre Mac
   - Menu : **Keychain Access > Certificate Assistant > Request a Certificate From a Certificate Authority**
   - Entrer votre email et nom
   - Sélectionner **"Save to disk"**
   - Télécharger le fichier `.certSigningRequest`
5. Uploader le fichier CSR sur le site Apple
6. Télécharger le certificat créé
7. Double-cliquer sur le certificat pour l'installer dans Keychain

### 3. Créer un Provisioning Profile

1. Dans le menu de gauche, cliquer sur **"Profiles"**
2. Cliquer sur le bouton **"+"** en haut à droite
3. Sélectionner **"iOS App Development"** et cliquer sur **"Continue"**
4. Sélectionner l'App ID : **`com.bruno.tshiakaniVTC`**
5. Sélectionner le certificat créé à l'étape 2
6. Sélectionner les appareils de test (si nécessaire)
7. Donner un nom au profile : **"Tshiakani VTC Development"**
8. Cliquer sur **"Generate"**
9. Télécharger le provisioning profile

### 4. Configurer dans Xcode

1. Ouvrir Xcode
2. Menu : **Xcode > Preferences > Accounts**
3. Sélectionner votre compte Apple Developer
4. Cliquer sur **"Download Manual Profiles"**
5. Fermer la fenêtre Preferences
6. Dans le projet, sélectionner le target **"Tshiakani VTC"**
7. Onglet **"Signing & Capabilities"**
8. Cocher **"Automatically manage signing"** OU
9. Sélectionner manuellement le **Team** et le **Provisioning Profile**

### 5. Vérifier la Configuration

1. Dans Xcode, sélectionner le projet
2. Target **"Tshiakani VTC"**
3. Onglet **"Signing & Capabilities"**
4. Vérifier :
   - ✅ **Team** : Votre équipe
   - ✅ **Bundle Identifier** : `com.bruno.tshiakaniVTC`
   - ✅ **Provisioning Profile** : Tshiakani VTC Development

## ⚠️ Notes Importantes

- Les certificats de développement sont valides **1 an**
- Les provisioning profiles doivent être mis à jour si vous ajoutez de nouveaux appareils
- Pour la production, créez un **Distribution Certificate** et un **App Store Provisioning Profile**

## 🔗 Liens Utiles

- [Apple Developer Portal](https://developer.apple.com)
- [Documentation Apple - Certificats](https://developer.apple.com/documentation/xcode/managing-your-team-s-signing-assets)

