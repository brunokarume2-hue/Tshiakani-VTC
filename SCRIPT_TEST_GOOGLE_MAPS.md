# Script de Test Google Maps

## 🧪 Tests à Effectuer

### Test 1 : Initialisation du SDK

**Objectif** : Vérifier que Google Maps SDK s'initialise correctement

**Étapes** :
1. Lancez l'application en mode Debug
2. Ouvrez la console Xcode (⌘⇧Y)
3. Recherchez le message : `"✅ Google Maps SDK initialisé avec succès"`
4. Si vous voyez `"⚠️ GOOGLE_MAPS_API_KEY non trouvée"`, vérifiez la configuration

**Résultat attendu** : ✅ Message de succès dans la console

---

### Test 2 : Autocomplétion d'Adresses (Google Places)

**Objectif** : Vérifier que l'autocomplétion fonctionne dans RideRequestView

**Étapes** :
1. Lancez l'application
2. Connectez-vous ou créez un compte
3. Allez dans **"Nouvelle course"** (RideRequestView)
4. Tapez dans le champ **"Destination"** : `"Kinshasa"`
5. Attendez 1-2 secondes
6. Vérifiez que des suggestions d'adresses apparaissent

**Résultats attendus** :
- ✅ Des suggestions d'adresses apparaissent
- ✅ Les suggestions sont pertinentes (contiennent "Kinshasa")
- ✅ En sélectionnant une suggestion, l'adresse est remplie
- ✅ Les coordonnées sont correctement récupérées

**Tests supplémentaires** :
- Testez avec : `"123 Avenue"`
- Testez avec : `"Aéroport"`
- Testez avec : `"Place de l'Indépendance"`

---

### Test 3 : Calcul d'Itinéraire avec Trafic (Google Directions)

**Objectif** : Vérifier que le calcul de prix utilise Google Directions avec trafic

**Étapes** :
1. Dans **RideRequestView**, remplissez :
   - **Départ** : `"Aéroport de Kinshasa"` (ou votre position actuelle)
   - **Destination** : `"Place de l'Indépendance, Kinshasa"`
2. Attendez 3-5 secondes pour le calcul
3. Vérifiez que les informations suivantes s'affichent :
   - **Distance** : Doit être > 0 (ex: "12.5 km")
   - **Temps d'attente** : Doit être > 0 (ex: "18 min")
   - **Prix estimé** : Doit être > 0 (ex: "3500 FC")

**Résultats attendus** :
- ✅ Distance calculée avec précision
- ✅ Temps de trajet inclut le trafic en temps réel
- ✅ Prix estimé basé sur distance + temps + trafic
- ✅ Les valeurs sont cohérentes (prix augmente avec distance/temps)

**Tests supplémentaires** :
- Testez avec un trajet court (< 2 km)
- Testez avec un trajet long (> 10 km)
- Testez à différents moments de la journée (pour voir les variations de trafic)

---

### Test 4 : Gestion des Erreurs

**Objectif** : Vérifier que les erreurs sont gérées correctement

**Test 4.1 : Clé API invalide**
1. Modifiez temporairement la clé API dans Info.plist avec une clé invalide
2. Lancez l'application
3. Vérifiez que l'application ne crash pas
4. Vérifiez qu'un message d'erreur approprié est affiché

**Test 4.2 : Pas de connexion Internet**
1. Désactivez le WiFi et les données mobiles
2. Essayez d'utiliser l'autocomplétion
3. Vérifiez que l'application gère l'erreur gracieusement
4. Vérifiez qu'un message d'erreur est affiché

**Test 4.3 : Quota dépassé** (si applicable)
1. Si vous avez dépassé le quota, vérifiez que l'application utilise le fallback local
2. Vérifiez que le calcul de prix fonctionne toujours (avec calcul local)

---

### Test 5 : Performance

**Objectif** : Vérifier que les performances sont acceptables

**Étapes** :
1. Testez l'autocomplétion avec des requêtes rapides
2. Vérifiez que le debouncing fonctionne (pas trop de requêtes)
3. Vérifiez que l'interface reste réactive pendant les calculs
4. Vérifiez les temps de réponse :
   - Autocomplétion : < 1 seconde
   - Calcul d'itinéraire : < 3 secondes

---

## 📊 Checklist de Validation

### Configuration
- [ ] Clé API configurée dans Info.plist ou Build Settings
- [ ] Packages Swift installés (GoogleMaps, GooglePlaces)
- [ ] Application compile sans erreurs
- [ ] SDK s'initialise correctement au démarrage

### Fonctionnalités
- [ ] Autocomplétion fonctionne dans RideRequestView
- [ ] Suggestions d'adresses pertinentes
- [ ] Coordonnées correctement récupérées
- [ ] Calcul d'itinéraire fonctionne
- [ ] Distance, temps et prix affichés correctement
- [ ] Trafic en temps réel pris en compte

### Robustesse
- [ ] Gestion des erreurs (clé API invalide, pas de connexion)
- [ ] Fallback local si Google Directions échoue
- [ ] Interface reste réactive
- [ ] Pas de crashs ou de freezes

### Performance
- [ ] Autocomplétion rapide (< 1 seconde)
- [ ] Calcul d'itinéraire acceptable (< 3 secondes)
- [ ] Debouncing fonctionne (pas trop de requêtes)

---

## 🐛 Dépannage Rapide

### Problème : "API key not valid"
**Solution** : Vérifiez la clé API dans Info.plist et Google Cloud Console

### Problème : Autocomplétion ne fonctionne pas
**Solution** : Vérifiez que Places API est activée et que les quotas ne sont pas dépassés

### Problème : Calcul de prix ne fonctionne pas
**Solution** : Vérifiez que Directions API est activée et consultez les logs de la console

### Problème : Application crash au démarrage
**Solution** : Vérifiez que les packages Swift sont bien installés et que les frameworks sont liés

---

## 📝 Notes de Test

**Date du test** : _______________

**Version de l'application** : _______________

**Clé API** : ✅ Configurée / ❌ Non configurée

**Résultats** :
- Test 1 (Initialisation) : ✅ / ❌
- Test 2 (Autocomplétion) : ✅ / ❌
- Test 3 (Calcul d'itinéraire) : ✅ / ❌
- Test 4 (Gestion erreurs) : ✅ / ❌
- Test 5 (Performance) : ✅ / ❌

**Remarques** :
_________________________________________________
_________________________________________________
_________________________________________________

