on run
	try
		set configDir to (path to home folder as text) & ".config:display-layout:"
		set configFile to configDir & "display-layout.plist"
		
		set configDirPath to POSIX path of configDir
		set configFilePath to POSIX path of configFile
		
		tell application "System Events"
			if not (exists file configFile) then
				display dialog "Configuration file not found at:" & return & configFilePath & return & return & "Please run CaptureDisplayLayout first." buttons {"OK"} default button 1 with icon stop
				return
			end if
		end tell
		
		set displayplacerPath to findDisplayplacer()
		
		if displayplacerPath is "" then
			set installResult to offerDisplayplacerInstallation()
			if installResult is "install" then
				set installSuccess to installDisplayplacer()
				if installSuccess then
					set displayplacerPath to findDisplayplacer()
					if displayplacerPath is "" then
						display dialog "Installation completed, but displayplacer was not found. Please restart the script or check your PATH." buttons {"OK"} default button 1 with icon caution
						return
					end if
				else
					return
				end if
			else
				return
			end if
		end if
		
		set plistContent to do shell script "cat " & quoted form of configFilePath
		set savedDisplays to parsePlistDisplays(plistContent)
		
		set currentDisplayList to do shell script quoted form of displayplacerPath & " list"
		set availableDisplays to extractAvailableDisplays(currentDisplayList)
		
		set displayplacerCommand to ""
		set restoredCount to 0
		set missingCount to 0
		set missingDisplayNames to {}
		set mainDisplayCommand to ""
		set nonMainDisplayCommands to {}
		
		repeat with savedDisplay in savedDisplays
			set savedScreenId to getValueForKey(savedDisplay, "persistentScreenId")
			set savedScreenId to trimWhitespace(savedScreenId)
			set isAvailable to false
			set availableScreenId to ""
			set matchedDisplay to {}
			
			repeat with availableDisplay in availableDisplays
				set availableScreenId to getValueForKey(availableDisplay, "persistentScreenId")
				set availableScreenId to trimWhitespace(availableScreenId)
				if availableScreenId is savedScreenId then
					set isAvailable to true
					set matchedDisplay to availableDisplay
					exit repeat
				end if
			end repeat
			
			if isAvailable then
				set enabledStatus to getValueForKey(matchedDisplay, "enabled")
				if enabledStatus is "" or enabledStatus is "true" then
					set displayCommand to buildDisplayCommand(savedDisplay)
					if displayCommand is not "" then
						set isMain to getValueForKey(savedDisplay, "isMain")
						if isMain is "true" then
							set mainDisplayCommand to quoted form of displayCommand
						else
							set end of nonMainDisplayCommands to quoted form of displayCommand
						end if
						set restoredCount to restoredCount + 1
					end if
				else
					set missingCount to missingCount + 1
					set displayName to getValueForKey(savedDisplay, "type")
					if displayName is "" then
						set displayName to "Display " & savedScreenId
					end if
					set end of missingDisplayNames to displayName & " (disabled)"
				end if
			else
				set missingCount to missingCount + 1
				set displayName to getValueForKey(savedDisplay, "type")
				if displayName is "" then
					set displayName to "Display " & savedScreenId
				end if
				set end of missingDisplayNames to displayName
			end if
		end repeat
		
		if mainDisplayCommand is not "" then
			set displayplacerCommand to mainDisplayCommand
		end if
		
		repeat with cmd in nonMainDisplayCommands
			if displayplacerCommand is not "" then
				set displayplacerCommand to displayplacerCommand & " "
			end if
			set displayplacerCommand to displayplacerCommand & cmd
		end repeat
		
		if displayplacerCommand is "" then
			display dialog "No displays from the saved configuration are currently available." buttons {"OK"} default button 1 with icon caution
			return
		end if
		
		do shell script quoted form of displayplacerPath & " " & displayplacerCommand
		
		set resultMessage to "Display configuration restored!" & return & return
		set resultMessage to resultMessage & "Restored: " & restoredCount & " display(s)" & return
		
		if missingCount > 0 then
			set resultMessage to resultMessage & "Missing: " & missingCount & " display(s)" & return
			repeat with missingName in missingDisplayNames
				set resultMessage to resultMessage & "  - " & missingName & return
			end repeat
		end if
		
		display dialog resultMessage buttons {"OK"} default button 1 with icon note
		
	on error errorMessage
		display dialog "Error restoring display layout: " & errorMessage buttons {"OK"} default button 1 with icon stop
	end try
