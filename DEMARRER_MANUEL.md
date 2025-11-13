# 🚀 Démarrage Manuel du Dashboard

## Si Node.js est installé mais pas dans le PATH

### Trouver Node.js

Essayez ces commandes dans votre terminal :

```bash
# Option 1
/usr/local/bin/node --version

# Option 2 (si installé via Homebrew sur Mac M1/M2)
/opt/homebrew/bin/node --version

# Option 3 (si installé via NVM)
~/.nvm/versions/node/*/bin/node --version

# Option 4 - Chercher Node.js
which node
whereis node
```

### Une fois Node.js trouvé

1. **Ouvrez 2 terminaux séparés**

2. **Terminal 1 - Backend :**
```bash
cd "/Users/admin/Documents/wewa taxi/backend"

# Si node_modules n'existe pas
npm install

# Démarrer le backend
npm run dev
```

3. **Terminal 2 - Dashboard :**
```bash
cd "/Users/admin/Documents/wewa taxi/admin-dashboard"

# Si node_modules n'existe pas
npm install

# Démarrer le dashboard
npm run dev
```

4. **Ouvrez votre navigateur :**
   - Allez à : **http://localhost:3001**

5. **Connectez-vous :**
   - Numéro : `+243900000000`
   - Mot de passe : (vide)

## Si vous voyez des erreurs

### Erreur "Cannot find module"
```bash
cd backend
rm -rf node_modules package-lock.json
npm install

cd ../admin-dashboard
rm -rf node_modules package-lock.json
npm install
```

### Erreur "Port already in use"
```bash
# Trouver et arrêter le processus
lsof -ti:3000 | xargs kill -9
lsof -ti:3001 | xargs kill -9
```

### Erreur MongoDB
Assurez-vous que MongoDB est démarré :
```bash
mongod
```

## Alternative : Utiliser un IDE

Si vous utilisez VS Code ou un autre IDE :
1. Ouvrez le dossier `backend` dans un terminal intégré
2. Exécutez `npm install` puis `npm run dev`
3. Ouvrez le dossier `admin-dashboard` dans un autre terminal
4. Exécutez `npm install` puis `npm run dev`

