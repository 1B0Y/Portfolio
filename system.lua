System = {
	connection = nil, 
	serverReady = false, 
	pirated = false
}

Debugger = {
	enabled = false, 
}

System.Permissions = {
	{"function.callRemote"}, 
	{"function.kickPlayer"},
	{"function.network"}
}

addEvent("Odin:System:unsupportedResolution", true)

--[[
	System Manager

	Handles resource authentication for start up, MySQL connection initialisation, ingame chat management and more.
]]

function System.onStart(auth)
	--Make System.onStart not start unless AIDS pass this auth code.
	if not (auth == "**AUTHENTICATION_HIDDEN**") then return end

	outputServerLog("-------------------------------------------------")
	outputServerLog("--          Welcome to Odin:Reloaded           --")
	outputServerLog("--                Version: 2.0                 --")
	outputServerLog("-------------------------------------------------")
	outputServerLog("")

	Debugger.output("[ODIN_SYSTEM] Server starting, please wait...")

	--Setup the database connection
	System.connection = Connection("mysql", "dbname=server;host=**HIDDEN**;port=3306;unix_socket=/var/run/mysqld/mysqld.sock;", "**HIDDEN**", "**HIDDEN**", "share=1")
	
	if System.connection then
		--Check see if the database is online, otherwise abort.
		System.connection:query(
			function(query)
				if (query == false) then
					Debugger.output("[ODIN_SYSTEM] Database connection failed. Please check your configuration settings and start the resource again.", 1)
					cancelEvent()
					return
				end

				query:free()
				Debugger.output("[ODIN_SYSTEM] Connection established. Triggering other systems...")
				triggerEvent("Odin:System:Database:connectionEstablished", resourceRoot)
				if (Accounts.onStart() and Vehicles.onStart() and Player.onStart() and Housing.onStart()) then
					exports.scoreboard:scoreboardAddColumn("playtime", root, 70, "Playtime")
					exports.scoreboard:scoreboardAddColumn("level", root, 70, "Level")
					System.serverReady = true
					Debugger.output("[ODIN_SYSTEM] System ready. Game time!")

					for i, player in ipairs(getElementsByType("player")) do
						triggerEvent("onPlayerJoin", player)
					end
				end
			end, "SHOW VERSION"
		)
	else
		Debugger.output("[ODIN_SYSTEM] Database connection failed. Please check your configuration settings and start the resource again.", 1)
		cancelEvent() --Stop the resource from being loaded in.
		return
	end
end

function System.onStop()
	if not (System.serverReady) then return end
	outputServerLog("[ODIN_SYSTEM] Shutting systems down, please wait...")

	triggerEvent("Odin:System:systemShuttingDown", resourceRoot, true)
	if (Accounts.onStop() and Vehicles.onStop() --[[and Housing.onStop()]]) then
		outputServerLog("[ODIN_SYSTEM] Systems closed safely. Have a nice day!")
		return true
	end

	outputServerLog("[ODIN_SYSTEM] Issue closing one of more systems. Data loss may occur.")
	return false
end
addEventHandler("onResourceStop", resourceRoot, System.onStop)

function System.playerConnect()
	if System.pirated then
		source:redirect("mtasa://s1.fulltheftauto.net", 22003)
		return
	end

	if not System.serverReady then
		cancelEvent(true, "Server still loading, please retry in a few seconds.")
		return
	end
end
addEventHandler("onPlayerConnect", root, System.playerConnect)

function System.playerJoin()
	--Check see if the player is banned
	local banInfo
	if (Player.isBanned(source)) then
		banInfo = Player.getBanInfo(source)
		System.callClient(source, "Odin:System:displayBanScreen", banInfo)
		triggerEvent("Odin:System:onPlayerJoinBanned", source)
	end

	return true
end
addEventHandler("onPlayerJoin", root, System.playerJoin)

function System.playerQuit()
	--We can do shizzle here if we need to.
end
addEventHandler("onPlayerQuit", root, System.playerQuit)

function System.checkPermissions()
	--Check see if the core has the correct permissions to run
	for i, permission in ipairs(System.Permissions) do
		if (not hasObjectPermissionTo(getThisResource(), permission[1])) then
			Debugger.output("[ODIN_SYSTEM] Unable to start Odin. Server does not have the correct permissions.", 1)
			return false
		end
	end

	return true
end

function System.onPlayerChat(message, _type)
	cancelEvent()

	if not (Accounts.isPlayerLoggedIn(source)) then return false end
	local r, g, b = source:getNametagColor()
	local name = source:getName()

	if _type == 0 then
			message = name..": #FFFFFF"..message
	elseif _type == 1 then
			message = name.." "..message
	elseif _type == 2 then
			local team = source:getTeam()
			if not team then return false end

			local hex = Utils.convertToHex(r, g, b)
			outputChatBox("#FFFFFF(TEAM) "..hex..""..name..": #FFFFFF"..message, getPlayersInTeam(team), r, g, b, true)
			return true
	end

	outputChatBox(message, root, r, g, b, true)
	outputServerLog(message)
	return true
end
addEventHandler("onPlayerChat", root, System.onPlayerChat)

function System.unsupportedResolution(width, height)
	client:kick("Unsupported resolution: "..width.."x"..height)
end
addEventHandler("Odin:System:unsupportedResolution", root, System.unsupportedResolution)

function System.callClient(player, event, ...)
	if not player or not isElement(player) then return end

	return triggerClientEvent(player, event, player, ...)
end

function Debugger.output(text, level)
	if not Debugger.enabled then return end

	outputDebugString(text, level)
	return true
end
