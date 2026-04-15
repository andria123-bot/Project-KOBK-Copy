local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AmmoTracer = ReplicatedStorage.VFX.Tracers:FindFirstChild("TracerAmmo")
local RunService = game:GetService("RunService")

local BulletVisualiser = {}

local activeTracers = {}

function BulletVisualiser:CreateVisualTracer(origin, direction, speed)
    if not AmmoTracer then return end

    local tracer = AmmoTracer:Clone()
    tracer.Parent = workspace.BulletTracers
    tracer.Position = origin
    tracer.Anchored = true
    tracer.CanCollide = false
    
    local tracerData = {
        tracer = tracer,
        position = origin,
        direction = direction,
        speed = speed,
        startTime = tick(),
        active = true
    }

    table.insert(activeTracers, tracerData)

    -- Tracer Creation
    task.spawn(function()
        local lastPos = origin
        local startTime = tick()
        local duration = 2 -- Tracer lifetime

        local gravity = 196.2  -- roblox gravity

        while tracerData.active and tick() - startTime < duration do
            local elapsed = tick() - startTime
            local distance = speed * elapsed
            
            -- gravity drop
            local drop = 0.5 * gravity * elapsed * elapsed
            
            local currentPos = origin + (direction * distance)
            currentPos = currentPos - Vector3.new(0, drop, 0)
            
            tracer.CFrame = CFrame.new(currentPos, currentPos + direction)
            
            -- Scale tracer size based on distance to camera
            local distanceToCamera = (workspace.CurrentCamera.CFrame.Position - currentPos).Magnitude
            local scale = math.clamp(distanceToCamera / 200, 0.2, 2)
            tracer.Size = Vector3.new(scale, scale, scale)
            
            RunService.RenderStepped:Wait()
        end

        tracer:Destroy()
        tracerData.active = false
    end)
    
    return tracer
end

return BulletVisualiser