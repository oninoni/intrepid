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
--  LCARS Engi Transporter | Server  --
---------------------------------------

local SELF = INTERFACE
SELF.BaseInterface = "transporter"

function SELF:Open(ent)
	local success, windows = self:OpenInternal(
		Vector(-22, -34, 8.2),
		Angle(0, 0, -90),
		500,
		Vector(-26, -5, -2),
		Angle(0, 0, 0),
		550,
		720,
		Vector(0, -34, 8),
		Angle(0, 0, -90),
		Vector(0, -0.5, -2),
		Angle(0, 0, 0),
		550,
		720,
		nil
	)
	if not success then
		return false, windows
	end

	return true, windows, Vector(0, 0, 0), Angle(0, 0, 0)
end

function Star_Trek.LCARS:OpenTransporterEngMenu()
	Star_Trek.LCARS:OpenInterface(TRIGGER_PLAYER, CALLER, "eng_transporter")
end