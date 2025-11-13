# ⚡ Déploiement Rapide sur Render - Mode Automatique

## 🚀 Lancer le Script Automatique

```bash
cd "/Users/admin/Documents/Tshiakani VTC/backend"
./scripts/deploy-render-automatic.sh
```

Le script va :
1. ✅ Vérifier que le code est sur GitHub
2. 🌐 Ouvrir Render Dashboard dans votre navigateur
3. 📋 Vous guider étape par étape
4. ⏳ Attendre vos confirmations

## 📋 Checklist Rapide

### ✅ Prérequis (Vérifiés automatiquement)
- [x] Code sur GitHub : `brunokarume2-hue/Tshiakani-VTC`
- [x] Repository accessible
- [x] Fichiers de configuration prêts

### 📝 Dans Render Dashboard

#### 1. PostgreSQL Database
- Name : `tshiakani-vtc-db`
- Database : `tshiakani_vtc`
- User : `tshiakani_user`
- Version : `15`
- Plan : `Free`

#### 2. Web Service
- Name : `tshiakani-vtc-backend`
- Environment : `Node`
- Repository : `brunokarume2-hue/Tshiakani-VTC`
- Branch : `main`
- **Root Directory** : `backend` ⚠️ **IMPORTANT**
- Build Command : `npm ci --only=production`
- Start Command : `node server.postgres.js`
- Plan : `Free`

#### 3. Variables d'Environnement
Voir `RENDER_ENV_VARS.txt` ou copier depuis le script

#### 4. Lier Database
- Link Database → `tshiakani-vtc-db`

#### 5. Déployer
- Create Web Service
- Attendre 5-10 minutes

## 🧪 Test Après Déploiement

```bash
curl https://tshiakani-vtc-backend.onrender.com/health
```

## 📱 Mise à Jour iOS

Dans `Info.plist` :
- `API_BASE_URL` = `https://tshiakani-vtc-backend.onrender.com/api`
- `WS_BASE_URL` = `https://tshiakani-vtc-backend.onrender.com`

---

**Temps total** : 15-20 minutes
**Coût** : Gratuit (plan Free)

