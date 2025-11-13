# 📋 Instructions de Renommage - Tshiakani VTC

## ⚠️ IMPORTANT : Avant de Commencer

1. **Sauvegarder le projet** : Faites une copie de sauvegarde ou un commit Git
2. **Fermer Xcode** : Fermez complètement Xcode avant d'exécuter le script
3. **Vérifier Git** : Assurez-vous que tous les changements sont commités

## 🚀 Exécution du Script

### Option 1 : Exécution Automatique (Recommandée)

```bash
cd "/Users/admin/Documents/wewa taxi"
./rename_to_tshiakani_vtc.sh
```

Le script va :
- ✅ Renommer tous les dossiers
- ✅ Renommer tous les fichiers
- ✅ Mettre à jour le Bundle Identifier
- ✅ Mettre à jour toutes les références dans le code
- ✅ Mettre à jour la documentation
- ✅ Nettoyer le cache Xcode

### Option 2 : Exécution Manuelle

Si vous préférez faire les changements manuellement, suivez le guide dans `GUIDE_RENOMMAGE_TSHIAKANI.md`

## 📝 Changements Effectués

### Bundle Identifiers

| Type | Ancien | Nouveau |
|------|--------|---------|
| App | `optimacode.com.wewa-taxi` | `com.bruno.tshiakaniVTC` |
| Tests | `optimacode.com.wewa-taxiTests` | `com.bruno.tshiakaniVTCTests` |
| UI Tests | `optimacode.com.wewa-taxiUITests` | `com.bruno.tshiakaniVTCUITests` |

### Dossiers

- `wewa taxi/` → `Tshiakani VTC/`
- `wewa taxiTests/` → `TshiakaniVTCTests/`
- `wewa taxiUITests/` → `TshiakaniVTCUITests/`
- `wewa taxi.xcodeproj/` → `Tshiakani VTC.xcodeproj/`

### Fichiers Principaux

- `wewa_taxiApp.swift` → `TshiakaniVTCApp.swift`
- Structure `wewa_taxiApp` → `TshiakaniVTCApp`

## ✅ Vérifications Post-Renommage

### 1. Ouvrir le Projet dans Xcode

```bash
open "Tshiakani VTC.xcodeproj"
```

### 2. Vérifier le Bundle Identifier

1. Sélectionner le projet dans le navigateur
2. Sélectionner le target "Tshiakani VTC"
3. Onglet "Signing & Capabilities"
4. Vérifier : `com.bruno.tshiakaniVTC`

### 3. Nettoyer et Compiler

1. **Nettoyer** : Product > Clean Build Folder (⇧⌘K)
2. **Compiler** : Product > Build (⌘B)
3. **Vérifier** : Aucune erreur de compilation

### 4. Mettre à Jour les Certificats

1. Aller sur [developer.apple.com](https://developer.apple.com)
2. Créer un nouvel App ID : `com.bruno.tshiakaniVTC`
3. Créer de nouveaux certificats si nécessaire
4. Créer de nouveaux provisioning profiles
5. Télécharger dans Xcode : Preferences > Accounts

### 5. Tester

1. Lancer l'application : Product > Run (⌘R)
2. Exécuter les tests : Product > Test (⌘U)
3. Vérifier toutes les fonctionnalités

## 🔍 Recherche de Références Restantes

Après le renommage, vérifiez qu'il ne reste aucune référence :

```bash
cd "/Users/admin/Documents/wewa taxi"
grep -r "wewa" --exclude-dir=node_modules --exclude-dir=.git --exclude-dir="Tshiakani VTC.xcodeproj/xcuserdata" .
```

Si des références restent, mettez-les à jour manuellement.

## 📦 Git

Après vérification que tout fonctionne :

```bash
git add -A
git commit -m "Rename project from 'wewa taxi' to 'Tshiakani VTC'

- Renamed all folders and files
- Updated Bundle Identifier to com.bruno.tshiakaniVTC
- Updated all code references
- Updated documentation and configuration files"
```

## 🆘 Problèmes ?

Consultez `GUIDE_RENOMMAGE_TSHIAKANI.md` pour les solutions aux problèmes courants.

## ✨ Résultat Attendu

Après le renommage complet :

- ✅ Projet s'appelle "Tshiakani VTC"
- ✅ Bundle Identifier : `com.bruno.tshiakaniVTC`
- ✅ Tous les fichiers et dossiers renommés
- ✅ Code compile sans erreurs
- ✅ Application fonctionne correctement
- ✅ Git conserve l'historique

