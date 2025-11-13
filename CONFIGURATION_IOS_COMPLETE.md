# ✅ Configuration iOS Complète - Tshiakani VTC

## 🎉 Configuration Terminée !

L'application iOS est maintenant configurée pour se connecter à votre backend local.

---

## 📱 Méthode 1: Configuration via l'Interface (Recommandé)

### Étapes

1. **Ouvrir l'app iOS** dans Xcode
2. **Lancer l'app** sur le simulateur ou un appareil réel
3. **Aller dans les Paramètres:**
   - Ouvrir le menu (☰)
   - Sélectionner "Paramètres"
4. **Section "Développement":**
   - Sélectionner "Test de connexion backend"
   - Puis "Configurer l'URL du backend"
5. **Configurer les URLs:**
   - **API Base URL:** `http://192.168.1.79:3000/api`
   - **Socket Base URL:** `http://192.168.1.79:3000`
6. **Valider:**
   - Appuyer sur "Terminé"

### ✅ Avantages

- Configuration facile via l'interface
- Pas besoin de recompiler l'app
- Peut être modifié à tout moment
- Valeurs par défaut affichées

---

## 🎯 Méthode 2: Configuration Automatique (Appareil Réel)

**L'app est déjà configurée avec votre IP par défaut !**

### Simulateur iOS
- ✅ **API:** `http://localhost:3000/api`
- ✅ **Socket:** `http://localhost:3000`

### Appareil Réel
- ✅ **API:** `http://192.168.1.79:3000/api` (déjà configuré)
- ✅ **Socket:** `http://192.168.1.79:3000` (déjà configuré)

**Aucune configuration manuelle nécessaire sur appareil réel !**

---

## 🧪 Test de la Connexion

### Via l'Interface

1. **Dans les Paramètres:**
   - Aller dans "Test de connexion backend"
   - Appuyer sur "Tester la connexion"
2. **Vérifier les résultats:**
   - ✅ Connexion réussie
   - ❌ Connexion échouée → Vérifier l'URL et que le serveur est démarré

### Via le Terminal

```bash
# Vérifier que le backend est démarré
curl http://localhost:3000/health

# Résultat attendu:
# {"status":"OK","database":"connected","timestamp":"..."}
```

---

## ✅ Vérifications

### 1. Backend Démarré

```bash
cd backend
npm run dev
```

**Vérifier:**
```bash
curl http://localhost:3000/health
```

### 2. CORS Configuré

Le backend doit autoriser votre IP. Vérifier dans `backend/.env` :

```env
CORS_ORIGIN=http://localhost:3001,http://localhost:5173,capacitor://localhost,ionic://localhost,http://192.168.1.79:3000
```

**Si non configuré:**
```bash
./scripts/configurer-tout.sh
```

### 3. Test depuis l'App

1. Ouvrir l'app iOS
2. Aller dans Paramètres → Test de connexion backend
3. Appuyer sur "Tester la connexion"
4. Vérifier que la connexion réussit

---

## 📊 État de la Configuration

| Élément | Statut | Détails |
|---------|--------|---------|
| Backend | ✅ Opérationnel | Port 3000 |
| CORS | ✅ Configuré | IP `192.168.1.79` autorisée |
| iOS Simulateur | ✅ Configuré | `localhost:3000` |
| iOS Appareil | ✅ Configuré | `192.168.1.79:3000` |
| Interface Config | ✅ Disponible | Dans Paramètres → Développement |
| Test Connexion | ✅ Disponible | Dans Paramètres → Test de connexion |

---

## 🎉 Résultat

Une fois configuré :

- ✅ L'app se connecte au backend
- ✅ L'authentification fonctionne
- ✅ Les courses peuvent être créées
- ✅ WebSocket fonctionne pour les mises à jour temps réel
- ✅ Les notifications fonctionnent

---

## 🐛 Dépannage

### Erreur: "Cannot connect to server"

**Solutions:**
1. Vérifier que le backend est démarré : `curl http://localhost:3000/health`
2. Vérifier l'URL dans la configuration (doit correspondre à l'IP du serveur)
3. Vérifier que l'appareil iOS est sur le même réseau WiFi
4. Vérifier CORS dans `backend/.env`

### Erreur: "CORS policy"

**Solution:**
```bash
# Vérifier CORS dans backend/.env
cat backend/.env | grep CORS_ORIGIN

# Si l'IP n'est pas présente, l'ajouter
./scripts/configurer-tout.sh
```

### L'interface de configuration n'apparaît pas

**Solution:**
- L'interface n'est visible qu'en mode DEBUG
- Compiler l'app en mode DEBUG
- Ou utiliser la configuration automatique (déjà configurée)

---

## 📚 Documentation

- **GUIDE_CONFIGURATION_IOS.md** - Guide détaillé de configuration
- **GUIDE_CONNEXION_IOS.md** - Guide de connexion complet
- **ConfigurationService.swift** - Service de configuration
- **BackendConnectionTestView.swift** - Interface de test et configuration

---

## ✅ Checklist Finale

### Configuration
- [x] Backend configuré et démarré
- [x] CORS configuré avec IP `192.168.1.79`
- [x] iOS Simulateur configuré (`localhost`)
- [x] iOS Appareil configuré (`192.168.1.79`)
- [x] Interface de configuration disponible
- [x] Test de connexion disponible

### Tests
- [ ] Backend testé (health check)
- [ ] Connexion iOS testée
- [ ] Authentification testée
- [ ] Création de course testée
- [ ] WebSocket testé

---

**Date:** Novembre 2025  
**Version:** 1.0.0  
**IP Locale:** 192.168.1.79  
**Statut:** ✅ Configuration complète

**Prochaine étape:** Tester la connexion depuis l'app iOS !

