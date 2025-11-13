# 🔧 Résolution du Problème de Projet GCP

## 🚨 Problème Identifié

Le projet GCP `tshiakani-vtc` n'est pas accessible avec les permissions actuelles.

**Erreur** :
```
ERROR: [brunokarume@gmail.com] does not have permission to access projects instance [tshiakani-vtc]
```

---

## ✅ Solutions

### Solution 1 : Utiliser un Projet Existant

Si vous avez accès à un projet existant, configurez-le :

```bash
# Lister les projets disponibles
gcloud projects list

# Configurer le projet
gcloud config set project VOTRE_PROJET_ID

# Exporter la variable d'environnement
export GCP_PROJECT_ID=VOTRE_PROJET_ID
```

**Exemple** :
```bash
gcloud config set project formal-truth-471400-i3
export GCP_PROJECT_ID=formal-truth-471400-i3
```

---

### Solution 2 : Créer un Nouveau Projet

Créer un nouveau projet avec un nom unique :

```bash
# Créer un nouveau projet (remplacez par un nom unique)
gcloud projects create tshiakani-vtc-YOUR-ID \
  --name="Tshiakani VTC"

# Configurer le projet
gcloud config set project tshiakani-vtc-YOUR-ID

# Activer la facturation (si nécessaire)
gcloud beta billing projects link tshiakani-vtc-YOUR-ID \
  --billing-account=YOUR_BILLING_ACCOUNT_ID
```

**Exemple** :
```bash
gcloud projects create tshiakani-vtc-$(date +%s) \
  --name="Tshiakani VTC"
```

---

### Solution 3 : Demander les Permissions

Si le projet `tshiakani-vtc` existe et que vous devez y accéder :

1. **Contacter l'administrateur** du projet pour obtenir les permissions
2. **Demander le rôle** `Owner` ou `Editor` sur le projet
3. **Vérifier les permissions** une fois accordées :

```bash
gcloud projects get-iam-policy tshiakani-vtc
```

---

## 🔧 Configuration du Script

Une fois le projet configuré, vous pouvez exécuter le script avec la variable d'environnement :

```bash
# Exporter la variable d'environnement
export GCP_PROJECT_ID=VOTRE_PROJET_ID

# Exécuter le script
./scripts/executer-actions-suivantes.sh
```

---

## 📋 Vérification

Vérifier que tout est configuré correctement :

```bash
# Vérifier le projet actuel
gcloud config get-value project

# Vérifier les permissions
gcloud projects describe $(gcloud config get-value project)

# Vérifier la facturation
gcloud billing projects describe $(gcloud config get-value project)
```

---

## 🎯 Prochaines Étapes

1. **Choisir une solution** (utiliser un projet existant ou créer un nouveau)
2. **Configurer le projet** avec `gcloud config set project`
3. **Exporter la variable** `GCP_PROJECT_ID` si nécessaire
4. **Réexécuter le script** : `./scripts/executer-actions-suivantes.sh`

---

**Date de création**: 2025-01-15  
**Version**: 1.0.0  
**Statut**: Guide de résolution du problème de projet

