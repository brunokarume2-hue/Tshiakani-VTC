# 📱 Guide : Compiler et Installer sur iPhone

## 🎯 Objectif

Compiler le projet et l'installer sur votre iPhone connecté.

## ⚙️ Prérequis

1. **Xcode installé** dans `/Applications/Xcode.app`
2. **iPhone connecté** via USB
3. **Compte développeur Apple** configuré dans Xcode

## 🔧 Étape 1 : Configurer Xcode (Si nécessaire)

Si vous voyez l'erreur `xcode-select: error: tool 'xcodebuild' requires Xcode` :

### Option A : Via Terminal (Recommandé)

```bash
# Configurer Xcode comme outil de développement
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer

# Accepter la licence Xcode
sudo xcodebuild -license accept
```

### Option B : Via Xcode

1. Ouvrez **Xcode**
2. Allez dans **Xcode** > **Settings** (ou **Preferences**)
3. Allez dans l'onglet **Locations**
4. Vérifiez que **Command Line Tools** pointe vers votre version de Xcode

## 📱 Étape 2 : Connecter votre iPhone

1. **Connectez votre iPhone** à votre Mac via USB
2. **Déverrouillez votre iPhone**
3. Si c'est la première fois, **faites confiance à cet ordinateur** sur votre iPhone
4. Dans Xcode, vous devriez voir votre iPhone dans la liste des destinations

## 🔨 Étape 3 : Compiler et Installer

### Méthode 1 : Via Xcode (Recommandé)

1. **Ouvrez le projet** dans Xcode :
   ```bash
   open "/Users/admin/Documents/Tshiakani VTC/Tshiakani VTC.xcodeproj"
   ```

2. **Sélectionnez votre iPhone** comme destination :
   - En haut de la fenêtre Xcode, cliquez sur le menu déroulant à côté du bouton Run
   - Sélectionnez votre iPhone dans la liste

3. **Configurez le compte développeur** (si nécessaire) :
   - Sélectionnez le projet "Tshiakani VTC" dans le Project Navigator
   - Sélectionnez le target "Tshiakani VTC"
   - Allez dans l'onglet **Signing & Capabilities**
   - Cochez **"Automatically manage signing"**
   - Sélectionnez votre **Team** (votre compte Apple)

4. **Nettoyez le build** :
   - **Product** > **Clean Build Folder** (⇧⌘K)

5. **Compilez et installez** :
   - Cliquez sur le bouton **Run** (▶️) ou appuyez sur **⌘R**
   - Xcode va compiler et installer l'app sur votre iPhone

### Méthode 2 : Via Terminal

```bash
cd "/Users/admin/Documents/Tshiakani VTC"
./compiler-et-installer.sh
```

## ⚠️ Résolution des Problèmes

### Erreur : "No signing certificate found"

**Solution** :
1. Ouvrez Xcode
2. Allez dans **Xcode** > **Settings** > **Accounts**
3. Ajoutez votre compte Apple ID
4. Dans le projet, allez dans **Signing & Capabilities**
5. Sélectionnez votre **Team**

### Erreur : "Untrusted Developer"

**Solution** :
1. Sur votre iPhone, allez dans **Settings** > **General** > **VPN & Device Management**
2. Trouvez votre profil développeur
3. Appuyez sur **Trust**

### Erreur : "Device not found"

**Solution** :
1. Vérifiez que votre iPhone est bien connecté via USB
2. Déverrouillez votre iPhone
3. Faites confiance à l'ordinateur sur votre iPhone
4. Dans Xcode, allez dans **Window** > **Devices and Simulators**
5. Vérifiez que votre iPhone apparaît

### Erreur : "Multiple commands produce Info.plist"

**Solution** : Déjà corrigé ! Si l'erreur persiste :
1. **Product** > **Clean Build Folder** (⇧⌘K)
2. Fermez Xcode
3. Supprimez le DerivedData :
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/Tshiakani_VTC-*
   ```
4. Rouvrez Xcode et recompilez

### Erreur : "Missing package product 'GoogleMaps'"

**Solution** :
1. Dans Xcode : **File** > **Packages** > **Reset Package Caches**
2. **File** > **Packages** > **Resolve Package Versions**
3. Attendez que les packages soient résolus
4. Recompilez

## ✅ Vérification

Une fois installé sur votre iPhone :

1. ✅ L'app **Tshiakani VTC** apparaît sur votre iPhone
2. ✅ Vous pouvez l'ouvrir
3. ✅ L'app se lance correctement

## 📝 Notes Importantes

- **Première installation** : Vous devrez faire confiance au développeur sur votre iPhone
- **Certificats** : Xcode gère automatiquement les certificats si "Automatically manage signing" est activé
- **Bundle ID** : Le Bundle ID est `com.bruno.tshiakaniVTC`
- **Team** : Utilisez votre compte Apple ID personnel (gratuit) pour le développement

## 🚀 Commandes Utiles

```bash
# Lister les appareils connectés
xcrun xctrace list devices

# Voir les erreurs de compilation
xcodebuild -project "Tshiakani VTC.xcodeproj" -scheme "Tshiakani VTC" build 2>&1 | grep error

# Nettoyer le build
xcodebuild -project "Tshiakani VTC.xcodeproj" -scheme "Tshiakani VTC" clean
```

---

**Date de création** : $(date)
**Statut** : Prêt pour compilation et installation

