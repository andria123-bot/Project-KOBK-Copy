local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RequestWeaponData = ReplicatedStorage.Shared.Remotes.Requests:WaitForChild("RequestWeaponData")
local RequestWeaponSystemData = ReplicatedStorage.Shared.Remotes.Requests:WaitForChild("RequestWeaponSystemData")

local LoadModule = require(ServerScriptService.Server.ModuleHandler.LoadModule)
local playerWeaponSystemData = require(script.Parent.Parent.PlayerWeaponSystemData)
local UpdateWeaponStateRemote = ReplicatedStorage.Shared.Remotes:WaitForChild("UpdateWeaponState")

RequestWeaponData.OnServerInvoke = function(player, Item)
    -- print(debug.traceback())
    -- print("Request for", Item, "data received from", player.Name)
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
            canSemi = data.canSemi,
            canFullAuto = data.canFullAuto,
            fireMode = data.fireMode,
        }
    }
end

UpdateWeaponStateRemote.OnServerEvent:Connect(function(player, newState)
    playerWeaponSystemData:setState(newState)
end)

RequestWeaponSystemData.OnServerInvoke = function(player)
    print("Request for weapon system data received from", player.Name)
    print(playerWeaponSystemData)
    
    return {
        playerWeaponSystemData
    }
end