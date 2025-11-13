-- Script AppleScript pour résoudre automatiquement les packages dans Xcode
tell application "Xcode"
	activate
	delay 2
	
	-- Ouvrir le projet si pas déjà ouvert
	set projectPath to "/Users/admin/Documents/Tshiakani VTC/Tshiakani VTC.xcodeproj"
	try
		open projectPath
		delay 5
	on error
		display dialog "Impossible d'ouvrir le projet. Veuillez l'ouvrir manuellement." buttons {"OK"}
		return
	end try
	
	-- Attendre que le projet soit chargé
	delay 3
	
	-- Instructions pour l'utilisateur
	display dialog "Le projet est ouvert dans Xcode." & return & return & "Le script va maintenant essayer de résoudre les packages." & return & return & "Si cela ne fonctionne pas automatiquement, suivez ces étapes:" & return & return & "1. File > Packages > Reset Package Caches" & return & "2. File > Packages > Resolve Package Versions" & return & return & "Appuyez sur OK pour continuer." buttons {"OK"} default button "OK"
	
	-- Essayer d'accéder au menu File > Packages
	tell application "System Events"
		tell process "Xcode"
			-- Essayer d'ouvrir le menu File
			try
				click menu bar item "File" of menu bar 1
				delay 1
				
				-- Essayer d'accéder au sous-menu Packages
				try
					click menu item "Packages" of menu "File" of menu bar 1
					delay 1
					
					-- Essayer de cliquer sur Reset Package Caches
					try
						click menu item "Reset Package Caches" of menu "Packages" of menu "File" of menu bar 1
						delay 3
						
						-- Essayer de cliquer sur Resolve Package Versions
						try
							click menu bar item "File" of menu bar 1
							delay 1
							click menu item "Packages" of menu "File" of menu bar 1
							delay 1
							click menu item "Resolve Package Versions" of menu "Packages" of menu "File" of menu bar 1
							
							display dialog "Résolution des packages lancée!" & return & return & "Attendez 2-5 minutes que les packages soient téléchargés." & return & "Vous verrez une barre de progression en bas de Xcode." buttons {"OK"} default button "OK"
						on error
							display dialog "Impossible d'automatiser 'Resolve Package Versions'." & return & return & "Veuillez le faire manuellement:" & return & "File > Packages > Resolve Package Versions" buttons {"OK"} default button "OK"
						end try
					on error
						display dialog "Impossible d'automatiser 'Reset Package Caches'." & return & return & "Veuillez le faire manuellement:" & return & "File > Packages > Reset Package Caches" buttons {"OK"} default button "OK"
					end try
				on error
					display dialog "Impossible d'accéder au menu Packages." & return & return & "Veuillez résoudre les packages manuellement:" & return & "File > Packages > Resolve Package Versions" buttons {"OK"} default button "OK"
				end try
			on error
				display dialog "Impossible d'accéder au menu File." & return & return & "Veuillez résoudre les packages manuellement:" & return & "File > Packages > Resolve Package Versions" buttons {"OK"} default button "OK"
			end try
		end tell
	end tell
end tell

