local AimHelper = {}

AimHelper.weaponModule = nil
AimHelper.viewmodel = nil

local PlayerWeaponSystemData = require(script.Parent.PlayerWeaponSystemData)

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

function AimHelper:Aim(dt)
	if not (self.weaponModule and self.viewmodel and self.weaponModule.canAim) then return end
	
	if PlayerWeaponSystemData.weaponSystem.state == PlayerWeaponSystemData.weaponSystem.states[5] then
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

	elseif PlayerWeaponSystemData.weaponSystem.state == PlayerWeaponSystemData.weaponSystem.states[1] then
		self.weaponModule.currentSwayAMT = self.weaponModule.swayAMT
		
		local alpha = math.clamp(1 - self.weaponModule.aimSmooth ^ dt, 0, 1)
		self.weaponModule.aimCF = self.weaponModule.aimCF:Lerp(CFrame.new(), alpha)
	end
end

return AimHelper