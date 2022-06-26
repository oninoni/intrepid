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
--            World Entity           --
--     Base Acceleration | Client    --
---------------------------------------

if not istable(ENT) then Star_Trek:LoadAllModules() return end
local SELF = ENT

function SELF:ReadData()
	self.Models = net.ReadTable()

	self.Acc 	= net.ReadVector()
	self.AngAcc = net.ReadAngle()
end

function SELF:ReadDynData()
	self.Pos = net.ReadWorldVector()
	self.Ang = net.ReadAngle()

	local x, y, z = net.ReadFloat(), net.ReadFloat(), net.ReadFloat()
	self.Vel = Vector(x, y, z)

	self.AngVel = net.ReadAngle()
end