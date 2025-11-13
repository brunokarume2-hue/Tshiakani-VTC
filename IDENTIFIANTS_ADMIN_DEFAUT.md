# 🔐 Identifiants Admin par Défaut - Tshiakani VTC

## ✅ Admin Créé avec Succès

Un compte administrateur par défaut a été créé dans la base de données.

## 🔑 Identifiants de Connexion

**Numéro de téléphone :**
```
+243820098808
```

**Mot de passe :**
```
Nyota9090
```

## 🚀 Accès au Dashboard

1. **URL du Dashboard :** https://tshiakani-vtc-99cea.web.app
2. **URL du Backend :** https://tshiakani-vtc-backend-418102154417.us-central1.run.app

## 📋 Informations du Compte Admin

- **Nom :** Admin
- **Numéro :** 243820098808
- **Rôle :** admin
- **Statut :** Vérifié (isVerified: true)
- **Mot de passe :** Nyota9090 (hashé avec bcrypt)

## 🔧 Comment Se Connecter

1. Ouvrez votre navigateur et allez à **https://tshiakani-vtc-99cea.web.app**
2. Sur la page de connexion, entrez :
   - **Numéro de téléphone :** `+243820098808`
   - **Mot de passe :** `Nyota9090`
3. Cliquez sur **"Se connecter"**

## ✅ Vérification

Pour vérifier que l'admin existe dans la base de données :

```bash
cd backend
node -e "
require('dotenv').config();
const AppDataSource = require('./config/database');
const User = require('./entities/User');

(async () => {
  await AppDataSource.initialize();
  const userRepository = AppDataSource.getRepository(User);
  const admin = await userRepository.findOne({ where: { role: 'admin' } });
  console.log('Admin:', admin);
  await AppDataSource.destroy();
})();
"
```

## 📝 Notes

- Le mot de passe est maintenant **obligatoire** pour la sécurité
- Le numéro de téléphone est normalisé automatiquement (espaces et caractères spéciaux supprimés)
- Le mot de passe est hashé avec bcrypt avant d'être stocké dans la base de données
- Si vous oubliez le mot de passe, vous pouvez le réinitialiser en exécutant le script `backend/scripts/create-admin.js`

---

**Date de création :** $(date)
**Statut :** ✅ Actif

