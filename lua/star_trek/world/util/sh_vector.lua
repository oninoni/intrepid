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
--       World Vector | Shared       --
---------------------------------------

-- Concept:

-- 2 Floats per Coordiate
-- Split at 1024*1024
-- plenty precision for ,... !
-- INT RANGE: (1024*1024*1024*1024*64) * (1024*1024), (1024 * 1024 * 1024 * 64)
-- 

Star_Trek.World.Vector = {}

local metaTable = {
	__index = 
}

local BX = 1
local BY = 2
local BZ = 3
local SX = 4
local SY = 5
local SZ = 6

function WorldVector(bx, by, bz, sx, sy, sz)
	local vector = {
		[BX] = bx,
		[BY] = by,
		[BZ] = bz,
		[SX] = sx,
		[SY] = sy,
		[SZ] = sz,
	}

end














--[[






-- Add the given Vector or World Vector to the World Vector
--
-- @param WorldVector a
-- @param WorldVector/Vector b
-- @return WorldVector result
local function __add(a, b)
	if isvector(b) then
		return WorldVector(a[1], a[2] + b)
	end

	return WorldVector(a[1] + b[1], a[2] + b[2])
end

-- Substract the given Vector or World Vector from the World Vector
--
-- @param WorldVector a
-- @param WorldVector/Vector b
-- @return WorldVector result
local function __sub(a, b)
	if isvector(b) then
		return WorldVector(a[1], a[2] - b)
	end

	return WorldVector(a[1] - b[1], a[2] - b[2])
end

-- Mutliplies a given vector with a scalar.
--
-- @param WorldVector a
-- @param Number b
-- @return WorldVector result
local function __mul(a, b)
	return WorldVector(a[1] * b, a[2] * b)
end

-- Divides a given vector by a scalar.
--
-- @param WorldVector a
-- @param Number b
-- @return WorldVector result
local function __div(a, b)
	return WorldVector(a[1] / b, a[2] / b)
end

-- Compares two vectors with each other for being the same.
--
-- @param WorldVector a
-- @param WorldVector b
-- @return Boolean equal
local function  __eq(a, b)
	return (a[1] == b[1]) and (a[2] == b[2])
end

-- Converts the vector into a string, to be printed.
--
-- @param WorldVector a
-- @return Strint string
local function __tostring(a)
	return tostring(a[1]) .. " | " .. tostring(a[2])
end

-- Define the Meta Table here. Optimisation!
local metaTable = {
	__index = Star_Trek.World.Vector,
	__add = __add, -- +
	__sub = __sub, -- -
	__mul = __mul, -- *
	__div = __div, -- /
	__eq  =  __eq, -- ==
	__tostring = __tostring,
}

-- Initialize a Vector.
--
-- @param Vector big
-- @param Vector small
-- @return WorldVector vector
function WorldVector(big, small)
	local worldVector = {[1] = big or Vector(), [2] = small or Vector()}
	setmetatable(worldVector, metaTable)

	worldVector:FixValue()

	return worldVector
end

-- Reduces the Value to its minimum "Small" Vector Size.
-- Should be called after any operation.
function Star_Trek.World.Vector:FixValue()
	local b = self[1]
	local s = self[2]

	local s2 = Vector(
		s[1] % BIG_SCALE,
		s[2] % BIG_SCALE,
		s[3] % BIG_SCALE
	)

	local temp = (s - s2) / BIG_SCALE
	self[1] = Vector(
		b[1] + math.floor(temp[1]),
		b[2] + math.floor(temp[2]),
		b[3] + math.floor(temp[3])
	)
	self[2] = s2

	if SERVER and false then
		print("...")
		print("B", b)
		print("S", s)
		print("S2", s2)
		print("S-S2", s - s2)
		print("T", temp)
		print(self[1], self[2])
	end
end

function Star_Trek.World.Vector:ToVector()
	return self[1] * BIG_SCALE + self[2]
end

function Star_Trek.World.Vector:LengthSqr()
	local temp = self[1] * BIG_SCALE + self[2]
	return temp:LengthSqr()
end

function Star_Trek.World.Vector:Length()
	local temp = self[1] * BIG_SCALE + self[2]
	return temp:Length()
end

function WorldToLocalBig(pos, ang, newSystemOrigin, newSystemAngles)
	local offsetPos = pos - newSystemOrigin

	return WorldToLocal(offsetPos:ToVector(), ang, Vector(), newSystemAngles)
end

function net.ReadWorldVector()
	local big   = net.ReadVector()
	local small = net.ReadVector()

	return WorldVector(big, small)
end

function net.WriteWorldVector(vec)
	net.WriteVector(vec[1])
	net.WriteVector(vec[2])
end

]]