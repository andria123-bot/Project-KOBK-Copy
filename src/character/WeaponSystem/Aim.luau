local AimHelper = {}

AimHelper.weaponModule = nil
AimHelper.viewmodel = nil

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RequestWeaponSystemData = ReplicatedStorage.Shared.Remotes.Requests:WaitForChild("RequestWeaponSystemData")
-- local UpdateWeaponStateRemote = ReplicatedStorage.Shared.Remotes:WaitForChild("UpdateWeaponState")

local PlayerWeaponSystem = RequestWeaponSystemData:InvokeServer()

local currentAimPart = 1

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
end

function AimHelper:Aim(dt)
    if not (self.weaponModule and self.viewmodel and self.weaponModule.canAim) then return end
    
    -- Check if aiming (state 5) OR if player is holding aim button during shooting
    local isAiming = (self.weaponSystem.state == self.weaponSystem.states[5]) or 
                     (self.weaponSystem.modifiers.IsAiming == true)
    
    if isAiming and not 
        self.weaponSystem.modifiers.IsReloading and not 
        self.weaponSystem.modifiers.IsInspecting then
											
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
			self.weaponModule.currentSwayAMT = self.weaponModule.aimSwayAMT
		else
			self.weaponModule.currentSwayAMT = self.weaponModule.swayAMT
		end

		local alpha = math.clamp(1 - self.weaponModule.aimSmooth ^ dt, 0, 1)
		self.weaponModule.aimCF = self.weaponModule.aimCF:Lerp(targetOffset, alpha)

	elseif not isAiming then
		self.weaponModule.currentSwayAMT = self.weaponModule.swayAMT
		
		local alpha = math.clamp(1 - self.weaponModule.aimSmooth ^ dt, 0, 1)
		self.weaponModule.aimCF = self.weaponModule.aimCF:Lerp(CFrame.new(), alpha)
	end
end

return AimHelper