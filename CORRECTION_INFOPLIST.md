# 🔧 Correction : Conflit Info.plist

## 📋 Date : 2025-01-15

---

## ⚠️ Problème

Erreur de compilation Xcode :
```
duplicate output file '/Users/admin/Library/Developer/Xcode/DerivedData/.../Info.plist'
```

**Cause :**
- `GENERATE_INFOPLIST_FILE = YES` est activé (Xcode génère automatiquement Info.plist)
- Un fichier `Info.plist` manuel existe dans le dossier
- Le projet utilise `PBXFileSystemSynchronizedRootGroup` qui synchronise automatiquement tous les fichiers
- Conflit : Xcode essaie de générer ET d'utiliser le fichier manuel

---

## ✅ Solution Appliquée

Le fichier `Info.plist` manuel a été renommé en `Info.plist.manual`.

**Résultat :**
- ✅ Xcode génère automatiquement Info.plist depuis les Build Settings
- ✅ Le fichier manuel est conservé comme référence
- ✅ Plus de conflit lors de la compilation

---

## 📝 Configuration Actuelle

### Build Settings (GENERATE_INFOPLIST_FILE = YES)

Les valeurs sont définies via `INFOPLIST_KEY_*` dans Build Settings :

- `INFOPLIST_KEY_API_BASE_URL` : https://tshiakani-vtc-backend-418102154417.us-central1.run.app/api
- `INFOPLIST_KEY_WS_BASE_URL` : https://tshiakani-vtc-backend-418102154417.us-central1.run.app
- `INFOPLIST_KEY_GOOGLE_MAPS_API_KEY` : AIzaSyBBSOYw1qSUrp3yU4t097tjRZRwRZ0z1w8
- `INFOPLIST_KEY_NSLocationWhenInUseUsageDescription` : (défini)
- `INFOPLIST_KEY_NSLocationAlwaysAndWhenInUseUsageDescription` : (défini)
- `INFOPLIST_KEY_NSLocationAlwaysUsageDescription` : (défini)

---

## 🔄 Si Vous Voulez Utiliser le Fichier Manuel

Si vous préférez utiliser le fichier `Info.plist.manual` :

1. **Renommez-le** : `Info.plist.manual` → `Info.plist`
2. **Dans Xcode** :
   - Sélectionnez le target **Tshiakani VTC**
   - Allez dans **Build Settings**
   - Recherchez `GENERATE_INFOPLIST_FILE`
   - Mettez à `NO`
   - Recherchez `INFOPLIST_FILE`
   - Définissez le chemin : `Tshiakani VTC/Info.plist`

---

## ✅ Vérification

Après cette correction, le projet devrait compiler sans erreur.

**Test :**
1. Ouvrez le projet dans Xcode
2. Nettoyez le build : `Product` > `Clean Build Folder` (⇧⌘K)
3. Compilez : `Product` > `Build` (⌘B)

---

**Date** : 2025-01-15

