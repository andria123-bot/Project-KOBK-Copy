local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RequestModule = ReplicatedStorage.Shared.Remotes:WaitForChild("RequestModule")
local RequestWeaponCategory = ReplicatedStorage.Shared.Remotes.RequestWeaponCategory

local LoadModule = require(script.Parent.LoadModule)
local WeaponCategory = require(script.Parent.WeaponCategories)

RequestWeaponCategory.OnServerInvoke = function(player)
    return WeaponCategory
end

RequestModule.OnServerInvoke = function(player, Item)
    local module = LoadModule.GetModule(Item)
    return require(module)
end