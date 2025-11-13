# Solution : Erreur "Multiple commands produce Info.plist"

## Problème
L'erreur "Multiple commands produce '/Users/admin/Library/Developer/Xcode/DerivedData/.../Info.plist'" se produit lorsque Xcode essaie de créer/copier Info.plist de plusieurs façons.

## Cause
Avec `PBXFileSystemSynchronizedRootGroup`, Xcode synchronise automatiquement tous les fichiers du dossier "Tshiakani VTC", y compris Info.plist. Cela peut causer un conflit car :
1. Xcode essaie d'utiliser Info.plist comme fichier Info.plist (via `INFOPLIST_FILE`)
2. Xcode essaie de copier Info.plist comme ressource (via `PBXFileSystemSynchronizedRootGroup`)

## Solution dans Xcode (Manuelle)

### Option 1 : Retirer Info.plist de Copy Bundle Resources (Recommandé)

1. **Ouvrir Xcode** et le projet
2. **Sélectionner le target "Tshiakani VTC"**
3. **Aller dans l'onglet Build Phases**
4. **Développer "Copy Bundle Resources"**
5. **Chercher "Info.plist" dans la liste**
6. **Si présent, le sélectionner et appuyer sur "-" (moins) pour le supprimer**

### Option 2 : Vérifier Target Membership

1. **Sélectionner Info.plist** dans le Project Navigator
2. **Ouvrir le File Inspector** (⌥⌘1)
3. **Dans "Target Membership", décocher "Tshiakani VTC"**
4. **Vérifier que Info.plist est toujours référencé via `INFOPLIST_FILE` dans Build Settings**

### Option 3 : Nettoyer le Build

1. **Product > Clean Build Folder** (⇧⌘K)
2. **Fermer Xcode complètement**
3. **Supprimer le DerivedData :**
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/Tshiakani_VTC-*
   ```
4. **Rouvrir Xcode**
5. **Product > Build** (⌘B)

## Modifications Appliquées dans project.pbxproj

Les modifications suivantes ont été appliquées :
- ✅ `GENERATE_INFOPLIST_FILE = NO` (Debug et Release)
- ✅ `INFOPLIST_FILE = "Tshiakani VTC/Info.plist"` (Debug et Release)
- ✅ `INFOPLIST_PREPROCESS = NO` (Debug et Release)
- ✅ `EXCLUDED_SOURCE_FILE_NAMES = "Info.plist"` (Debug et Release)

Cependant, avec `PBXFileSystemSynchronizedRootGroup`, ces settings peuvent ne pas suffire. Il faut également vérifier manuellement dans Xcode que Info.plist n'est pas dans "Copy Bundle Resources".

## Vérification

Après avoir suivi les étapes ci-dessus, vérifier que :
- ✅ Info.plist n'est PAS dans "Copy Bundle Resources"
- ✅ `GENERATE_INFOPLIST_FILE = NO` dans Build Settings
- ✅ `INFOPLIST_FILE = "Tshiakani VTC/Info.plist"` dans Build Settings
- ✅ Le build réussit sans l'erreur "Multiple commands produce"

## Notes

- Avec `PBXFileSystemSynchronizedRootGroup`, Xcode synchronise automatiquement les fichiers, ce qui peut inclure Info.plist dans les ressources
- La solution la plus fiable est de vérifier manuellement dans Xcode que Info.plist n'est pas dans "Copy Bundle Resources"
- Les clés `INFOPLIST_KEY_*` sont conservées mais ne sont plus utilisées maintenant que `GENERATE_INFOPLIST_FILE = NO`

