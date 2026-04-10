local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RequestWeaponData = ReplicatedStorage.Shared.Remotes.Requests:WaitForChild("RequestWeaponData")

local Scope = {}

function Scope:Init(weaponModule, weaponSys)
    self.weaponModule = weaponModule
    self.weaponSystem = weaponSys
end

function Scope:GetScopeData()
    local isDefaultScope = (self.weaponModule.scopeData.defaultScope) == ""

    print(isDefaultScope)
end


return Scope