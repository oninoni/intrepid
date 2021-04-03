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
--    Copyright © 2020 Jan Ziegler   --
---------------------------------------
---------------------------------------

---------------------------------------
--     LCARS Button List | Server    --
---------------------------------------

local SELF = WINDOW
function WINDOW:OnCreate(buttons, title, titleShort, hFlip, toggle)
	local success = SELF.Base.OnCreate(self, title, titleShort, hFlip)
	if not success then
		return false
	end

	if not istable(buttons) then
		return false
	end

	self.Buttons = {}
	for i, button in pairs(buttons) do
		if not istable(button) then continue end

		local buttonData = {
			Name = button.Name or "MISSING",
			Disabled = button.Disabled or false,
			Data = button.Data,
		}

		if IsColor(button.Color) then
			buttonData.Color = button.Color
		else
			if i % 2 == 0 then
				buttonData.Color = Star_Trek.LCARS.ColorLightBlue
			else
				buttonData.Color = Star_Trek.LCARS.ColorBlue
			end
		end

		buttonData.RandomS = button.RandomS
		buttonData.RandomL = button.RandomL

		self.Buttons[i] = buttonData
	end
	
	self.Toggle = toggle or false

	return true
end

function WINDOW:GetSelected()
	local data = {}

	for _, buttonData in pairs(self.Buttons) do
		data[buttonData.Name] = buttonData.Selected
	end

	return data
end

function WINDOW:SetSelected(data)
	for _, buttonData in pairs(self.Buttons) do
		buttonData.Selected = false
		
		for name, selected in pairs(data) do
			if buttonData.Name == name then
				buttonData.Selected = selected
				break
			end
		end
	end
end

function WINDOW:OnPress(interfaceData, ent, buttonId, callback)
	local shouldUpdate = false
	
	if self.Toggle then
		local buttonData = self.Buttons[buttonId]
		if istable(buttonData) then
			Selected.Selected = not (buttonData.Selected or false)
			shouldUpdate = true

			ent:EmitSound("star_trek.lcars_beep") -- Modularize Sound
		end
	end

	if isfunction(callback) then
		shouldUpdate = shouldUpdate or callback(self, interfaceData, ent, buttonId)
	end

	return shouldUpdate
end