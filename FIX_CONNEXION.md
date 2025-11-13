# 🔧 Résoudre l'Erreur de Connexion

## Diagnostic

L'erreur de connexion signifie que le dashboard ne peut pas communiquer avec le backend.

## ✅ Solutions

### 1. Vérifier que MongoDB est démarré

**MongoDB doit être en cours d'exécution !**

```bash
# Vérifier si MongoDB est actif
pgrep -x mongod

# Si pas actif, démarrer MongoDB :
mongod
```

Ou si installé via Homebrew :
```bash
brew services start mongodb-community
```

### 2. Démarrer le Backend

Dans un terminal :
```bash
cd "/Users/admin/Documents/wewa taxi/backend"
npm run dev
```

Vous devriez voir :
```
✅ Connecté à MongoDB
🚀 Serveur démarré sur le port 3000
```

### 3. Vérifier que le backend répond

Dans un autre terminal :
```bash
curl http://localhost:3000/health
```

Devrait retourner : `{"status":"OK",...}`

### 4. Vérifier la console du navigateur

1. Ouvrez http://localhost:3001
2. Appuyez sur **F12** (ou Cmd+Option+I sur Mac)
3. Allez dans l'onglet **Console**
4. Regardez les erreurs en rouge

### 5. Vérifier l'URL de l'API

Le dashboard doit pointer vers : `http://localhost:3000/api`

Vérifiez dans `admin-dashboard/src/services/api.js` :
```javascript
baseURL: import.meta.env.VITE_API_URL || 'http://localhost:3000/api'
```

## 🔍 Erreurs courantes

### "Network Error" ou "Failed to fetch"
→ Le backend n'est pas démarré ou MongoDB n'est pas actif

### "Cannot connect to MongoDB"
→ Démarrez MongoDB : `mongod`

### "Port 3000 already in use"
→ Arrêtez le processus : `lsof -ti:3000 | xargs kill -9`

### "CORS error"
→ Vérifiez que le backend autorise `http://localhost:3001`

## 📋 Checklist

- [ ] MongoDB est démarré (`mongod`)
- [ ] Backend est démarré (`npm run dev` dans backend/)
- [ ] Backend répond (`curl http://localhost:3000/health`)
- [ ] Dashboard est démarré (`npm run dev` dans admin-dashboard/)
- [ ] Pas d'erreurs dans la console du navigateur (F12)

## 🆘 Si ça ne marche toujours pas

1. Regardez les logs du backend dans le terminal
2. Regardez les erreurs dans la console du navigateur (F12)
3. Vérifiez que les ports 3000 et 3001 ne sont pas utilisés par d'autres applications

