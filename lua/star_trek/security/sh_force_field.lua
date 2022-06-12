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
--   Security Force Fields | Shared  --
---------------------------------------

hook.Add("PhysgunPickup", "Star_Trek.Security.PreventForceFieldPickup", function(ply, ent)
	if ent:GetClass() ~= "force_field" then
		return
	end

	return false
end)

hook.Add("CanTool", "Star_Trek.Security.PreventCanTool", function(ply, tr, toolname, tool, button)
	local ent = tr.Entity
	if not IsValid(ent) then
		return
	end

	if ent:GetClass() ~= "force_field" then
		return
	end

	return false
end)