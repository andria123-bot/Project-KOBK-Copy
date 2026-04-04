local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RequestWeaponData = ReplicatedStorage.Shared.Remotes.Requests:WaitForChild("RequestWeaponData")
local RequestWeaponSystemData = ReplicatedStorage.Shared.Remotes.Requests:WaitForChild("RequestWeaponSystemData")
local RequestShoot = ReplicatedStorage.Shared.Remotes.Requests:WaitForChild("RequestShoot")

local LoadModule = require(ServerScriptService.Server.ModuleHandler.LoadModule)
local playerWeaponSystemData = require(script.Parent.Parent.PlayerWeaponSystemData)
local UpdateWeaponStateRemote = ReplicatedStorage.Shared.Remotes:WaitForChild("UpdateWeaponState")

local SpringModule = require(script.Parent.Parent.Parent.Spring)

local recoilSpring = SpringModule.new(Vector3.new(0,0,0), 0.5, 50)
recoilSpring.Damping = 5

RequestWeaponData.OnServerInvoke = function(player, Item) -- returnes weapon module's specifications data
    -- print(debug.traceback())
    local data = require(LoadModule.GetModule(Item))
    
    return {
        animations = data.animations,
        sounds = data.sounds,
        name = data.name,
        aimData = {
            lastCameraCF = data.lastCameraCF,
            currentSwayAMT = data.swayAMT,
            aimSwayAMT = data.aimSwayAMT,
            aimSmooth = data.aimSmooth,
            sprintCF = data.sprintCF,
            swayAMT = data.swayAMT,
            canAim = data.canAim,
            swayCF = data.swayCF,
            aimCF = data.aimCF,
        },

        modifiers = {
            canFullAuto = data.canFullAuto,
            isShooting = data.isShooting,
            fireMode = data.fireMode,
            debounce = data.debounce,
            canSemi = data.canSemi,
        }
    }
end

RequestShoot.OnServerInvoke = function(player, item)
	if player.Character then
		local weaponModule = LoadModule.GetModule(item)
		if not weaponModule  then return end

		local weaponData = require(weaponModule)
        local ammo = weaponData.ammo
        local maxAmmo = weaponData.maxAmmo
        local fireRate = weaponData.fireRate
        local debounce = weaponData.debounce

        local modX, modY, modZ = weaponData.x, weaponData.y, weaponData.z

        local rx = (math.rad((math.random() * modX * 0.8) + (math.random() < 0.2 and -modX * 0.2 or 0))) 
        local ry = (math.rad((math.random() - 0.5) * 2 * modY))  -- [-modY, modY]
        local rz = (math.rad((math.random() - 0.5) * 2 * modZ))  -- [-modZ, modZ]


		local sound = player.Character:WaitForChild("UpperTorso"):FindFirstChild("Shoot")
		if sound then
			sound:Play()
		end

        return true, {x = rx, y = ry, z = rz}, {
            debounce = debounce,
            fireRate = fireRate,
        }
	end
end

UpdateWeaponStateRemote.OnServerEvent:Connect(function(player, newState)
    playerWeaponSystemData:setState(newState)
end)

RequestWeaponSystemData.OnServerInvoke = function(player)
    return {
        playerWeaponSystemData.weaponSystem
    }
end

--[[    modifiers = playerWeaponSystemData.weaponSystem.modifiers,
        state = playerWeaponSystemData.weaponSystem.state,
        states = playerWeaponSystemData.weaponSystem.states,
        animations = playerWeaponSystemData.weaponSystem.animations,
        sounds = playerWeaponSystemData.weaponSystem.sounds,
        viewmodel = playerWeaponSystemData.weaponSystem.viewmodel,
]]