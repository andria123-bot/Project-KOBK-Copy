local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SyncProjectileBindable = ReplicatedStorage.Shared.Remotes.Bindables:WaitForChild("SyncProjectileBindable")
local SnycTracerToOthers = ReplicatedStorage.Shared.Remotes:FindFirstChild("SnycTracerToOthers")

local BulletHandler = {}
local activeBullets = {}

function BulletHandler:ValidateBulletHit(origin, direction, maxDistance, owner, ignoreList)
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = ignoreList or {owner.Character}

    local ray = workspace:Raycast(origin, direction * maxDistance, rayParams)
    if ray then
        local hit = ray.Instance
        local hitPos = ray.Position
        local hitNormal = ray.Normal

        return {
            hit = hit;
            hitPos = hitPos;
            hitNormal = hitNormal;
            distance = (origin - hitPos).Magnitude;
            material = hit.Material;
        }
    end
end

function BulletHandler:CreateServerBeam(origin, direction, maxDistance, player, weaponData)
    
end

SyncProjectileBindable.Event:Connect(function(player, origin, direction, speed)
    for _, otherPlayer in pairs(game.Players:GetPlayers()) do
        if otherPlayer ~= player then
            SnycTracerToOthers:FireClient(otherPlayer, origin, direction, speed, player)
        end
    end
end)

function BulletHandler:ClearAllBullets()
    for _, bullet in pairs(activeBullets) do
        bullet.active = false
        if bullet.tracer then
            bullet.tracer:Destroy()
        end
    end
    table.clear(activeBullets)
end

return BulletHandler