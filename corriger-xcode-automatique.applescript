-- Script AppleScript pour corriger automatiquement les erreurs de compilation dans Xcode
-- Ce script automatise les actions nécessaires dans Xcode

tell application "System Events"
    tell application "Xcode"
        activate
        delay 2
        
        -- Ouvrir le projet si pas déjà ouvert
        set projectPath to "/Users/admin/Documents/Tshiakani VTC/Tshiakani VTC.xcodeproj"
        try
            open projectPath
            delay 3
        end try
        
        -- Attendre que Xcode soit prêt
        delay 2
    end tell
    
    tell process "Xcode"
        -- Menu File > Packages > Reset Package Caches
        try
            click menu item "Reset Package Caches" of menu "Packages" of menu bar item "File" of menu bar 1
            delay 5
            log "✅ Package caches réinitialisés"
        on error
            log "⚠️ Impossible de réinitialiser les caches (peut-être déjà fait)"
        end try
        
        -- Menu File > Packages > Resolve Package Versions
        try
            click menu item "Resolve Package Versions" of menu "Packages" of menu bar item "File" of menu bar 1
            log "✅ Résolution des packages démarrée (cela peut prendre quelques minutes)"
            delay 2
        on error
            log "⚠️ Impossible de résoudre les packages (peut-être déjà en cours)"
        end try
    end tell
end tell

log "✅ Script terminé. Vérifiez Xcode pour la résolution des packages."

