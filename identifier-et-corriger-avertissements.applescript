-- Script pour compiler et identifier les vrais avertissements dans Xcode

tell application "Xcode"
    activate
    delay 2
    
    set projectPath to "/Users/admin/Documents/Tshiakani VTC/Tshiakani VTC.xcodeproj"
    
    try
        open projectPath
        delay 5
        log "✅ Projet ouvert"
    on error errMsg
        log "⚠️ Erreur: " & errMsg
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
        log "🔍 IDENTIFICATION DES AVERTISSEMENTS"
        log "===================================="
        log ""
        
        -- Étape 1: Clean Build Folder
        log "Étape 1: Clean Build Folder..."
        try
            keystroke "k" using {shift down, command down}
            delay 3
            log "✅ Clean effectué"
        on error errMsg
            log "⚠️ Erreur Clean: " & errMsg
        end try
        
        delay 2
        
        -- Étape 2: Build
        log "Étape 2: Build pour identifier les avertissements..."
        try
            keystroke "b" using {command down}
            log "✅ Build lancé"
            log ""
            log "⏳ Attente de la compilation..."
            log "   (Cela peut prendre plusieurs minutes)"
        on error errMsg
            log "⚠️ Erreur Build: " & errMsg
        end try
        
        delay 10
        
        log ""
        log "===================================="
        log "✅ Compilation lancée !"
        log ""
        log "📋 POUR VOIR LES AVERTISSEMENTS:"
        log ""
        log "1. Ouvrez le panneau d'erreurs (⌘5)"
        log ""
        log "2. Filtrez par 'Warnings' (icône jaune)"
        log "   → Cliquez sur l'icône jaune en haut du panneau"
        log ""
        log "3. Les avertissements courants à corriger:"
        log "   → Variables non utilisées: Préfixez avec _"
        log "   → Imports non utilisés: Supprimez-les"
        log "   → Code mort: Supprimez-le"
        log "   → Force unwrapping: Utilisez if let ou guard let"
        log "   → Conversions implicites: Ajoutez des casts"
        log ""
        log "4. Une fois les avertissements identifiés,"
        log "   envoyez-moi la liste et je les corrigerai"
        log ""
        log "===================================="
        
    end tell
end tell

