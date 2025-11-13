# 🚀 Déployer sur un Projet Firebase Existant

## 📋 Projets Disponibles

Vous avez actuellement ces projets Firebase :
- `mwasi-cycle-professionnel`
- `optima-teach`

## ✅ Option 1: Utiliser mwasi-cycle-professionnel

### Étape 1: Modifier .firebaserc

```bash
cd "/Users/admin/Documents/Tshiakani VTC"
```

Modifiez le fichier `.firebaserc` :

```json
{
  "projects": {
    "default": "mwasi-cycle-professionnel"
  }
}
```

### Étape 2: Sélectionner le Projet

```bash
export PATH=~/.npm-global/bin:$PATH
firebase use mwasi-cycle-professionnel
```

### Étape 3: Déployer

```bash
firebase deploy --only hosting
```

**URL du dashboard** : `https://mwasi-cycle-professionnel.firebaseapp.com`

---

## ✅ Option 2: Créer le Projet tshiakani-vtc

### Étape 1: Aller sur Firebase Console

1. Allez sur https://console.firebase.google.com/
2. Cliquez sur **"Ajouter un projet"**
3. Nom : `tshiakani-vtc`
4. Project ID : `tshiakani-vtc`
5. Créez le projet

### Étape 2: Activer Hosting

1. Dans Firebase Console, allez dans **Hosting**
2. Cliquez sur **"Get started"**
3. Suivez les instructions

### Étape 3: Déployer

```bash
export PATH=~/.npm-global/bin:$PATH
firebase use tshiakani-vtc
firebase deploy --only hosting
```

**URL du dashboard** : `https://tshiakani-vtc.firebaseapp.com`

---

## 🎯 Recommandation

**Utilisez un projet existant temporairement** pour tester le déploiement, puis créez le projet `tshiakani-vtc` si nécessaire.

---

## 📝 Commandes Rapides

```bash
# Utiliser un projet existant
export PATH=~/.npm-global/bin:$PATH
firebase use mwasi-cycle-professionnel
firebase deploy --only hosting

# OU créer tshiakani-vtc dans Firebase Console puis
firebase use tshiakani-vtc
firebase deploy --only hosting
```

---

**Date** : $(date)

