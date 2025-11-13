# 🚀 Déploiement sur Supabase - Guide Complet

## ✅ Pourquoi Supabase ?

- ✅ **PostgreSQL** : Déjà utilisé dans votre projet
- ✅ **Gratuit** : Plan gratuit généreux
- ✅ **Simple** : Déploiement en quelques clics
- ✅ **Edge Functions** : Backend serverless
- ✅ **Real-time** : WebSockets intégrés
- ✅ **Storage** : Pour les fichiers

## 📋 Prérequis

1. Compte Supabase : https://supabase.com
2. Projet Supabase créé
3. Variables d'environnement configurées

## 🚀 Étapes de Déploiement

### Étape 1 : Créer un Projet Supabase (2 minutes)

1. Aller sur : https://supabase.com
2. Cliquer **"Start your project"** ou **"New Project"**
3. Remplir :
   - **Name** : `tshiakani-vtc`
   - **Database Password** : (choisir un mot de passe fort)
   - **Region** : `West US` (ou le plus proche)
   - **Plan** : `Free`
4. Cliquer **"Create new project"**
5. ⚠️ **ATTENDRE** 2-3 minutes que le projet soit créé

### Étape 2 : Récupérer les Variables d'Environnement

Dans Supabase Dashboard :

1. Aller dans **Settings** → **API**
2. Noter :
   - **Project URL** : `https://xxxxx.supabase.co`
   - **anon public key** : `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`
   - **service_role key** : `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

3. Aller dans **Settings** → **Database**
4. Noter :
   - **Connection string** : `postgresql://postgres:[PASSWORD]@db.xxxxx.supabase.co:5432/postgres`

### Étape 3 : Configurer la Base de Données

1. Dans Supabase Dashboard, aller dans **SQL Editor**
2. Exécuter les migrations :
   - Copier le contenu de `backend/migrations/001_init_postgis.sql`
   - Exécuter dans SQL Editor
   - Répéter pour les autres migrations

### Étape 4 : Déployer le Backend (Option 1 : Edge Functions)

Supabase Edge Functions sont parfaites pour le backend :

1. Installer Supabase CLI :
```bash
npm install -g supabase
```

2. Initialiser Supabase :
```bash
cd "/Users/admin/Documents/Tshiakani VTC"
supabase init
```

3. Lier au projet :
```bash
supabase link --project-ref votre-project-ref
```

4. Créer une Edge Function :
```bash
supabase functions new api
```

5. Déployer :
```bash
supabase functions deploy api
```

### Étape 4 : Déployer le Backend (Option 2 : Railway/Render avec Supabase DB)

Utiliser Supabase uniquement pour la base de données :

1. Créer le projet Supabase (étape 1)
2. Récupérer la connection string
3. Déployer le backend sur Railway ou Render
4. Utiliser la connection string Supabase comme `DATABASE_URL`

## 🔧 Configuration des Variables

Dans votre service de déploiement (Railway/Render), ajouter :

```
DATABASE_URL=postgresql://postgres:[PASSWORD]@db.xxxxx.supabase.co:5432/postgres
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

## 🎯 Option Recommandée : Railway + Supabase

1. **Supabase** : Pour la base de données PostgreSQL
2. **Railway** : Pour déployer le backend Node.js
   - Plus simple que Render
   - Déploiement automatique depuis GitHub
   - Configuration minimale

## 📚 Documentation

- Supabase : https://supabase.com/docs
- Railway : https://railway.app

---

**Temps estimé** : 10-15 minutes
**Coût** : Gratuit (plan Free pour les deux)

