# 💰 Configuration des Prix Dynamiques - Kinshasa

## 🎯 Système de Tarification Configurable

Le système de tarification est maintenant **entièrement configurable depuis le dashboard admin** et s'adapte automatiquement aux tendances de Kinshasa.

---

## 📊 Fonctionnalités

### ✅ Tarifs de Base Configurables
- **Prix de base** : Montant fixe pour chaque course (défaut: 500 CDF)
- **Prix par kilomètre** : Tarif variable selon la distance (défaut: 200 CDF/km)

### ✅ Multiplicateurs Temporels
- **Heures de pointe** (7h-9h, 17h-19h) : Multiplicateur configurable (défaut: 1.5 = +50%)
- **Nuit** (22h-6h) : Multiplicateur configurable (défaut: 1.3 = +30%)
- **Week-end** : Multiplicateur configurable (défaut: 1.2 = +20%)

### ✅ Surge Pricing (Selon la Demande)
- **Demande faible** (ratio < 0.5) : Réduction configurable (défaut: 0.9 = -10%)
- **Demande normale** (ratio 0.5-1.0) : Multiplicateur 1.0
- **Demande élevée** (ratio 1.0-1.5) : Multiplicateur configurable (défaut: 1.2 = +20%)
- **Demande très élevée** (ratio 1.5-2.0) : Multiplicateur configurable (défaut: 1.4 = +40%)
- **Demande extrême** (ratio > 2.0) : Multiplicateur configurable (défaut: 1.6 = +60%)

---

## 🖥️ Interface Dashboard Admin

### Accès
**URL** : `http://localhost:3001/pricing`

### Fonctionnalités
- ✅ Visualiser la configuration actuelle
- ✅ Modifier tous les tarifs et multiplicateurs
- ✅ Voir un exemple de calcul en temps réel
- ✅ Description de la configuration (pour référence)
- ✅ Sauvegarde instantanée avec invalidation du cache

---

## 🔧 API Endpoints

### Obtenir la Configuration
```http
GET /api/admin/pricing
Authorization: Bearer {token}
```

**Réponse** :
```json
{
  "id": 1,
  "basePrice": 500.0,
  "pricePerKm": 200.0,
  "rushHourMultiplier": 1.5,
  "nightMultiplier": 1.3,
  "weekendMultiplier": 1.2,
  "surgeLowDemandMultiplier": 0.9,
  "surgeNormalMultiplier": 1.0,
  "surgeHighMultiplier": 1.2,
  "surgeVeryHighMultiplier": 1.4,
  "surgeExtremeMultiplier": 1.6,
  "description": "Tarifs Kinshasa - Janvier 2025",
  "isActive": true
}
```

### Mettre à Jour la Configuration
```http
PUT /api/admin/pricing
Authorization: Bearer {token}
Content-Type: application/json

{
  "basePrice": 600.0,
  "pricePerKm": 250.0,
  "rushHourMultiplier": 1.6,
  "description": "Tarifs Kinshasa - Février 2025"
}
```

**Note** : Seuls les champs fournis seront mis à jour.

---

## 🧠 Algorithme de Calcul

### Formule
```
Prix final = (Prix de base + Distance × Prix/km) × Multiplicateur temps × Multiplicateur jour × Multiplicateur demande
```

### Exemple
**Course de 5 km en heures de pointe (week-end) avec demande élevée** :
- Prix de base : 500 CDF
- Distance : 5 km × 200 CDF = 1000 CDF
- Sous-total : 1500 CDF
- Multiplicateurs : 1.5 (heures de pointe) × 1.2 (week-end) × 1.2 (demande élevée) = 2.16
- **Prix final : 1500 × 2.16 = 3240 CDF**

---

## 💾 Base de Données

### Table `price_configurations`
- Stocke toutes les configurations de prix
- Une seule configuration active à la fois (`isActive = true`)
- Historique conservé pour référence

### Cache
- Configuration mise en cache pendant **5 minutes**
- Cache invalidé automatiquement après mise à jour
- Fallback vers valeurs par défaut en cas d'erreur

---

## 📋 Recommandations pour Kinshasa

### Tarifs de Base Suggérés
- **Prix de base** : 500-700 CDF (selon la zone)
- **Prix par km** : 200-300 CDF/km (selon la zone)

### Multiplicateurs Suggérés
- **Heures de pointe** : 1.5-1.8 (trafic dense)
- **Nuit** : 1.3-1.5 (sécurité)
- **Week-end** : 1.2-1.4 (demande élevée)

### Surge Pricing
- Ajuster selon les zones :
  - **Gombe, Kinshasa** : Multiplicateurs plus élevés
  - **Zones périphériques** : Multiplicateurs plus bas

---

## ✅ Checklist d'Utilisation

### Pour Ajuster les Prix
1. [ ] Se connecter au dashboard admin
2. [ ] Aller dans "Tarification" (menu latéral)
3. [ ] Modifier les valeurs selon les tendances de Kinshasa
4. [ ] Vérifier l'exemple de calcul
5. [ ] Ajouter une description (ex: "Tarifs Kinshasa - Janvier 2025")
6. [ ] Cliquer sur "Enregistrer"
7. [ ] Les nouveaux prix seront appliqués immédiatement

### Pour Surveiller
- [ ] Vérifier les statistiques de revenus
- [ ] Analyser les tendances de demande
- [ ] Ajuster selon les retours des conducteurs et clients

---

## 🎯 Avantages

✅ **Flexibilité** : Ajustement en temps réel sans redémarrage
✅ **Adaptabilité** : S'adapte aux tendances de Kinshasa
✅ **Transparence** : Historique des configurations
✅ **Performance** : Cache pour éviter les requêtes répétées
✅ **Sécurité** : Seuls les admins peuvent modifier

---

## 📝 Notes Importantes

1. **Les modifications sont immédiates** : Le cache est invalidé après chaque mise à jour
2. **Une seule configuration active** : La dernière configuration active est utilisée
3. **Valeurs par défaut** : Si pas de configuration, les valeurs par défaut sont utilisées
4. **Validation** : Les valeurs sont validées (min/max) avant sauvegarde

---

## ✅ Conclusion

**Le système de tarification est maintenant entièrement configurable !** 🎉

- ✅ Tarifs ajustables depuis le dashboard
- ✅ Adaptation automatique aux tendances de Kinshasa
- ✅ Surge pricing configurable
- ✅ Interface intuitive pour les admins

**Prêt pour ajuster les prix selon les tendances de Kinshasa !** 💰

