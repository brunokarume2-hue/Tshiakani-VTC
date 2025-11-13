# 🎨 Guide : Configuration de l'AppIcon avec le Logo Tshiakani VTC

## 📋 Méthode 1 : Utilisation Automatique (Recommandée)

### Étape 1 : Préparer votre Logo
1. Assurez-vous que votre logo est en format **PNG** (recommandé) ou **JPG**
2. L'image doit faire **1024x1024 pixels** (carré)
3. Fond transparent recommandé pour un meilleur rendu

### Étape 2 : Exécuter le Script
```bash
cd "/Users/admin/Documents/wewa taxi"
./SCRIPT_GENERER_APPICON.sh chemin/vers/votre/logo_1024x1024.png
```

**Exemple** :
```bash
./SCRIPT_GENERER_APPICON.sh ~/Downloads/logo_tshiakani_1024x1024.png
```

Le script va :
- ✅ Générer automatiquement toutes les tailles d'icônes nécessaires (20x20 à 1024x1024)
- ✅ Mettre à jour le fichier `Contents.json`
- ✅ Placer toutes les icônes dans le bon dossier

---

## 📋 Méthode 2 : Configuration Manuelle dans Xcode

### Étape 1 : Préparer votre Logo
1. Créez une image **1024x1024 pixels** de votre logo
2. Format PNG recommandé

### Étape 2 : Dans Xcode
1. Ouvrez le projet dans Xcode
2. Dans le navigateur de projet, ouvrez :
   ```
   Tshiakani VTC > Assets.xcassets > AppIcon
   ```
3. Glissez-déposez votre image **1024x1024** dans l'emplacement "App Store" (1024x1024)
4. Xcode générera automatiquement toutes les autres tailles

---

## 📋 Méthode 3 : Configuration Minimale (iOS 11+)

Depuis iOS 11, Apple accepte une seule icône 1024x1024 qui sera automatiquement redimensionnée.

### Configuration Simple
1. Remplacez le fichier existant dans `Tshiakani VTC/Assets.xcassets/AppIcon.appiconset/`
2. Nommez-le `AppIcon-1024x1024.png`
3. Mettez à jour `Contents.json` :

```json
{
  "images" : [
    {
      "filename" : "AppIcon-1024x1024.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

---

## 🎨 Spécifications du Logo Tshiakani VTC

D'après la description du logo :
- **Couleurs principales** :
  - Bleu foncé : #1A2B4D (voiture et texte "Tshiakani")
  - Orange : #F28C28 (flèche et texte "VTC")
- **Éléments** :
  - Silhouette de voiture (bleu foncé)
  - Flèche courbe vers le haut (orange)
  - Texte "Tshiakani" (bleu foncé)
  - Texte "VTC" (orange)

### Recommandations pour l'AppIcon
- ✅ Utiliser un fond blanc ou transparent
- ✅ S'assurer que le logo est bien centré
- ✅ Vérifier la lisibilité à petite taille (20x20)
- ✅ Tester sur différents fonds (clair/sombre)

---

## ✅ Vérification

Après avoir configuré l'AppIcon :

1. **Dans Xcode** :
   - Ouvrez `Assets.xcassets > AppIcon`
   - Vérifiez que toutes les tailles sont remplies

2. **Compiler** :
   ```bash
   # Dans Xcode : Product > Build (⌘B)
   ```

3. **Tester sur un appareil** :
   - Installez l'app sur un iPhone/iPad
   - Vérifiez que l'icône s'affiche correctement sur l'écran d'accueil

---

## 🐛 Problèmes Courants

### L'icône ne s'affiche pas
- ✅ Vérifier que l'image fait bien 1024x1024 pixels
- ✅ Vérifier le format (PNG recommandé)
- ✅ Nettoyer le build : Product > Clean Build Folder (⇧⌘K)

### L'icône est floue
- ✅ Utiliser une image vectorielle ou haute résolution
- ✅ Éviter les images redimensionnées depuis une petite taille

### Erreur "Missing App Icon"
- ✅ Vérifier que toutes les tailles requises sont présentes
- ✅ Utiliser le script automatique pour générer toutes les tailles

---

## 📚 Ressources

- [Apple Human Interface Guidelines - App Icons](https://developer.apple.com/design/human-interface-guidelines/app-icons)
- [App Icon Generator](https://www.appicon.co/) - Outil en ligne pour générer toutes les tailles

---

**Note** : Le script `SCRIPT_GENERER_APPICON.sh` utilise la commande `sips` (macOS) pour redimensionner automatiquement votre logo. Si vous n'avez pas macOS ou si `sips` n'est pas disponible, utilisez la méthode 2 (manuelle dans Xcode).

