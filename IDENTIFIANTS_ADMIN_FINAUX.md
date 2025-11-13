# 🔐 Identifiants Admin Finaux - Tshiakani VTC

## ✅ Configuration Complète

Le système d'authentification admin a été mis à jour avec un mot de passe sécurisé.

---

## 🔑 Identifiants de Connexion

**Numéro de téléphone :**
```
+243820098808
```

**Mot de passe :**
```
Nyota9090
```

---

## 🚀 Accès au Dashboard

**URL du Dashboard :**
```
https://tshiakani-vtc-99cea.web.app
```

**URL du Backend :**
```
https://tshiakani-vtc-backend-418102154417.us-central1.run.app
```

---

## 🔧 Comment Se Connecter

1. Ouvrez votre navigateur et allez à **https://tshiakani-vtc-99cea.web.app**
2. Sur la page de connexion, entrez :
   - **Numéro de téléphone :** `+243820098808`
   - **Mot de passe :** `Nyota9090`
3. Cliquez sur **"Se connecter"**

---

## 📋 Informations du Compte Admin

- **Nom :** Admin
- **Numéro :** 243820098808
- **Rôle :** admin
- **Statut :** Vérifié (isVerified: true)
- **Mot de passe :** Nyota9090 (hashé avec bcrypt dans la base de données)

---

## 🔒 Sécurité

- ✅ Le mot de passe est **obligatoire** pour la connexion
- ✅ Le mot de passe est hashé avec **bcrypt** (10 rounds)
- ✅ Le mot de passe n'est jamais stocké en clair
- ✅ Le champ password n'est pas inclus par défaut dans les requêtes (select: false)

---

## 🛠️ Réinitialisation du Mot de Passe

Si vous devez réinitialiser le mot de passe, exécutez :

```bash
cd backend
node scripts/create-admin.js
```

Ce script mettra à jour le mot de passe du compte admin.

---

## 📝 Notes

- Le numéro de téléphone est normalisé automatiquement (espaces et caractères spéciaux supprimés)
- Le format accepté : `+243820098808`, `243820098808`, ou `+243 820 098 808`
- Le mot de passe est sensible à la casse (majuscules/minuscules)

---

## ✅ Modifications Apportées

1. ✅ Ajout du champ `password` à l'entité User
2. ✅ Migration SQL pour ajouter la colonne password
3. ✅ Modification de la route `/api/auth/admin/login` pour vérifier le mot de passe
4. ✅ Création du script `create-admin.js` pour gérer le compte admin
5. ✅ Mise à jour du dashboard avec le nouveau numéro
6. ✅ Documentation mise à jour

---

**Date de création :** 2025-01-15  
**Statut :** ✅ Actif et Sécurisé

