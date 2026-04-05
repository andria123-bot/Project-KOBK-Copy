local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RequestWeaponData = ReplicatedStorage.Shared.Remotes.Requests:WaitForChild("RequestWeaponData")
local RequestWeaponSystemData = ReplicatedStorage.Shared.Remotes.Requests:WaitForChild("RequestWeaponSystemData")
local RequestShoot = ReplicatedStorage.Shared.Remotes.Requests:WaitForChild("RequestShoot")
local RequestReload = ReplicatedStorage.Shared.Remotes.Requests:WaitForChild("RequestReload")
local UpdateClientState = ReplicatedStorage.Shared.Remotes:WaitForChild("UpdateClientState")

local LoadModule = require(ServerScriptService.Server.ModuleHandler.LoadModule)
local PlayerWeaponSystemData = require(script.Parent.Parent.PlayerWeaponSystemData)
local UpdateWeaponStateRemote = ReplicatedStorage.Shared.Remotes:WaitForChild("UpdateWeaponState")

local lastShotTime = {}
local playerAmmo = {}

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
        animations = weaponModule.animations,
        sounds = weaponModule.sounds,
        name = weaponModule.name,
        currentAmmo = playerAmmo[player][Item],
        maxAmmo = playerAmmo[player][Item .. "_max"],
        imageIconId = weaponModule.imageIconId,
        fireMode = weaponModule.fireMode,
        ammoType = weaponModule.ammoType,
        reloadTime = weaponModule.reloadTime,

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

RequestShoot.OnServerInvoke = function(player, item, LookVector, muzzlePos)
    local character = player.Character or player:WaitForChild(player.Character)
	if not character then return end 

    local weaponModule = LoadModule.GetModule(item)
    if not weaponModule then return false end

    local weaponData = require(weaponModule)
    local direction = LookVector.Unit
	    
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
    weaponData:Fire(player, character, muzzlePos, direction, weaponData.bulletSpeed, nil) -- leater change to character's weapon muzzle's position and lookvector

    local modX, modY, modZ = weaponData.x, weaponData.y, weaponData.z

    local rx = (math.random() * modX * 0.8) + (math.random() < 0.2 and -modX * 0.2 or 0)
    local ry = (math.random() - 0.5) * 2 * modY
    local rz = (math.random() - 0.5) * 2 * modZ

    local sound = player.Character:WaitForChild("UpperTorso"):FindFirstChild("Shoot")
    if sound then
        sound:Play()
    end
		
	return true, {rx = rx, ry = ry, rz = rz}, {
        isLastBullet = isLastBullet,
        ammoLeft = playerAmmo[player][item],
        maxAmmo = playerAmmo[player][item .. "_max"],
        imageIconId = weaponData.imageIconId,
        fireMode = weaponData.fireMode,
        ammoType = weaponData.ammoType,
    }
end

RequestReload.OnServerInvoke = function(player, gun)
    if not playerAmmo[player] or not playerAmmo[player][gun] then
        return false
    end
    
    local currentAmmo = playerAmmo[player][gun]
    local maxAmmo = playerAmmo[player][gun .. "_max"]
    local isLastBullet = (playerAmmo[player][gun] == 0)
    
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
    lastShotTime[player] = nil
    playerAmmo[player] = nil
end)

UpdateWeaponStateRemote.OnServerEvent:Connect(function(player, newState)
    -- print(debug.traceback()) -- debug
    PlayerWeaponSystemData:setState(newState)
    UpdateClientState:FireClient(player, newState)
end)

RequestWeaponSystemData.OnServerInvoke = function(player)
    return {
        PlayerWeaponSystemData.weaponSystem
    }
end