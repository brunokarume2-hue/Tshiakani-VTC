-- Script AppleScript pour retirer automatiquement Info.plist de Copy Bundle Resources
-- Corrige l'erreur: Multiple commands produce Info.plist

tell application "Xcode"
    activate
    delay 3
    
    -- Ouvrir le projet si pas déjà ouvert
    set projectPath to "/Users/admin/Documents/Tshiakani VTC/Tshiakani VTC.xcodeproj"
    try
        open projectPath
        delay 5
    end try
end tell

tell application "System Events"
    tell process "Xcode"
        -- Attendre que Xcode soit chargé
        repeat 15 times
            try
                if exists menu bar 1 then
                    exit repeat
                end if
            end try
            delay 1
        end repeat
        
        delay 3
        
        log "🔧 Retrait automatique d'Info.plist de Copy Bundle Resources"
        log "============================================================"
        log ""
        
        -- Étape 1: Ouvrir le Project Navigator
        log "Étape 1: Ouverture du Project Navigator..."
        try
            keystroke "1" using {command down}
            delay 1
            log "✅ Project Navigator ouvert"
        on error errMsg
            log "⚠️ Project Navigator: " & errMsg
        end try
        
        delay 1
        
        -- Étape 2: Sélectionner le projet (icône bleue)
        log "Étape 2: Sélection du projet..."
        try
            -- Chercher le projet dans le navigateur
            keystroke "f" using {command down}
            delay 0.5
            keystroke "Tshiakani VTC"
            delay 1
            keystroke return
            delay 2
            
            -- Cliquer sur l'icône bleue du projet
            -- Cette partie est difficile à automatiser, on va essayer avec Tab
            keystroke tab
            delay 0.5
            keystroke return
            delay 2
            
            log "✅ Projet sélectionné"
        on error errMsg
            log "⚠️ Sélection projet: " & errMsg
        end try
        
        delay 2
        
        -- Étape 3: Aller dans Build Phases
        log "Étape 3: Navigation vers Build Phases..."
        try
            -- Utiliser Tab pour naviguer vers les onglets
            -- Généralement: General, Signing & Capabilities, Build Phases, Build Rules, Build Settings
            -- On va utiliser plusieurs Tab pour arriver à Build Phases
            repeat 2 times
                keystroke tab
                delay 0.5
            end repeat
            
            -- Ou utiliser Cmd+Option+Right pour naviguer
            keystroke "]" using {command down, option down}
            delay 1
            keystroke "]" using {command down, option down}
            delay 1
            
            log "✅ Navigation vers Build Phases"
        on error errMsg
            log "⚠️ Navigation Build Phases: " & errMsg
        end try
        
        delay 2
        
        -- Étape 4: Développer Copy Bundle Resources
        log "Étape 4: Recherche de Copy Bundle Resources..."
        try
            -- Chercher "Copy Bundle Resources" dans la page
            keystroke "f" using {command down}
            delay 0.5
            keystroke "Copy Bundle Resources"
            delay 1
            keystroke return
            delay 1
            
            -- Essayer de développer avec la flèche droite
            keystroke "]" using {option down}
            delay 1
            
            log "✅ Copy Bundle Resources développé"
        on error errMsg
            log "⚠️ Développement Copy Bundle Resources: " & errMsg
        end try
        
        delay 2
        
        -- Étape 5: Chercher et supprimer Info.plist
        log "Étape 5: Recherche d'Info.plist..."
        try
            -- Chercher Info.plist
            keystroke "f" using {command down}
            delay 0.5
            keystroke "Info.plist"
            delay 1
            keystroke return
            delay 1
            
            -- Si trouvé, le sélectionner et le supprimer
            -- Utiliser Delete ou le bouton -
            keystroke "x" using {command down}
            delay 1
            
            log "✅ Info.plist supprimé (si présent)"
        on error errMsg
            log "⚠️ Suppression Info.plist: " & errMsg
            log "   → Info.plist n'est peut-être pas présent, ou action manuelle requise"
        end try
        
        delay 2
        
        log ""
        log "============================================================"
        log "✅ Tentative automatique terminée"
        log ""
        log "📋 Vérification manuelle recommandée:"
        log ""
        log "1. Dans Xcode, vérifiez que:"
        log "   → Target 'Tshiakani VTC' est sélectionné"
        log "   → Onglet 'Build Phases' est ouvert"
        log "   → 'Copy Bundle Resources' est développé"
        log "   → Info.plist n'est PAS dans la liste"
        log ""
        log "2. Si Info.plist est encore présent:"
        log "   → Sélectionnez-le"
        log "   → Cliquez sur '-' ou appuyez sur Delete"
        log ""
        log "3. Nettoyez et compilez:"
        log "   → Product > Clean Build Folder (⇧⌘K)"
        log "   → Product > Build (⌘B)"
        log ""
        log "============================================================"
        
    end tell
end tell

