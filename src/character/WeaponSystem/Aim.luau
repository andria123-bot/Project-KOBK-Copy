local AimHelper = {}

AimHelper.weaponModule = nil
AimHelper.viewmodel = nil

local Scope = require(script.Parent.Scope)

local camera = workspace.CurrentCamera

local defaultFOV = 70

local currentAimPart = 1
local currentFOV = defaultFOV

function AimHelper:Init(weaponModule, viewmodel, weaponSys)
    self.weaponModule = weaponModule
    self.viewmodel = viewmodel
    self.weaponSystem = weaponSys
end

function AimHelper:switchAimpart()
    if currentAimPart == 1 then
        currentAimPart = 2
    else
        currentAimPart = 1
    end
    Scope:switchAimpart()
end

function AimHelper:Reset()
    currentFOV = defaultFOV
    currentAimPart = 1
    camera.FieldOfView = defaultFOV
    
    if self.weaponModule and self.weaponModule.aimData then
        self.weaponModule.aimData.aimCF = CFrame.new()
        self.weaponModule.aimData.currentSwayAMT = self.weaponModule.aimData.swayAMT
    end
end

function AimHelper:Aim(dt)
    if not self.weaponSystem or not self.viewmodel or not self.viewmodel.Parent then
        currentFOV = defaultFOV
        camera.FieldOfView = defaultFOV
        return
    end
    
    if not (self.weaponModule and self.viewmodel and self.weaponModule.aimData.canAim) then return end

    if self.weaponSystem.modifiers.IsReloading then
        self.weaponModule.aimData.aimCF = self.weaponModule.aimData.aimCF:Lerp(CFrame.new(), 0.3)
        currentFOV = currentFOV + (defaultFOV - currentFOV) * 0.3
        camera.FieldOfView = currentFOV
        self.weaponModule.aimData.currentSwayAMT = self.weaponModule.aimData.swayAMT
        return
    end
    
    local isAiming = (self.weaponSystem.state == self.weaponSystem.states[5]) or 
                     (self.weaponSystem.modifiers.IsAiming == true) 
    if isAiming and not 
        self.weaponSystem.modifiers.IsReloading and not 
        self.weaponSystem.modifiers.IsInspecting then

        Scope:Init(self.weaponModule, self.weaponSystem)
        local scopeData = Scope:GetScopeData()
        
        local aimFOV = scopeData.aimFOV
                                            
        local primary = self.viewmodel.PrimaryPart
        if not primary then return end

        local targetPart
        if currentAimPart == 1 then
            targetPart = self.viewmodel:FindFirstChild("AimPart", true)
        else
            targetPart = self.viewmodel:FindFirstChild("AimPart2", true)
        end

        local targetOffset = CFrame.new()

        if targetPart then
            targetOffset = targetPart.CFrame:ToObjectSpace(primary.CFrame)
            self.weaponModule.aimData.currentSwayAMT = self.weaponModule.aimData.aimSwayAMT
        else
            self.weaponModule.aimData.currentSwayAMT = self.weaponModule.aimData.swayAMT
        end

        local alpha = math.clamp(1 - self.weaponModule.aimData.aimSmooth ^ dt, 0, 1)
        self.weaponModule.aimData.aimCF = self.weaponModule.aimData.aimCF:Lerp(targetOffset, alpha)
        
        currentFOV = currentFOV + (aimFOV - currentFOV) * alpha
        camera.FieldOfView = currentFOV
    elseif not isAiming then
        self.weaponModule.aimData.currentSwayAMT = self.weaponModule.aimData.swayAMT
        
        local alpha = math.clamp(1 - self.weaponModule.aimData.aimSmooth ^ dt, 0, 1)
        self.weaponModule.aimData.aimCF = self.weaponModule.aimData.aimCF:Lerp(CFrame.new(), alpha)
        
        currentFOV = currentFOV + (defaultFOV - currentFOV) * alpha
        camera.FieldOfView = currentFOV
    end
end

return AimHelper