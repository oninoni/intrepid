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
--    LCARS Bridge Security | Util   --
---------------------------------------

if not istable(INTERFACE) then Star_Trek:LoadAllModules() return end
local SELF = INTERFACE

local PAGE_SIZE = 25

function SELF:CreateControlMenu()
	local buttons = {
		[1] = {
			Name = "Previous Entry",
			Disabled = true,
		},
		[2] = {
			Name = "Next Entry",
			Disabled = true,
		},
		[4] = {
			Name = "Delete Entry",
			Color = Star_Trek.LCARS.ColorRed,
			Disabled = true,
		},
		[6] = {
			Name = "Disable Console",
			Color = Star_Trek.LCARS.ColorRed,
		}
	}

	local success, controlWindow = Star_Trek.LCARS:CreateWindow(
		"button_list",
		Vector(15, -28.05, 10),
		Angle(0, 0, -76.5),
		nil,
		600,
		300,
		function(windowData, interfaceData, ply, buttonId)
			if buttonId == 1 or buttonId == 2 then -- Next Log
				local listWindow = self.Windows[3]
				local intButtons = listWindow.Buttons
				for i, buttonData in pairs(intButtons) do
					if buttonData.Selected then
						local nextButton
						if buttonId == 1 then
							nextButton = intButtons[i - 1]
						else
							nextButton = intButtons[i + 1]
						end

						self:SelectLogFile(nextButton.Data)
						listWindow:Update()

						interfaceData.Ent:EmitSound("star_trek.lcars_beep")

						return
					end
				end
			elseif buttonId == 6 then -- Disable Button
				windowData:Close()
			end
		end,
		buttons,
		"Control",
		nil,
		false
	)
	if not success then
		return false, controlWindow
	end

	return true, controlWindow
end

function SELF:CreateCategorySelectionWindow()
	local buttons = {}

	for _, typeName in pairs(Star_Trek.Logs.Types) do
		local button = {
			Name = typeName
		}
		table.insert(buttons, button)
	end

	local success, categorySelection = Star_Trek.LCARS:CreateWindow(
		"button_list",
		Vector(15, -24.5, -4.75),
		Angle(0, 0, -76.5),
		nil,
		600,
		300,
		function(windowData, interfaceData, ply, buttonId)
			self:DeSelectLogFile(true)

			local types = {}
			for _, buttonData in pairs(windowData.Buttons) do
				if buttonData.Selected then
					table.insert(types, buttonData.Name)
				end
			end

			self.Types = types

			Star_Trek.Logs:GetPageCount(types, function(successInternal, pageCount)
				if not successInternal then
					return -- TODO
				end

				self.PageCount = pageCount

				local windows = self.Windows
				if windows then
					local listWindow = windows[3]
					self:ApplyListWindowPage(listWindow.Categories, 1)
				end
			end, pageSize)
		end,
		buttons,
		"Categories",
		"CTGRS",
		false,
		true -- Toggle
	)
	if not success then
		return false, categorySelection
	end

	return true, categorySelection
end

function SELF:ApplyListWindowCategories(categories, page, disableAll)
	local pageCount = self.PageCount or 1

	local mainCategory = categories[5]
	local prevCategory = categories[1]
	local nextCategory = categories[4]

	self.Page = math.min(pageCount, math.max(page, 1))

	mainCategory.Name = "Page " .. self.Page .. "/" .. pageCount
	if self.Page <= 1 then
		prevCategory.Disabled = true
	else
		prevCategory.Disabled = false
	end
	if self.Page >= pageCount then
		nextCategory.Disabled = true
	else
		nextCategory.Disabled = false
	end
	if disableAll then
		prevCategory.Disabled = true
		nextCategory.Disabled = true
		mainCategory.Disabled = true
	end
end