end run

on parsePlistDisplays(plistContent)
	set displays to {}
	set inDisplayDict to false
	set inDisplaysArray to false
	set currentDisplay to {}
	set currentKey to ""
	
	set plistLines to paragraphs of plistContent
	
	repeat with aLine in plistLines
		set lineText to trimWhitespace(aLine)
		
		if lineText contains "<key>displays</key>" then
			set inDisplaysArray to true
		else if lineText contains "</array>" and inDisplaysArray then
			set inDisplaysArray to false
		else if inDisplaysArray then
			if lineText contains "<dict>" and lineText does not contain "</dict>" then
				if inDisplayDict then
					set end of displays to currentDisplay
				end if
				set currentDisplay to {}
				set inDisplayDict to true
			else if lineText contains "</dict>" then
				if inDisplayDict then
					set end of displays to currentDisplay
					set currentDisplay to {}
					set inDisplayDict to false
				end if
			else if lineText starts with "<key>" then
				set keyStart to "<key>"
				set keyEnd to "</key>"
				set keyStartPos to offset of keyStart in lineText
				set keyEndPos to offset of keyEnd in lineText
				if keyStartPos > 0 and keyEndPos > keyStartPos then
					set currentKey to text (keyStartPos + (length of keyStart)) thru (keyEndPos - 1) of lineText
				end if
			else if lineText starts with "<string>" then
				set valueStart to "<string>"
				set valueEnd to "</string>"
				set valueStartPos to offset of valueStart in lineText
				set valueEndPos to offset of valueEnd in lineText
				if valueStartPos > 0 and valueEndPos > valueStartPos then
					set currentValue to text (valueStartPos + (length of valueStart)) thru (valueEndPos - 1) of lineText
					set currentValue to unescapeXML(currentValue)
					if currentKey is "rotation" then
						set currentValue to extractNumericValue(currentValue)
					end if
					set end of currentDisplay to {key:currentKey, value:currentValue}
				end if
			else if lineText contains "<true/>" or lineText contains "<false/>" then
				if currentKey is "isMain" then
					if lineText contains "<true/>" then
						set end of currentDisplay to {key:"isMain", value:"true"}
					else
						set end of currentDisplay to {key:"isMain", value:"false"}
					end if
				end if
			end if
		end if
	end repeat
	
	if inDisplayDict and (count of currentDisplay) > 0 then
		set end of displays to currentDisplay
	end if
	
	return displays
end parsePlistDisplays

on extractAvailableDisplays(displayListOutput)
	set availableDisplays to {}
	set currentDisplay to {}
	set displayLines to paragraphs of displayListOutput
	
	repeat with aLine in displayLines
		set lineText to trimWhitespace(aLine)
		
		if lineText starts with "Persistent screen id:" then
			if (count of currentDisplay) > 0 then
				set end of availableDisplays to currentDisplay
			end if
			set currentDisplay to {}
			set screenId to extractValue(lineText, "Persistent screen id:")
			set end of currentDisplay to {key:"persistentScreenId", value:screenId}
		else if lineText starts with "Type:" then
			set displayType to extractValue(lineText, "Type:")
			set end of currentDisplay to {key:"type", value:displayType}
		else if lineText starts with "Enabled:" then
			set enabledValue to extractValue(lineText, "Enabled:")
			if enabledValue is "true" then
				set end of currentDisplay to {key:"enabled", value:"true"}
			end if
		end if
	end repeat
	
	if (count of currentDisplay) > 0 then
		set end of availableDisplays to currentDisplay
	end if
	
	return availableDisplays
end extractAvailableDisplays

on buildDisplayCommand(displayConfig)
	set commandParts to {}
	
	set screenId to getValueForKey(displayConfig, "persistentScreenId")
	if screenId is "" then
		return ""
	end if
	
	set end of commandParts to "id:" & screenId
	
	set resolution to getValueForKey(displayConfig, "resolution")
	if resolution is not "" then
		set end of commandParts to "res:" & resolution
	end if
	
	set hertz to getValueForKey(displayConfig, "hertz")
	if hertz is not "" then
		set end of commandParts to "hz:" & hertz
	end if
	
	set colorDepth to getValueForKey(displayConfig, "colorDepth")
	if colorDepth is not "" then
		set end of commandParts to "color_depth:" & colorDepth
	end if
	
	set scaling to getValueForKey(displayConfig, "scaling")
	if scaling is not "" then
		set end of commandParts to "scaling:" & scaling
	end if
	
	set origin to getValueForKey(displayConfig, "origin")
	if origin is not "" then
		set originCoords to extractOriginCoordinates(origin)
		if originCoords is not "" then
			set end of commandParts to "origin:" & originCoords
		end if
	end if
	
	set AppleScript's text item delimiters to " "
	set commandString to commandParts as string
	set AppleScript's text item delimiters to ""
	
	return commandString
