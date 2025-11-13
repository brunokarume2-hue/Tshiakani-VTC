# 🔧 Résolution du Conflit Info.plist

## 📋 Problème

```
Multiple commands produce '/Users/admin/Library/Developer/Xcode/DerivedData/.../Info.plist'
```

Cette erreur indique que Xcode essaie de générer ou traiter `Info.plist` de plusieurs façons en même temps.

## 🔍 Causes Possibles

1. **Fichier Info.plist ajouté dans les ressources** alors qu'il est aussi configuré via `INFOPLIST_FILE`
2. **GENERATE_INFOPLIST_FILE** activé alors qu'un fichier manuel existe
3. **Script de build** qui génère Info.plist
4. **Plusieurs targets** qui génèrent le même fichier

## ✅ Solution : Vérifier la Configuration

### Étape 1 : Vérifier dans Xcode

1. **Ouvrez le projet** dans Xcode
2. **Sélectionnez le target "Tshiakani VTC"** (pas les tests)
3. Allez dans l'onglet **Build Settings**
4. Recherchez `INFOPLIST_FILE` dans la barre de recherche
5. Vérifiez que :
   - ✅ `INFOPLIST_FILE` = `Tshiakani VTC/Info.plist`
   - ✅ `GENERATE_INFOPLIST_FILE` = `NO`

### Étape 2 : Vérifier que Info.plist n'est PAS dans les Ressources

1. Dans le **Project Navigator**, sélectionnez le fichier `Info.plist`
2. Ouvrez le **File Inspector** (⌥⌘1) dans le panneau de droite
3. Vérifiez la section **Target Membership** :
   - ✅ La case "Tshiakani VTC" doit être **COCHÉE**
   - ⚠️ Mais le fichier ne doit **PAS** être dans la phase **Copy Bundle Resources**

4. Allez dans l'onglet **Build Phases**
5. Développez **Copy Bundle Resources**
6. Si `Info.plist` est dans cette liste, **supprimez-le** (sélectionnez-le et appuyez sur `-`)

### Étape 3 : Vérifier les Scripts de Build

1. Dans l'onglet **Build Phases**, vérifiez s'il y a des **Run Script** phases
2. Si un script génère ou modifie `Info.plist`, il peut causer le conflit
3. Vérifiez que les scripts ne créent pas de `Info.plist` dans le dossier de sortie

### Étape 4 : Nettoyer et Reconstruire

1. **Product** > **Clean Build Folder** (⇧⌘K)
2. Fermez Xcode complètement
3. Supprimez le DerivedData :
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/Tshiakani_VTC-*
   ```
4. Rouvrez Xcode
5. **Product** > **Build** (⌘B)

## 🔧 Solution Alternative : Utiliser uniquement la Génération Automatique

Si le problème persiste, vous pouvez utiliser uniquement la génération automatique :

### Option A : Supprimer le fichier Info.plist manuel

1. **Supprimez** le fichier `Tshiakani VTC/Info.plist` du projet
2. Dans **Build Settings**, changez :
   - `GENERATE_INFOPLIST_FILE` = `YES`
   - Supprimez `INFOPLIST_FILE`
3. Toutes les clés `INFOPLIST_KEY_*` seront utilisées pour générer Info.plist automatiquement

### Option B : Utiliser uniquement le fichier manuel (Recommandé)

1. **Gardez** le fichier `Tshiakani VTC/Info.plist`
2. Dans **Build Settings**, assurez-vous que :
   - `GENERATE_INFOPLIST_FILE` = `NO`
   - `INFOPLIST_FILE` = `Tshiakani VTC/Info.plist`
3. **Supprimez** toutes les clés `INFOPLIST_KEY_*` des Build Settings (ou gardez-les, elles seront ignorées)
4. **Vérifiez** que le fichier n'est pas dans **Copy Bundle Resources**

## 📝 Configuration Actuelle

D'après le fichier `project.pbxproj` :

✅ **Target Principal (Tshiakani VTC)** :
- `GENERATE_INFOPLIST_FILE` = `NO` ✅
- `INFOPLIST_FILE` = `"Tshiakani VTC/Info.plist"` ✅

✅ **Targets de Test** :
- `GENERATE_INFOPLIST_FILE` = `YES` ✅ (normal pour les tests)

## 🎯 Vérification Finale

Après avoir appliqué les corrections :

1. ✅ Le projet compile sans erreur
2. ✅ Aucun conflit Info.plist
3. ✅ Le fichier Info.plist est correctement utilisé

## 🆘 Si le Problème Persiste

1. **Fermez Xcode**
2. **Supprimez complètement le DerivedData** :
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/*
   ```
3. **Supprimez les caches Xcode** :
   ```bash
   rm -rf ~/Library/Caches/com.apple.dt.Xcode/*
   ```
4. **Rouvrez Xcode**
5. **File** > **Open Recent** > Sélectionnez le projet
6. **Product** > **Clean Build Folder**
7. **Product** > **Build**

---

**Date de création** : $(date)
**Statut** : Configuration correcte, vérification dans Xcode nécessaire

