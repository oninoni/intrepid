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
--       Logs Archive | Server       --
---------------------------------------

Star_Trek.Logs.Archive = Star_Trek.Logs.Archive or {}

-- Archives the session of the given entity.
--
-- @param Table sessionData
-- @param function callback(success)
-- @return Boolean success
-- @return? String error
function Star_Trek.Logs:ArchiveSession(sessionData, callback)
	if not istable(sessionData) then
		return false, "Invalid Session Data"
	end

	if not isfunction(callback) then
		return false, "Invalid callback"
	end

	local archiveSessionData = table.Copy(sessionData)

	archiveSessionData.SessionArchived = os.time()

	archiveSessionData.Status = ST_LOGS_ARCHIVED
	archiveSessionData.RandomSeed = math.random(0, 2^16)

	local preventDefault = hook.Run("Star_Trek.Logs.ArchiveSession", archiveSessionData, callback) -- TODO: Gamemode Database Inplementation. Callback Rewrite
	if not preventDefault then
		table.insert(Star_Trek.Logs.Archive, archiveSessionData)

		callback(true)
	end

	return true
end

-- Return the ammount of pages to have with the given types.
--
-- @param Table types
-- @param function callback(success, pageCount)
-- @param? Number pageSize
-- @return Boolean success
-- @return? String error
function STar_Trek.Logs:GetPageCount(types, callback, pageSize)
	if not istable(types) then
		return false, "Invalid Types"
	end

	if not isnumber(pageSize) then
		pageSize = 20
	end

	local preventDefault = hook.Run("Star_Trek.Logs.GetPageCount", types, callback, pageSize) -- TODO: Gamemode Database Inplementation. Callback Rewrite
	if not preventDefault then
		local filteredData = {}

		for _, archivedSession in SortedPairs(Star_Trek.Logs.Archive, true) do
			if not table.HasValue(types, archivedSession.Type) then
				continue
			end

			table.insert(filteredData, archivedSession)
		end

		local entryCount = table.Count(filteredData)
		local pageCount = math.ceil(entryCount / pageSize)

		callback(true, pageCount)
	end

	return true
end

-- Return the selected sessions.
--
-- @param Table types
-- @param function callback(success, pageCount)
-- @param? Number pageSize
-- @param? Number page
-- @return Boolean success
-- @return? String error
function Star_Trek.Logs:LoadSessionArchive(types, callback, pageSize, page)
	if not istable(types) then
		return false, "Invalid Types"
	end

	if not isnumber(pageSize) then
		pageSize = 20
	end

	if not isnumber(page) then
		page = 1
	end

	local preventDefault = hook.Run("Star_Trek.Logs.LoadSessionArchive", types, callback, pageSize, page) -- TODO: Gamemode Database Inplementation. Callback Rewrite
	if not preventDefault then
		local archiveData = {}
		local filteredData = {}

		for _, archivedSession in SortedPairs(Star_Trek.Logs.Archive, true) do
			if not table.HasValue(types, archivedSession.Type) then
				continue
			end

			table.insert(filteredData, archivedSession)
		end

		local offset = (page - 1) * pageSize + 1
		local entryCount = math.min(20, table.Count(filteredData) - (offset - 1))

		local limit = offset + entryCount
		for i = offset, limit do
			archiveData[i] = filteredData[i]
		end

		callback(true, archiveData)
	end

	return true
end