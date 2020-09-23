function WINDOW.OnCreate(windowData, padNumber, title)
    windowData.Pads = {}
    windowData.Title = title or ""

    local radius = windowData.WindowHeight / 8
    local offset = radius * 2.5
    local outerX = 0.5 * offset
    local outerY = 0.866 * offset

    for _, ent in pairs(ents.GetAll()) do
        local name = ent:GetName()

        if string.StartWith(name, "TRPad") then
            local values = string.Split(string.sub(name, 6), "_")
            local k = tonumber(values[1])
            local n = tonumber(values[2])
            
            if n ~= padNumber then continue end
            
            local pad = {
                Name = k .. "_" .. n,
                Data = ent,
            }

            if k == 7 then
                pad.X = 0
                pad.Y = 0
                pad.Type = "Round"
            else
                if k == 3 or k == 4 then
                    if k == 3 then
                        pad.X = -offset
                    else
                        pad.X =  offset
                    end

                    pad.Y = 0
                else
                    if k == 1 or k == 2 then
                        pad.Y = outerY
                    elseif k == 5 or k == 6 then
                        pad.Y = -outerY
                    end

                    if k == 1 or k == 5 then
                        pad.X = -outerX
                    elseif k == 2 or k == 6 then
                        pad.X = outerX
                    end
                end

                pad.Type = "Hex"
            end
            
            windowData.Pads[k] = pad
        end

    end

    return windowData
end

function WINDOW.GetData(windowData)
    local data = {}
    for _, pad in pairs(windowData.Pads) do
        data[pad.Name] = pad.Selected
    end

    return data
end

function WINDOW.SetData(windowData, data)
    for name, selected in pairs(data) do
        for _, pad in pairs(windowData.Pads) do
            if pad.Name == name then
    	        pad.Selected = selected
                break
            end
        end
    end
end

function WINDOW.OnPress(windowData, interfaceData, ent, buttonId, callback)
    ent:EmitSound("buttons/blip1.wav")
    -- TODO: Replace Sound

    local shouldUpdate = false

    local pad = windowData.Pads[buttonId]
    if istable(pad) then
        pad.Selected = not (pad.Selected or false)
        shouldUpdate = true
    end

    if isfunction(callback) then
        local updated = callback(windowData, interfaceData, ent, buttonId)
        if updated then 
            shouldUpdate = true
        end
    end

    return shouldUpdate
end