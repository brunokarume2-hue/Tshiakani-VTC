# 📊 Statut des Services

## ✅ Dashboard Admin
**Status** : ✅ Démarré et accessible
**URL** : http://localhost:3001
**Port** : 3001

## ⚠️ Backend API
**Status** : En cours de démarrage...
**URL** : http://localhost:3000
**Port** : 3000

### Si le backend ne démarre pas :

1. **Vérifiez MongoDB** :
   ```bash
   mongod
   ```
   MongoDB doit être démarré pour que le backend fonctionne.

2. **Vérifiez les logs** :
   Regardez dans le terminal où vous avez lancé `npm run dev` dans le dossier `backend`

3. **Erreur courante** :
   - "Cannot connect to MongoDB" → Démarrez MongoDB
   - "Port 3000 already in use" → Arrêtez le processus : `lsof -ti:3000 | xargs kill -9`

## 🔗 Accès au Dashboard

1. Ouvrez votre navigateur
2. Allez à : **http://localhost:3001**
3. Connectez-vous avec :
   - Numéro : `+243900000000`
   - Mot de passe : (vide)

**Note** : Le dashboard peut fonctionner même si le backend n'est pas encore démarré, mais vous ne pourrez pas vous connecter tant que le backend n'est pas prêt.

