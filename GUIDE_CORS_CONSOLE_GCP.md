# 🌐 Guide Pas à Pas - Configuration CORS via Console GCP

## 📋 Objectif

Configurer CORS dans Cloud Run pour autoriser le dashboard et les apps iOS à communiquer avec le backend.

---

## 🎯 Étape par Étape

### Étape 1 : Accéder à Cloud Run

1. **Ouvrir le lien direct** :
   - Cliquez sur : https://console.cloud.google.com/run/detail/us-central1/tshiakani-vtc-backend?project=tshiakani-vtc-477711
   - Ou allez sur : https://console.cloud.google.com/run
   - Sélectionnez le projet : `tshiakani-vtc-477711`
   - Cliquez sur le service : `tshiakani-vtc-backend`

### Étape 2 : Modifier le Service

1. **En haut de la page**, cliquez sur le bouton :
   ```
   "MODIFIER ET DÉPLOYER UNE NOUVELLE RÉVISION"
   ```
   (Bouton bleu en haut à droite)

### Étape 3 : Accéder aux Variables d'Environnement

1. Dans le menu latéral gauche, cliquez sur :
   ```
   "Variables d'environnement, secrets et connexions"
   ```
   (Ou cherchez l'onglet "Variables d'environnement")

### Étape 4 : Ajouter/Modifier CORS_ORIGIN

1. **Si `CORS_ORIGIN` existe déjà** :
   - Cliquez sur l'icône ✏️ (crayon) à droite de `CORS_ORIGIN`
   - Modifiez la valeur

2. **Si `CORS_ORIGIN` n'existe pas** :
   - Cliquez sur "AJOUTER UNE VARIABLE D'ENVIRONNEMENT"
   - Nom de la variable : `CORS_ORIGIN`
   - Valeur : Copiez-collez exactement ceci :
   ```
   https://tshiakani-vtc-99cea.web.app,https://tshiakani-vtc-99cea.firebaseapp.com,capacitor://localhost,ionic://localhost,http://localhost:3001,http://localhost:5173
   ```

### Étape 5 : Déployer

1. **En bas de la page**, cliquez sur :
   ```
   "DÉPLOYER"
   ```
   (Bouton bleu)

2. **Attendre le déploiement** :
   - Le déploiement prend environ 1-2 minutes
   - Vous verrez un message de confirmation

### Étape 6 : Vérifier

1. **Tester le dashboard** :
   - Ouvrez : https://tshiakani-vtc-99cea.web.app
   - Ouvrez la console du navigateur (F12)
   - Vérifiez qu'il n'y a pas d'erreurs CORS

2. **Tester depuis le terminal** :
   ```bash
   curl -H "Origin: https://tshiakani-vtc-99cea.web.app" \
     https://tshiakani-vtc-backend-418102154417.us-central1.run.app/health
   ```

---

## 📝 Valeur Exacte à Copier

Copiez cette valeur exactement (sans espaces supplémentaires) :

```
https://tshiakani-vtc-99cea.web.app,https://tshiakani-vtc-99cea.firebaseapp.com,capacitor://localhost,ionic://localhost,http://localhost:3001,http://localhost:5173
```

---

## ✅ Checklist

- [ ] Accédé à Cloud Run Console
- [ ] Cliqué sur "MODIFIER ET DÉPLOYER UNE NOUVELLE RÉVISION"
- [ ] Allé dans "Variables d'environnement"
- [ ] Ajouté/Modifié `CORS_ORIGIN` avec la bonne valeur
- [ ] Cliqué sur "DÉPLOYER"
- [ ] Attendu la confirmation de déploiement
- [ ] Testé le dashboard

---

## 🎯 Résultat Attendu

Après configuration :
- ✅ Le dashboard peut communiquer avec le backend
- ✅ Les apps iOS peuvent communiquer avec le backend
- ✅ Pas d'erreurs CORS dans la console du navigateur

---

## 🔍 Vérification Post-Configuration

### Test 1 : Dashboard

1. Ouvrir https://tshiakani-vtc-99cea.web.app
2. Ouvrir la console (F12)
3. Se connecter au dashboard
4. Vérifier qu'il n'y a pas d'erreurs CORS

### Test 2 : Backend

```bash
curl -H "Origin: https://tshiakani-vtc-99cea.web.app" \
  -H "Access-Control-Request-Method: GET" \
  -X OPTIONS \
  https://tshiakani-vtc-backend-418102154417.us-central1.run.app/health
```

Devrait retourner des headers CORS.

---

## ⚠️ Notes Importantes

1. **Le déploiement prend 1-2 minutes** - Attendez la confirmation
2. **Vérifiez l'orthographe** - `CORS_ORIGIN` (en majuscules)
3. **Pas d'espaces** - La valeur doit être collée sans espaces supplémentaires
4. **Toutes les URLs** - Assurez-vous que toutes les URLs sont incluses

---

## 🆘 En Cas de Problème

### Erreur : "Variable déjà existante"
- Modifiez la variable existante au lieu d'en créer une nouvelle

### Erreur : "Déploiement échoué"
- Vérifiez que la valeur est correcte (pas d'espaces, virgules correctes)
- Réessayez le déploiement

### Le dashboard ne fonctionne toujours pas
- Attendez 2-3 minutes après le déploiement
- Videz le cache du navigateur (Ctrl+Shift+R ou Cmd+Shift+R)
- Vérifiez les logs Cloud Run pour voir les erreurs

---

**Date** : 2025-01-15  
**Lien direct** : https://console.cloud.google.com/run/detail/us-central1/tshiakani-vtc-backend?project=tshiakani-vtc-477711

