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
--  LCARS Transporter | Window Util  --
---------------------------------------

if not istable(INTERFACE) then Star_Trek:LoadAllModules() return end
local SELF = INTERFACE

-- Create the menu window for a transporter screen.
--
-- @param Vector pos
-- @param Angle angle
-- @param Number width
-- @param Table menuTable
-- @param? Boolean hFlip
-- @return Boolean success 
-- @return Table menuWindow
function SELF:CreateMenuWindow(pos, angle, width, menuTable, hFlip)
	local buttons = {}

	local n = 0
	for i, menuType in pairs(menuTable.MenuTypes) do
		n = n + 1

		local name = self:GetMenuType(menuType, menuTable.Target)
		if not name then continue end

		local color = Star_Trek.LCARS.ColorBlue
		if i % 2 == 0 then
			color = Star_Trek.LCARS.ColorLightBlue
		end

		local button = {
			Name = name,
			Color = color,
		}

		table.insert(buttons, button)
	end

	if self.AdvancedMode then
		local utilButtonData = {}
		if not menuTable.Target then
			utilButtonData.Name = "Narrow Beam"
			utilButtonData.Color = Star_Trek.LCARS.ColorOrange
		else
			utilButtonData.Name = "Instant Dematerialisation"
			utilButtonData.Color = Star_Trek.LCARS.ColorOrange
		end

		buttons[n + 2] = utilButtonData
		menuTable.UtilButtonId = n + 2
		n = n + 1

		function menuTable:GetUtilButtonState()
			return self.MenuWindow.Buttons[self.UtilButtonId].SelectedCustom or false
		end
	end

	local actionButtonData = {}
	if menuTable.Target then
		actionButtonData.Name = "Disable Console"
		actionButtonData.Color = Star_Trek.LCARS.ColorRed
	else
		actionButtonData.Name = "Swap Sides"
		actionButtonData.Color = Star_Trek.LCARS.ColorOrange
	end
	buttons[n + 2] = actionButtonData
	menuTable.ActionButtonId = n + 2

	local height = table.maxn(buttons) * 35 + 80
	local transporterType = menuTable.Target and "Target" or "Source"
	local name = "Transporter " .. transporterType
	local success, menuWindow = Star_Trek.LCARS:CreateWindow(
		"button_list",
		pos,
		angle,
		24,
		width,
		height,
		function(windowData, interfaceData, ply, buttonId)
			if buttonId > n then -- Custom Buttons
				local button = windowData.Buttons[buttonId]
				if button.Name == "Wide Beam" or button.Name == "Narrow Beam" then
					button.SelectedCustom = not (button.SelectedCustom or false)
					if button.SelectedCustom then
						button.Color = Star_Trek.LCARS.ColorRed
					else
						button.Color = Star_Trek.LCARS.ColorOrange
					end

					if button.SelectedCustom then
						button.Name = "Wide Beam"
					else
						button.Name = "Narrow Beam"
					end

					return true
				end

				if button.Name == "Instant Dematerialisation" or button.Name == "Delayed Dematerialisation" then
					button.SelectedCustom = not (button.SelectedCustom or false)
					if button.SelectedCustom then
						button.Color = Star_Trek.LCARS.ColorRed
					else
						button.Color = Star_Trek.LCARS.ColorOrange
					end

					if button.SelectedCustom then
						button.Name = "Delayed Dematerialisation"
					else
						button.Name = "Instant Dematerialisation"
					end

					return true
				end

				if button.Name == "Disable Console" then
					windowData:Close()

					return false
				end

				if button.Name == "Swap Sides" then
					local targetMenuTable = menuTable.TargetMenuTable
					local sourceMenuSelectionName = self:GetSelectedMenuType(menuTable)
					local targetMenuSelectionName = self:GetSelectedMenuType(targetMenuTable)
					if sourceMenuSelectionName == "Buffer" then
						interfaceData.Ent:EmitSound("star_trek.lcars_error")

						return false
					end

					local sourceMenuData = menuTable.MainWindow:GetSelected()
					local targetMenuData = targetMenuTable.MainWindow:GetSelected()

					local success2, error2 = menuTable:SelectType(targetMenuSelectionName)
					if not success2 then
						Star_Trek:Message(error2)
						return
					end

					local success3, error3 = targetMenuTable:SelectType(sourceMenuSelectionName)
					if not success3 then
						Star_Trek:Message(error3)
						return
					end

					targetMenuTable.MainWindow:SetSelected(sourceMenuData)
					menuTable.MainWindow:SetSelected(targetMenuData)

					-- Update All Windows (Source Menu Window gets updated automatically)
					targetMenuTable.MenuWindow:Update()
					targetMenuTable.MainWindow:Update()
					menuTable.MainWindow:Update()

					return true
				end
			else
				local success4, error4 = menuTable:SelectType(menuTable.MenuTypes[buttonId])
				if not success4 then
					Star_Trek:Message(error4)
					return
				end

				-- Update Main Window (Source Menu Window gets updated automatically)
				menuTable.MainWindow:Update()

				return true
			end
		end,
		buttons,
		name,
		transporterType,
		hFlip
	)
	if not success then
		return false, menuWindow
	end

	return true, menuWindow
end

