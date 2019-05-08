Progression = {
	exponent = 1.15, 
	baseXP = 200
}

addEvent("Odin:Accounts:onPlayerLoggedIn", true)

--[[
	Player Progression System
	USAGE: See functions below

	Introduces a leveling system that can be interpreted into any gaming platform with slight adjustments and enables players to gain levels when they perform an action.
]]

function Progression.onPlayerLogin()
	local level = Accounts.getData(Accounts.getPlayerAccount(source), "level") or 0
	local xp = Accounts.getData(Accounts.getPlayerAccount(source), "xp") or 0

	source:setData("level", level, true)
	source:setData("xp", xp, true)
end
addEventHandler("Odin:Accounts:onPlayerLoggedIn", root, Progression.onPlayerLogin)

function Progression.getPlayerXP(player)
	if not player or not isElement(player) then return false end
	if not Accounts.isPlayerLoggedIn(player) then return false end

	local xp = Accounts.getData(Accounts.getPlayerAccount(player), "xp") or 0
	return xp
end

function Progression.getPlayerLevel(player)
	if not player or not isElement(player) then return false end
	if not Accounts.isPlayerLoggedIn(player) then return false end

	local level = Accounts.getData(Accounts.getPlayerAccount(player), "level") or 1
	return level
end

function Progression.setPlayerXP(player, xp)
	if not player or not isElement(player) then return false end
	if not Accounts.isPlayerLoggedIn(player) then return false end

	Accounts.setData(Accounts.getPlayerAccount(player), "xp", xp)
	return true
end

function Progression.setPlayerLevel(player, level)
	if not player or not isElement(player) then return false end
	if not Accounts.isPlayerLoggedIn(player) then return false end
	if not level or type(level) ~= "number" then return false end

	Accounts.setData(Accounts.getPlayerAccount(player), "level", level)
	player:setData("level", level, true)
	return true
end

function Progression.givePlayerXP(player, xp)
	if not player or not isElement(player) then return false end
	if not Accounts.isPlayerLoggedIn(player) then return false end
	if not xp or type(xp) ~= "number" then return false end

	local playerXP = Progression.getPlayerXP(player)
	local level = Progression.getPlayerLevel(player)

	--Add XP before calling checkLevelUpProgress
	Progression.setPlayerXP(player, playerXP+xp)

	--Check progression of his leveling.
	if (Progression.checkLevelUpProgress(player)) then --Level up!
		--Calculate the excess for that level, before resetting.
		local xpExcess = Progression.getNextLevelXP(level)
		xpExcess = (playerXP+xp) - xpExcess --Excess should now be on there
		Progression.setPlayerXP(player, xpExcess)
		Progression.setPlayerLevel(player, level+1)

		Player.createNotification(player, "Leveled up!", "You're now level "..Progression.getPlayerLevel(player).."!")
		triggerEvent("Odin:Progression:onPlayerLeveledUp", player, Progression.getPlayerLevel(player), playerXP, Progression.getPlayerXP(player))
		System.callClient(player, "Odin:Progression:onPlayerGainedXP", Progression.getPlayerLevel(player), 0, Progression.getPlayerXP(player))
	else
		System.callClient(player, "Odin:Progression:onPlayerGainedXP", Progression.getPlayerLevel(player), playerXP, Progression.getPlayerXP(player))
	end

	return true
end

function Progression.getNextLevelXP(level)
	return Utils.round(Progression.baseXP * (level ^ Progression.exponent))
end

function Progression.checkLevelUpProgress(player)
	local xp = Progression.getPlayerXP(player) or 0
	local level = Progression.getPlayerLevel(player) or 0

	--Check if the XP exceeds next level's XP. If so, return true to process level announcement
	if (xp >= Progression.getNextLevelXP(level)) then
		return true --Process level up in other function
	else
		return false --Not ready to level up, but add XP anyways.
	end
end