# 📤 Instructions pour Pousser sur GitHub

## ✅ Étape 1 : Créer le Repository sur GitHub

1. **Ouvrir Chrome** et aller sur : https://github.com/new
2. **Repository name** : `Tshiakani-VTC`
3. **Description** (optionnel) : `Backend et app iOS pour Tshiakani VTC`
4. **Visibility** : 
   - ✅ **Public** (recommandé pour Render gratuit)
   - ⚠️ **Private** (nécessite un plan payant Render)
5. **NE PAS** cocher :
   - ❌ Add a README file
   - ❌ Add .gitignore
   - ❌ Choose a license
6. Cliquer sur **"Create repository"**

## ✅ Étape 2 : Copier l'URL du Repository

Après la création, GitHub affichera une page avec des instructions.

**Copier l'URL** qui ressemble à :
```
https://github.com/VOTRE_USERNAME/Tshiakani-VTC.git
```

## ✅ Étape 3 : Dans le Terminal

Exécuter ces commandes (remplacer `VOTRE_USERNAME` par votre nom d'utilisateur GitHub) :

```bash
cd "/Users/admin/Documents/Tshiakani VTC"

# Ajouter le remote GitHub
git remote add origin https://github.com/VOTRE_USERNAME/Tshiakani-VTC.git

# Renommer la branche en main (si nécessaire)
git branch -M main

# Pousser le code
git push -u origin main
```

## 🔐 Authentification GitHub

Si GitHub demande une authentification :
- **Option 1** : Utiliser un **Personal Access Token** (recommandé)
  - Aller sur : https://github.com/settings/tokens
  - Cliquer "Generate new token (classic)"
  - Cocher `repo` (accès complet aux repositories)
  - Copier le token
  - Utiliser le token comme mot de passe lors du push

- **Option 2** : Utiliser **GitHub CLI**
  ```bash
  gh auth login
  ```

## ✅ Étape 4 : Vérifier

Après le push, vérifier sur GitHub :
- Aller sur : https://github.com/VOTRE_USERNAME/Tshiakani-VTC
- Vérifier que les fichiers `backend/` sont présents

## 🚀 Prochaine Étape

Une fois le code sur GitHub :
1. Aller sur https://dashboard.render.com
2. Suivre `backend/GUIDE_COMPLET_RENDER.md`

---

**Temps estimé** : 5 minutes