end buildDisplayCommand

on getValueForKey(displayConfig, searchKey)
	repeat with configItem in displayConfig
		set itemKey to key of configItem
		if itemKey is searchKey then
			return value of configItem
		end if
	end repeat
	return ""
end getValueForKey

on extractValue(lineText, prefix)
	set prefixLength to length of prefix
	if length of lineText > prefixLength then
		set valueText to text (prefixLength + 1) thru -1 of lineText
		return trimWhitespace(valueText)
	end if
	return ""
end extractValue

on trimWhitespace(inputString)
	set AppleScript's text item delimiters to ""
	set trimmed to inputString
	repeat while trimmed starts with " " or trimmed starts with tab
		set trimmed to text 2 thru -1 of trimmed
	end repeat
	repeat while trimmed ends with " " or trimmed ends with tab
		set trimmed to text 1 thru -2 of trimmed
	end repeat
	return trimmed
end trimWhitespace

on extractOriginCoordinates(originString)
	set openParenPos to offset of "(" in originString
	set closeParenPos to offset of ")" in originString
	if openParenPos > 0 and closeParenPos > openParenPos then
		return text openParenPos thru closeParenPos of originString
	end if
	return originString
end extractOriginCoordinates

on extractNumericValue(inputString)
	set trimmed to trimWhitespace(inputString)
	set numericPart to ""
	repeat with i from 1 to length of trimmed
		set currentChar to text i thru i of trimmed
		if currentChar is in "0123456789" then
			set numericPart to numericPart & currentChar
		else if numericPart is not "" then
			exit repeat
		end if
	end repeat
	return numericPart
end extractNumericValue

on unescapeXML(inputString)
	set unescaped to inputString
	set unescaped to my replaceText(unescaped, "&apos;", "'")
	set unescaped to my replaceText(unescaped, "&quot;", "\"")
	set unescaped to my replaceText(unescaped, "&gt;", ">")
	set unescaped to my replaceText(unescaped, "&lt;", "<")
	set unescaped to my replaceText(unescaped, "&amp;", "&")
	return unescaped
end unescapeXML

on replaceText(inputString, searchString, replaceString)
	set AppleScript's text item delimiters to searchString
	set textItems to text items of inputString
	set AppleScript's text item delimiters to replaceString
	set resultString to textItems as string
	set AppleScript's text item delimiters to ""
	return resultString
end replaceText

on findDisplayplacer()
	set possiblePaths to {"/usr/local/bin/displayplacer", "/opt/homebrew/bin/displayplacer", "/opt/homebrew/opt/displayplacer/bin/displayplacer"}
	
	repeat with testPath in possiblePaths
		try
			do shell script "test -f " & quoted form of testPath & " && echo exists"
			return testPath
		end try
	end repeat
	
	try
		set whichResult to do shell script "which displayplacer 2>/dev/null"
		if whichResult is not "" then
			return whichResult
		end if
	end try
	
	return ""
end findDisplayplacer

on offerDisplayplacerInstallation()
	set dialogResult to display dialog "displayplacer is not installed." & return & return & "Would you like to install it automatically using Homebrew?" buttons {"Install", "Cancel"} default button "Install" with icon question
	if button returned of dialogResult is "Install" then
		return "install"
	else
		return "cancel"
	end if
end offerDisplayplacerInstallation

on installDisplayplacer()
	try
		do shell script "brew install displayplacer" with administrator privileges
		
		display dialog "displayplacer installed successfully!" buttons {"OK"} default button 1 with icon note
		return true
	on error errorMessage
		display dialog "Failed to install displayplacer: " & errorMessage & return & return & "Please install manually using: brew install displayplacer" buttons {"OK"} default button 1 with icon stop
		return false
	end try
end installDisplayplacer

