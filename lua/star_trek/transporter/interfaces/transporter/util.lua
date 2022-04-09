---------------------------------------
---------------------------------------
--        Star Trek Utilities        --
--                                   --
--            Created by             --
--       Jan 'Oninoni' Ziegler       --
--                                   --
-- This software can be used freely, --
--    but only distributed by me.    --
--                                   --
--    Copyright © 2022 Jan Ziegler   --
---------------------------------------
---------------------------------------

---------------------------------------
--      LCARS Transporter | Util     --
---------------------------------------

if not istable(INTERFACE) then Star_Trek:LoadAllModules() return end
local SELF = INTERFACE

local DEMAT_DELAY = 5

function SELF:GetSelectedMenuType(menuTable)
	local selected = menuTable.MenuWindow:GetSelected()

	local menuType
	for type, active in pairs(selected) do
		if active then
			menuType = type
		end
	end

	return menuType
end

function SELF:GetMenuType(menuType, target)
	if istable(menuType) then
		if target then
			menuType = menuType[2]
		else
			menuType = menuType[1]
		end
	end

	return menuType
end

-- Returns the name of the currently selected transporter mode.
--
-- @param Table menuTable
-- @return String modeName
function SELF:GetMode(menuTable)
	local menuType = self:GetSelectedMenuType(menuTable)
	local modeName = self:GetMenuType(menuType, menuTable.Target)

	return modeName
end

-- Scan the selected menuTable for entities and compile locations for a beamin.
--
-- @param table menuTable
-- @param Boolean wideField
-- @return table patterns
function SELF:GetPatternData(menuTable, wideField)
	local modeName = self:GetMode(menuTable)
	local mainWindow = menuTable.MainWindow

	if modeName == "Transporter Pad" then
		local pads = {}
		for _, pad in pairs(mainWindow.Pads) do
			if pad.Selected then
				table.insert(pads, pad.Data)
			end
		end

		return Star_Trek.Transporter:GetPatternsFromPads(pads)
	elseif modeName == "Crew" then
		local players = {}
		for _, button in pairs(mainWindow.Buttons) do
			if button.Selected then
				local ply = button.Data
				if hook.Run("Star_Trek.Transporter.CheckLifeforms", ply) == false then
					continue
				end

				table.insert(players, ply)
			end
		end

		return Star_Trek.Transporter:GetPatternsFromPlayers(players, wideField)
	elseif modeName == "Sections" then
		local deck = mainWindow.Selected
		if menuTable.Target then
			local positions = {}

			for _, button in pairs(mainWindow.Buttons or {}) do
				if not button.Selected then
					continue
				end

				local sectionData = Star_Trek.Sections:GetSection(deck, button.Data)
				if not sectionData then
					continue
				end

				for _, pos in pairs(sectionData.BeamLocations or {}) do
					table.insert(positions, pos)
				end
			end

			return Star_Trek.Transporter:GetPatternsFromLocations(positions, wideField)
		else
			local sectionIds = {}

			for buttonId, buttonData in pairs(mainWindow.Buttons) do
				if buttonData.Selected then
					table.insert(sectionIds, buttonData.Data)
				end
			end

			return Star_Trek.Transporter:GetPatternsFromAreas(deck, sectionIds)
		end
	elseif modeName == "Buffer" then
		local entities = {}
		for _, button in pairs(mainWindow.Buttons) do
			if button.Selected then
				table.insert(entities, button.Data)
			end
		end

		return Star_Trek.Transporter:GetPatternsFromBuffers(entities)
	elseif modeName == "Other Pads" or modeName == "Transporter Pads"  then
		local pads = {}
		for _, button in pairs(mainWindow.Buttons) do
			if button.Selected then
				for _, pad in pairs(button.Data) do
					table.insert(pads, pad)
				end
			end
		end

		return Star_Trek.Transporter:GetPatternsFromPads(pads)
	elseif modeName == "External" then
		local positions = {}
		for _, button in pairs(mainWindow.Buttons) do
			if button.Selected then
				local pos = button.Data
				table.insert(positions, pos)

				for i = 1, 6 do
					local a = math.rad( ( i / 6 ) * -360 )

					table.insert(positions, pos + 32 * Vector(math.sin(a), math.cos(a), 0))
				end
			end
		end

		return Star_Trek.Transporter:GetPatternsFromLocations(positions, wideField)
	end
end

-- Prevent Noclipped players from being listed.
hook.Add("Star_Trek.Transporter.CheckLifeforms", "Star_Trek.Transporter.PreventAdmins", function(ply)
	if ply:GetMoveType() == MOVETYPE_NOCLIP then
		return false
	end
end)

-- Engage a transporter system with the given menu tables and wide field.
--
-- @param Player ply
-- @param Table sourceMenuTable
-- @param Table targetMenuTable
-- @param? Boolean wideField
-- @param? Function callback
function SELF:Energize(ply, sourceMenuTable, targetMenuTable, wideField, callback)
	local sourcePatterns = self:GetPatternData(sourceMenuTable, wideField)
	local targetPatterns = self:GetPatternData(targetMenuTable, false)
	Star_Trek.Transporter:ActivateTransporter(self.Ent, ply, sourcePatterns, targetPatterns, self.CycleClass, self.NoBuffer)

	--ent:EmitSound("star_trek.lcars_transporter_lock")

	if isfunction(callback) then
		callback(sourcePatterns, targetPatterns)
	end
end

-- Force Update of Source Buffer Table, by just switching.
--
-- @param Table sourceMenuTable
function SELF:UpdateBufferMenu(sourceMenuTable)
	local success, error = sourceMenuTable:SelectType(sourceMenuTable.MenuTypes[1])
	if not success then
		Star_Trek:Message(error)
		return
	end

	sourceMenuTable.MenuWindow:Update()
	sourceMenuTable.MainWindow:Update()
end

-- Trigger a Transporter.
--
-- @param Player ply
-- @param Table sourceMenuTable
-- @param Table targetMenuTable
function SELF:TriggerTransporter(ply, sourceMenuTable, targetMenuTable)
	local wideField = false
	if isfunction(sourceMenuTable.GetUtilButtonState) then
		wideField = sourceMenuTable:GetUtilButtonState()
	end

	local delayDematerialisation = false
	if isfunction(targetMenuTable.GetUtilButtonState) then
		delayDematerialisation = targetMenuTable:GetUtilButtonState()
	end

	if delayDematerialisation then
		timer.Simple(DEMAT_DELAY, function()
			self:Energize(ply, sourceMenuTable, targetMenuTable, wideField, function(sourcePatterns, targetPatterns)
				if sourcePatterns.IsBuffer then self:UpdateBufferMenu(sourceMenuTable) end
			end)
		end)
	else
		self:Energize(ply, sourceMenuTable, targetMenuTable, wideField, function(sourcePatterns, targetPatterns)
			if sourcePatterns.IsBuffer then self:UpdateBufferMenu(sourceMenuTable) end
		end)
	end
end