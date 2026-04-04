local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RequestWeaponData = ReplicatedStorage.Shared.Remotes.Requests:WaitForChild("RequestWeaponData")
local RequestWeaponSystemData = ReplicatedStorage.Shared.Remotes.Requests:WaitForChild("RequestWeaponSystemData")
local RequestShoot = ReplicatedStorage.Shared.Remotes.Requests:WaitForChild("RequestShoot")

local LoadModule = require(ServerScriptService.Server.ModuleHandler.LoadModule)
local PlayerWeaponSystemData = require(script.Parent.Parent.PlayerWeaponSystemData)
local UpdateWeaponStateRemote = ReplicatedStorage.Shared.Remotes:WaitForChild("UpdateWeaponState")
local lastShotTime = {}
local itemData 

RequestWeaponData.OnServerInvoke = function(player, Item) -- returnes weapon module's specifications data
    -- print(debug.traceback())
    itemData = require(LoadModule.GetModule(Item))
    itemData.module = require(LoadModule.GetModule(Item))

    return {
        animations = itemData.animations,
        sounds = itemData.sounds,
        name = itemData.name,
        aimData = {
            lastCameraCF = itemData.lastCameraCF,
            currentSwayAMT = itemData.swayAMT,
            aimSwayAMT = itemData.aimSwayAMT,
            aimSmooth = itemData.aimSmooth,
            sprintCF = itemData.sprintCF,
            swayAMT = itemData.swayAMT,
            canAim = itemData.canAim,
            swayCF = itemData.swayCF,
            aimCF = itemData.aimCF,
        },

        modifiers = {
            canFullAuto = itemData.canFullAuto,
            isShooting = itemData.isShooting,
            isGrenade = itemData.isGrenade,
            fireMode = itemData.fireMode,
            debounce = itemData.debounce,
            isMelee = itemData.isMelee,
            canSemi = itemData.canSemi,
        }
    }
end

RequestShoot.OnServerInvoke = function(player, item)
	if player.Character then
		local weaponModule = LoadModule.GetModule(item)
		if not weaponModule then return false end

		local weaponData = require(weaponModule)
		
		local now = tick()
		local lastShot = lastShotTime[player] or 0
		if now - lastShot < weaponData.fireRate then
            -- player:Kick("Cheating Detected! (Too Fast Shooting). If you think this is a mistake, please contact support.") add debounce on client and then enable ts
			return false  -- Reject shot, too fast 
		end
		lastShotTime[player] = now
		
		if itemData.ammo <= 0 then return false end
		
		itemData.ammo -= 1

		local isLastBullet = (weaponData.ammo == 0)

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
			ammoLeft = weaponData.ammo
		}
	end

	return false
end

UpdateWeaponStateRemote.OnServerEvent:Connect(function(player, newState)
    PlayerWeaponSystemData:setState(newState)
end)

RequestWeaponSystemData.OnServerInvoke = function(player)
    return {
        PlayerWeaponSystemData.weaponSystem
    }
end

