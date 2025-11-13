# 🔑 Configuration de la Clé API Google Maps

## ✅ Clé API configurée

Votre clé API Google Maps a été ajoutée : `AIzaSyBBSOYw1qSUrp3yU4t097tjRZRwRZ0z1w8`

## 📝 Instructions pour Xcode

### Méthode 1 : Via Build Settings (Recommandée)

1. Ouvrez le projet dans **Xcode**
2. Sélectionnez le target **Tshiakani VTC** dans le Project Navigator (icône bleue en haut)
3. Allez dans l'onglet **Build Settings**
4. Dans la barre de recherche en haut, tapez : `INFOPLIST_KEY`
5. Cliquez sur le **+** à côté de "Info.plist Values" (ou "Custom iOS Target Properties")
6. Ajoutez une nouvelle entrée :
   - **Key**: `GOOGLE_MAPS_API_KEY`
   - **Type**: String
   - **Value**: `AIzaSyBBSOYw1qSUrp3yU4t097tjRZRwRZ0z1w8`

### Méthode 2 : Utiliser le fichier Info.plist créé

1. Dans Xcode, faites un clic droit sur le dossier **Tshiakani VTC**
2. Sélectionnez **Add Files to "Tshiakani VTC"...**
3. Sélectionnez le fichier `Info.plist` que j'ai créé
4. Cochez **"Copy items if needed"** et **"Add to targets: Tshiakani VTC"**
5. Dans **Build Settings**, recherchez `INFOPLIST_FILE`
6. Changez la valeur pour pointer vers : `Tshiakani VTC/Info.plist`
7. Désactivez `GENERATE_INFOPLIST_FILE` (mettez à `NO`)

## ✅ Vérification

Après avoir configuré la clé, lancez l'application et vérifiez dans la console :

- ✅ Si vous voyez : `"✅ Google Maps SDK initialisé avec succès"` → Tout fonctionne !
- ⚠️ Si vous voyez : `"⚠️ GOOGLE_MAPS_API_KEY non trouvée"` → Vérifiez la configuration

## 🔒 Sécurité

⚠️ **Important** : Ne commitez jamais votre clé API dans Git si le repository est public !

Pour sécuriser votre clé :
1. Ajoutez `Info.plist` dans `.gitignore` si vous utilisez la méthode 2
2. Ou utilisez des variables d'environnement pour le développement

## 📱 Bundle ID

Votre Bundle ID est : `com.bruno.tshiakaniVTC`

Assurez-vous que cette clé API a les bonnes restrictions dans Google Cloud Console :
- **Application restrictions** : iOS apps
- **Bundle ID** : `com.bruno.tshiakaniVTC`

