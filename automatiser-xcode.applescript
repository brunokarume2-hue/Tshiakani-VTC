-- Script AppleScript amélioré pour automatiser les corrections dans Xcode
-- Ce script attend que Xcode soit prêt avant d'effectuer les actions

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
        -- Attendre que Xcode soit complètement chargé
        repeat 10 times
            try
                if exists menu bar 1 then
                    exit repeat
                end if
            end try
            delay 1
        end repeat
        
        delay 2
        
        -- Action 1: Reset Package Caches
        try
            tell menu bar 1
                tell menu bar item "File"
                    tell menu "File"
                        tell menu item "Packages"
                            tell menu "Packages"
                                click menu item "Reset Package Caches"
                            end tell
                        end tell
                    end tell
                end tell
            end tell
            delay 3
            log "✅ Package caches réinitialisés"
        on error errMsg
            log "⚠️ Reset Package Caches: " & errMsg
        end try
        
        -- Action 2: Resolve Package Versions
        try
            tell menu bar 1
                tell menu bar item "File"
                    tell menu "File"
                        tell menu item "Packages"
                            tell menu "Packages"
                                click menu item "Resolve Package Versions"
                            end tell
                        end tell
                    end tell
                end tell
            end tell
            log "✅ Résolution des packages démarrée"
            log "⏳ Cela peut prendre 2-5 minutes. Surveillez la barre de progression en bas d'Xcode."
        on error errMsg
            log "⚠️ Resolve Package Versions: " & errMsg
        end try
        
        delay 2
        
        -- Note: Les autres actions (retirer Info.plist des ressources, vérifier les frameworks)
        -- nécessitent une interaction avec l'interface graphique qui est plus complexe à automatiser
        -- Ces actions doivent être faites manuellement
        
    end tell
end tell

log ""
log "✅ Automatisation terminée"
log ""
log "📋 Actions restantes à effectuer manuellement dans Xcode:"
log ""
log "1. Retirer Info.plist de Copy Bundle Resources:"
log "   - Target 'Tshiakani VTC' > Build Phases > Copy Bundle Resources"
log "   - Si Info.plist est présent, supprimez-le"
log ""
log "2. Vérifier les frameworks:"
log "   - Target 'Tshiakani VTC' > General"
log "   - Section 'Frameworks, Libraries, and Embedded Content'"
log "   - Vérifiez que GoogleMaps et GooglePlaces sont présents"
log ""
log "3. Nettoyer et compiler:"
log "   - Product > Clean Build Folder (⇧⌘K)"
log "   - Product > Build (⌘B)"

