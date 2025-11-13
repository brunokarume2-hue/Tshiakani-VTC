# 🔧 Solution pour Ajouter la Colonne `name`

## ⚠️ Problème

La colonne `name` n'existe pas dans la table `users` de la base de données Cloud SQL, ce qui cause l'erreur :
```
column User.name does not exist (code 42703)
```

## ✅ Solution Recommandée : Via Google Cloud Console

### Étape 1: Accéder à Cloud SQL

1. Allez sur : https://console.cloud.google.com/sql/instances/tshiakani-db?project=tshiakani-vtc-477711
2. Cliquez sur l'onglet **"Databases"**
3. Sélectionnez la base de données **"tshiakani"**
4. Cliquez sur **"Connect using Cloud Shell"** ou utilisez l'éditeur SQL

### Étape 2: Exécuter la Migration

Dans l'éditeur SQL ou Cloud Shell, exécutez :

```sql
ALTER TABLE users ADD COLUMN IF NOT EXISTS name VARCHAR(255);
```

### Étape 3: Vérifier

```sql
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'users' AND column_name = 'name';
```

---

## 🔄 Alternative : Via gcloud CLI (si accessible)

```bash
# Se connecter à la base de données
gcloud sql connect tshiakani-db \
  --user=dbadmin \
  --database=tshiakani \
  --project=tshiakani-vtc-477711

# Puis exécuter :
ALTER TABLE users ADD COLUMN IF NOT EXISTS name VARCHAR(255);
```

**Note** : Cette méthode peut ne pas fonctionner si vous êtes sur IPv6.

---

## 🚀 Après l'Ajout de la Colonne

Une fois la colonne ajoutée :

1. **Tester la route admin/login** :
   ```bash
   curl -X POST https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/api/auth/admin/login \
     -H "Content-Type: application/json" \
     -d '{"phoneNumber":"+243900000000"}'
   ```

2. **Tester la route signin** :
   ```bash
   curl -X POST https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/api/auth/signin \
     -H "Content-Type: application/json" \
     -d '{"phoneNumber":"+243900000001","role":"client","name":"Test User"}'
   ```

3. **Vérifier que les routes fonctionnent** et retournent un token JWT.

---

## 📝 Migration SQL Complète

Le fichier de migration est disponible dans :
- `backend/migrations/004_add_name_column.sql`

Vous pouvez l'exécuter directement dans Cloud SQL.

---

**Date** : $(date)
**Statut** : ⚠️ En attente d'exécution manuelle de la migration SQL

