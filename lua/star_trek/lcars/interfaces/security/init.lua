local securityUtil = include("util.lua")

function Star_Trek.LCARS:OpenSecurityMenu()
	local success, interfaceEnt = self:GetInterfaceEntity(TRIGGER_PLAYER, CALLER)
	if not success then
		Star_Trek:Message(interfaceEnt)
		return
	end

	if istable(self.ActiveInterfaces[interfaceEnt]) then
		return
	end

	local success2, menuWindow, actionWindow = securityUtil.CreateMenuWindow()

	local success3, mapWindow = securityUtil.CreateMapWindow(1)
	if not success3 then
		Star_Trek:Message(mapWindow)
		return
	end

	local success4, sectionWindow = Star_Trek.LCARS:CreateWindow(
		"category_list",
		Vector(-28, -5, -2),
		Angle(0, 0, 0),
		nil,
		500,
		700,
		function(windowData, interfaceData, ent, categoryId, buttonId)
			if isnumber(buttonId) then
				local buttonData = windowData.Categories[categoryId].Buttons[buttonId]
				local sectionId = buttonData.Data.Id

				local selected = mapWindow:GetSelected(mapWindow)
				selected[sectionId] = buttonData.Selected

				mapWindow:SetSelected(selected)
				
				Star_Trek.LCARS:UpdateWindow(ent, mapWindow.WindowId, mapWindow)
			else
				local updateSuccess, newMapWindow = securityUtil.CreateMapWindow(categoryId)
				if not updateSuccess then
					Star_Trek:Message(newMapWindow)
					return
				end

				Star_Trek.LCARS:UpdateWindow(ent, mapWindow.WindowId, newMapWindow)
				newMapWindow.WindowId = mapWindow.WindowId
				mapWindow = newMapWindow
			end
		end,
		Star_Trek.LCARS:GetSectionCategories(),
		"SECTIONS",
		"SECTNS",
		false,
		true
	)
	if not success4 then
		Star_Trek:Message(menuWindow)
		return
	end

	local windows = Star_Trek.LCARS:CombineWindows(
		menuWindow,
		sectionWindow,
		mapWindow,
		actionWindow
	)

	local success5, error = self:OpenInterface(interfaceEnt, windows)
	if not success5 then
		Star_Trek:Message(error)
		return
	end
end