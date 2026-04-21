local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TouchInputService = game:GetService("TouchInputService")
local Vetra = require(ReplicatedStorage.Vetra)
local BulletContext = require(ReplicatedStorage.Vetra.Core.BulletContext)
local AmmoTracer = ReplicatedStorage.VFX.Tracers:FindFirstChild("TracerAmmo")
local SendKillFeedMessage = ReplicatedStorage.Shared.Remotes:WaitForChild("SendKillFeedMessage")

local BulletHandler = {}

local function SendKillFeedback(killer, victim, weaponName, distance)
    local message = string.format("%s Killed %s with %s From %.1f Meters.", killer.Name, victim.Name, weaponName, distance)
    
    SendKillFeedMessage:FireAllClients(message)
end
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
        local pos = result.Position
        
        if hit then
            local hitData = ctx.__solverData
            if not hitData then return end

            local humanoid = hit.Parent and hit.Parent:FindFirstChild("Humanoid")

            if humanoid and hit.Parent ~= player.Character then
                if humanoid.Health <= 0 then
                    return  -- Don't shoot dead bodies
                end

                local isHead = hit.Name == "Head"
                local damage = isHead and hitData.headshot or hitData.damage

                local healthBefore = humanoid.Health
                humanoid:TakeDamage(damage)

                if healthBefore - damage <= 0 and humanoid.Health <= 0  then
                    local distance = (ctx.Origin - pos).Magnitude
                    SendKillFeedback(player, hit.Parent, hitData.weapon, distance)
                end
            end
        -- else
            -- print("Hit nothing")
        end
    end)
    
    solver:Fire(context, behavior)
    print("Bullet fired!")
end

return BulletHandler