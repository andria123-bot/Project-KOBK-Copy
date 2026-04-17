local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RequestWeaponSystemData = ReplicatedStorage.Shared.Remotes.Requests:WaitForChild("RequestWeaponSystemData")
local SyncProjectileBindable = ReplicatedStorage.Shared.Remotes.Bindables:WaitForChild("SyncProjectileBindable")
local RequestWeaponData = ReplicatedStorage.Shared.Remotes.Requests:WaitForChild("RequestWeaponData")
local UpdateWeaponStateRemote = ReplicatedStorage.Shared.Remotes:WaitForChild("UpdateWeaponState")
local RequestReload = ReplicatedStorage.Shared.Remotes.Requests:WaitForChild("RequestReload")
local UpdateClientState = ReplicatedStorage.Shared.Remotes:WaitForChild("UpdateClientState")
local RequestShoot = ReplicatedStorage.Shared.Remotes.Requests:WaitForChild("RequestShoot")
local BulletImpactMaterials = ReplicatedStorage.VFX:WaitForChild("BulletImpactMaterials")
local PlayerRespawned = ReplicatedStorage.Shared.Remotes:WaitForChild("PlayerRespawned")

local PlayerWeaponSystemData = require(script.Parent.Parent.PlayerWeaponSystemData)
local BulletHandler = require(script.Parent.Parent.BulletHandler.BulletHandler)
local LoadModule = require(ServerScriptService.Server.ModuleHandler.LoadModule)

local playerAmmo = {}
local lastShotTime = {}

RequestWeaponData.OnServerInvoke = function(player, Item)
    local weaponModule = require(LoadModule.GetModule(Item))
    
    if not playerAmmo[player] then
        playerAmmo[player] = {}
    end
    
    if playerAmmo[player][Item] == nil then
        playerAmmo[player][Item] = weaponModule.ammo
        playerAmmo[player][Item .. "_max"] = weaponModule.maxAmmo
    end
    
    return {
        maxAmmo = playerAmmo[player][Item .. "_max"],
        currentAmmo = playerAmmo[player][Item],
        imageIconId = weaponModule.imageIconId,
        reloadTime = weaponModule.reloadTime,
        animations = weaponModule.animations,
        scopeData = weaponModule.scopeData;
        fireMode = weaponModule.fireMode,
        ammoType = weaponModule.ammoType,
        sounds = weaponModule.sounds,
        name = weaponModule.name,

        aimData = {
            lastCameraCF = weaponModule.lastCameraCF,
            currentSwayAMT = weaponModule.swayAMT,
            aimSwayAMT = weaponModule.aimSwayAMT,
            aimSmooth = weaponModule.aimSmooth,
            sprintCF = weaponModule.sprintCF,
            swayAMT = weaponModule.swayAMT,
            canAim = weaponModule.canAim,
            swayCF = weaponModule.swayCF,
            aimCF = weaponModule.aimCF,
        },
        
        modifiers = {
            canFullAuto = weaponModule.canFullAuto,
            isShooting = weaponModule.isShooting,
            isGrenade = weaponModule.isGrenade,
            fireMode = weaponModule.fireMode,
            debounce = weaponModule.debounce,
            isMelee = weaponModule.isMelee,
            canSemi = weaponModule.canSemi,
        }
    }
end

RequestShoot.OnServerInvoke = function(player, item, LookVector) -- everything from here should go to BulletHandler.lua
    local character = player.Character or player.CharacterAdded:Wait()
	if not character then return end 

    local weaponModule = LoadModule.GetModule(item)
    if not weaponModule then return false end

    local weaponData = require(weaponModule)

    local direction = LookVector
    local muzzlePos = character:FindFirstChild(item).Muzzle.Position
	    
    local now = tick()
    local lastShot = lastShotTime[player] or 0
    if now - lastShot < weaponData.fireRate then
        return false
    end
    lastShotTime[player] = now
    
    if not playerAmmo[player] or not playerAmmo[player][item] then
        return false
    end
    
    if playerAmmo[player][item] <= 0 then return false end
    
    playerAmmo[player][item] = playerAmmo[player][item] - 1
    
    local isLastBullet = (playerAmmo[player][item] == 0)

    -- weaponData:Fire(player, character, muzzlePos, direction, weaponData.bulletSpeed, nil) -- default fastcast
    SyncProjectileBindable:Fire(player, muzzlePos, direction, weaponData.bulletSpeed) -- custom projectile

    local modX, modY, modZ = weaponData.x, weaponData.y, weaponData.z

    local rx = (math.random() * modX * 0.8) + (math.random() < 0.2 and -modX * 0.2 or 0)
    local ry = (math.random() - 0.5) * 2 * modY
    local rz = (math.random() - 0.5) * 2 * modZ

    local sound = player.Character:WaitForChild("UpperTorso"):FindFirstChild("Shoot")
    if sound then
        sound:Play()
    end

	return true, {rx = rx, ry = ry, rz = rz}, {
        maxAmmo = playerAmmo[player][item .. "_max"],
        bulletSpeed = weaponData.bulletSpeed,
        imageIconId = weaponData.imageIconId,
        tracerColor = weaponData.tracerColor,
        ammoLeft = playerAmmo[player][item],
        fireMode = weaponData.fireMode,
        ammoType = weaponData.ammoType,
        isLastBullet = isLastBullet,
    }
end

RequestReload.OnServerInvoke = function(player, gun)
    if not playerAmmo[player] or not playerAmmo[player][gun] then
        return false
    end
    
    local currentAmmo = playerAmmo[player][gun]
    local maxAmmo = playerAmmo[player][gun .. "_max"]
    local isLastBullet = (playerAmmo[player][gun] == 1)
    
    if not maxAmmo then
        return false
    end
    
    if currentAmmo >= maxAmmo then
        return false
    end
    
    playerAmmo[player][gun] = maxAmmo
    
    return true, {
        isLastAmmo = isLastBullet,
        ammoLeft = playerAmmo[player][gun],
        maxAmmo = maxAmmo
    }
end

game.Players.PlayerRemoving:Connect(function(player)
    playerAmmo[player] = nil
end)

PlayerRespawned.OnServerEvent:Connect(function(player)
    if playerAmmo[player] then
        for weapon, current in pairs(playerAmmo[player]) do
            if not string.find(weapon, "_max") then
                local maxAmmo = playerAmmo[player][weapon .. "_max"]
                if maxAmmo then
                    playerAmmo[player][weapon] = maxAmmo
                end
            end
        end
    end
end)

UpdateWeaponStateRemote.OnServerEvent:Connect(function(player, newState)
    -- print(debug.traceback()) -- debug
    PlayerWeaponSystemData:setState(newState)
    UpdateClientState:FireClient(player, newState)
end)

RequestWeaponSystemData.OnServerInvoke = function(player)
    return {
        PlayerWeaponSystemData.weaponSystem;
    }
end