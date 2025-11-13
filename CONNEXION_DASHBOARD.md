# 🔐 Connexion au Dashboard Admin - Tshiakani VTC

## 📋 Identifiants de Connexion

### Identifiants par Défaut

Le dashboard utilise une **authentification simplifiée** basée sur le numéro de téléphone.

**Identifiants à utiliser** :

```
Numéro de téléphone : +243900000000
                        (ou n'importe quel numéro congolais valide)

Mot de passe : (laissez vide)
```

### Comment ça fonctionne

1. **Première connexion** : Le système crée automatiquement un compte admin avec le numéro fourni
2. **Connexions suivantes** : Le système utilise le compte admin existant
3. **Mot de passe** : Optionnel (peut être laissé vide pour le développement)

---

## 🚀 Étapes de Connexion

### 1. Accéder au Dashboard

Ouvrez votre navigateur et allez à :
- **URL** : `https://tshiakani-vtc-99cea.web.app`
- **URL alternative** : `https://tshiakani-vtc-99cea.firebaseapp.com`

### 2. Remplir le Formulaire

**Numéro de téléphone** :
```
+243900000000
```

**Mot de passe** :
```
(laissez vide)
```

### 3. Cliquer sur "Se connecter"

Le système va vous connecter automatiquement.

---

## ⚠️ Problème Actuel

### Route Non Disponible

La route `/api/auth/admin/login` n'est **pas disponible** sur le backend Cloud Run déployé.

**Erreur rencontrée** : `Cannot POST /api/auth/admin/login`

### Solution

Il faut **vérifier ou redéployer le backend** pour que la route soit disponible.

---

## 🔧 Vérification du Backend

### Vérifier que le Backend Fonctionne

```bash
# Vérifier le health check
curl https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/health

# Résultat attendu : {"status":"ok",...}
```

### Vérifier que la Route Existe

```bash
# Tester la route admin login
curl -X POST https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/api/auth/admin/login \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber":"+243900000000"}'
```

**Si la route n'existe pas** : Il faut redéployer le backend avec la route `/api/auth/admin/login`.

---

## 📝 Résumé

### Identifiants

- **Numéro** : `+243900000000` (ou n'importe quel numéro valide)
- **Mot de passe** : (vide)

### URLs

- **Dashboard** : `https://tshiakani-vtc-99cea.web.app`
- **Backend** : `https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app`

### Statut

- ✅ Dashboard déployé et accessible
- ⚠️ Route d'authentification à vérifier sur le backend
- ✅ Configuration prête (une fois la route disponible)

---

**Date** : $(date)

