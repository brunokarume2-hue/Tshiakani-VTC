-- Script AppleScript pour FORCER la suppression d'Info.plist de Copy Bundle Resources
-- Solution définitive pour le conflit "Multiple commands produce Info.plist"

tell application "Xcode"
    activate
    delay 2
    
    set projectPath to "/Users/admin/Documents/Tshiakani VTC/Tshiakani VTC.xcodeproj"
    try
        open projectPath
        delay 5
        log "✅ Projet ouvert"
    on error errMsg
        log "⚠️ Erreur ouverture projet: " & errMsg
    end try
end tell

tell application "System Events"
    tell process "Xcode"
        -- Attendre que Xcode soit prêt
        repeat 30 times
            try
                if exists menu bar 1 then
                    exit repeat
                end if
            end try
            delay 1
        end repeat
        
        delay 3
        log ""
        log "🔧 FORCEMENT de la suppression d'Info.plist"
        log "=========================================="
        log ""
        
        -- Étape 1: Ouvrir Project Navigator
        log "Étape 1: Ouverture du Project Navigator..."
        try
            keystroke "1" using {command down}
            delay 1
            log "✅ Project Navigator ouvert"
        on error errMsg
            log "⚠️ Erreur Project Navigator: " & errMsg
        end try
        
        delay 2
        
        -- Étape 2: Sélectionner le projet (icône bleue)
        log "Étape 2: Sélection du projet..."
        try
            -- Cliquer sur l'icône bleue (premier élément dans le Project Navigator)
            keystroke "0" using {command down} -- Focus sur le Project Navigator
            delay 0.5
            keystroke return -- Sélectionner le premier élément (le projet)
            delay 2
            log "✅ Projet sélectionné"
        on error errMsg
            log "⚠️ Erreur sélection projet: " & errMsg
        end try
        
        delay 2
        
        -- Étape 3: Aller dans Build Phases
        log "Étape 3: Navigation vers Build Phases..."
        try
            -- Utiliser Tab pour naviguer vers Build Phases (3ème onglet)
            repeat 2 times
                keystroke tab
                delay 0.5
            end repeat
            log "✅ Build Phases sélectionné"
        on error errMsg
            log "⚠️ Erreur navigation Build Phases: " & errMsg
        end try
        
        delay 2
        
        -- Étape 4: Développer Copy Bundle Resources
        log "Étape 4: Développement de Copy Bundle Resources..."
        try
            -- Chercher "Copy Bundle Resources" avec Cmd+F
            keystroke "f" using {command down}
            delay 0.5
            keystroke "Copy Bundle Resources"
            delay 1
            keystroke return
            delay 1
            
            -- Développer avec Option+Flèche droite ou clic
            keystroke "]" using {option down}
            delay 1
            
            log "✅ Copy Bundle Resources développé"
        on error errMsg
            log "⚠️ Erreur développement: " & errMsg
        end try
        
        delay 2
        
        -- Étape 5: Chercher et supprimer Info.plist
        log "Étape 5: Recherche et suppression d'Info.plist..."
        try
            -- Chercher Info.plist
            keystroke "f" using {command down}
            delay 0.5
            keystroke "Info.plist"
            delay 1
            keystroke return
            delay 1
            
            -- Sélectionner le résultat
            keystroke return
            delay 0.5
            
            -- Essayer plusieurs méthodes de suppression
            -- Méthode 1: Bouton moins
            try
                -- Chercher le bouton moins (généralement en bas de la liste)
                -- Utiliser Tab pour naviguer vers le bouton
                repeat 5 times
                    keystroke tab
                    delay 0.2
                end repeat
                keystroke return -- Cliquer sur le bouton moins
                delay 1
                log "✅ Tentative avec bouton moins"
            end try
            
            -- Méthode 2: Delete
            key code 51 -- Delete
            delay 0.5
            key code 51 -- Delete (double pour être sûr)
            delay 0.5
            log "✅ Tentative avec Delete"
            
            -- Méthode 3: Cmd+Delete
            keystroke "x" using {command down}
            delay 0.5
            log "✅ Tentative avec Cmd+X"
            
        on error errMsg
            log "⚠️ Erreur suppression: " & errMsg
        end try
        
        delay 2
        
        log ""
        log "=========================================="
        log "✅ Script terminé"
        log ""
        log "📋 VÉRIFICATION MANUELLE OBLIGATOIRE:"
        log ""
        log "1. Dans Xcode, vérifiez visuellement:"
        log "   Target 'Tshiakani VTC' > Build Phases"
        log "   > Copy Bundle Resources (développé)"
        log "   > Info.plist est-il encore présent ?"
        log ""
        log "2. Si Info.plist est TOUJOURS présent:"
        log "   → Sélectionnez-le manuellement"
        log "   → Cliquez sur '-' (moins) en bas"
        log "   → OU appuyez sur Delete (⌫)"
        log ""
        log "3. Vérifiez qu'Info.plist n'est plus dans la liste"
        log ""
        log "4. Product > Clean Build Folder (⇧⌘K)"
        log ""
        log "5. Product > Build (⌘B)"
        log ""
        log "=========================================="
        
    end tell
end tell

