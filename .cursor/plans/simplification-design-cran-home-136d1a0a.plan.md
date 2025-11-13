<!-- 136d1a0a-4180-401d-8915-10d830574bf5 f1267afa-51e5-45cb-befa-c1d7246aff38 -->
# Adaptation Style Bolt - Tous les Écrans Client

## Objectif

Adapter tous les écrans client restants au style Bolt : design minimaliste, carte pleine écran, panneaux épurés, uniquement l'essentiel pour le MVP.

## Écrans à adapter

### 1. SearchingDriversView

**Fichier**: [Tshiakani VTC/Views/Client/SearchingDriversView.swift](Tshiakani VTC/Views/Client/SearchingDriversView.swift)

**Modifications**:

- Carte pleine écran sans éléments superflus
- Panneau en bas minimaliste avec :
  - Animation de recherche (cercles pulsants)
  - Timer de recherche (optionnel, discret)
  - Bouton "Annuler la course" proéminent en bas
- Supprimer toutes les informations redondantes
- Design épuré style Bolt

### 2. DriverFoundView

**Fichier**: [Tshiakani VTC/Views/Client/DriverFoundView.swift](Tshiakani VTC/Views/Client/DriverFoundView.swift)

**Modifications**:

- Carte pleine écran avec position du chauffeur
- Panneau en bas compact avec :
  - Photo/avatar du chauffeur (cercle)
  - Nom et note du chauffeur
  - Temps d'arrivée estimé (badge en haut de la carte)
  - Bouton "Appeler" (flottant ou dans le panneau)
  - Bouton "Suivre la course" (pleine largeur)
- Supprimer les adresses complètes (garder uniquement dans le panneau si nécessaire)
- Design minimaliste

### 3. RideTrackingView

**Fichier**: [Tshiakani VTC/Views/Client/RideTrackingView.swift](Tshiakani VTC/Views/Client/RideTrackingView.swift)

**Modifications**:

- Carte pleine écran avec itinéraire et position du chauffeur
- Badge "Arrivée dans X min" en haut (style pill)
- Panneau en bas minimaliste avec :
  - Avatar du chauffeur
  - Statut "En route" / "Arrivé"
  - Bouton "Appeler le chauffeur" (pleine largeur, orange)
- Supprimer toutes les informations non essentielles
- Design épuré

### 4. RideHistoryView

**Fichier**: [Tshiakani VTC/Views/Client/RideHistoryView.swift](Tshiakani VTC/Views/Client/RideHistoryView.swift)

**Modifications**:

- Liste épurée style Bolt :
  - Cartes compactes avec date/heure
  - Adresses (départ et destination) sur 2 lignes
  - Prix à droite
  - Icône simple (flèche ou mappin)
- Supprimer les détails non essentiels
- Design minimaliste avec espacements généreux
- État vide amélioré

### 5. AddressSearchView

**Fichier**: [Tshiakani VTC/Views/Client/AddressSearchView.swift](Tshiakani VTC/Views/Client/AddressSearchView.swift)

**Modifications**:

- Barre de recherche en haut (déjà fait)
- Liste de résultats épurée :
  - Icônes discrètes
  - Typographie claire
  - Espacements généreux
- État vide amélioré
- Design cohérent avec le reste

### 6. SettingsView

**Fichier**: [Tshiakani VTC/Views/Client/SettingsView.swift](Tshiakani VTC/Views/Client/SettingsView.swift)

**Vérification**:

- S'assurer que le design est cohérent avec le style Bolt
- Vérifier les espacements et la typographie
- Garder uniquement les options essentielles

## Principes de design Bolt

1. **Carte pleine écran** : Tous les écrans avec carte doivent avoir la carte en plein écran
2. **Panneaux en bas** : Bottom sheets avec indicateur de drag, contenu minimaliste
3. **Typographie** : Hiérarchie claire, espacements généreux
4. **Couleurs** : Orange pour les actions principales, fonds épurés
5. **Minimalisme** : Uniquement l'essentiel, pas d'options superflues
6. **Animations** : Discrètes et fluides

## Structure commune des écrans avec carte

```
┌─────────────────────────┐
│      CARTE              │ ← Plein écran
│      (plein écran)      │
│                         │
│  [Badge info] (optionnel)│
│                         │
├─────────────────────────┤
│ ─────────────────────   │ ← Indicateur drag
│                         │
│  [Contenu minimaliste]  │
│                         │
│  [Bouton action]        │
└─────────────────────────┘
```

## Priorités MVP

- **Essentiel** : Recherche, sélection véhicule, commande, suivi, appel chauffeur
- **Non essentiel** : Options avancées, détails superflus, multiples boutons d'action

## Fichiers à modifier

1. [Tshiakani VTC/Views/Client/SearchingDriversView.swift](Tshiakani VTC/Views/Client/SearchingDriversView.swift)
2. [Tshiakani VTC/Views/Client/DriverFoundView.swift](Tshiakani VTC/Views/Client/DriverFoundView.swift)
3. [Tshiakani VTC/Views/Client/RideTrackingView.swift](Tshiakani VTC/Views/Client/RideTrackingView.swift)
4. [Tshiakani VTC/Views/Client/RideHistoryView.swift](Tshiakani VTC/Views/Client/RideHistoryView.swift)
5. [Tshiakani VTC/Views/Client/AddressSearchView.swift](Tshiakani VTC/Views/Client/AddressSearchView.swift)
6. [Tshiakani VTC/Views/Client/SettingsView.swift](Tshiakani VTC/Views/Client/SettingsView.swift) (vérification)

## Notes

- Garder la cohérence avec ClientHomeView déjà adapté
- Utiliser AppDesign, AppColors, AppTypography pour la cohérence
- Tester chaque écran après modification
- Supprimer le code non utilisé après simplification

### To-dos

- [x] Simplifier l'en-tête : retirer le titre centré, réduire la taille du bouton profil, utiliser un fond plus subtil
- [x] Épurer la barre de recherche : augmenter les espacements, améliorer la typographie, réduire les ombres
- [x] Simplifier les boutons rapides : réduire les tailles, uniformiser les couleurs, améliorer les espacements
- [x] Simplifier le panneau d'informations : réduire le padding, améliorer la hiérarchie typographique
- [x] Améliorer la typographie : utiliser des styles cohérents et élégants dans tout le composant
- [x] Augmenter les espacements : padding et margins plus généreux pour un design aéré
- [x] Harmoniser les icônes : tailles et styles uniformes pour cohérence visuelle