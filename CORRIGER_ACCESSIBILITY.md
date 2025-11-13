# Correction accessibilityLabel avec hint

## Problème

L'utilisation de `.accessibilityLabel(..., hint: ...)` avec deux paramètres n'est pas la syntaxe correcte de SwiftUI. Il faut utiliser `.accessibilityLabel(...)` et `.accessibilityHint(...)` séparément.

## Solution

Remplacer :
```swift
.accessibilityLabel("Texte", hint: "Hint")
```

Par :
```swift
.accessibilityLabel("Texte")
.accessibilityHint("Hint")
```

## Fichiers à corriger

Les fichiers suivants utilisent cette syntaxe incorrecte :
- `Tshiakani VTC/Views/Auth/AuthGateView.swift`
- `Tshiakani VTC/Views/Client/ClientHomeView.swift`
- `Tshiakani VTC/Views/Client/RideTrackingView.swift`
- `Tshiakani VTC/Views/Client/AddressSearchView.swift`
- `Tshiakani VTC/Views/Client/HelpView.swift`
- `Tshiakani VTC/Views/Client/SearchingDriversView.swift`
- `Tshiakani VTC/Views/Client/RideMapView.swift`
- `Tshiakani VTC/Views/Client/SavedAddressesView.swift`

## Fichiers déjà corrigés

- ✅ `Tshiakani VTC/Views/Client/VehicleSelectionView.swift`
- ✅ `Tshiakani VTC/Views/Home/RideSummaryScreen.swift`
- ✅ `Tshiakani VTC/Views/Client/RideConfirmationView.swift`

