-- Script AppleScript pour corriger l'erreur de duplication d'Info.plist
-- Erreur: Multiple commands produce '.../Info.plist'

tell application "Xcode"
    activate
    delay 2
end tell

tell application "System Events"
    tell process "Xcode"
        -- Attendre que Xcode soit chargé
        repeat 10 times
            try
                if exists menu bar 1 then
                    exit repeat
                end if
            end try
            delay 1
        end repeat
        
        delay 2
        
        log "🔧 Correction de l'erreur de duplication Info.plist"
        log "=================================================="
        log ""
        
        -- Étape 1: Sélectionner le target
        log "Étape 1: Sélection du target 'Tshiakani VTC'..."
        try
            -- Ouvrir le Project Navigator
            keystroke "1" using {command down}
            delay 1
            
            -- Sélectionner le projet (icône bleue en haut)
            keystroke "f" using {command down}
            delay 0.5
            keystroke "Tshiakani VTC"
            delay 1
            keystroke return
            delay 1
            
            log "✅ Project Navigator ouvert"
        on error errMsg
            log "⚠️ Navigation: " & errMsg
        end try
        
        log ""
        log "📋 Instructions manuelles pour retirer Info.plist:"
        log ""
        log "1. Dans Xcode, sélectionnez le target 'Tshiakani VTC' (icône bleue en haut)"
        log "2. Allez dans l'onglet 'Build Phases'"
        log "3. Développez 'Copy Bundle Resources'"
        log "4. Cherchez 'Info.plist' dans la liste"
        log "5. Si Info.plist est présent:"
        log "   - Sélectionnez-le"
        log "   - Cliquez sur le bouton '-' (moins) en bas de la liste"
        log "   - OU appuyez sur la touche Delete"
        log ""
        log "6. Vérifiez que Info.plist n'est plus dans la liste"
        log ""
        log "7. Nettoyez et compilez:"
        log "   - Product > Clean Build Folder (⇧⌘K)"
        log "   - Product > Build (⌘B)"
        log ""
        
        -- Essayer d'ouvrir Build Phases automatiquement
        log "🔍 Tentative d'ouverture automatique de Build Phases..."
        try
            -- Sélectionner le target dans le Project Navigator
            -- Puis essayer d'ouvrir Build Phases via le menu
            delay 2
            
            -- Utiliser les raccourcis clavier pour naviguer
            -- Cmd+1 pour Project Navigator si pas déjà ouvert
            keystroke "1" using {command down}
            delay 1
            
            log "✅ Navigation effectuée"
            log "   → Allez maintenant manuellement dans:"
            log "   → Target 'Tshiakani VTC' > Build Phases > Copy Bundle Resources"
            log "   → Retirez Info.plist si présent"
            
        on error errMsg
            log "⚠️ Navigation automatique impossible: " & errMsg
            log "   → Suivez les instructions manuelles ci-dessus"
        end try
        
        log ""
        log "=================================================="
        log "✅ Instructions affichées"
        log ""
        log "💡 Alternative: Nettoyer le DerivedData"
        log "   Cela peut aussi résoudre le problème:"
        log "   rm -rf ~/Library/Developer/Xcode/DerivedData/Tshiakani_VTC-*"
        log ""
        
    end tell
end tell

