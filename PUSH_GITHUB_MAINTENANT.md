# 🚀 Pousser sur GitHub - Instructions Rapides

## ✅ Étape 1 : Créer le Repository (déjà ouvert dans votre navigateur)

Dans la page GitHub qui s'est ouverte :
1. ✅ **Repository name** : `Tshiakani-VTC` (déjà rempli)
2. ✅ **Description** : `Backend et app iOS pour Tshiakani VTC` (déjà rempli)
3. ✅ **Visibility** : `Public` (déjà sélectionné)
4. ❌ **NE PAS** cocher "Add a README file"
5. Cliquer sur **"Create repository"**

## ✅ Étape 2 : Copier l'URL

Après la création, GitHub affichera une page avec des instructions.

**Copier l'URL** qui ressemble à :
```
https://github.com/VOTRE_USERNAME/Tshiakani-VTC.git
```

## ✅ Étape 3 : Exécuter ces Commandes

**Dans le terminal**, exécuter (remplacer `VOTRE_USERNAME` par votre nom d'utilisateur) :

```bash
cd "/Users/admin/Documents/Tshiakani VTC"

# Ajouter le remote GitHub (remplacer l'URL)
git remote add origin https://github.com/VOTRE_USERNAME/Tshiakani-VTC.git

# Renommer la branche en main (si nécessaire)
git branch -M main

# Pousser le code
git push -u origin main
```

## 🔐 Si GitHub Demande une Authentification

**Option 1 : Personal Access Token (Recommandé)**
1. Aller sur : https://github.com/settings/tokens
2. Cliquer "Generate new token (classic)"
3. Nom : `Tshiakani-VTC`
4. Cocher : `repo` (accès complet)
5. Cliquer "Generate token"
6. **COPIER LE TOKEN** (il ne sera affiché qu'une fois)
7. Lors du `git push`, utiliser :
   - **Username** : Votre nom d'utilisateur GitHub
   - **Password** : Le token que vous venez de copier

**Option 2 : Utiliser le Script Automatique**
```bash
./scripts/setup-github-auto.sh
```

## ✅ Vérification

Après le push, vérifier :
- Aller sur : https://github.com/VOTRE_USERNAME/Tshiakani-VTC
- Vérifier que le dossier `backend/` est présent
- Vérifier que `render.yaml` est présent

## 🚀 Prochaine Étape

Une fois le code sur GitHub :
1. Aller sur : https://dashboard.render.com
2. Suivre : `backend/GUIDE_COMPLET_RENDER.md`

---

**Temps estimé** : 3-5 minutes

