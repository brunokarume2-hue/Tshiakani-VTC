# 🚀 Déploiement Railway - Mode Simple

## ✅ Tout est prêt !

- ✅ Connection string Supabase configurée
- ✅ Variables d'environnement préparées
- ✅ Code sur GitHub : brunokarume2-hue/Tshiakani-VTC
- ✅ Scripts de déploiement créés

## 🎯 Option 1 : Via Interface Web (RECOMMANDÉ - 5 minutes)

1. **Aller sur** : https://railway.app/new
2. **Cliquer** : "Deploy from GitHub repo"
3. **Sélectionner** : brunokarume2-hue/Tshiakani-VTC
4. **Settings → Root Directory** : `backend`
5. **Settings → Start Command** : `node server.postgres.js`
6. **Variables** : Copier depuis `backend/RAILWAY_VARIABLES_COMPLETE.txt`
7. **Railway déploiera automatiquement !**

## 🎯 Option 2 : Via CLI (Après connexion)

```bash
cd backend
./scripts/deploy-railway-final-simple.sh
```

Le script vous guidera pour la connexion, puis tout sera automatique.

---

**Temps total** : 5 minutes
**Coût** : Gratuit
