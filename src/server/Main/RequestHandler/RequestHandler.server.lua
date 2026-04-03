local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RequestWeaponData = ReplicatedStorage.Shared.Remotes.Requests:WaitForChild("RequestWeaponData")
local LoadModule = require(ServerScriptService.Server.ModuleHandler.LoadModule)

RequestWeaponData.OnServerInvoke = function(player, Item)
    print(debug.traceback())
    print("Request for", Item, "data received from", player.Name)
    local data = require(LoadModule.GetModule(Item))
    print(data)
    
    return {
        animations = data.animations,
        sounds = data.sounds,
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