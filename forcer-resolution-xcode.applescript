-- Script pour forcer la résolution des packages dans Xcode
tell application "Xcode"
	activate
	delay 2
	
	-- Ouvrir le projet
	set projectPath to "/Users/admin/Documents/Tshiakani VTC/Tshiakani VTC.xcodeproj"
	try
		open projectPath
		delay 5
	on error
		display dialog "Impossible d'ouvrir le projet. Veuillez l'ouvrir manuellement." buttons {"OK"}
		return
	end try
	
	-- Attendre que le projet soit chargé
	delay 5
	
	-- Utiliser System Events pour accéder au menu
	tell application "System Events"
		tell process "Xcode"
			-- Essayer d'accéder au menu File
			try
				click menu item "Packages" of menu "File" of menu bar 1
				delay 1
				click menu item "Resolve Package Versions" of menu "Packages" of menu item "Packages" of menu "File" of menu bar 1
				display dialog "Résolution des packages lancée!" buttons {"OK"}
			on error
				-- Si l'automatisation échoue, donner des instructions
				display dialog "L'automatisation du menu a échoué." & return & return & "Veuillez faire manuellement:" & return & return & "1. File > Packages > Reset Package Caches" & return & "2. File > Packages > Resolve Package Versions" & return & return & "Les packages devraient se résoudre automatiquement grâce au Package.resolved créé." buttons {"OK"} default button "OK"
			end try
		end tell
	end tell
end tell

