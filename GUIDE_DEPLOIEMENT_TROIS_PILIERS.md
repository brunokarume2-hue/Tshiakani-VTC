# 🚀 Guide de Déploiement - Trois Piliers

Guide complet pour déployer l'architecture Tshiakani VTC sur **Render** (API + BD), **Vercel** (Dashboard), et intégrer **Stripe** (Paiements).

---

## 📋 Table des matières

1. [Prérequis](#prérequis)
2. [I. Base de Données & Backend API (Render)](#i-base-de-données--backend-api-render)
3. [II. Paiement (Stripe SDK)](#ii-paiement-stripe-sdk)
4. [III. Dashboard Admin (Vercel)](#iii-dashboard-admin-vercel)
5. [Vérification finale](#vérification-finale)

---

## Prérequis

- Compte [Render](https://render.com) (gratuit)
- Compte [Vercel](https://vercel.com) (gratuit)
- Compte [Stripe](https://stripe.com) (gratuit pour les tests)
- Git installé
- Node.js 18+ installé

---

## I. Base de Données & Backend API (Render)

### Étape 1: Créer la base de données PostgreSQL sur Render

1. **Connectez-vous à Render** → [dashboard.render.com](https://dashboard.render.com)

2. **Créer une nouvelle base de données PostgreSQL**:
   - Cliquez sur "New +" → "PostgreSQL"
   - Nom: `tshiakani-vtc-db`
   - Plan: **Free** (suffisant pour le MVP)
   - Région: Choisissez la plus proche (ex: `Frankfurt`)
   - PostgreSQL Version: `15`
   - Cliquez sur "Create Database"

3. **Notez les informations de connexion**:
   - `Internal Database URL` (pour l'API)
   - `External Database URL` (pour les migrations SQL)
   - `Host`, `Port`, `Database`, `User`, `Password`

### Étape 2: Initialiser PostGIS et les tables

1. **Se connecter à la base de données**:
   ```bash
   # Utilisez l'External Database URL depuis le dashboard Render
   psql "postgresql://user:password@host:port/database"
   ```

2. **Exécuter le script SQL**:
   ```bash
   # Depuis le répertoire backend
   psql "postgresql://..." < migrations/002_render_init.sql
   ```

   Ou copiez-collez le contenu de `backend/migrations/002_render_init.sql` dans l'éditeur SQL de Render.

3. **Vérifier que PostGIS est activé**:
   ```sql
   SELECT PostGIS_version();
   ```

### Étape 3: Déployer l'API Backend sur Render

1. **Préparer le repository Git**:
   ```bash
   cd backend
   git init
   git add .
   git commit -m "Initial commit - Backend pour Render"
   ```

2. **Pousser sur GitHub** (ou GitLab/Bitbucket):
   ```bash
   git remote add origin https://github.com/votre-username/tshiakani-vtc-backend.git
   git push -u origin main
   ```

3. **Créer un nouveau Web Service sur Render**:
   - Cliquez sur "New +" → "Web Service"
   - Connectez votre repository GitHub
   - Sélectionnez le repository `tshiakani-vtc-backend`
   - Configuration:
     - **Name**: `tshiakani-vtc-api`
     - **Environment**: `Node`
     - **Build Command**: `npm install`
     - **Start Command**: `npm start`
     - **Plan**: **Free**

4. **Configurer les variables d'environnement**:
   Dans la section "Environment Variables", ajoutez:
   ```
   NODE_ENV=production
   PORT=10000
   DATABASE_URL=<Internal Database URL depuis la BD Render>
   DB_HOST=<host depuis DATABASE_URL>
   DB_PORT=<port depuis DATABASE_URL>
   DB_USER=<user depuis DATABASE_URL>
   DB_PASSWORD=<password depuis DATABASE_URL>
   DB_NAME=<database depuis DATABASE_URL>
   JWT_SECRET=<générez un secret aléatoire>
   CORS_ORIGIN=https://votre-dashboard.vercel.app
   STRIPE_SECRET_KEY=<votre clé secrète Stripe>
   STRIPE_CURRENCY=CDF
   STRIPE_PUBLISHABLE_KEY=<votre clé publique Stripe>
   ```

5. **Déployer**:
   - Cliquez sur "Create Web Service"
   - Render va automatiquement:
     - Cloner le repository
     - Installer les dépendances (`npm install`)
     - Démarrer le serveur (`npm start`)

6. **Vérifier le déploiement**:
   - Attendez que le statut passe à "Live"
   - Visitez: `https://votre-api.onrender.com/health`
   - Vous devriez voir: `{"status":"OK","database":"connected",...}`

### Étape 4: Tester l'endpoint `/api/chauffeurs`

```bash
curl https://votre-api.onrender.com/api/chauffeurs
```

Réponse attendue:
```json
{
  "success": true,
  "count": 0,
  "drivers": [],
  "filters": {...}
}
```

---

## II. Paiement (Stripe SDK)

### Étape 1: Créer un compte Stripe

1. **Inscrivez-vous sur [stripe.com](https://stripe.com)**

2. **Récupérez vos clés API**:
   - Allez dans [Dashboard → Developers → API keys](https://dashboard.stripe.com/test/apikeys)
   - **Publishable key** (commence par `pk_test_...`)
   - **Secret key** (commence par `sk_test_...`)

3. **Note**: En mode test, utilisez la carte de test:
   - Numéro: `4242 4242 4242 4242`
   - Date: n'importe quelle date future
   - CVC: n'importe quel 3 chiffres

### Étape 2: Configurer Stripe dans le Backend

1. **Installer le package Stripe** (si pas déjà fait):
   ```bash
   cd backend
   npm install stripe
   ```

2. **Ajouter les clés Stripe dans Render**:
   - Dans le dashboard Render → Votre Web Service → Environment
   - Ajoutez:
     ```
     STRIPE_SECRET_KEY=sk_test_...
     STRIPE_PUBLISHABLE_KEY=pk_test_...
     ```

### Étape 3: Intégrer Stripe dans l'application iOS

1. **Ajouter Stripe iOS SDK** (optionnel, pour une vraie intégration):
   - Ouvrez Xcode
   - File → Add Packages...
   - URL: `https://github.com/stripe/stripe-ios`
   - Version: Latest

2. **Configurer les clés dans l'app iOS**:
   - Ouvrez `Info.plist`
   - Ajoutez:
     ```xml
     <key>STRIPE_PUBLISHABLE_KEY</key>
     <string>pk_test_...</string>
     <key>API_BASE_URL</key>
     <string>https://votre-api.onrender.com/api</string>
     ```

3. **Utiliser la vue de paiement**:
   ```swift
   StripePaymentView(
       ride: ride,
       onPaymentSuccess: {
           // Paiement réussi
       },
       onPaymentCancel: {
           // Paiement annulé
       }
   )
   ```

### Étape 4: Tester le paiement

1. **Créer une course** via l'app iOS

2. **Tester le paiement**:
   - Utilisez la carte de test Stripe: `4242 4242 4242 4242`
   - Le backend va créer un PaymentIntent
   - Le paiement sera confirmé automatiquement

---

## III. Dashboard Admin (Vercel)

### Étape 1: Préparer le dashboard

1. **Naviguer vers le dossier dashboard**:
   ```bash
   cd admin-dashboard-vercel
   ```

2. **Installer les dépendances**:
   ```bash
   npm install
   ```

3. **Configurer l'URL de l'API**:
   - Créez `.env.local`:
     ```env
     API_BASE_URL=https://votre-api.onrender.com/api
     ```

### Étape 2: Déployer sur Vercel

#### Option A: Via l'interface Vercel (Recommandé)

1. **Aller sur [vercel.com](https://vercel.com)** et se connecter

2. **Importer un projet**:
   - Cliquez sur "Add New..." → "Project"
   - Importez depuis GitHub (ou poussez le code sur GitHub d'abord)

3. **Configurer le projet**:
   - Framework Preset: **Next.js**
   - Root Directory: `admin-dashboard-vercel`
   - Build Command: `npm run build`
   - Output Directory: `.next`

4. **Ajouter les variables d'environnement**:
   - Cliquez sur "Environment Variables"
   - Ajoutez:
     ```
     API_BASE_URL=https://votre-api.onrender.com/api
     ```

5. **Déployer**:
   - Cliquez sur "Deploy"
   - Attendez la fin du déploiement
   - Votre dashboard sera disponible à: `https://votre-dashboard.vercel.app`

#### Option B: Via Vercel CLI

1. **Installer Vercel CLI**:
   ```bash
   npm i -g vercel
   ```

2. **Se connecter**:
   ```bash
   vercel login
   ```

3. **Déployer**:
   ```bash
   cd admin-dashboard-vercel
   vercel
   ```

4. **Configurer les variables d'environnement**:
   ```bash
   vercel env add API_BASE_URL
   # Entrez: https://votre-api.onrender.com/api
   ```

### Étape 3: Vérifier le dashboard

1. **Visitez votre URL Vercel**: `https://votre-dashboard.vercel.app`

2. **Vous devriez voir**:
   - Statistiques des chauffeurs
   - Tableau avec la liste des chauffeurs
   - Bouton "Actualiser"

---

## Vérification finale

### Checklist de vérification

- [ ] **Base de données Render**:
  - [ ] PostgreSQL créé et actif
  - [ ] PostGIS activé (`SELECT PostGIS_version();`)
  - [ ] Tables créées (`users`, `rides`, `stripe_transactions`)

- [ ] **API Backend Render**:
  - [ ] Service déployé et "Live"
  - [ ] `/health` retourne `{"status":"OK","database":"connected"}`
  - [ ] `/api/chauffeurs` fonctionne
  - [ ] `/api/paiements/preauthorize` fonctionne (avec Stripe configuré)

- [ ] **Stripe**:
  - [ ] Compte créé
  - [ ] Clés API configurées dans Render
  - [ ] Clés configurées dans l'app iOS (Info.plist)
  - [ ] Paiement testé avec carte de test

- [ ] **Dashboard Vercel**:
  - [ ] Projet déployé
  - [ ] Variables d'environnement configurées
  - [ ] Dashboard affiche les chauffeurs depuis l'API Render

### Tests de bout en bout

1. **Test API → BD**:
   ```bash
   curl https://votre-api.onrender.com/api/chauffeurs
   ```

2. **Test Dashboard → API**:
   - Visitez le dashboard Vercel
   - Vérifiez que les chauffeurs s'affichent

3. **Test Paiement iOS → API → Stripe**:
   - Créez une course dans l'app iOS
   - Testez le paiement avec la carte `4242 4242 4242 4242`
   - Vérifiez que le PaymentIntent est créé dans Stripe Dashboard

---

## 🔧 Dépannage

### Problème: L'API ne se connecte pas à la base de données

**Solution**:
- Vérifiez que `DATABASE_URL` est correct dans Render
- Utilisez l'**Internal Database URL** (pas l'External)
- Vérifiez que PostGIS est activé: `CREATE EXTENSION IF NOT EXISTS postgis;`

### Problème: Le dashboard n'affiche pas les données

**Solution**:
- Vérifiez `API_BASE_URL` dans Vercel
- Vérifiez les CORS dans l'API Render (`CORS_ORIGIN`)
- Ouvrez la console du navigateur pour voir les erreurs

### Problème: Stripe retourne une erreur

**Solution**:
- Vérifiez que `STRIPE_SECRET_KEY` est correct (commence par `sk_test_` ou `sk_live_`)
- Vérifiez que vous utilisez les bonnes clés (test vs production)
- Consultez les logs Stripe dans le dashboard Stripe

---

## 📚 Ressources

- [Documentation Render](https://render.com/docs)
- [Documentation Vercel](https://vercel.com/docs)
- [Documentation Stripe iOS](https://stripe.com/docs/payments/accept-a-payment?platform=ios)
- [Documentation PostGIS](https://postgis.net/documentation/)

---

## ✅ Résumé des URLs

Après le déploiement, vous aurez:

- **API Backend**: `https://votre-api.onrender.com`
- **Dashboard Admin**: `https://votre-dashboard.vercel.app`
- **Base de données**: Gérée automatiquement par Render

Tous les services sont gratuits et prêts à recevoir les données géospatiales de votre application iOS ! 🎉

