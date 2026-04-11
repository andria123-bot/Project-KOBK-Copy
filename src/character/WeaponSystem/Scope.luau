local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RequestWeaponData = ReplicatedStorage.Shared.Remotes.Requests:WaitForChild("RequestWeaponData")
local ScopeConfigs = require(ReplicatedStorage.Shared.Modules.ScopeConfig.ScopeConfigs)

local Scope = {}

function Scope:Init(weaponModule, weaponSys)
    self.weaponModule = weaponModule
    self.weaponSystem = weaponSys
end

function Scope:GetScopeData()
    local scopeData = self.weaponModule.scopeData

    if scopeData.currentScope == "Empty" then
        scopeData.currentScope = scopeData.defaultScope
    end

    local currentScopeName = scopeData.currentScope
    local currentScope = ScopeConfigs[currentScopeName]

    return currentScope
end


return Scope