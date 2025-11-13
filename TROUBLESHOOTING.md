# 🔧 Guide de Dépannage - Dashboard Admin

## Problèmes courants et solutions

### ❌ "npm: command not found"

**Solution :**
1. Installez Node.js depuis https://nodejs.org
2. Téléchargez la version LTS (Long Term Support)
3. Redémarrez votre terminal après l'installation
4. Vérifiez avec : `node --version` et `npm --version`

### ❌ "Port 3000 already in use"

**Solution :**
```bash
# Trouver le processus utilisant le port 3000
lsof -ti:3000

# Arrêter le processus
kill -9 $(lsof -ti:3000)

# Ou changer le port dans backend/.env
PORT=3001
```

### ❌ "Port 3001 already in use"

**Solution :**
```bash
# Trouver le processus utilisant le port 3001
lsof -ti:3001

# Arrêter le processus
kill -9 $(lsof -ti:3001)

# Ou changer le port dans admin-dashboard/vite.config.js
server: {
  port: 3002,  // Au lieu de 3001
}
```

### ❌ "Cannot connect to MongoDB"

**Solution :**
1. Vérifiez que MongoDB est installé : `mongod --version`
2. Démarrez MongoDB :
   ```bash
   mongod
   ```
3. Vérifiez la connexion dans `backend/.env` :
   ```
   MONGODB_URI=mongodb://localhost:27017/wewa_taxi
   ```

### ❌ "Error: Cannot find module"

**Solution :**
```bash
# Réinstaller les dépendances
cd backend
rm -rf node_modules package-lock.json
npm install

cd ../admin-dashboard
rm -rf node_modules package-lock.json
npm install
```

### ❌ Le dashboard affiche une erreur de connexion

**Vérifications :**
1. Le backend est-il démarré ? Testez : `curl http://localhost:3000/health`
2. Vérifiez la console du navigateur (F12) pour les erreurs
3. Vérifiez les logs du backend dans le terminal

### ❌ "CORS error" dans le navigateur

**Solution :**
Vérifiez `backend/server.js` :
```javascript
app.use(cors({
  origin: process.env.CORS_ORIGIN || "http://localhost:3001",
  credentials: true
}));
```

### ❌ Le dashboard ne se charge pas

**Vérifications :**
1. Ouvrez la console du navigateur (F12)
2. Vérifiez l'onglet "Network" pour voir les requêtes
3. Vérifiez l'onglet "Console" pour les erreurs JavaScript

### ❌ Erreur de connexion à l'API

**Solution :**
1. Vérifiez que l'URL de l'API est correcte dans `admin-dashboard/src/services/api.js`
2. Par défaut : `http://localhost:3000/api`
3. Créez un fichier `.env` dans `admin-dashboard/` :
   ```
   VITE_API_URL=http://localhost:3000/api
   ```

## 📋 Checklist de démarrage

- [ ] Node.js installé (`node --version`)
- [ ] npm installé (`npm --version`)
- [ ] MongoDB installé et démarré
- [ ] Dépendances backend installées (`cd backend && npm install`)
- [ ] Dépendances dashboard installées (`cd admin-dashboard && npm install`)
- [ ] Backend démarré (`cd backend && npm run dev`)
- [ ] Dashboard démarré (`cd admin-dashboard && npm run dev`)
- [ ] Backend accessible (`curl http://localhost:3000/health`)
- [ ] Dashboard accessible (http://localhost:3001)

## 🆘 Obtenir de l'aide

Si le problème persiste, fournissez :
1. Le message d'erreur exact
2. Les logs du backend (terminal où `npm run dev` est lancé)
3. Les erreurs de la console du navigateur (F12)
4. La version de Node.js (`node --version`)

