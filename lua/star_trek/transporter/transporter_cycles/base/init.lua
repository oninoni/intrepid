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
--  Base Transporter Cycle | Server  --
---------------------------------------

if not istable(CYCLE) then Star_Trek:LoadAllModules() return end
local SELF = CYCLE

-- Initialises the transporter cycle.
--
-- @param Entity ent
function SELF:Initialise()
	self.State = 1
	if self.SkipDemat then
		self.State = self.SkipDematState
	end
end

function SELF:ResetCollisionGroup()
	local ent = self.Entity

	local defaultCollisionGroup = ent.TransporterDefaultCollisionGroup
	if defaultCollisionGroup == nil then
		defaultCollisionGroup = COLLISION_GROUP_NONE
	end

	ent:SetCollisionGroup(defaultCollisionGroup)
end

function SELF:ResetRenderMode()
	local ent = self.Entity

	local defaultRenderMode = ent.TransporterDefaultRenderMode
	if defaultRenderMode == nil then
		defaultRenderMode = RENDERMODE_NORMAL
	end

	ent:SetRenderMode(defaultRenderMode)
end

function SELF:ResetMoveType()
	local ent = self.Entity

	local defaultMoveType = ent.TransporterDefaultMoveType
	if defaultMoveType == nil then
		defaultMoveType = MOVETYPE_WALK
	end

	ent:SetMoveType(defaultMoveType)
end

function SELF:End()
	self:ResetCollisionGroup()
	self:ResetRenderMode()
	self:ResetMoveType()

	self:DrawShadow(true)
end

-- Aborts the transporter cycle and brings the entity back to its normal state.
-- This will dump the player into the transporter buffer!
function SELF:Abort()
	self:End()

	local bufferPos = Star_Trek.Transporter:GetBufferPos()
	ent:SetPos(bufferPos)
end

-- Applies the current state to the transporter cycle.
--
-- @param Number state
function SELF:ApplyState(state)
	self.State = state
	self.StateTime = CurTime()

	if state == self.SkipRematState then return false end

	local stateData = self:GetStateData()
	if not istable(stateData) then return false end
	
	local ent = self.Entity

	local collisionGroup = stateData.CollisionGroup
	if collisionGroup ~= nil then
		if collisionGroup == false then
			self:ResetCollisionGroup()
			ent.TransporterDefaultCollisionGroup = nil
		else
			ent.TransporterDefaultCollisionGroup = ent.TransporterDefaultRenderMode or ent:GetCollisionGroup()
			ent:SetCollisionGroup(collisionGroup)
		end
	end
	
	local renderMode = stateData.RenderGroup
	if renderMode ~= nil then
		if renderMode == false then
			self:ResetRenderMode()
			ent.TransporterDefaultRenderMode = nil
		else
			ent.TransporterDefaultRenderMode = ent.TransporterDefaultRenderMode or ent:GetRenderMode()
			ent:SetRenderMode(renderMode)
		end
	end

	local moveType = stateData.RenderGroup
	if moveType ~= nil then
		if moveType == false then
			self:ResetMoveType()
			ent.TransporterDefaultMoveType = nil
		else
			ent.TransporterDefaultMoveType = ent.TransporterDefaultMoveType or ent:GetMoveType()
			ent:SetMoveType(moveType)
		end
	end

	local shadow = stateData.Shadow
	if shadow ~= nil then
		ent:DrawShadow(shadow)
	end

	if stateData.TPToBuffer then
		local bufferPos = Star_Trek.Transporter:GetBufferPos()
		ent:SetPos(bufferPos)
	end

	if stateData.TPToTarget then
		ent:SetPos(self.TargetPos)
	end

	local soundName = stateData.SoundName
	if soundName then
		sound.Play(soundName, ent:GetPos(), 20, 100, 0.5)
	end

	return true
end