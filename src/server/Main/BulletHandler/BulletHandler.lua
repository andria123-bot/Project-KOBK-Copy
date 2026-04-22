local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Vetra = require(ReplicatedStorage.Vetra)
local BulletContext = require(ReplicatedStorage.Vetra.Core.BulletContext)
local BehaviorBuilder = require(ReplicatedStorage.Vetra.Builders.BehaviorBuilder)
local SendKillFeedMessage = ReplicatedStorage.Shared.Remotes:WaitForChild("SendKillFeedMessage")
local SyncProjectile = ReplicatedStorage.Shared.Remotes:WaitForChild("SyncProjectile")

local ImpactHoles = workspace:FindFirstChild("ImpactHoles")

local ConcreteImpact = ReplicatedStorage.VFX.BulletImpactMaterials:FindFirstChild("ConcreteImpact")

local BulletHandler = {}

local ImpactMaterials = {
    [Enum.Material.Concrete] = ConcreteImpact,
}

local function SendKillFeedback(killer, victim, weaponName, distance)
    local message = string.format("%s Killed %s with %s From %.1f Meters.", killer.Name, victim.Name, weaponName, distance)
    SendKillFeedMessage:FireAllClients(message)
end

local function CreateBulletHole(hit, position, normal, material)
    local hitImpactTemplate = ImpactMaterials[material]
    
    local impact = hitImpactTemplate:Clone()
    impact.Parent = ImpactHoles
    impact.CFrame = CFrame.new(position, position + normal)
    impact.CanCollide = false
    
    impact.CFrame = impact.CFrame * CFrame.Angles(0, math.rad(math.random(0, 360)), 0)
    
    for _, v in pairs(impact:GetDescendants()) do
        if v:IsA("ParticleEmitter") then
            v:Emit(math.random(3, 8))
        elseif v:IsA("Sound") then
            v.Volume = 0.4
            v:Play()
        end
    end
    
    -- game:GetService("Debris"):AddItem(impact, 15) 
end

function BulletHandler:FireBullet(shooter, clientFirstPersonOrigin, direction, weaponData)
    local character = shooter.Character
    if not character then return end

    local weapon = character:FindFirstChild(weaponData.name)
    local thirdPersonOrigin = weapon and weapon:FindFirstChild("Muzzle") and weapon.Muzzle.Position or character.HumanoidRootPart.Position

    local distanceFromCharacter = (clientFirstPersonOrigin - character.HumanoidRootPart.Position).Magnitude

    if distanceFromCharacter > 10 then 
        warn("Suspicious origin from", shooter.Name)
        clientFirstPersonOrigin = thirdPersonOrigin 
    end 

    for _, targetPlayer in pairs(game.Players:GetPlayers()) do
        SyncProjectile:FireClient(targetPlayer, shooter, clientFirstPersonOrigin, thirdPersonOrigin, direction, weaponData)
    end

    local solver = Vetra.new()

    local Behavior = BehaviorBuilder.new():
          Physics()
            :MaxDistance(weaponData.maxDistanceTravel or 800)
            :Gravity(Vector3.new(0, -workspace.Gravity, 0))
          :Done()
          :Drag()
            :Coefficient(weaponData.dragCoefficient or 0.00022)
            :Model(Vetra.Enums.DragModel.Quadratic)
          :Done()
          :Build()

    local context = BulletContext.new({
        Origin = thirdPersonOrigin,
        Direction = direction,
        Speed = weaponData.bulletSpeed or 880,
        SolverData = {
            player = shooter,
            weapon = weaponData.name,
            damage = weaponData.damage,
            headShot = weaponData.headshot,
        }
    })

    local signals = solver:GetSignals()
    
    signals.OnHit:Connect(function(ctx, result, vel)
        if not result then return end
        local hit = result.Instance
        local pos = result.Position
        local normal = result.Normal
        
        print("Hit detected:", hit and hit.Name or "nil", "Material:", hit and hit.Material or "nil")
        
        if hit then
            local hitData = ctx.__solverData
            if not hitData then return end

            local humanoid = hit.Parent and hit.Parent:FindFirstChild("Humanoid")

            if humanoid and hit.Parent ~= shooter.Character then
                if humanoid.Health <= 0 then
                    return
                end

                local isHead = hit.Name == "Head"
                local damage = isHead and hitData.headShot or hitData.damage

                local healthBefore = humanoid.Health
                humanoid:TakeDamage(damage)

                if healthBefore - damage <= 0 and humanoid.Health <= 0 then
                    local distance = (ctx.Origin - pos).Magnitude
                    SendKillFeedback(shooter, hit.Parent, hitData.weapon, distance)
                end
            else
                CreateBulletHole(hit, pos, normal, hit.Material)
            end
        end
    end)
    
    solver:Fire(context, Behavior)
    print("Bullet fired from:", shooter.Name)
end

return BulletHandler