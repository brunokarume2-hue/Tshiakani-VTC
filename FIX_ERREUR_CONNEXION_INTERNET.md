# 🔧 Fix : Erreur "Aucune connexion Internet disponible" lors de l'inscription

## 📋 Problème

L'application iOS affiche l'erreur "Aucune connexion Internet disponible" lors de l'inscription, alors que le téléphone est connecté au WiFi.

## 🔍 Causes Identifiées

1. **ConfigurationService utilisait une IP locale inexistante en mode DEBUG**
   - En mode DEBUG sur un appareil réel, ConfigurationService retournait `http://192.168.1.79:3000/api`
   - Cette IP n'existe pas, ce qui causait l'erreur de connexion

2. **Info.plist n'était peut-être pas lu correctement**
   - L'URL Cloud Run est configurée dans les build settings (`INFOPLIST_KEY_API_BASE_URL`)
   - Mais ConfigurationService ne la lisait pas correctement en mode DEBUG

3. **Manque de logs pour diagnostiquer**
   - Aucun log n'indiquait quelle URL était utilisée
   - Difficile de diagnostiquer le problème

## ✅ Corrections Appliquées

### 1. ConfigurationService.swift

**Avant** :
```swift
#if DEBUG
    #if targetEnvironment(simulator)
        return "http://localhost:3000/api"
    #else
        // IP par défaut pour développement (à modifier selon votre réseau)
        return "http://192.168.1.79:3000/api"  // ❌ IP inexistante
    #endif
#endif
```

**Après** :
```swift
#if DEBUG
    #if targetEnvironment(simulator)
        return "http://localhost:3000/api"
    #else
        // Fallback vers Cloud Run même en DEBUG si aucune configuration locale
        return "https://tshiakani-vtc-backend-418102154417.us-central1.run.app/api"  // ✅
    #endif
#endif
```

**Améliorations** :
- ✅ Fallback vers Cloud Run même en mode DEBUG sur un appareil réel
- ✅ Logs ajoutés pour diagnostiquer l'URL utilisée
- ✅ Priorité correcte : UserDefaults > Info.plist > Fallback

### 2. APIService.swift

**Améliorations** :
- ✅ Logs détaillés pour chaque requête HTTP
- ✅ Affichage de l'URL complète utilisée
- ✅ Logs d'erreur détaillés avec domain, code, userInfo
- ✅ Messages de diagnostic clairs avec emojis

**Logs ajoutés** :
- `🔧 ConfigurationService: URL depuis Info.plist` - URL lue depuis Info.plist
- `🌐 APIService POST: [URL]` - URL complète de la requête
- `📤 APIService: Envoi de la requête...` - Début de la requête
- `📥 APIService: Réponse reçue - Status: [code]` - Réponse reçue
- `✅ APIService: Requête réussie` - Requête réussie
- `❌ APIService: Erreur réseau - [détails]` - Erreur réseau

## 🔍 Comment Diagnostiquer

### 1. Vérifier les logs dans Xcode

1. Ouvrez Xcode
2. Connectez votre iPhone
3. Lancez l'application
4. Ouvrez la console (View > Debug Area > Activate Console)
5. Cherchez les messages commençant par :
   - `🔧 ConfigurationService:`
   - `🌐 APIService:`
   - `❌ APIService:`

### 2. Vérifier l'URL utilisée

Les logs afficheront :
```
🔧 ConfigurationService: URL depuis Info.plist: https://tshiakani-vtc-backend-418102154417.us-central1.run.app/api
🌐 APIService.register: URL complète = https://tshiakani-vtc-backend-418102154417.us-central1.run.app/api/auth/register
```

Si l'URL est incorrecte, vous verrez :
```
⚠️ ConfigurationService: URL par défaut (appareil réel DEBUG): https://tshiakani-vtc-backend-418102154417.us-central1.run.app/api
```

### 3. Vérifier les erreurs réseau

Si une erreur réseau se produit, les logs afficheront :
```
❌ APIService.register: Erreur réseau - [description]
❌ APIService.register: Domain - NSURLErrorDomain, Code - [code]
❌ APIService.register: UserInfo - [détails]
```

**Codes d'erreur courants** :
- `-1009` : Pas de connexion Internet (NSURLErrorNotConnectedToInternet)
- `-1001` : Timeout (NSURLErrorTimedOut)
- `-1003` : Impossible de trouver l'hôte (NSURLErrorCannotFindHost)
- `-1004` : Impossible de se connecter à l'hôte (NSURLErrorCannotConnectToHost)

## 🚀 Solutions

### Solution 1 : Vérifier la configuration Info.plist

1. Ouvrez Xcode
2. Sélectionnez le projet dans le navigateur
3. Allez dans **Build Settings**
4. Recherchez `INFOPLIST_KEY_API_BASE_URL`
5. Vérifiez que l'URL est : `https://tshiakani-vtc-backend-418102154417.us-central1.run.app/api`

### Solution 2 : Forcer l'URL via UserDefaults (temporaire)

Pour tester rapidement, vous pouvez forcer l'URL dans le code :

```swift
// Dans ConfigurationService.swift, temporairement :
UserDefaults.standard.set("https://tshiakani-vtc-backend-418102154417.us-central1.run.app/api", forKey: "api_base_url")
```

### Solution 3 : Vérifier les permissions réseau

Assurez-vous que les permissions réseau sont configurées dans Info.plist :

1. Ouvrez Xcode
2. Sélectionnez le projet
3. Allez dans **Info** tab
4. Vérifiez que **App Transport Security Settings** est configuré pour permettre les connexions HTTPS

### Solution 4 : Vérifier la connectivité

Testez la connectivité depuis votre iPhone :

1. Ouvrez Safari sur votre iPhone
2. Allez à : `https://tshiakani-vtc-backend-418102154417.us-central1.run.app/health`
3. Vous devriez voir une réponse JSON avec `{"status":"OK",...}`

Si cela ne fonctionne pas, le problème vient de la connexion Internet ou du firewall.

## 📱 Test dans l'App

### Étapes de test

1. **Builder l'app dans Xcode**
   - `Product` > `Clean Build Folder` (⇧⌘K)
   - `Product` > `Build` (⌘B)
   - `Product` > `Run` (⌘R)

2. **Tester l'inscription**
   - Ouvrez l'app
   - Cliquez sur "S'inscrire"
   - Remplissez le formulaire
   - Cliquez sur "S'inscrire"
   - Vérifiez les logs dans la console Xcode

3. **Vérifier les logs**
   - Cherchez les messages `🔧 ConfigurationService:`
   - Vérifiez que l'URL Cloud Run est utilisée
   - Si une erreur se produit, notez le code d'erreur et le message

## 🔄 Prochaines Étapes

1. **Tester l'inscription** avec les corrections appliquées
2. **Vérifier les logs** pour confirmer que l'URL Cloud Run est utilisée
3. **Tester la connexion** pour s'assurer qu'elle fonctionne également
4. **Retirer les logs de debug** une fois que tout fonctionne (optionnel)

## 📝 Notes

- Les logs de debug sont utiles pour diagnostiquer les problèmes, mais peuvent être retirés en production
- L'URL Cloud Run est maintenant utilisée par défaut même en mode DEBUG
- Si vous avez un backend local, vous pouvez toujours le configurer via UserDefaults

## ✅ Statut

- ✅ ConfigurationService corrigé
- ✅ APIService amélioré avec logs
- ✅ Fallback vers Cloud Run en mode DEBUG
- ⏳ À tester sur l'appareil réel

---

**Date** : 2025-01-15  
**Statut** : ✅ **Corrections Appliquées - À Tester**

