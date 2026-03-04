local AimHelper = {}

AimHelper.weaponModule = nil
AimHelper.viewmodel = nil
AimHelper.isReloading = nil
AimHelper.isInspecting = nil
AimHelper.isAiming = nil
AimHelper.canAim = nil

local currentAimPart = 1

function AimHelper:Init(weaponModule, viewmodel)
    self.weaponModule = weaponModule
    self.viewmodel = viewmodel
end

function AimHelper:switchAimpart()
    if currentAimPart == 1 then
		currentAimPart = 2
	else
		currentAimPart = 1
	end
end

function AimHelper:Aim(dt, state)
	if not (self.weaponModule and self.viewmodel and self.weaponModule.canAim) then return end
	if state.isReloading or state.isInspecting then return end

	if self.canAim then
		local primary = self.viewmodel.PrimaryPart
		if not primary then return end

		local targetPart
		if currentAimPart == 1 then
			targetPart = self.viewmodel:FindFirstChild("AimPart", true)
		else
			targetPart = self.viewmodel:FindFirstChild("AimPart2", true)
		end

		local targetOffset = CFrame.new()

		if state.isAiming and targetPart and not state.isSprinting then
			targetOffset = targetPart.CFrame:ToObjectSpace(primary.CFrame)
			self.weaponModule.currentSwayAMT = self.weaponModule.aimSwayAMT
		else
			self.weaponModule.currentSwayAMT = self.weaponModule.swayAMT
		end

		local alpha = math.clamp(1 - self.weaponModule.aimSmooth ^ dt, 0, 1)
		self.weaponModule.aimCF = self.weaponModule.aimCF:Lerp(targetOffset, alpha)
	end
end

return AimHelper