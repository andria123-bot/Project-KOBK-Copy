local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RequestWeaponData = ReplicatedStorage.Shared.Remotes.Requests:WaitForChild("RequestWeaponData")
local ScopeConfigs = require(ReplicatedStorage.Shared.Modules.ScopeConfig.ScopeConfigs)

local Scope = {
    currentAimPart = 1,
}

function Scope:Init(weaponModule, weaponSys)
    self.weaponModule = weaponModule
    self.weaponSystem = weaponSys
end

function Scope:switchAimpart()
    if self.currentAimPart == 1 then
        self.currentAimPart = 2
    else
        self.currentAimPart = 1
    end
end

function Scope:GetScopeData()
    local scopeData = self.weaponModule.scopeData

    if scopeData.currentScope == "Empty" then
        scopeData.currentScope = scopeData.defaultScope
    end

    local currentScopeName = scopeData.currentScope
    local currentScope = ScopeConfigs[currentScopeName]
    
    if currentScope then
        local result = {
            aimFOV = currentScope.aimFOV,
            aimSwayAMT = currentScope.aimSwayAMT,
            aimSmooth = currentScope.aimSmooth,
            zoomLevel = currentScope.zoomLevel,
        }
        
        if self.currentAimPart == 2 and currentScope.aimPart2FOV then
            result.aimFOV = currentScope.aimPart2FOV
        end
        
        return result
    end

    return nil
end

return Scope