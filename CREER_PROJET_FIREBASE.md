# 🔥 Créer le Projet Firebase - tshiakani-vtc

## ⚠️ Situation

Le projet Firebase `tshiakani-vtc` n'existe pas encore dans votre compte Firebase.

## ✅ Solution: Créer le Projet Firebase

### Option 1: Créer via Firebase Console (Recommandé)

1. **Aller sur Firebase Console** :
   - URL : https://console.firebase.google.com/
   - Connectez-vous avec votre compte Google

2. **Créer un nouveau projet** :
   - Cliquez sur **"Ajouter un projet"** ou **"Add project"**
   - Nom du projet : `tshiakani-vtc`
   - Project ID : `tshiakani-vtc` (sera généré automatiquement)
   - Cliquez sur **"Continuer"**

3. **Configurer Google Analytics** (optionnel) :
   - Activez ou désactivez Google Analytics selon vos besoins
   - Cliquez sur **"Créer le projet"**

4. **Attendre la création** :
   - Firebase va créer le projet (quelques secondes)
   - Cliquez sur **"Continuer"** une fois terminé

5. **Activer Firebase Hosting** :
   - Dans le menu de gauche, cliquez sur **"Hosting"**
   - Cliquez sur **"Get started"** ou **"Commencer"**
   - Suivez les instructions pour initialiser Hosting

### Option 2: Créer via Firebase CLI

```bash
# Créer le projet Firebase
firebase projects:create tshiakani-vtc --display-name "Tshiakani VTC"

# Sélectionner le projet
firebase use tshiakani-vtc
```

**Note** : Cette commande nécessite les permissions appropriées dans Firebase.

---

## 🔧 Après la Création du Projet

Une fois le projet créé, vous pouvez déployer :

```bash
# Vérifier que le projet est sélectionné
firebase use tshiakani-vtc

# Déployer le dashboard
firebase deploy --only hosting
```

---

## 🔄 Alternative: Utiliser un Projet Existant

Si vous préférez utiliser un des projets existants (`mwasi-cycle-professionnel` ou `optima-teach`), vous pouvez :

### Option A: Modifier .firebaserc

Modifiez le fichier `.firebaserc` :

```json
{
  "projects": {
    "default": "mwasi-cycle-professionnel"
  }
}
```

Puis déployez :

```bash
firebase use mwasi-cycle-professionnel
firebase deploy --only hosting
```

### Option B: Utiliser un Alias

```bash
# Ajouter un alias pour un projet existant
firebase use --add mwasi-cycle-professionnel

# Sélectionner l'alias
firebase use mwasi-cycle-professionnel

# Déployer
firebase deploy --only hosting
```

---

## ✅ Vérification

Après avoir créé ou sélectionné le projet :

```bash
# Vérifier le projet actuel
firebase use

# Vérifier les projets disponibles
firebase projects:list

# Déployer
firebase deploy --only hosting
```

---

## 📝 URLs après Déploiement

Une fois déployé, le dashboard sera accessible sur :
- `https://tshiakani-vtc.firebaseapp.com`
- `https://tshiakani-vtc.web.app`

Si vous utilisez un autre projet, les URLs seront différentes :
- `https://[project-id].firebaseapp.com`
- `https://[project-id].web.app`

---

## 🆘 Dépannage

### Erreur: "Failed to get Firebase project"

**Solution** : Vérifiez que le projet existe dans Firebase Console ou créez-le.

### Erreur: "Permission denied"

**Solution** : Vérifiez que vous avez les permissions nécessaires pour créer des projets Firebase.

### Erreur: "Project ID already exists"

**Solution** : Le projet existe peut-être déjà. Vérifiez dans Firebase Console.

---

**Date** : $(date)
**Statut** : ⚠️ Projet Firebase à créer