-- @param Vector pos
-- @param Angle angle
-- @param Number width
-- @param Number height
-- @param Table menuTable
-- @param? Boolean hFlip
-- @return Boolean success 
-- @return Table mainWindow
function SELF:CreateMainWindow(pos, angle, width, height, menuTable, hFlip)
	local modeName = self:GetMode(menuTable)

	-- Transport Pad Window
	if modeName == "Transporter Pad" then
		local success, mainWindow = Star_Trek.LCARS:CreateWindow(
			"transport_pad",
			pos,
			angle,
			nil,
			width,
			height,
			nil,
			self.PadEntities or {},
			"Transporter Pad",
			"Pad",
			hFlip
		)
		if not success then
			return false, mainWindow
		end

		return true, mainWindow
	end

	-- Category List Window
	if modeName == "Sections" then
		local success, mainWindow = Star_Trek.LCARS:CreateWindow(
			"category_list",
			pos,
			angle,
			nil,
			width,
			height,
			nil,
			Star_Trek.Sections:GetSectionCategories(menuTable.Target),
			"Sections",
			"SECTNS",
			hFlip,
			true
		)
		if not success then
			return false, mainWindow
		end

		return true, mainWindow
	end

	-- Button List Window
	local titleShort = ""
	local buttons = {}

	if modeName == "Crew" then
		titleShort = "CREW"

		for _, ply in pairs(player.GetHumans()) do
			if hook.Run("Star_Trek.Transporter.CheckLifeforms", ply) == false then
				continue
			end

			table.insert(buttons, {
				Name = ply:GetName(),
				Data = ply,
			})
		end
		table.SortByMember(buttons, "Name")
	elseif modeName == "Buffer" then
		titleShort = "Buffer"

		for _, ent in pairs(Star_Trek.Transporter.Buffer.Entities) do
			if not IsValid(ent) then
				continue
			end

			local name = "Unknown Pattern"
			if ent:IsPlayer() or ent:IsNPC() then
				name = "Organic Pattern"
			end
			local className = ent:GetClass()
			if className == "prop_physics" then
				name = "Pattern"
			end

			table.insert(buttons, {
				Name = name,
				Data = ent,
			})
		end
	elseif modeName == "Transporter Rooms" then
		titleShort = "Rooms"

		local pads = Star_Trek.Transporter:GetTransporterRooms(self)

		for _, roomData in SortedPairs(pads) do
			table.insert(buttons, {
				Name = roomData.Name,
				Data = roomData.Pads,
			})
		end
	elseif modeName == "External Sensors" then
		titleShort = "External"

		local externalMarkers = Star_Trek.Transporter:GetExternalMarkers(self)
		for _, externalData in pairs(externalMarkers) do
			table.insert(buttons, {
				Name = externalData.Name,
				Data = externalData.Pos,
			})
		end
	else
		return false, "Invalid Menu Type"
	end

	local success, mainWindow = Star_Trek.LCARS:CreateWindow(
		"button_list",
		pos,
		angle,
		nil,
		width,
		height,
		nil,
		buttons,
		modeName,
		titleShort,
		hFlip,
		true
	)
	if not success then
		return false, mainWindow
	end

	return true, mainWindow
end

-- Create the Window Pair for one side of the transporter interface.
--
-- @param Vector menuPos
-- @param Angle menuAngle
-- @param Number menuWidth
-- @param Vector mainPos
-- @param Angle mainAngle
-- @param Number mainWidth
-- @param Number mainHeight
-- @param Boolean hFlip
-- @param Boolean targetSide
-- @return Boolean success 
-- @return Table mainWindow
function SELF:CreateWindowTable(menuPos, menuAngle, menuWidth, mainPos, mainAngle, mainWidth, mainHeight, hFlip, targetSide)
	local menuTypes = {
		"Crew",
		"Transporter Rooms",
		"Sections",
		"External Sensors",
	}
	if istable(self.PadEntities) and table.Count(self.PadEntities) > 0 then
		menuTypes = {
			"Transporter Pad",
			"Transporter Rooms",
			"Sections",
			"Crew",
			"External Sensors",
		}
	end

	if self.AdvancedMode then
		table.insert(menuTypes, {"Buffer", false})

	end

	local menuTable = {
		MenuTypes = menuTypes,
		Target = targetSide or false,
	}

	local success, menuWindow = self:CreateMenuWindow(menuPos, menuAngle, menuWidth, menuTable, hFlip)
	if not success then
		return false, "Error on MenuWindow: " .. menuWindow
	end
	menuTable.MenuWindow = menuWindow

	local interfaceData = self
	function menuTable:SelectType(menuType)
		local name = interfaceData:GetMenuType(menuType, self.Target)
		menuTable.MenuWindow:SetSelected({
			[name] = true,
		})

		local success2, mainWindow = interfaceData:CreateMainWindow(mainPos, mainAngle, mainWidth, mainHeight, menuTable, hFlip)
		if not success2 then
			return false, "Error on MainWindow: " .. mainWindow
		end
		if istable(self.MainWindow) then
			mainWindow.Id = self.MainWindow.Id
			mainWindow.Interface = self.MainWindow.Interface
		end
		self.MainWindow = mainWindow

		return true
	end

	local defaultMenuType = targetSide and menuTable.MenuTypes[2] or menuTable.MenuTypes[1]
	local selectSuccess, selectError = menuTable:SelectType(defaultMenuType)
	if not selectSuccess then
		return false, selectError
	end

	return true, menuTable
end