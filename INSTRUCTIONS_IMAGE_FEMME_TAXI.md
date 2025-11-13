# 📸 Instructions : Ajouter l'Image de la Femme qui Commande son Taxi

## 🎯 Objectif
Remplacer le placeholder stylisé par une vraie image d'une femme noire souriante qui commande son taxi.

## 📋 Étapes pour Ajouter l'Image

### Option 1 : Via Xcode (Recommandé)

1. **Ouvrir Xcode**
   - Ouvrez le projet `Tshiakani VTC.xcodeproj`

2. **Naviguer vers Assets**
   - Dans le navigateur de projet, allez dans :
     ```
     Tshiakani VTC > Assets.xcassets > woman_taxi.imageset
     ```

3. **Ajouter les Images**
   - Glissez-déposez votre image dans le dossier `woman_taxi.imageset`
   - Nommez les fichiers :
     - `woman_taxi.png` (1x - 70x70 pixels)
     - `woman_taxi@2x.png` (2x - 140x140 pixels)
     - `woman_taxi@3x.png` (3x - 210x210 pixels)

4. **Vérifier le Contenu**
   - Le fichier `Contents.json` devrait être mis à jour automatiquement
   - Si ce n'est pas le cas, vérifiez que les noms de fichiers correspondent

### Option 2 : Via le Terminal

1. **Préparer les Images**
   - Créez 3 versions de votre image :
     - 70x70 pixels → `woman_taxi.png`
     - 140x140 pixels → `woman_taxi@2x.png`
     - 210x210 pixels → `woman_taxi@3x.png`

2. **Copier les Images**
   ```bash
   cd "/Users/admin/Documents/Tshiakani VTC"
   cp chemin/vers/votre/image_70x70.png "Tshiakani VTC/Assets.xcassets/woman_taxi.imageset/woman_taxi.png"
   cp chemin/vers/votre/image_140x140.png "Tshiakani VTC/Assets.xcassets/woman_taxi.imageset/woman_taxi@2x.png"
   cp chemin/vers/votre/image_210x210.png "Tshiakani VTC/Assets.xcassets/woman_taxi.imageset/woman_taxi@3x.png"
   ```

## 🎨 Spécifications de l'Image

### Contenu Recommandé
- **Personne** : Femme noire souriante et joyeuse
- **Contexte** : En train de commander un taxi (téléphone à la main ou visible)
- **Style** : Photo professionnelle, éclairage naturel, fond neutre ou flou
- **Expression** : Sourire authentique et chaleureux

### Dimensions
- **1x** : 70x70 pixels (minimum)
- **2x** : 140x140 pixels (recommandé pour Retina)
- **3x** : 210x210 pixels (pour iPhone avec écran haute résolution)

### Format
- **Format** : PNG avec transparence (recommandé) ou JPG
- **Qualité** : Haute résolution pour un rendu net
- **Aspect** : Carré (1:1) pour un meilleur rendu dans le cercle

## 🔄 Comportement Actuel

### Si l'Image Existe
- L'image personnalisée sera affichée automatiquement
- Format circulaire avec bordure orange
- Ombre pour la profondeur

### Si l'Image N'Existe Pas (Placeholder)
- Un avatar stylisé est affiché :
  - Visage avec teint foncé
  - Yeux souriants
  - Sourire large
  - Icône de téléphone (elle commande)
  - Icône de voiture (le taxi arrive)

## ✅ Vérification

Après avoir ajouté l'image :
1. Compilez le projet dans Xcode (⌘B)
2. Lancez l'application
3. L'image devrait apparaître dans le header de l'écran d'onboarding

## 📝 Notes

- L'image sera automatiquement redimensionnée pour s'adapter au cercle
- Le format circulaire est appliqué automatiquement
- La bordure orange et l'ombre sont ajoutées par le code
- Si vous changez l'image, nettoyez le build (⇧⌘K) puis recompilez

