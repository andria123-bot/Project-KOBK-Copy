local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AmmoTracer = ReplicatedStorage.VFX.Tracers:FindFirstChild("TracerAmmo")
local RunService = game:GetService("RunService")
local SyncProjectile = ReplicatedStorage.Shared.Remotes:WaitForChild("SyncProjectile")  -- RemoteEvent

local BulletVisualiser = {}

local activeTracers = {}

function BulletVisualiser:CreateVisualTracer(origin, direction, speed, loadedBulletType)
    if not AmmoTracer then return end
    if loadedBulletType:sub(-1) ~= "T" then return end

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
    
    local startOrigin = origin
    local startDirection = direction.Unit
    local startSpeed = speed
    local startTime = tick()
    
    local tracerData = {
        tracer = tracer,
        active = true
    }

    table.insert(activeTracers, tracerData)

    task.spawn(function()
        local lastPos = startOrigin
        local gravity = 196.2
        local duration = .5
        
        local elapsed = 0
        local lastUpdate = tick()
        
        while tracerData.active and tick() - startTime < duration do
            local now = tick()
            local dt = now - lastUpdate
            lastUpdate = now
            elapsed = elapsed + dt
            
            local distance = startSpeed * elapsed
            local drop = 0.5 * gravity * elapsed * elapsed
            
            local currentPos = startOrigin + (startDirection * distance)
            currentPos = currentPos - Vector3.new(0, drop, 0)
            
            -- Only update position if tracer still exists
            if tracer and tracer.Parent then
                tracer.CFrame = CFrame.new(currentPos, currentPos + startDirection)
                
                -- scale tracer size based on distance to camera
                local distanceToCamera = (workspace.CurrentCamera.CFrame.Position - currentPos).Magnitude
                local scale = math.clamp(distanceToCamera / 200, 0.2, 2)
                tracer.Size = Vector3.new(scale, scale, scale)
            end
            
            lastPos = currentPos
            RunService.RenderStepped:Wait()
        end

        if tracer and tracer.Parent then
            tracer:Destroy()
        end
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

local function EjectCasing(weapon, bulletType, character)
    if not bulletType or not character or not weapon then return end

    local ejectPart = weapon:FindFirstChild("EjectPart")
    if not ejectPart then return end
    
    local casing = ReplicatedStorage.Objects.BulletCasings:FindFirstChild(bulletType):Clone()
    if not casing then return end
    
    casing.Parent = workspace.EjectedCasings
    casing.CFrame = ejectPart.WorldCFrame  -- Server uses weapon's actual position
    casing.Anchored = false
    casing.CanCollide = true
    
    casing.AssemblyLinearVelocity = ejectPart.CFrame.RightVector * 10 + Vector3.new(0, 8, 0)
    casing.AssemblyAngularVelocity = Vector3.new(math.random(-30, 30), math.random(-30, 30), math.random(-30, 30))
    
    game:GetService("Debris"):AddItem(casing, 15)
end


SyncProjectile.OnClientEvent:Connect(function(shooter, firstPersonOrigin, thirdPersonOrigin, direction, weaponData)
    local player = game.Players.LocalPlayer

    local origin = (shooter == player) and firstPersonOrigin or thirdPersonOrigin
    
    if shooter == player then
        local character = player.Character
        if character then
            local weapon = character:FindFirstChild(weaponData.name)
            if weapon then
                local ejectPart = weapon:FindFirstChild("EjectPart")
                if ejectPart then
                    local bulletType = weaponData.loadedBulletType
                    local casing = ReplicatedStorage.Objects.BulletCasings:FindFirstChild(bulletType):Clone()
                    if casing then
                        casing.Parent = workspace.EjectedCasings
                        casing.CFrame = ejectPart.CFrame
                        casing.Anchored = false
                        casing.CanCollide = true
                        
                        local camera = workspace.CurrentCamera
                        casing.AssemblyLinearVelocity = camera.CFrame.RightVector * 12 + Vector3.new(0, 8, -2)
                        casing.AssemblyAngularVelocity = Vector3.new(
                            math.random(-40, 40),
                            math.random(-40, 40),
                            math.random(-40, 40)
                        )
                        
                        game:GetService("Debris"):AddItem(casing, 5)
                    end
                end
            end
        end
    else
        local character = shooter.Character
        if character then
            local weapon = character:FindFirstChild(weaponData.name)
            if weapon then
                local ejectPart = weapon:FindFirstChild("EjectPart")
                if ejectPart then
                    local bulletType = weaponData.loadedBulletType
                    local casing = ReplicatedStorage.Objects.BulletCasings:FindFirstChild(bulletType):Clone()
                    if casing then
                        casing.Parent = workspace.EjectedCasings
                        casing.CFrame = ejectPart.WorldCFrame
                        casing.Anchored = false
                        casing.CanCollide = true
                        
                        casing.AssemblyLinearVelocity = ejectPart.CFrame.RightVector * 10 + Vector3.new(0, 6, 0)
                        casing.AssemblyAngularVelocity = Vector3.new(
                            math.random(-30, 30),
                            math.random(-30, 30),
                            math.random(-30, 30)
                        )
                        
                        game:GetService("Debris"):AddItem(casing, 5)
                    end
                end
            end
        end
    end
    
    local loadedBulletType = weaponData.loadedBulletType

    local muzzleFlashTemplate = ReplicatedStorage.VFX.MuzzleFlashes.DefaultMuzzleFlash
    local newMuzzleFlash = muzzleFlashTemplate:Clone()
    newMuzzleFlash.Parent = workspace
    newMuzzleFlash.CFrame = CFrame.new(origin)  -- Position at muzzle
    
    -- Play effects
    local flashAmount = math.random(0, 2)
    local didFlash = flashAmount > 0

    for _, v in pairs(newMuzzleFlash:GetDescendants()) do
        if v:IsA("ParticleEmitter") then
            v:Emit(flashAmount)

        elseif v:IsA("Light") then
            if didFlash then
                v.Enabled = true

                task.delay(0.07, function()
                    if v and v.Parent then
                        v.Enabled = false
                    end
                end)
            end
        end
    end
    
    BulletVisualiser:CreateVisualTracer(origin, direction, weaponData.bulletSpeed, loadedBulletType)
end)

return BulletVisualiser