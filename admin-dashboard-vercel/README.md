# Dashboard Tshiakani VTC - Vercel

Dashboard administrateur simple pour visualiser les chauffeurs et les courses, déployé sur Vercel.

## 🚀 Déploiement sur Vercel

### Option 1: Via l'interface Vercel

1. **Installer Vercel CLI** (optionnel):
   ```bash
   npm i -g vercel
   ```

2. **Se connecter à Vercel**:
   ```bash
   vercel login
   ```

3. **Déployer**:
   ```bash
   vercel
   ```

### Option 2: Via GitHub

1. **Pousser le code sur GitHub**

2. **Aller sur [vercel.com](https://vercel.com)**

3. **Importer le projet** depuis GitHub

4. **Configurer les variables d'environnement**:
   - `API_BASE_URL`: URL de votre API Render (ex: `https://votre-api.onrender.com/api`)

5. **Déployer**

## 📝 Configuration

Créez un fichier `.env.local` avec:

```env
API_BASE_URL=https://votre-api.onrender.com/api
```

## 🛠️ Développement local

```bash
npm install
npm run dev
```

Ouvrez [http://localhost:3000](http://localhost:3000)

## 📦 Build

```bash
npm run build
npm start
```

