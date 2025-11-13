# 💰 Configuration Monnaie - Francs Congolais (CDF)

## ✅ Configuration Actuelle

Tous les prix dans l'application sont en **Francs Congolais (CDF)**.

---

## 📊 Backend

### PricingService.js
```javascript
// Tarifs de base (en Francs Congolais - CDF)
static BASE_PRICE = 500.0; // Prix de base en CDF
static PRICE_PER_KM = 200.0; // Prix par kilomètre en CDF
```

**Calcul du prix** :
- Prix de base : **500 CDF**
- Prix par kilomètre : **200 CDF/km**
- Multiplicateurs selon l'heure, le jour et la demande

---

## 📱 Application iOS

### Extension de Formatage

Fichier : `Extensions.swift`

```swift
extension Double {
    func formatCurrency() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "CDF"
        formatter.locale = Locale(identifier: "fr_CD")
        return formatter.string(from: NSNumber(value: self)) ?? "\(Int(self)) CDF"
    }
}
```

**Utilisation** :
```swift
Text(estimatedPrice.formatCurrency())
// Affiche : "1 500 CDF" ou "1,500 CDF" selon la locale
```

### Affichage des Prix

Tous les prix sont affichés avec "CDF" :
- ✅ `RideRequestView` : Prix estimé
- ✅ `RideHistoryView` : Historique des courses
- ✅ `DriverMainView` : Demandes de course
- ✅ `DriverHistoryView` : Historique conducteur
- ✅ `DriverEarningsScreen` : Revenus
- ✅ `DriverDashboardScreen` : Statistiques

---

## 🎯 Format d'Affichage

### Format Standard
```
1 500 CDF
```

### Format avec Séparateurs
```
1,500 CDF  (format international)
1 500 CDF  (format français)
```

### Format Abrégé (pour grands montants)
```
45K CDF    (pour 45 000 CDF)
1.5M CDF   (pour 1 500 000 CDF)
```

---

## 📋 Vérification

### ✅ Backend
- [x] Commentaires mentionnent CDF
- [x] Tarifs en CDF (500 + 200/km)
- [x] Calculs en CDF

### ✅ iOS
- [x] Extension `formatCurrency()` avec CDF
- [x] Locale `fr_CD` (Congo)
- [x] Tous les affichages incluent "CDF"
- [x] Formatage cohérent

### ✅ Dashboard Admin
- [x] Affichage en CDF
- [x] Format "K CDF" pour grands montants

---

## 🔧 Utilisation

### Dans le Code Swift

**Méthode recommandée** (avec formatage automatique) :
```swift
Text(price.formatCurrency())
```

**Méthode alternative** (format simple) :
```swift
Text("\(Int(price)) CDF")
```

### Exemples

```swift
// Prix simple
let price = 1500.0
Text(price.formatCurrency()) // "1 500 CDF"

// Prix avec décimales
let price = 1500.75
Text(price.formatCurrency()) // "1 500,75 CDF"

// Prix arrondi
let price = 1500.0
Text("\(Int(price)) CDF") // "1500 CDF"
```

---

## 📝 Notes Importantes

1. **Tous les prix sont en CDF** - Pas de conversion nécessaire
2. **Formatage automatique** - Utilisez `formatCurrency()` pour un formatage cohérent
3. **Locale** - `fr_CD` pour le format français congolais
4. **Séparateurs** - Espaces ou virgules selon la locale système

---

## ✅ Conclusion

**Tous les prix sont correctement configurés en Francs Congolais (CDF)** 💰

- ✅ Backend : Tarifs en CDF
- ✅ iOS : Formatage avec locale `fr_CD`
- ✅ Dashboard : Affichage en CDF
- ✅ Cohérence : Tous les composants utilisent CDF

**Configuration complète et cohérente !** 🎉

