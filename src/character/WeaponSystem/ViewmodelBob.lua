local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait() or script.Parent.Parent
local humanoid = character:WaitForChild("Humanoid")

local ViewmodelBob = {}

local bobCache = {}

function ViewmodelBob.GetBob(t, camOffset, sprintCF)
    local roundedTime = math.floor(t * 50) / 50
    local cacheKey = roundedTime .. "_" .. humanoid.WalkSpeed
    
    if bobCache[cacheKey] then
        return bobCache[cacheKey]
    end

    local bobOffset

    if humanoid.MoveDirection.Magnitude > 0 then
        if humanoid.WalkSpeed == 16 then
            local x = math.cos(t * 8) * 0.02
            local y = -camOffset.Y / 7
            local z = -camOffset.Z / 3
            local rz = math.sin(t * -4) * 0.01
            bobOffset = CFrame.new(x, y, z) * CFrame.Angles(0, 0, rz)
        elseif humanoid.WalkSpeed == 22 then
            local x = math.cos(t * 10) * 0.1
            local y = -camOffset.Y / 3
            local z = -camOffset.Z / 3
            local ry = math.cos(t * -8) * -0.1
            local rz = math.sin(t * -8) * 0.1
            bobOffset = CFrame.new(x, y, z) * CFrame.Angles(0, ry, rz) * (sprintCF or CFrame.new())
        else
            bobOffset = CFrame.new(0, -camOffset.Y / 3, 0)
        end
    else
        bobOffset = CFrame.new(0, -camOffset.Y / 3, 0)
    end
    
    if #bobCache > 1000 then
        bobCache = {}
    end
    
    bobCache[cacheKey] = bobOffset
    return bobOffset
end

function ViewmodelBob.ClearCache()
    bobCache = {}
end

return ViewmodelBob