# 📋 Instructions - Configuration Dashboard pour Production

## ⚠️ Action Requise

Le dashboard admin nécessite un fichier `.env.production` pour fonctionner correctement en production.

## 📝 Étapes

### 1. Créer le fichier `.env.production`

Dans le répertoire `admin-dashboard/`, créez un fichier `.env.production` avec le contenu suivant:

```env
# Configuration pour la production
# URL du backend Cloud Run
VITE_API_URL=https://tshiakani-vtc-backend-418102154417.us-central1.run.app/api

# Clé API Admin (pour les routes /api/admin/*)
VITE_ADMIN_API_KEY=aadf3378b1d5eca1c38398e5ee31ad6f978747762f9d546847173eb54e7637d8
```

### 2. Commandes

```bash
cd admin-dashboard
cat > .env.production << 'EOF'
# Configuration pour la production
# URL du backend Cloud Run
VITE_API_URL=https://tshiakani-vtc-backend-418102154417.us-central1.run.app/api

# Clé API Admin (pour les routes /api/admin/*)
VITE_ADMIN_API_KEY=aadf3378b1d5eca1c38398e5ee31ad6f978747762f9d546847173eb54e7637d8
EOF
```

### 3. Vérification

Après avoir créé le fichier, reconstruisez le dashboard:

```bash
cd admin-dashboard
npm run build
```

Le fichier `.env.production` sera utilisé automatiquement lors du build de production.

## ✅ Statut Actuel

- ✅ **Développement**: Le proxy Vite fonctionne correctement
- ⚠️ **Production**: Nécessite le fichier `.env.production`

## 📚 Documentation

Voir `RAPPORT_VERIFICATION_CONNEXION_FRONTEND_BACKEND.md` pour plus de détails.

