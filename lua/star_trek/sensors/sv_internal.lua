---------------------------------------
---------------------------------------
--         Star Trek Modules         --
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
--     Internal Sensors | Server     --
---------------------------------------

-- Register Internal Sensors Control Type.
Star_Trek.Control:Register("internal_sensors", "Internal sensors")

-- Scan some internal sections of the ship.
--
-- @param Number deck
-- @param Table sectionIds
-- @param? Boolean scanLife
-- @param? Boolean scanObjects
-- @param? Boolean scanWeapons
-- @return Boolean success
-- @return Table/String objects/error
function Star_Trek.Sensors:ScanInternal(deck, sectionIds, scanLife, scanObjects, scanWeapons)
	if Star_Trek.Control:GetStatus("internal_sensors", deck) ~= Star_Trek.Control.ACTIVE then
		return false, "Internal scanners unavailable on Deck " .. deck .. "!"
	end

	for _, sectionId in pairs(sectionIds) do
		if Star_Trek.Control:GetStatus("internal_sensors", deck, sectionId) ~= Star_Trek.Control.ACTIVE then
			local sectionName = Star_Trek.Sections:GetSectionName(deck, sectionId)

			return false, "Internal scanners unavailable in " .. sectionName .. " on Deck " .. deck .. "!"
		end
	end

	local objects = Star_Trek.Sections:GetInSections(deck, sectionIds, function(object)
		local ent = object.Entity
		local removeEntity = hook.Run("Star_Trek.Sensors.FilterEntity", ent)
		if removeEntity then return true end
		local success, scanData = Star_Trek.Sensors:ScanEntity(ent)
		if not success then return true end
		object.ScanData = scanData
		object.SectionName = Star_Trek.Sections:GetSectionName(object.Deck, object.SectionId)

		if scanData.IsWeapon then
			if not scanWeapons then return true end
			return
		end

		-- Prevent Entities with parents that are not weapons.	
		local parent = ent:GetParent()
		if IsValid(parent) and not parent:IsVehicle() then
			return true
		end

		if scanData.Alive then
			if not scanLife then return true end
			return
		end

		if not scanObjects then return true end
	end, false, scanWeapons)

	local objectsGrouped = {}
	for _, object in pairs(objects) do
		local scanData = object.ScanData
		local groupName = scanData.GroupName
		if isstring(groupName) then
			local groupObject = objectsGrouped[groupName .. "_" .. object.SectionName] or {
				Deck = object.Deck,
				SectionId = object.SectionId,
				SectionName = object.SectionName,

				ScanData = scanData,
				Entities = {},

				GroupObject = true,
			}

			table.insert(groupObject.Entities, object.Entity)

			objectsGrouped[groupName .. "_" .. object.SectionName] = groupObject
		else
			table.insert(objectsGrouped, object)
		end
	end

	return true, objectsGrouped
end