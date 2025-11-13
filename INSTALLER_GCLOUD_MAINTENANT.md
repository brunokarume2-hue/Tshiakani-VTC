# 🚀 Installer gcloud CLI - Instructions Rapides

## ✅ Option la Plus Simple (Recommandée)

### Étape 1: Installer via le Script Officiel

```bash
# Télécharger et installer Google Cloud SDK
curl https://sdk.cloud.google.com | bash
```

### Étape 2: Redémarrer le Terminal

```bash
# Recharger la configuration du shell
source ~/.zshrc

# OU simplement fermer et rouvrir le terminal
```

### Étape 3: Initialiser gcloud

```bash
# Se connecter à Google Cloud
gcloud auth login

# Configurer le projet
gcloud config set project tshiakani-vtc
```

### Étape 4: Vérifier l'Installation

```bash
# Vérifier la version
gcloud --version

# Vérifier la configuration
gcloud config list
```

---

## 🔄 Alternative: Installation via Homebrew

Si vous avez Homebrew installé :

```bash
# Installer Homebrew (si pas installé)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Installer gcloud
brew install --cask google-cloud-sdk

# Initialiser
gcloud init
```

---

## 🎯 Après l'Installation

Une fois gcloud installé et configuré :

1. **Déployer le backend** :
   ```bash
   cd "/Users/admin/Documents/Tshiakani VTC/backend"
   ./scripts/deploy-cloud-run.sh
   ```

2. **Vérifier le déploiement** :
   ```bash
   curl https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/health
   ```

3. **Tester la route admin/login** :
   ```bash
   curl -X POST https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/api/auth/admin/login \
     -H "Content-Type: application/json" \
     -d '{"phoneNumber":"+243900000000"}'
   ```

---

## 📝 Documentation Complète

Pour plus de détails, consultez :
- `INSTALLATION_GCLOUD_DETAILLEE.md` - Guide détaillé
- `installer-gcloud.sh` - Script d'installation automatique

---

**Date** : $(date)

