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
--    LCARS Transport Pad | Client   --
---------------------------------------

if not istable(WINDOW) then Star_Trek:LoadAllModules() return end
local SELF = WINDOW

function SELF:OnCreate(padNumber, title, titleShort, hFlip)
	local success = SELF.Base.OnCreate(self, title, titleShort, hFlip)
	if not success then
		return false
	end

	self.Pads = {}

	local radius = self.WindowHeight / 8
	local offset = radius * 2.5
	local outerX = 0.5 * offset
	local outerY = 0.866 * offset

	for _, ent in pairs(ents.GetAll()) do
		local name = ent:GetName()

		if string.StartWith(name, "TRPad") then
			local values = string.Split(string.sub(name, 6), "_")
			local k = tonumber(values[1])
			local n = tonumber(values[2])

			if n ~= padNumber then continue end

			local pad = {}
			pad.Data = ent

			if k == 7 then
				pad.X = 0
				pad.Y = 0
				pad.Type = "Round"
			else
				if k == 3 or k == 4 then
					if k == 3 then
						pad.X = -offset
					else
						pad.X =  offset
					end

					pad.Y = 0
				else
					if k == 1 or k == 2 then
						pad.Y = outerY
					elseif k == 5 or k == 6 then
						pad.Y = -outerY
					end

					if k == 1 or k == 5 then
						pad.X = -outerX
					elseif k == 2 or k == 6 then
						pad.X = outerX
					end
				end

				pad.Type = "Hex"
			end

			-- Pad Offset (Frame)
			if hFlip then
				pad.X = pad.X - 90
			else
				pad.X = pad.X - 40
			end

			pad.Y = pad.Y - 60

			self.Pads[k] = pad
		end

	end

	return self
end

function SELF:GetClientData()
	local clientData = SELF.Base.GetClientData(self)

	clientData.Pads = {}
	for i, pad in pairs(self.Pads) do
		clientPad = {
			Type = pad.Type,

			X = pad.X,
			Y = pad.Y,

			Selected = pad.Selected,
		}

		clientData.Pads[i] = clientPad
	end

	return clientData
end

function SELF:GetSelected()
	local data = {}

	for i, pad in pairs(self.Pads) do
		data[i] = pad.Selected
	end

	return data
end

function SELF:SetSelected(data)
	for i, pad in pairs(self.Pads) do
		pad.Selected = false

		for iData, selected in pairs(data) do
			if i == iData then
				pad.Selected = selected
				break
			end
		end
	end
end

function SELF:OnPress(interfaceData, ply, buttonId, callback)
	local shouldUpdate = false

	local pad = self.Pads[buttonId]
	if istable(pad) then
		pad.Selected = not (pad.Selected or false)
		shouldUpdate = true
	end

	if isfunction(callback) then
		local updated = callback(self, interfaceData, ply, buttonId)
		if updated then
			shouldUpdate = true
		end
	end

	interfaceData.Ent:EmitSound("star_trek.lcars_beep")

	return shouldUpdate
end