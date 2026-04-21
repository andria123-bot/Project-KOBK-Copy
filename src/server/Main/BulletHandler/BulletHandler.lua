local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Vetra = require(ReplicatedStorage.Vetra)
local BulletContext = require(ReplicatedStorage.Vetra.Core.BulletContext)
local AmmoTracer = ReplicatedStorage.VFX.Tracers:FindFirstChild("TracerAmmo")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local BulletHandler = {}

function BulletHandler:FireBullet(player, origin, direction, weaponData)
    
    local solver = Vetra.new()

    local behavior = {
        MaxDistance = weaponData.maxDistanceTravel or 800,
        DragCoefficient = weaponData.dragCoefficient or 0.00022,
        DragModel = Vetra.Enums.DragModel.Quadratic,
        Gravity = Vector3.new(0, -workspace.Gravity, 0),
    }

    local context = BulletContext.new({
        Origin = origin,
        Direction = direction,
        Speed = weaponData.bulletSpeed or 880,
        SolverData = {
            player = player,
            weapon = weaponData.name,
            damage = weaponData.damage,
            headShot = weaponData.headshot,
        }
    })

    local signals = solver:GetSignals()
    
    signals.OnHit:Connect(function(ctx, result, vel)
        if not result then return end
        local hit = result.Instance
        
        if hit then
            local hitData = ctx.__solverData
            if not hitData then return end

            local humanoid = hit.Parent and hit.Parent:FindFirstChild("Humanoid")

            if humanoid and hit.Parent ~= player.Character then
                local isHead = hit.Name == "Head"
                local damage = isHead and hitData.headshot or hitData.damage
                humanoid:TakeDamage(damage)
            end
        -- else
            -- print("Hit nothing")
        end
    end)
    
    solver:Fire(context, behavior)
    print("Bullet fired!")
end

return BulletHandler