# 🚨 Problème de Facturation GCP

## ❌ Problème Identifié

Le projet GCP `formal-truth-471400-i3` ne peut pas créer de nouvelles ressources car :

1. **Le compte de facturation n'est pas lié au projet** (`billingEnabled: false`)
2. **Le quota de facturation est dépassé** pour le compte `01A0D2-26A848-5DC5B9`

**Erreur** :
```
ERROR: Cloud billing quota exceeded
```

---

## ✅ Solutions

### Solution 1 : Augmenter le Quota de Facturation (Recommandé)

1. **Contacter le support Google Cloud** pour augmenter le quota :
   - https://support.google.com/code/contact/billing_quota_increase
   - Expliquer que vous avez besoin de créer des instances Cloud SQL et Memorystore

2. **Vérifier les limites** dans la console GCP :
   - https://console.cloud.google.com/iam-admin/quotas

---

### Solution 2 : Utiliser un Autre Compte de Facturation

Si vous avez accès à un autre compte de facturation :

```bash
# Lister les comptes de facturation disponibles
gcloud billing accounts list

# Lier le projet à un autre compte
gcloud billing projects link formal-truth-471400-i3 \
  --billing-account=ACCOUNT_ID
```

---

### Solution 3 : Créer un Nouveau Projet avec Facturation

Créer un nouveau projet et le lier à un compte de facturation valide :

```bash
# Créer un nouveau projet
gcloud projects create tshiakani-vtc-new \
  --name="Tshiakani VTC"

# Lier le compte de facturation
gcloud billing projects link tshiakani-vtc-new \
  --billing-account=01A0D2-26A848-5DC5B9

# Configurer le projet
gcloud config set project tshiakani-vtc-new
export GCP_PROJECT_ID=tshiakani-vtc-new

# Réexécuter le script
./scripts/executer-actions-suivantes.sh --yes
```

---

### Solution 4 : Utiliser un Projet avec Facturation Active

Si vous avez accès à un autre projet avec facturation active :

```bash
# Lister les projets
gcloud projects list

# Configurer le projet
gcloud config set project AUTRE_PROJET_ID
export GCP_PROJECT_ID=AUTRE_PROJET_ID

# Réexécuter le script
./scripts/executer-actions-suivantes.sh --yes
```

---

## 🔧 Vérification de la Facturation

Vérifier l'état de la facturation :

```bash
# Vérifier la facturation du projet
gcloud billing projects describe formal-truth-471400-i3

# Lister les comptes de facturation
gcloud billing accounts list

# Vérifier les quotas
gcloud compute project-info describe --project=formal-truth-471400-i3
```

---

## 📋 Actions Immédiates

1. **Vérifier les quotas** dans la console GCP
2. **Contacter le support** pour augmenter le quota si nécessaire
3. **Ou utiliser un autre projet** avec facturation active
4. **Réexécuter le script** une fois le problème résolu

---

## 🎯 Prochaines Étapes

Une fois le problème de facturation résolu :

```bash
# Configurer le projet
gcloud config set project VOTRE_PROJET_ID
export GCP_PROJECT_ID=VOTRE_PROJET_ID

# Réexécuter le script
./scripts/executer-actions-suivantes.sh --yes
```

---

**Date de création**: 2025-01-15  
**Version**: 1.0.0  
**Statut**: Guide de résolution du problème de facturation

