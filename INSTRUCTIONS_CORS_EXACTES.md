# ✅ Oui, c'est "Variables et secrets" !

## 📍 Vous êtes au Bon Endroit

Dans la console GCP, vous devez aller dans :
```
"Variables d'environnement, secrets et connexions"
```
ou simplement
```
"Variables et secrets"
```

---

## 🎯 Étapes Exactes

### 1. Dans "Variables et secrets"

Vous devriez voir une liste de variables d'environnement comme :
- `NODE_ENV`
- `INSTANCE_CONNECTION_NAME`
- `DB_USER`
- `DB_PASSWORD`
- etc.

### 2. Ajouter CORS_ORIGIN

**Option A : Si CORS_ORIGIN n'existe pas**
- Cliquez sur **"AJOUTER UNE VARIABLE D'ENVIRONNEMENT"** (bouton bleu)
- **Nom de la variable** : `CORS_ORIGIN`
- **Valeur** : Copiez depuis `VALEUR_CORS.txt` ou utilisez :
  ```
  https://tshiakani-vtc-99cea.web.app,https://tshiakani-vtc-99cea.firebaseapp.com,capacitor://localhost,ionic://localhost,http://localhost:3001,http://localhost:5173
  ```

**Option B : Si CORS_ORIGIN existe déjà**
- Cliquez sur l'icône ✏️ (crayon) à droite de `CORS_ORIGIN`
- Modifiez la valeur avec celle ci-dessus

### 3. Déployer

- **En bas de la page**, cliquez sur **"DÉPLOYER"** (bouton bleu)
- Attendez 1-2 minutes pour la confirmation

---

## ✅ Vérification

Après le déploiement, vous verrez :
- ✅ "Révision déployée avec succès"
- ✅ Nouvelle révision créée

---

## 📋 Valeur Exacte

Copiez cette valeur (sans espaces supplémentaires) :

```
https://tshiakani-vtc-99cea.web.app,https://tshiakani-vtc-99cea.firebaseapp.com,capacitor://localhost,ionic://localhost,http://localhost:3001,http://localhost:5173
```

---

**C'est bien là !** ✅ Continuez avec les étapes ci-dessus.

