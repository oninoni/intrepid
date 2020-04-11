

-- List of active Paneln.
-- Filled via Networking.
LCARS.ActivePanels = LCARS.ActivePanels or {}

util.AddNetworkString("LCARS.Screens.OpenMenu")
util.AddNetworkString("LCARS.Screens.CloseMenu")
util.AddNetworkString("LCARS.Screens.Pressed")
util.AddNetworkString("LCARS.Screens.UpdateWindow")

-- Returns the corrent menu Position and orientation for a given panel.
--
-- @param Entity panel
-- @return Vector screenPos
-- @return Angle screenAngle
function LCARS:GetMenuPos(panel)
    local pos = panel:GetPos()
    local screenAngle = panel:GetUp():Angle()

    local moveDirAngle = panel:GetKeyValues()["movedir"]
    if isvector(moveDirAngle) then
        screenAngle = moveDirAngle:Angle()
    end

    local attachmentID = panel:LookupAttachment("button")
    if isnumber(attachmentID) and attachmentID > 0 then
        local attachmentPoint = panel:GetAttachment(attachmentID)
        pos = attachmentPoint.Pos
        screenAngle = attachmentPoint.Ang
        
        screenAngle:RotateAroundAxis(screenAngle:Up(), 180)
    else
        screenAngle:RotateAroundAxis(screenAngle:Up(), 180)
    end

    local offset = 0
    local modelSetting = self.ModelSettings[panel:GetModel()]
    if modelSetting then
        offset = modelSetting.Offset
    end

    local screenPos = pos + screenAngle:Forward() * offset 
    
    return screenPos, screenAngle
end

-- Returns the menu prop from the brush and player.
--
-- @param Player ply
-- @param Entity panel_brush
-- @return Entity panel
function LCARS:GetMenuProp(ply, panel_brush)
    if not IsValid(panel_brush) then return false end

    local children = panel_brush:GetChildren()
    if table.Count(children) == 0 then return panel_brush end

    if IsValid(ply) and ply:IsPlayer() then
        local panel = ply:GetEyeTrace().Entity
        if not (IsValid(panel) or panel:IsWorld()) then return false end
        if not table.HasValue(children, panel) then return false end

        return panel
    end

    return true -- TODO: What?
end

-- Validates panel and brush for using a menu on it.
--
-- @param Player ply
-- @param Entity panel_brush
-- @param Function callback
function LCARS:OpenMenuInternal(ply, panel_brush, callback)
    local panel = LCARS:GetMenuProp(ply, panel_brush)
    if panel then 
        if istable(self.ActivePanels[panel]) then return panel end

        local screenPos, screenAngle = self:GetMenuPos(panel)

        if isfunction(callback) then
            callback(ply, panel_brush, panel, screenPos, screenAngle)
        end
    end
end

function LCARS:ActivatePanel(panel, panelData)
    self.ActivePanels[panel] = panelData

    net.Start("LCARS.Screens.OpenMenu")
        net.WriteString("ENT_" .. panel:EntIndex())
        net.WriteTable(panelData)
    net.Broadcast()
end

function LCARS:DisablePanel(panel)
    self.ActivePanels[panel] = nil

    net.Start("LCARS.Screens.CloseMenu")
        net.WriteString("ENT_" .. panel:EntIndex())
    net.Broadcast()
end

-- TODO: Sync Active Panels to joining players

function LCARS:UpdateWindow(panel, windowId, window)
    local panelData = self.ActivePanels[panel]

    panelData.Windows[windowId] = window

    net.Start("LCARS.Screens.UpdateWindow")
        net.WriteString("ENT_" .. panel:EntIndex())
        net.WriteInt(windowId, 32)
        net.WriteTable(window)
    net.Broadcast()
end

-- Sends the panel and it's data to the client.
--
-- @param Entity panel
-- @param Table panelData
function LCARS:SendPanel(panel, panelData)
    if not IsValid(panel) then return end
    if not (istable(panelData) and table.Count(panelData) > 0) then return end

    -- Only Error - Fix the values here that are actually needed serverside
    panelData.Type = panelData.Type or "Universal"
    panelData.Pos = panelData.Pos or Vector()

    self:ActivatePanel(panel, panelData)
end

