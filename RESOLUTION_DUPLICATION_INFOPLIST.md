# 🔧 Résolution : Multiple commands produce Info.plist

## 📋 Erreur

```
Multiple commands produce '/Users/admin/Library/Developer/Xcode/DerivedData/.../Info.plist'
```

## 🔍 Cause

Info.plist est généré/processé **deux fois** :
1. Via `INFOPLIST_FILE = "Tshiakani VTC/Info.plist"` (correct)
2. Via `Copy Bundle Resources` (à retirer)

Avec `PBXFileSystemSynchronizedRootGroup` (objectVersion 77), Xcode synchronise automatiquement les fichiers et peut ajouter Info.plist aux ressources même s'il n'apparaît pas explicitement dans project.pbxproj.

## ✅ Solution

### Étape 1 : Retirer Info.plist de Copy Bundle Resources

1. **Ouvrez Xcode** (le projet devrait déjà être ouvert)

2. **Sélectionnez le target "Tshiakani VTC"**
   - Cliquez sur l'icône bleue en haut du Project Navigator (⌘1)
   - OU cliquez sur "Tshiakani VTC" dans la liste des targets

3. **Allez dans l'onglet "Build Phases"**
   - C'est le 3ème onglet en haut (après General et Signing & Capabilities)

4. **Développez "Copy Bundle Resources"**
   - Cliquez sur la flèche à gauche de "Copy Bundle Resources"
   - Vous verrez une liste de fichiers

5. **Cherchez "Info.plist" dans la liste**
   - Faites défiler la liste si nécessaire
   - Info.plist peut être présent même si la section semble vide dans project.pbxproj

6. **Si Info.plist est présent :**
   - **Sélectionnez-le** (cliquez dessus)
   - **Cliquez sur le bouton "-"** (moins) en bas de la liste
   - **OU appuyez sur la touche Delete** (⌫)

7. **Vérifiez que Info.plist n'est plus dans la liste**
   - La liste ne doit plus contenir Info.plist

### Étape 2 : Nettoyer et Compiler

1. **Product** > **Clean Build Folder** (⇧⌘K)
   - Attendez que le nettoyage se termine

2. **Product** > **Build** (⌘B)
   - L'erreur devrait disparaître

## ✅ Vérification

Après avoir retiré Info.plist de Copy Bundle Resources :

- ✅ Info.plist n'est plus dans Copy Bundle Resources
- ✅ `GENERATE_INFOPLIST_FILE = NO` (déjà correct)
- ✅ `INFOPLIST_FILE = "Tshiakani VTC/Info.plist"` (déjà correct)
- ✅ BUILD SUCCEEDED

## 🆘 Si le Problème Persiste

### Solution Alternative 1 : Vérifier les Build Settings

1. Target "Tshiakani VTC" > **Build Settings**
2. Recherchez `GENERATE_INFOPLIST_FILE`
3. Vérifiez que c'est **NO** (pas YES)
4. Recherchez `INFOPLIST_FILE`
5. Vérifiez que c'est **"Tshiakani VTC/Info.plist"**

### Solution Alternative 2 : Nettoyer Complètement

```bash
# Supprimer le DerivedData
rm -rf ~/Library/Developer/Xcode/DerivedData/Tshiakani_VTC-*

# Dans Xcode: Product > Clean Build Folder (⇧⌘K)
# Puis: Product > Build (⌘B)
```

### Solution Alternative 3 : Vérifier le File Inspector

1. Dans le Project Navigator, sélectionnez **Info.plist**
2. Ouvrez le **File Inspector** (⌥⌘1) dans le panneau de droite
3. Vérifiez la section **Target Membership**
4. La case "Tshiakani VTC" doit être **cochée**
5. Mais Info.plist ne doit **PAS** être dans Copy Bundle Resources

## 📊 État de la Configuration

| Élément | Statut | Action |
|---------|--------|--------|
| GENERATE_INFOPLIST_FILE | ✅ NO | Aucune |
| INFOPLIST_FILE | ✅ Configuré | Aucune |
| Info.plist dans ressources | ⚠️ À vérifier | **Retirer si présent** |

## 🎯 Résultat Attendu

Après avoir retiré Info.plist de Copy Bundle Resources :

- ✅ 0 erreurs de compilation
- ✅ BUILD SUCCEEDED
- ✅ L'erreur "Multiple commands produce Info.plist" disparaît

---

**Date** : $(date)
**Statut** : ⚠️ Action manuelle requise dans Xcode

