# 🔧 Ajouter la Colonne `name` à la Table `users`

## ⚠️ Problème

La colonne `name` n'existe pas dans la table `users`, causant l'erreur :
```
column User.name does not exist (code 42703)
```

## ✅ Solution : Via Google Cloud Console

### Étape 1: Accéder à Cloud SQL

1. Allez sur : **https://console.cloud.google.com/sql/instances/tshiakani-db?project=tshiakani-vtc-477711**
2. Cliquez sur l'onglet **"Databases"**
3. Sélectionnez la base de données **"tshiakani"**

### Étape 2: Ouvrir l'Éditeur SQL

1. Cliquez sur **"Connect using Cloud Shell"** ou utilisez l'**éditeur SQL** dans la console
2. Si vous utilisez Cloud Shell, connectez-vous avec :
   ```bash
   gcloud sql connect tshiakani-db --user=dbadmin --database=tshiakani
   ```

### Étape 3: Exécuter la Migration

Exécutez cette commande SQL :

```sql
ALTER TABLE users ADD COLUMN IF NOT EXISTS name VARCHAR(255);
```

### Étape 4: Vérifier

```sql
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'users' AND column_name = 'name';
```

Vous devriez voir :
```
 column_name | data_type 
-------------+-----------
 name        | character varying
```

---

## 🧪 Tester Après l'Ajout

Une fois la colonne ajoutée, testez les routes :

```bash
# Test admin/login
curl -X POST https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/api/auth/admin/login \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber":"+243900000000"}'

# Test signin
curl -X POST https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/api/auth/signin \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber":"+243900000001","role":"client","name":"Test User"}'
```

Les routes devraient retourner un token JWT au lieu d'une erreur.

---

## 📝 Alternative : Script Node.js

Un script est disponible dans `backend/scripts/add-name-column.js` mais nécessite une connexion directe à la base de données (pas via Cloud Run).

---

**Date** : $(date)
**Statut** : ⚠️ En attente d'exécution manuelle

