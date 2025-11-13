# 🚀 Ouvrir le Dashboard Admin

## 📋 Instructions Rapides

### 1. Démarrer le Dashboard

```bash
cd "/Users/admin/Documents/wewa taxi/admin-dashboard"
npm run dev
```

### 2. Accéder au Dashboard

Le dashboard sera accessible sur :
- **http://localhost:5173** (port Vite par défaut)
- ou **http://localhost:3001** (si configuré différemment)

### 3. Page de Tarification

Une fois connecté, allez dans le menu latéral et cliquez sur **"Tarification"** 💵

Ou accédez directement à : **http://localhost:5173/pricing**

---

## 🔐 Connexion

**Identifiants Admin** (à configurer dans le backend) :
- Numéro de téléphone admin
- Mot de passe admin

---

## 📊 Pages Disponibles

- 📊 **Tableau de bord** - Statistiques générales
- 🚗 **Courses** - Gestion des courses
- 👥 **Utilisateurs** - Liste des utilisateurs
- 🏍️ **Conducteurs** - Gestion des conducteurs
- 👤 **Clients** - Gestion des clients
- 💰 **Finance** - Revenus et statistiques
- 💵 **Tarification** - Configuration des prix ⭐ NOUVEAU
- 🗺️ **Carte** - Vue en temps réel
- 🚨 **Alertes SOS** - Gestion des alertes
- 🔔 **Notifications** - Notifications système

---

## ✅ Vérification

Si le dashboard ne s'ouvre pas :

1. Vérifier que le backend est démarré :
   ```bash
   cd backend
   npm run dev
   ```

2. Vérifier les ports :
   ```bash
   lsof -ti:5173  # Dashboard
   lsof -ti:3000  # Backend
   ```

3. Vérifier la console du navigateur (F12) pour les erreurs

---

## 🎯 Page Tarification

Sur la page **Tarification**, vous pouvez :

✅ Ajuster les tarifs de base (prix fixe, prix/km)
✅ Configurer les multiplicateurs temporels
✅ Ajuster le surge pricing selon la demande
✅ Voir des exemples de calcul en temps réel
✅ Enregistrer les modifications

**Les changements sont appliqués immédiatement !** 🚀