-- Creates the data structure for a button.
--
-- @param? String name
-- @param? Color color
-- @param? Boolean disabled
function LCARS:CreateButton(name, color, disabled)
    local button = {
        Name = name or "",
        Disabled = tobool(disabled) or false,
    }

    if IsColor(color) then
        button.Color = color
    else
        button.Color = LCARS.Colors[math.random(1, #(LCARS.Colors))]
    end

    button.RandomS = "" .. math.random(1, 99)

    local r = math.random(1, 99)
    local d = math.random(1, 9999)
    
    local v
    if r > 9 then
        v = "" .. r .. "-"
    else
        v = "0" .. r .. "-"
    end

    if d > 999 then
        v = v .. d
    elseif d > 99 then
        v = v .. "0" .. d
    elseif d > 9 then
        v = v .. "00" .. d
    else
        v = v .. "00" .. d
    end

    button.RandomL = v

    return button
end

-- Open a General LCARS Menu using the keyvalues of an panel's func_button brush.
function LCARS:OpenMenu()
    self:OpenMenuInternal(TRIGGER_PLAYER, CALLER, function(ply, panel_brush, panel, screenPos, screenAngle)
        local panelData = {
            Pos = screenPos,
            Windows = {
                [1] = {
                    Pos = screenPos,
                    Angles = screenAngle,
                    Type = "button_list",
                    Buttons = {}
                }
            },
        }

        local keyValues = panel_brush.LCARSKeyData
        if istable(keyValues) then
            local scale = tonumber(keyValues["lcars_scale"])
            if isnumber(scale) then
                panelData.Windows[1].Scale = scale
            end
            
            local width = tonumber(keyValues["lcars_width"])
            if isnumber(width) then
                panelData.Windows[1].Width = width
            end
            
            local height = tonumber(keyValues["lcars_height"])
            if isnumber(height) then
                panelData.Windows[1].Height = height
            end

            for i=1,20 do
                local name = keyValues["lcars_name_" .. i]
                if isstring(name) then
                    local button = self:CreateButton(name, nil, keyValues["lcars_disabled_" .. i])
                    panelData.Windows[1].Buttons[i] = button
                else
                    break
                end
            end
        end

        self:SendPanel(panel, panelData)
    end)
end

-- Detect Updates in _name, _disabled.
hook.Add("LCARS.ChangedKeyValue", "LCARS.Screens.ValueChanged", function(ent, key, value)
    if string.StartWith(key, "lcars_name_") or string.StartWith(key, "lcars_disabled_") then
        local keyValues = ent.LCARSKeyData
        if istable(keyValues) and keyValues["lcars_keep_open"] then
            ent.LCARSMenuHasChanged = true
        end
    end
end)

-- Capture closeLcars Input
hook.Add("AcceptInput", "LCARS.Screen.CaptureClose", function(ent, input, activator, caller, value)
    if LCARS.ActivePanels[ent] then
        
    if input ~= "CloseLcars" then return end
        LCARS:DisablePanel(ent)
    end
end)

-- Closing the panel when you are too far away.
-- This is also done clientside so we don't need to network.
hook.Add("Think", "LCARS.ThinkClose", function()
    local toBeClosed = {}
    
    for panel, panelData in pairs(LCARS.ActivePanels) do
        if panel.LCARSMenuHasChanged then
            panelData.Windows[1].Buttons = {}

            local panel_brush = panel:GetParent()
            if not IsValid(panel_brush) then 
                panel_brush = panel
            end

            local keyValues = panel_brush.LCARSKeyData
            if istable(keyValues) then
                for i=1,20 do
                    local name = keyValues["lcars_name_" .. i]
                    if isstring(name) then
                        local button = LCARS:CreateButton(name, nil, keyValues["lcars_disabled_" .. i])
                        panelData.Windows[1].Buttons[i] = button
                    else
                        break
                    end
                end
            end

            LCARS:UpdateWindow(panel, 1, panelData.Windows[1])
            panel.LCARSMenuHasChanged = false
        end

        local pos = panelData.Pos

        local entities = ents.FindInSphere(pos, 200)
        local playersFound = false
        for _, ent in pairs(entities) do
            if ent:IsPlayer() then
                playersFound = true
            end
        end

        if not playersFound then
            table.insert(toBeClosed, panel)
        end
    end

    for _, panel in pairs(toBeClosed) do
        LCARS:DisablePanel(panel)
    end
end)


-- Receive the pressed event from the client when a user presses his panel.
net.Receive("LCARS.Screens.Pressed", function(len, ply)
    local panelId = net.ReadString()
    local windowId = net.ReadInt(32)
    local buttonId = net.ReadInt(32)

    local entId = tonumber(string.sub(panelId, 5))
    local panel = ents.GetByIndex(entId)
    if not IsValid(panel) then return end

    -- TODO: Replace Sound
    panel:EmitSound("buttons/blip1.wav")

    local panel_brush = panel:GetParent()
    if not IsValid(panel_brush) then 
        panel_brush = panel
    end

    local panelData = LCARS.ActivePanels[panel]
    if not istable(panelData) then return end

    if panelData.Type == "Universal" then
        if buttonId > 4 then
            local name = panel_brush:GetName()
            local caseEntities = ents.FindByName(name .. "_case")
            for _, caseEnt in pairs(caseEntities) do
                if IsValid(caseEnt) then
                    caseEnt:Fire("InValue", buttonId - 4)
                end
            end
        else
            panel_brush:Fire("FireUser" .. buttonId)
        end
        
        local keyValues = panel_brush.LCARSKeyData
        if istable(keyValues) and not keyValues["lcars_keep_open"] then
            timer.Simple(0.5, function()
                LCARS:DisablePanel(panel)
            end)
        end
    else
        hook.Run("LCARS.PressedCustom", ply, panelData, panel, panelBrush, windowId, buttonId)
    end
end)