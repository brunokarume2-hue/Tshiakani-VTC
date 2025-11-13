# Correction : Erreur "Multiple commands produce Info.plist"

## Modifications Appliquées

### 1. Build Settings dans project.pbxproj

Ajouté les build settings suivants pour les configurations Debug et Release du target principal :

- ✅ `EXCLUDED_SOURCE_FILE_NAMES = "Info.plist";` - Tente d'exclure Info.plist des fichiers source
- ✅ `GENERATE_INFOPLIST_FILE = NO;` - Désactive la génération automatique d'Info.plist
- ✅ `INFOPLIST_FILE = "Tshiakani VTC/Info.plist";` - Spécifie le fichier Info.plist à utiliser
- ✅ `INFOPLIST_PREPROCESS = NO;` - Désactive le préprocessing d'Info.plist

### 2. Nettoyage des Caches

Les caches ont été nettoyés :
- ✅ DerivedData supprimé
- ✅ ModuleCache supprimé
- ✅ Packages vérifiés (GoogleMaps et GooglePlaces présents)

## Problème Restant

Avec `PBXFileSystemSynchronizedRootGroup`, Xcode synchronise automatiquement tous les fichiers du dossier "Tshiakani VTC", ce qui peut inclure Info.plist dans les ressources même avec les build settings ci-dessus.

## Solution Manuelle dans Xcode (REQUIS)

### Étape 1 : Vérifier Copy Bundle Resources

1. **Ouvrir Xcode** et le projet `Tshiakani VTC.xcodeproj`
2. **Sélectionner le target "Tshiakani VTC"** dans la liste des targets
3. **Aller dans l'onglet "Build Phases"**
4. **Développer "Copy Bundle Resources"**
5. **Chercher "Info.plist" dans la liste**
6. **Si Info.plist est présent :**
   - Le sélectionner
   - Appuyer sur le bouton **"-"** (moins) en bas de la liste
   - Confirmer la suppression

### Étape 2 : Vérifier Target Membership (Alternative)

Si l'étape 1 ne fonctionne pas :

1. **Dans le Project Navigator**, sélectionner le fichier `Info.plist`
2. **Ouvrir le File Inspector** (⌥⌘1 ou View > Utilities > Show File Inspector)
3. **Dans la section "Target Membership" :**
   - **Décocher "Tshiakani VTC"** si la case est cochée
   - **Vérifier que Info.plist est toujours référencé via `INFOPLIST_FILE` dans Build Settings**

### Étape 3 : Vérifier les Build Settings

1. **Sélectionner le target "Tshiakani VTC"**
2. **Aller dans l'onglet "Build Settings"**
3. **Rechercher "Info.plist" dans la barre de recherche**
4. **Vérifier que :**
   - `GENERATE_INFOPLIST_FILE` = `NO`
   - `INFOPLIST_FILE` = `Tshiakani VTC/Info.plist`
   - `INFOPLIST_PREPROCESS` = `NO`

### Étape 4 : Nettoyer et Recompiler

1. **Product > Clean Build Folder** (⇧⌘K)
2. **Fermer Xcode complètement**
3. **Supprimer le DerivedData :**
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/Tshiakani_VTC-*
   ```
4. **Rouvrir Xcode**
5. **Product > Build** (⌘B)

## Vérification Finale

Après avoir suivi les étapes ci-dessus, vérifier que :
- ✅ Info.plist n'est PAS dans "Copy Bundle Resources"
- ✅ `GENERATE_INFOPLIST_FILE = NO` dans Build Settings
- ✅ `INFOPLIST_FILE = "Tshiakani VTC/Info.plist"` dans Build Settings
- ✅ Le build réussit sans l'erreur "Multiple commands produce Info.plist"

## Pourquoi cette Solution est Nécessaire

Avec `PBXFileSystemSynchronizedRootGroup`, Xcode synchronise automatiquement tous les fichiers du dossier, et il n'y a pas de moyen direct dans `project.pbxproj` d'exclure un fichier spécifique des ressources. La seule façon fiable de résoudre ce problème est de vérifier manuellement dans Xcode que Info.plist n'est pas dans "Copy Bundle Resources".

## Fichiers Modifiés

1. ✅ `Tshiakani VTC.xcodeproj/project.pbxproj` - Build settings ajoutés
2. ✅ `SOLUTION_MULTIPLE_COMMANDS_INFO_PLIST.md` - Documentation de la solution
3. ✅ `CORRECTION_MULTIPLE_COMMANDS_INFO_PLIST.md` - Ce document

## Prochaines Étapes

1. Ouvrir Xcode
2. Suivre les étapes ci-dessus pour retirer Info.plist de "Copy Bundle Resources"
3. Nettoyer le build folder
4. Recompiler le projet
5. Vérifier que l'erreur est résolue

---

**Statut :** ✅ Modifications appliquées, action manuelle dans Xcode requise

