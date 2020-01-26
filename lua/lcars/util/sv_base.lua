

-- Checks whether something is blocking the specified position within the radius.
-- 
-- @param Vector pos
-- @param? Number radius - defaults to 35 which is good for checking players positions.
function LCARS:IsEmptyPos(pos, lower, higher, radius)
	radius = radius or 35

    if pos.x < lower.x
    or pos.x > higher.x
    or pos.y < lower.y
    or pos.y > higher.y
    or pos.z < lower.z
    or pos.z > higher.z then
        return false
    end

	-- Check whether the position is inside something blocking in the map.
	local point = util.PointContents(pos + Vector(0, 0, 1))

	if point == CONTENTS_SOLID
		or point == CONTENTS_MOVEABLE
		or point == CONTENTS_LADDER
		or point == CONTENTS_PLAYERCLIP
		or point == CONTENTS_MONSTERCLIP
	then
		return false
	end

	local entities = ents.FindInSphere(pos, radius)

	-- The position will be considered empty if there are no entities inside the sphere.
	if #entities == 0 then
		return true
	end

	-- The position will be considered taken if there is a solid entity inside the sphere
	for k, entity in pairs(entities) do
		if entity:IsSolid() then
			return false
		end
	end

	return true
end

-- Returns pos if it is empty, if not, it tries to find a near
-- position that is empty and returns it as an alternative position.
--
-- @param Vector pos
-- @return Vector pos or Boolean false if no empty position was found.
function LCARS:FindEmptyPosWithin(pos, lower, higher)
	local x = pos.x
	local y = pos.y
	local z = pos.z
	local apos

	if self:IsEmptyPos(pos, lower, higher) then
		return pos
	end
	
	-- Look in steps of 10 for an empty position.
	-- Modify x and y coordinates in every possible combination
	-- until an empty position is found.
	for i = 10, 200, 10 do
		apos = Vector(x + i, y, z)
		if self:IsEmptyPos(apos, lower, higher) then
			return apos
		end

		apos = Vector(x - i, y, z)
		if self:IsEmptyPos(apos, lower, higher) then
			return apos
		end

		apos = Vector(x, y + i, z)
		if self:IsEmptyPos(apos, lower, higher) then
			return apos
		end

		apos = Vector(x, y - i, z)
		if self:IsEmptyPos(apos, lower, higher) then
			return apos
		end

		apos = Vector(x + i, y + i, z)
		if self:IsEmptyPos(apos, lower, higher) then
			return apos
		end

		apos = Vector(x - i, y - i, z)
		if self:IsEmptyPos(apos, lower, higher) then
			return apos
		end

		apos = Vector(x + i, y - i, z)
		if self:IsEmptyPos(apos, lower, higher) then
			return apos
		end

		apos = Vector(x - i, y + i, z)
		if self:IsEmptyPos(apos, lower, higher) then
			return apos
		end
	end

	return false
end

-- Capture all Keyvalues so they can be read when needed.
hook.Add("EntityKeyValue", "LCARS.CaptureKeyValues", function(ent, key, value)
    ent.LCARSKeyData = ent.LCARSKeyData or {}

    if string.StartWith(key, "lcars") then
        ent.LCARSKeyData[key] = value
    end
end)

-- Capture Live Changes to lcars convars.
hook.Add("AcceptInput", "LCARS.CaptureKeyValuesLive", function(ent, input, activator, caller, value)
    ent.LCARSKeyData = ent.LCARSKeyData or {}
    
    if input ~= "AddOutput" then return end

    local valueSplit = string.Split(value, " ")
    local key = valueSplit[1]
    if string.StartWith(key, "lcars") then
        ent.LCARSKeyData[key] = valueSplit[2]
    end
end)