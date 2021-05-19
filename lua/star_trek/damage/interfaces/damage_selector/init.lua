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
--   LCARS Damage Selector | Server  --
---------------------------------------

local SELF = INTERFACE
SELF.BaseInterface = "base"

function SELF:Open(ent, title, lines)
	local success, window = Star_Trek.LCARS:CreateWindow(
		"category_list",
		Vector(),
		Angle(),
		ent.MenuScale or 35,
		ent.MenuWidth or 325,
		ent.MenuHeight or 540,
		function(windowData, interfaceData, categoryId, buttonId)
			if buttonId then
				local buttonData = windowData.Buttons[buttonId]

				local damageSuccess = Star_Trek.Damage:DamageSection(categoryId, buttonData.Data, "eps_breach")
				if damageSuccess then
					ent:EmitSound("star_trek.lcars_beep")
				else
					ent:EmitSound("star_trek.lcars_error")
				end

				ent:EnableScreenClicker(false)
			end
		end,
		Star_Trek.LCARS:GetSectionCategories(),
		"Where Boom?",
		"SECTNS",
		true,
		false
	)
	if not success then
		return false, window
	end

	return true, {window}
end