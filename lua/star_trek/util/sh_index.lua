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
--    Copyright © 2021 Jan Ziegler   --
---------------------------------------
---------------------------------------

---------------------------------------
--         Utilities | Index         --
---------------------------------------

Star_Trek:RequireModules()

Star_Trek.Util = Star_Trek.Util or {}

if SERVER then
	--AddCSLuaFile("cl_rendermap.lua")
	AddCSLuaFile("cl_fov.lua")

	include("sv_positions.lua")
	include("sv_keyvalues.lua")
	include("sv_holodeck.lua")
	include("sv_models.lua")

	include("luabsp.lua")
	include("sv_luabsp.lua")
end

if CLIENT then
	--include("cl_rendermap.lua")
	include("cl_fov.lua")
end