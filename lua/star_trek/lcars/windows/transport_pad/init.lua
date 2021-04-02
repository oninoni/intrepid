function WINDOW:OnCreate(padNumber, title, titleShort, hFlip)
	self.Pads = {}
	self.Title = title or ""
	self.TitleShort = titleShort or self.Title
	self.HFlip = hFlip or false

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

			local pad = {
				Name = k .. "_" .. n,
				Data = ent,
			}

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
			pad.X = pad.X + 30
			pad.Y = pad.Y + 30

			self.Pads[k] = pad
		end

	end

	return self
end

function WINDOW:GetSelected()
	local data = {}
	for _, pad in pairs(self.Pads) do
		data[pad.Name] = pad.Selected
	end

	return data
end

function WINDOW:SetSelected(data)
	for name, selected in pairs(data) do
		for _, pad in pairs(self.Pads) do
			if pad.Name == name then
				pad.Selected = selected
				break
			end
		end
	end
end

function WINDOW:OnPress(interfaceData, ent, buttonId, callback)
	local shouldUpdate = false

	local pad = self.Pads[buttonId]
	if istable(pad) then
		pad.Selected = not (pad.Selected or false)
		shouldUpdate = true
	end

	if isfunction(callback) then
		local updated = callback(self, interfaceData, ent, buttonId)
		if updated then
			shouldUpdate = true
		end
	end

	if Star_Trek.LCARS.ActiveInterfaces[ent] and not Star_Trek.LCARS.ActiveInterfaces[ent].Closing then
		ent:EmitSound("star_trek.lcars_beep")
	end

	return shouldUpdate
end