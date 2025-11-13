-- Script AppleScript FORCÉ pour retirer Info.plist
-- Utilise toutes les méthodes possibles

tell application "Xcode"
    activate
    delay 3
    
    set projectPath to "/Users/admin/Documents/Tshiakani VTC/Tshiakani VTC.xcodeproj"
    try
        open projectPath
        delay 5
    end try
end tell

tell application "System Events"
    tell process "Xcode"
        -- Attendre Xcode
        repeat 20 times
            try
                if exists menu bar 1 then
                    exit repeat
                end if
            end try
            delay 1
        end repeat
        
        delay 3
        
        log "🔧 Retrait FORCÉ d'Info.plist de Copy Bundle Resources"
        log "======================================================"
        log ""
        
        -- Méthode 1: Navigation clavier directe
        log "Méthode 1: Navigation clavier..."
        try
            -- Ouvrir Project Navigator
            keystroke "1" using {command down}
            delay 1
            
            -- Sélectionner le projet
            keystroke return
            delay 2
            
            -- Aller dans Build Phases avec Tab
            repeat 3 times
                keystroke tab
                delay 0.5
            end repeat
            
            log "✅ Navigation effectuée"
        on error errMsg
            log "⚠️ Navigation: " & errMsg
        end try
        
        delay 2
        
        -- Méthode 2: Recherche de Copy Bundle Resources
        log "Méthode 2: Recherche de Copy Bundle Resources..."
        try
            keystroke "f" using {command down}
            delay 0.5
            keystroke "Copy Bundle Resources"
            delay 1
            keystroke return
            delay 1
            
            -- Développer
            keystroke "]" using {option down}
            delay 1
            
            log "✅ Copy Bundle Resources développé"
        on error errMsg
            log "⚠️ Recherche: " & errMsg
        end try
        
        delay 2
        
        -- Méthode 3: Recherche et suppression d'Info.plist
        log "Méthode 3: Recherche et suppression d'Info.plist..."
        try
            -- Chercher Info.plist
            keystroke "f" using {command down}
            delay 0.5
            keystroke "Info.plist"
            delay 1
            keystroke return
            delay 1
            
            -- Sélectionner
            keystroke return
            delay 0.5
            
            -- Supprimer avec plusieurs méthodes
            keystroke "x" using {command down}
            delay 0.5
            keystroke "x" using {command down}
            delay 0.5
            
            -- Essayer Delete
            key code 51
            delay 0.5
            key code 51
            delay 0.5
            
            log "✅ Tentative de suppression effectuée"
        on error errMsg
            log "⚠️ Suppression: " & errMsg
        end try
        
        delay 2
        
        log ""
        log "======================================================"
        log "✅ Tentative automatique terminée"
        log ""
        log "📋 VÉRIFICATION MANUELLE OBLIGATOIRE:"
        log ""
        log "Le script a tenté de retirer Info.plist, mais avec"
        log "PBXFileSystemSynchronizedRootGroup, une vérification"
        log "visuelle est nécessaire."
        log ""
        log "1. Dans Xcode, vérifiez visuellement:"
        log "   → Target 'Tshiakani VTC' > Build Phases"
        log "   → 'Copy Bundle Resources' développé"
        log "   → Info.plist est-il présent ?"
        log ""
        log "2. Si Info.plist est présent:"
        log "   → Sélectionnez-le"
        log "   → Cliquez sur '-' (moins) en bas"
        log "   → OU appuyez sur Delete (⌫)"
        log ""
        log "3. Vérifiez qu'Info.plist n'est plus dans la liste"
        log ""
        log "4. Product > Clean Build Folder (⇧⌘K)"
        log ""
        log "5. Product > Build (⌘B)"
        log ""
        log "======================================================"
        
    end tell
end tell

