-- Script AppleScript amélioré pour retirer définitivement Info.plist
-- Utilise une approche plus directe avec navigation clavier

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
        repeat 15 times
            try
                if exists menu bar 1 then
                    exit repeat
                end if
            end try
            delay 1
        end repeat
        
        delay 3
        
        log "🔧 Retrait DÉFINITIF d'Info.plist de Copy Bundle Resources"
        log "=========================================================="
        log ""
        
        -- Étape 1: Ouvrir Project Navigator
        log "Étape 1: Project Navigator..."
        keystroke "1" using {command down}
        delay 1
        
        -- Étape 2: Sélectionner le projet (icône bleue)
        log "Étape 2: Sélection du projet..."
        try
            -- Utiliser Cmd+J pour aller au Project Navigator si nécessaire
            keystroke "j" using {command down}
            delay 1
            
            -- Sélectionner le premier élément (le projet)
            keystroke return
            delay 2
            log "✅ Projet sélectionné"
        on error errMsg
            log "⚠️ Sélection projet: " & errMsg
        end try
        
        -- Étape 3: Aller dans Build Phases
        log "Étape 3: Navigation vers Build Phases..."
        try
            -- Utiliser Tab plusieurs fois pour naviguer vers les onglets
            -- Ou utiliser les raccourcis clavier
            keystroke tab
            delay 0.5
            keystroke tab
            delay 0.5
            keystroke tab
            delay 1
            
            -- Alternative: utiliser Cmd+Option+Right pour naviguer entre les onglets
            keystroke "]" using {command down, option down}
            delay 1
            keystroke "]" using {command down, option down}
            delay 1
            
            log "✅ Navigation vers Build Phases"
        on error errMsg
            log "⚠️ Navigation: " & errMsg
        end try
        
        delay 2
        
        -- Étape 4: Chercher et développer Copy Bundle Resources
        log "Étape 4: Recherche de Copy Bundle Resources..."
        try
            -- Utiliser Cmd+F pour chercher
            keystroke "f" using {command down}
            delay 0.5
            keystroke "Copy Bundle Resources"
            delay 1
            keystroke return
            delay 1
            
            -- Développer avec la flèche droite
            keystroke "]" using {option down}
            delay 1
            
            log "✅ Copy Bundle Resources développé"
        on error errMsg
            log "⚠️ Développement: " & errMsg
        end try
        
        delay 2
        
        -- Étape 5: Chercher Info.plist et le supprimer
        log "Étape 5: Recherche et suppression d'Info.plist..."
        try
            -- Chercher Info.plist
            keystroke "f" using {command down}
            delay 0.5
            keystroke "Info.plist"
            delay 1
            keystroke return
            delay 1
            
            -- Si trouvé, le sélectionner
            keystroke return
            delay 0.5
            
            -- Supprimer avec Delete ou Cmd+X
            keystroke "x" using {command down}
            delay 1
            
            -- Ou utiliser le bouton -
            -- (difficile à automatiser, mais on essaie)
            
            log "✅ Tentative de suppression d'Info.plist"
        on error errMsg
            log "⚠️ Suppression: " & errMsg
            log "   → Info.plist peut ne pas être présent"
            log "   → Ou action manuelle requise"
        end try
        
        delay 2
        
        log ""
        log "=========================================================="
        log "✅ Tentative automatique terminée"
        log ""
        log "📋 VÉRIFICATION MANUELLE OBLIGATOIRE:"
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
        log "=========================================================="
        
    end tell
end tell

