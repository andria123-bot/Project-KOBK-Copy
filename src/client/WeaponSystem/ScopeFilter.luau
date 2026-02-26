local ScopeFilter = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local scopeFolder = ReplicatedStorage.Shared.Modules.Attachments.Scopes -- needs rework, bit hardcoded

local scopeModule = require(ReplicatedStorage.Shared.Modules.Attachments.Scopes:WaitForChild("ATACR"))

local partConfigs = {
    REG = { aiming = 0.02, normal = 0 },
    REGP = { aiming = 0.02, normal = 0 },
    LensZ = { aiming = 1, normal = 1 },
    ADS = { aiming = 0, normal = 1 },
    ADSP = { aiming = 0, normal = 1 },
    Mount = { aiming = 1, normal = 0 },
    MountP = { aiming = 1, normal = 0 },
    Lens = { aiming = 0.8, normal = 0 }
}

function ScopeFilter:Init(weaponModule, viewmodel)
    self.weaponModule = weaponModule
    self.viewmodel = viewmodel
    self.defaultFOV = 70
    self.attachmentsFolder = viewmodel:FindFirstChild("Attachments")
    self.scopeParts = {}

    if self.attachmentsFolder then
        for _, attachment in pairs(self.attachmentsFolder:GetChildren()) do
            for _, part in pairs(attachment:GetDescendants()) do
                if part:IsA("BasePart") and partConfigs[part.Name] then
                    table.insert(self.scopeParts, part)
                end
            end
        end
    end
end

function ScopeFilter:GetScopeFOV(dt, states)
    return self.weaponModule.scopeFOV or 50 -- default fov
end

function ScopeFilter:scopeFilter(dt, states)
    local camera = Workspace.CurrentCamera
    if not camera then return end
    
    if not self.viewmodel or not self.weaponModule then return end
    if self.weaponModule.isMelee or self.weaponModule.isGrenade then return end
    if states.isReloading then return end
    
    local isAiming = states.isAiming and self.weaponModule.canAim and not states.isSprinting
    
    local targetFOV = isAiming and self:GetScopeFOV() or self.defaultFOV
    camera.FieldOfView = camera.FieldOfView + (targetFOV - camera.FieldOfView) * 0.1
    
    for _, part in pairs(self.scopeParts) do
        local config = partConfigs[part.Name]
        if config then
            part.Transparency = isAiming and config.aiming or config.normal
        end
    end
end

return ScopeFilter