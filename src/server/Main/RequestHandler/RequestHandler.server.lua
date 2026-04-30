local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RequestWeaponSystemData = ReplicatedStorage.Shared.Remotes.Requests:WaitForChild("RequestWeaponSystemData")
local RequestWeaponData = ReplicatedStorage.Shared.Remotes.Requests:WaitForChild("RequestWeaponData")
local UpdateWeaponStateRemote = ReplicatedStorage.Shared.Remotes:WaitForChild("UpdateWeaponState")
local RequestReload = ReplicatedStorage.Shared.Remotes.Requests:WaitForChild("RequestReload")
local UpdateClientState = ReplicatedStorage.Shared.Remotes:WaitForChild("UpdateClientState")
local RequestShoot = ReplicatedStorage.Shared.Remotes.Requests:WaitForChild("RequestShoot")
local BulletImpactMaterials = ReplicatedStorage.VFX:WaitForChild("BulletImpactMaterials")
local AmmoList = require(ReplicatedStorage.Shared.Modules.Ammos:WaitForChild("AmmoList"))
local PlayerRespawned = ReplicatedStorage.Shared.Remotes:WaitForChild("PlayerRespawned")

local PlayerWeaponSystemData = require(script.Parent.Parent.PlayerWeaponSystemData)
local BulletHandler = require(script.Parent.Parent.BulletHandler.BulletHandler)
local LoadModule = require(ServerScriptService.Server.ModuleHandler.LoadModule)

local playerAmmo = {}
local lastShotTime = {}
local playerShotCount = {}

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
        loadedBulletType = weaponModule.loadedBulletType,
        emptyReloadTime = weaponModule.emptyReloadTime,
        kickbackAmount = weaponModule.kickbackAmount,
        kickReturnTime = weaponModule.kickReturnTime,
        maxAmmo = playerAmmo[player][Item .. "_max"],
        recoilSprings = weaponModule.recoilSprings,
        recoilForce = weaponModule.recoilForce,
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

RequestShoot.OnServerInvoke = function(player, item, LookVector, firstPersonOrigin)
    local character = player.Character
    if not character then return false end

    local weaponModule = LoadModule.GetModule(item)
    if not weaponModule then return false end

    local weaponData = require(weaponModule)
    local bulletData = AmmoList[weaponData.loadedBulletType]
    
    -- ammo check
    if not playerAmmo[player] or playerAmmo[player][item] <= 0 then 
        return false 
    end
    
    -- rate limit
    local now = tick()
    if lastShotTime[player] and now - lastShotTime[player] < weaponData.fireRate then
        return false
    end
    lastShotTime[player] = now
    
    -- ammo decrease
    playerAmmo[player][item] = playerAmmo[player][item] - 1
    local isLastBullet = playerAmmo[player][item] == 0
    
    -- srvr recoil pattern
    local shotNum = (playerShotCount[player] or 0) + 1
    playerShotCount[player] = shotNum
    
    local patternIndex = (shotNum - 1) % #weaponData.serverRecoilPattern + 1
    local recoilOffset = weaponData.serverRecoilPattern[patternIndex]
    
    -- apply server recoil
    local finalDirection = LookVector + Vector3.new(recoilOffset.x, recoilOffset.y, 0)
    finalDirection = finalDirection.Unit
    
    -- fire vetra bullet
    BulletHandler:FireBullet(player, firstPersonOrigin, finalDirection, weaponData)
    
    local sound = player.Character:FindFirstChild("UpperTorso"):FindFirstChild("Shoot")
    if sound then
        sound:Play()
    end


    return true, {
        serverRecoilPattern = weaponData.serverRecoilPattern,
        loadedBulletType = weaponData.loadedBulletType,
        maxAmmo = playerAmmo[player][item .. "_max"],
        bulletSpeed = weaponData.bulletSpeed,
        imageIconId = weaponData.imageIconId,
        ammoLeft = playerAmmo[player][item],
        fireMode = weaponData.fireMode,
        ammoType = weaponData.ammoType,
        fireRate = weaponData.fireRate,
        isLastBullet = isLastBullet,
        name = weaponData.name,
    }, {
        hipSpread = bulletData.hipSpread,
        aimSpread = bulletData.aimSpread,
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
        for weapon, _ in pairs(playerAmmo[player]) do
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