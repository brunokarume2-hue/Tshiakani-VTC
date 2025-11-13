# 🔄 Guide de Renommage : wewa taxi → Tshiakani VTC

Ce guide détaille toutes les étapes pour renommer complètement le projet.

## 📋 Changements Effectués

### 1. Noms et Identifiants

| Ancien | Nouveau |
|--------|---------|
| `wewa taxi` | `Tshiakani VTC` |
| `wewa_taxi` | `TshiakaniVTC` |
| `wewaTaxi` | `tshiakaniVTC` |
| `WEWA_TAXI` | `TSHIAKANI_VTC` |
| `com.bruno.wewa_taxi` | `com.bruno.tshiakaniVTC` |

### 2. Dossiers Renommés

- ✅ `wewa taxi/` → `Tshiakani VTC/`
- ✅ `wewa taxiTests/` → `TshiakaniVTCTests/`
- ✅ `wewa taxiUITests/` → `TshiakaniVTCUITests/`
- ✅ `wewa taxi.xcodeproj/` → `Tshiakani VTC.xcodeproj/`

### 3. Fichiers Renommés

- ✅ `wewa_taxiApp.swift` → `TshiakaniVTCApp.swift`
- ✅ Structure `wewa_taxiApp` → `TshiakaniVTCApp`

### 4. Bundle Identifier

- ✅ Ancien : `com.bruno.wewa_taxi`
- ✅ Nouveau : `com.bruno.tshiakaniVTC`

## 🚀 Exécution du Script

### Étape 1 : Exécuter le Script

```bash
cd "/Users/admin/Documents/wewa taxi"
./rename_to_tshiakani_vtc.sh
```

### Étape 2 : Vérifications dans Xcode

1. **Ouvrir le projet** :
   ```
   Ouvrir : Tshiakani VTC.xcodeproj
   ```

2. **Vérifier le Bundle Identifier** :
   - Sélectionner le projet dans le navigateur
   - Sélectionner le target "Tshiakani VTC"
   - Onglet "Signing & Capabilities"
   - Vérifier que le Bundle Identifier est : `com.bruno.tshiakaniVTC`

3. **Vérifier le Product Name** :
   - Onglet "Build Settings"
   - Rechercher "Product Name"
   - Vérifier que c'est "Tshiakani VTC"

4. **Vérifier les Schemes** :
   - Menu Product > Scheme > Manage Schemes
   - Vérifier que le scheme s'appelle "Tshiakani VTC"

### Étape 3 : Nettoyer et Compiler

1. **Nettoyer le build** :
   - Product > Clean Build Folder (⇧⌘K)

2. **Compiler le projet** :
   - Product > Build (⌘B)

3. **Vérifier les erreurs** :
   - Corriger toute erreur de compilation
   - Vérifier les imports et références

### Étape 4 : Certificats et Provisioning Profiles

1. **Mettre à jour dans Apple Developer Portal** :
   - Aller sur [developer.apple.com](https://developer.apple.com)
   - Créer un nouvel App ID : `com.bruno.tshiakaniVTC`
   - Créer de nouveaux certificats si nécessaire
   - Créer de nouveaux provisioning profiles

2. **Télécharger les profiles** :
   - Dans Xcode : Preferences > Accounts
   - Sélectionner votre compte
   - Cliquer sur "Download Manual Profiles"

3. **Sélectionner le profile** :
   - Dans les paramètres du projet
   - Sélectionner le provisioning profile correspondant

### Étape 5 : Tests

1. **Tests unitaires** :
   ```bash
   # Dans Xcode : Product > Test (⌘U)
   ```

2. **Tests UI** :
   - Vérifier que tous les tests passent

3. **Test de l'application** :
   - Lancer l'app sur un simulateur
   - Vérifier toutes les fonctionnalités

### Étape 6 : Git

```bash
# Voir les changements
git status

# Ajouter tous les changements
git add -A

# Commiter
git commit -m "Rename project from 'wewa taxi' to 'Tshiakani VTC'

- Renamed all folders and files
- Updated Bundle Identifier to com.bruno.tshiakaniVTC
- Updated all code references
- Updated documentation and configuration files"
```

## 🔍 Vérifications Post-Renommage

### Fichiers à Vérifier Manuellement

1. **project.pbxproj** :
   - Vérifier que tous les chemins sont corrects
   - Vérifier les références aux fichiers

2. **Info.plist** (si présent) :
   - Vérifier le Bundle Identifier
   - Vérifier le nom de l'application

3. **Fichiers de configuration** :
   - `Package.swift` (si présent)
   - `Podfile` (si présent)
   - Fichiers CI/CD (`.github/workflows/`, etc.)

### Recherche de Références Restantes

```bash
# Rechercher toute référence restante à "wewa"
cd "/Users/admin/Documents/wewa taxi"
grep -r "wewa" --exclude-dir=node_modules --exclude-dir=.git .
```

## ⚠️ Problèmes Courants et Solutions

### Problème 1 : Erreurs de Compilation

**Symptôme** : Erreurs "Cannot find type" ou "No such module"

**Solution** :
1. Nettoyer le build : Product > Clean Build Folder
2. Supprimer DerivedData : `rm -rf ~/Library/Developer/Xcode/DerivedData/*`
3. Réouvrir Xcode
4. Recompiler

### Problème 2 : Bundle Identifier Incorrect

**Symptôme** : Erreurs de signature ou de provisioning

**Solution** :
1. Vérifier le Bundle Identifier dans Xcode
2. Mettre à jour dans Apple Developer Portal
3. Télécharger les nouveaux profiles

### Problème 3 : Schemes Manquants

**Symptôme** : Impossible de lancer l'application

**Solution** :
1. Product > Scheme > Manage Schemes
2. Cocher "Shared" pour le scheme
3. Supprimer et recréer si nécessaire

### Problème 4 : Références Cassées

**Symptôme** : Fichiers rouges dans Xcode

**Solution** :
1. Sélectionner les fichiers dans Xcode
2. File > Delete > Remove Reference
3. Réajouter les fichiers au projet

## 📝 Checklist Finale

- [ ] Tous les dossiers renommés
- [ ] Tous les fichiers renommés
- [ ] Bundle Identifier mis à jour
- [ ] Product Name mis à jour
- [ ] Schemes mis à jour
- [ ] Code compilé sans erreurs
- [ ] Tests passent
- [ ] Certificats et profiles mis à jour
- [ ] Documentation mise à jour
- [ ] Git commit effectué
- [ ] Aucune référence à "wewa" restante

## 🎯 Résultat Attendu

Après le renommage complet :

- ✅ Projet s'appelle "Tshiakani VTC"
- ✅ Bundle Identifier : `com.bruno.tshiakaniVTC`
- ✅ Tous les fichiers et dossiers renommés
- ✅ Code compile sans erreurs
- ✅ Application fonctionne correctement
- ✅ Git conserve l'historique

## 📞 Support

Si vous rencontrez des problèmes :

1. Vérifiez ce guide
2. Consultez les logs Xcode
3. Vérifiez les fichiers de configuration
4. Nettoyez le cache Xcode

