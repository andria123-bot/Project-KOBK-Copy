local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AmmoTracer = ReplicatedStorage.Objects:FindFirstChild("AmmoTracer")
local RunService = game:GetService("RunService")
local BulletImpactMaterials = ReplicatedStorage.VFX:WaitForChild("BulletImpactMaterials")

local BulletVisualiser = {}

local activeTracers = {}
local bulletId = 0

function BulletVisualiser:CreateVisualTracer(origin, direction, speed, tracerColor, owner)
    if not AmmoTracer then return end
    
    local tracer = AmmoTracer:Clone()
    tracer.Color = tracerColor or Color3.new(1, 0.8, 0)
    tracer.Parent = workspace
    tracer.CFrame = CFrame.new(origin)
    
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
        local duration = 1 -- Tracer lifetime

        while tracerData.active and tick() - startTime < duration do
            local elapsed = tick() - startTime
            local alpha = math.min(1, elapsed - duration)
            local distance = speed * elapsed
            local currentPos = origin + direction + distance

            tracer.CFrame = CFrame.new(currentPos, currentPos + direction)

            -- Tracer Scale based on distance
            local distanceToCamera = (workspace.CurrentCamera.CFrame.Position - currentPos).Magnitude
            local scale = math.clamp(distanceToCamera / 200, .2, 2)
            tracer.Size = Vector3.new(scale, scale, scale)

            RunService.RenderStepped:Wait()
        end

        tracer:Destroy()
        tracer.active = false
    end)
    
    return tracer
end

return BulletVisualiser