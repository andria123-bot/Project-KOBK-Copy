local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AmmoTracer = ReplicatedStorage.VFX.Tracers:FindFirstChild("TracerAmmo")
local RunService = game:GetService("RunService")
local SyncProjectile = ReplicatedStorage.Shared.Remotes:WaitForChild("SyncProjectile")  -- RemoteEvent

local BulletVisualiser = {}

local activeTracers = {}

function BulletVisualiser:CreateVisualTracer(origin, direction, speed, loadedBulletType)
    if not AmmoTracer then return end
    if loadedBulletType ~= "Tracer" then return end

    -- Ensure folder exists
    local tracerFolder = workspace:FindFirstChild("BulletTracers")
    if not tracerFolder then
        tracerFolder = Instance.new("Folder")
        tracerFolder.Name = "BulletTracers"
        tracerFolder.Parent = workspace
    end

    local tracer = AmmoTracer:Clone()
    tracer.Parent = tracerFolder
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

    -- tracer movement
    task.spawn(function()
        local startTime = tick()
        local duration = 2 -- Tracer lifetime
        local gravity = 196.2  -- roblox def gravity

        while tracerData.active and tick() - startTime < duration do
            local elapsed = tick() - startTime
            local distance = speed * elapsed
            
            -- gravity drop
            local drop = 0.5 * gravity * elapsed * elapsed
            
            local currentPos = origin + (direction * distance)
            currentPos = currentPos - Vector3.new(0, drop, 0)
            
            tracer.CFrame = CFrame.new(currentPos, currentPos + direction)
            
            -- scale tracer size based on distance to camera
            local distanceToCamera = (workspace.CurrentCamera.CFrame.Position - currentPos).Magnitude
            local scale = math.clamp(distanceToCamera / 200, 0.2, 2)
            tracer.Size = Vector3.new(scale, scale, scale)
            
            RunService.RenderStepped:Wait()
        end

        tracer:Destroy()
        tracerData.active = false
        
        -- Remove from active tracers list
        for i, data in pairs(activeTracers) do
            if data == tracerData then
                table.remove(activeTracers, i)
                break
            end
        end
    end)
    
    return tracer
end

SyncProjectile.OnClientEvent:Connect(function(shooter, firstPersonOrigin, thirdPersonOrigin, direction, weaponData)
    local player = game.Players.LocalPlayer

    local origin = (shooter == player) and firstPersonOrigin or thirdPersonOrigin
    
    local loadedBulletType = weaponData.loadedBulletType

    local muzzleFlashTemplate = ReplicatedStorage.VFX.MuzzleFlashes.DefaultMuzzleFlash
    local newMuzzleFlash = muzzleFlashTemplate:Clone()
    newMuzzleFlash.Parent = workspace
    newMuzzleFlash.CFrame = CFrame.new(origin)  -- Position at muzzle
    
    -- Play effects
    for _, v in pairs(newMuzzleFlash:GetDescendants()) do
        if v:IsA("ParticleEmitter") then
            v:Emit(math.random(1, 3))
        elseif v:IsA("Light") then
            v.Enabled = true
            task.delay(0.07, function()
                if v and v.Parent then
                    v.Enabled = false
                end
            end)
        end
    end
    
    BulletVisualiser:CreateVisualTracer(origin, direction, weaponData.bulletSpeed or 880, loadedBulletType)
end)

return BulletVisualiser