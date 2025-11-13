# ✅ Google Cloud CLI - Installation Réussie

## 📋 Résumé

Google Cloud CLI a été installé avec succès sur votre système macOS.

### Installation

- ✅ **Google Cloud SDK 546.0.0** installé
- ✅ **Répertoire**: `~/google-cloud-sdk`
- ✅ **PATH configuré** dans `~/.zshrc`
- ✅ **gcloud fonctionnel**

---

## 🔧 Configuration Requise

### 1. Recharger la Configuration

```bash
# Recharger la configuration du shell
source ~/.zshrc

# Ou simplement fermer et rouvrir le terminal
```

### 2. Se Connecter à Google Cloud

```bash
# Se connecter avec votre compte Google Cloud
gcloud auth login

# Cela ouvrira une fenêtre du navigateur
# Connectez-vous avec votre compte Google Cloud
```

### 3. Configurer le Projet

**Important**: Vérifiez d'abord quel est le bon projet ID.

```bash
# Lister les projets disponibles
gcloud projects list

# Configurer le projet correct
gcloud config set project VOTRE_PROJET_ID
```

**Projet possible**: `tshiakani-vtc` ou `tshiakani-vtc-99cea` (selon Firebase)

---

## 🚀 Déployer le Backend

Une fois gcloud configuré :

```bash
cd "/Users/admin/Documents/Tshiakani VTC/backend"

# Déployer le backend
./scripts/deploy-cloud-run.sh
```

---

## ⚠️ Notes Importantes

### Projet ID

Le projet ID peut être :
- `tshiakani-vtc` (projet principal)
- `tshiakani-vtc-99cea` (ID Firebase)
- Un autre ID selon votre configuration Google Cloud

Vérifiez dans Google Cloud Console quel est le bon projet ID.

### Permissions

Assurez-vous d'avoir les permissions suivantes :
- **Cloud Run Admin**
- **Service Account User**
- **Cloud Build Service Account**

### APIs Requises

Les APIs suivantes doivent être activées :
- **Cloud Run API**
- **Cloud Build API**
- **Container Registry API** ou **Artifact Registry API**
- **Cloud Resource Manager API**

---

## 🆘 Dépannage

### Erreur: "API not enabled"

Activez l'API manquante :
```bash
# Activer Cloud Run API
gcloud services enable run.googleapis.com

# Activer Cloud Build API
gcloud services enable cloudbuild.googleapis.com
```

### Erreur: "Permission denied"

Vérifiez vos permissions dans Google Cloud Console :
1. Allez dans **IAM & Admin** > **IAM**
2. Vérifiez que vous avez les rôles nécessaires

### Erreur: "Project not found"

Vérifiez le projet ID :
```bash
# Lister les projets
gcloud projects list

# Configurer le bon projet
gcloud config set project VOTRE_PROJET_ID
```

---

## 📝 Prochaines Étapes

1. ✅ **gcloud installé** - Terminé
2. ⏳ **Se connecter** - `gcloud auth login`
3. ⏳ **Configurer le projet** - `gcloud config set project`
4. ⏳ **Déployer le backend** - `./scripts/deploy-cloud-run.sh`
5. ⏳ **Tester la route admin/login**

---

**Date** : $(date)
**Statut** : ✅ Installé, en attente de configuration