function SELF:ApplyListWindowPage(categories, page, disableAll)
	self:ApplyListWindowCategories(categories, page, true)
	local mainCategory = categories[5]

	Star_Trek.Logs:LoadSessionArchive(self.Types or {}, function(successInternal, archiveData)
		mainCategory.Buttons = {}
		if not successInternal then
			table.insert(mainCategory.Buttons, {
				Name = "Error Loading Data!",
				Disabled = true,
			})
		elseif table.Count(archiveData) == 0 then
			table.insert(mainCategory.Buttons, {
				Name = "No Data Selected...",
				Disabled = true,
			})
		else
			for _, archivedSession in SortedPairsByMemberValue(archiveData, "SessionArchived", true) do
				local button = {
					Name = archivedSession.Type .. "-" .. archivedSession.SessionArchived,
					Data = archivedSession
				}

				table.insert(mainCategory.Buttons, button)
			end
		end

		self:ApplyListWindowCategories(categories, self.Page)

		local windows = self.Windows
		if windows then
			local listWindow = windows[3]
			listWindow.Selection = 5

			listWindow:SetCategory(5)
			listWindow:Update()
		end
	end, PAGE_SIZE, self.Page)
end

function SELF:CreateListWindow(page)
	local categories = {
		{
			Name = "Previous Page",
			Disabled = true,
			Buttons = {
				{
					Name = "Loading...",
					Disabled = true,
				}
			},
		},
		{
			Name = "01-02-2020",
			Disabled = true,
			Buttons = {},
		},
		{
			Name = "05-03-2020",
			Disabled = true,
			Buttons = {},
		},
		{
			Name = "Next Page",
			Disabled = true,
			Buttons = {
				{
					Name = "Loading...",
					Disabled = true,
				}
			},
		},
		{
			Name = "Page 0/0",
			Disabled = true,
			Buttons = {
				{
					Name = "No Data Selected...",
					Disabled = true,
				}
			},
		},
	}

	local success, listWindow = Star_Trek.LCARS:CreateWindow(
		"category_list",
		Vector(-15, -26.25, 2.5),
		Angle(0, 0, -76.5),
		nil,
		600,
		600,
		function(windowData, interfaceData, ply, categoryId, buttonId)
			if not buttonId then
				if categoryId == 1 then
					self:ApplyListWindowPage(windowData.Categories, self.Page - 1)
				elseif categoryId == 4 then
					self:ApplyListWindowPage(windowData.Categories, self.Page + 1)
				end

				return
			end

			local buttonData = windowData.Buttons[buttonId]
			if not buttonData then return end

			local archivedSession = buttonData.Data
			self:SelectLogFile(archivedSession)

			return true
		end,
		categories,
		"Logs",
		nil,
		false
	)
	if not success then
		return false, listWindow
	end

	listWindow:SetCategory(5)

	return true, listWindow
end

function SELF:DeSelectLogFile(doUpdate)
	local controlWindow = self.Windows[2]
	controlWindow.Buttons[1].Disabled = true
	controlWindow.Buttons[2].Disabled = true

	local logWindow = self.Windows[4]
	logWindow:ClearLines()

	if doUpdate then
		controlWindow:Update()
		logWindow:Update()
	end
end

function SELF:SelectLogFile(archivedSession)
	self:DeSelectLogFile()
	local controlWindow = self.Windows[2]
	local listWindow = self.Windows[3]

	local buttons = listWindow.Buttons
	local buttonCount = table.Count(buttons)
	for i, buttonData in pairs(buttons) do
		if buttonData.Data == archivedSession then
			if i == 1 then
				controlWindow.Buttons[1].Disabled = true
			else
				controlWindow.Buttons[1].Disabled = false
			end
			if i == buttonCount then
				controlWindow.Buttons[2].Disabled = true
			else
				controlWindow.Buttons[2].Disabled = false
			end

			listWindow:SetSelected({
				Selected = listWindow.Selected,
				Buttons = {
					[buttonData.Name] = true,
				}
			})
			break
		end
	end

	local logWindow = self.Windows[4]

	logWindow:AddLine("Log Type: " .. archivedSession.Type, Star_Trek.LCARS.ColorRed)
	logWindow:AddLine("Log file started at " .. archivedSession.SessionStarted, Star_Trek.LCARS.ColorLightBlue)
	logWindow:AddLine("Log file archived at " .. archivedSession.SessionArchived, Star_Trek.LCARS.ColorLightBlue)

	local currentName = nil
	for _, entry in pairs(archivedSession.Entries) do
		local name = entry.Name
		if name ~= currentName then
			logWindow:AddLine("")
			logWindow:AddLine(name .. ":", Star_Trek.LCARS.ColorOrange)

			currentName = name
		end

		logWindow:AddLine(entry.Text, Star_Trek.LCARS.ColorLightBlue)
	end

	controlWindow:Update()
	logWindow:Update()
end