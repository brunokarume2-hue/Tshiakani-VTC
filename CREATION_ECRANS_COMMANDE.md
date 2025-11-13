# 📱 Création des Écrans de Commande

**Date**: 2025  
**Status**: ✅ Écrans créés

---

## 📋 Objectif

Créer deux écrans selon les images fournies :

1. **Image 1** : Écran de confirmation de commande
2. **Image 2** : Écran de recherche de chauffeurs

---

## 🎨 Écran 1 : RideConfirmationView (Image 1)

### Description

Écran qui s'affiche **une fois le client a choisi l'adresse de destination**.

### Éléments

1. **Carte Google Maps**
   - Affiche l'itinéraire entre le point de départ et la destination
   - Route tracée sur la carte

2. **Panneau en bas**
   - **Point de départ** : Icône personne + adresse
   - **Destination** : Icône drapeau + adresse + temps estimé + bouton "Arrêts"
   - **Sélection de véhicule horizontale** :
     - Éco (sélectionné par défaut)
     - Confort
     - Le plus rapide
   - **Offre d'upgrade** : "+950CDF et vous pouvez effectuer une course Confort"
   - **Bouton "Commander"** : Rouge avec icône de filtre à côté

### Fichier

`Tshiakani VTC/Views/Client/RideConfirmationView.swift`

### Fonctionnalités

- ✅ Affichage de la carte avec itinéraire
- ✅ Sélection de type de véhicule (horizontale)
- ✅ Calcul des prix pour chaque type
- ✅ Offre d'upgrade si Éco sélectionné
- ✅ Navigation vers l'écran de recherche après commande

---

## 🔍 Écran 2 : SearchingDriversView (Image 2)

### Description

Écran qui s'affiche **une fois le client a confirmé la commande** et recherche un chauffeur à proximité.

### Éléments

1. **Carte Google Maps** (grisée)
   - Affiche la zone de recherche

2. **Panneau en bas**
   - **En-tête** :
     - Titre : "Recherche de véhicules à proximité"
     - Sous-titre : "qui se dirigent dans votre direction"
     - **Timer** : "00:21" (format MM:SS)
   - **Liste d'options** :
     - Point de prise en charge (avec adresse)
     - Ajouter un arrêt
     - Destination (avec nom)
     - Méthode de paiement (Espèces: prix)
     - Montrer au conducteur où je me trouve (toggle)
     - Transporteur et coordonnées
     - Annuler la course (rouge)
   - **Bouton "+ Nouvelle commande"** : En bas du panneau

### Fichier

`Tshiakani VTC/Views/Client/SearchingDriversView.swift`

### Fonctionnalités

- ✅ Timer qui compte le temps de recherche
- ✅ Recherche de chauffeurs à proximité
- ✅ Liste d'options détaillée
- ✅ Toggle pour montrer la localisation au conducteur
- ✅ Annulation de course
- ✅ Suivi du statut de la course
- ✅ Navigation vers nouvelle commande

---

## 🔄 Flux de Navigation

```
ClientHomeView
    ↓
Sélection départ/destination
    ↓
RideConfirmationView (Image 1)
    ↓
Bouton "Commander"
    ↓
SearchingDriversView (Image 2)
    ↓
Recherche de chauffeurs
    ↓
Chauffeur trouvé → Suivi de course
```

---

## 🛠️ Logique de Recherche de Chauffeurs

### Méthode : `searchNearbyDrivers()`

1. **Recherche initiale** :
   - Appelle `RideViewModel.findAvailableDrivers(near: pickupLocation)`
   - Utilise l'API `/location/drivers/nearby`
   - Rayon de recherche : 5 km par défaut

2. **Création de la course** :
   - Appelle `RideViewModel.requestRide()`
   - Crée la course dans la base de données
   - Envoie une notification aux chauffeurs à proximité

3. **Recherche continue** :
   - Si aucun chauffeur n'est trouvé, recherche toutes les 5 secondes
   - Continue jusqu'à ce qu'un chauffeur accepte
   - Timer affiche le temps écoulé

4. **Acceptation** :
   - Quand un chauffeur accepte, `currentRide` est mis à jour
   - Le timer s'arrête
   - Le suivi du chauffeur commence

### Backend

- **Endpoint** : `GET /location/drivers/nearby`
- **Paramètres** :
  - `latitude` : Latitude du point de départ
  - `longitude` : Longitude du point de départ
  - `radius` : Rayon de recherche en km (défaut: 5)
- **Réponse** : Liste des chauffeurs disponibles avec distance

---

## 📊 Timer de Recherche

### Format

`MM:SS` (ex: "00:21")

### Fonctionnement

- Démarré quand l'écran apparaît
- Incrémenté chaque seconde
- Arrêté quand un chauffeur accepte
- Réinitialisé si la course est annulée

### Code

```swift
private func startTimer() {
    searchTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
        elapsedTime += 1
    }
}

private func formatTime(_ time: TimeInterval) -> String {
    let minutes = Int(time) / 60
    let seconds = Int(time) % 60
    return String(format: "%02d:%02d", minutes, seconds)
}
```

---

## ✅ Checklist

### RideConfirmationView
- [x] Carte avec itinéraire
- [x] Panneau en bas
- [x] Point de départ et destination
- [x] Sélection de véhicule horizontale
- [x] Offre d'upgrade
- [x] Bouton "Commander"
- [x] Navigation vers SearchingDriversView

### SearchingDriversView
- [x] Carte en arrière-plan
- [x] Panneau avec en-tête et timer
- [x] Liste d'options
- [x] Toggle pour localisation
- [x] Bouton annuler
- [x] Bouton nouvelle commande
- [x] Recherche de chauffeurs
- [x] Timer fonctionnel
- [x] Suivi du statut de course

---

## 🚀 Prochaines Étapes

1. **Tests** : Tester le flux complet
2. **Optimisations** : Optimiser la recherche de chauffeurs
3. **Notifications** : Ajouter des notifications push
4. **Améliorations** : Améliorer l'UX selon les retours

---

**Document créé par**: Agent Architecte Principal  
**Date**: 2025  
**Status**: ✅ Écrans créés

