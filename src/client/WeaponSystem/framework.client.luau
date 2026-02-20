local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local UserInputService = game:GetService("UserInputService")
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait() or script.Parent
local humanoid = character:WaitForChild("Humanoid")
local camera = game.Workspace.CurrentCamera

local viewmodelFinder = require(script.Parent.LoadViewmodel)
local moduleFinder = require(script.Parent.LoadModule)
local playerWeaponSystem = require(script.Parent.PlayerWeaponSystemData)

local weaponSystem = playerWeaponSystem.weaponSystem

local canChange = true
local isReloading = false
local isShooting = false
local isEquipedWeapon = false
local isAiming = false

local aimCF = CFrame.new()
local bobOffset = CFrame.new()

function loadSlot(Item)

	local newViewmodel = viewmodelFinder.GetViewmodel(Item)
	local newModule = moduleFinder.GetModule(Item)

	for _, v in pairs(camera:GetChildren()) do
		if v:IsA("Model") and v.Name ~= Item then
			v:Destroy()
		end
	end

	if newViewmodel and newModule and character then
		playerWeaponSystem.weaponSystem.viewmodel = newViewmodel
		playerWeaponSystem.weaponSystem.module = newModule

		playerWeaponSystem.weaponSystem.viewmodel.Parent = camera
	end
end

RunService.RenderStepped:Connect(function(dt)
	local rot = camera.CFrame:ToObjectSpace(weaponSystem.module.lastCameraCF)
	local X,Y,Z = rot:ToOrientation() 
	weaponSystem.module.swayCF = weaponSystem.module.swayCF:Lerp(CFrame.Angles(math.sin(X) * weaponSystem.module.currentSwayAMT, math.sin(Y) * weaponSystem.module.currentSwayAMT, math.sin(Z) * weaponSystem.module.currentSwayAMT), 1-0.001^dt)
	weaponSystem.module.lastCameraCF = camera.CFrame
	if humanoid then
		if weaponSystem.viewmodel ~= nil and weaponSystem.module ~= nil then
			if humanoid.MoveDirection.Magnitude > 0 then
				if humanoid.WalkSpeed == 16 then
					bobOffset = bobOffset:Lerp(CFrame.new(math.cos(tick() * 8) * .02, -humanoid.CameraOffset.Y/7, -humanoid.CameraOffset.Z/3) * CFrame.Angles(0, math.cos(tick() * -0) * -.0, math.sin(tick() * -4) * .01), 1-0.001^dt)
				elseif humanoid.WalkSpeed == 22 then
					bobOffset = bobOffset:Lerp(CFrame.new(math.cos(tick() * 10) * .1, -humanoid.CameraOffset.Y/3, -humanoid.CameraOffset.Z/3) * CFrame.Angles(0, math.cos(tick() * -8) * -.1, math.sin(tick() * -8) * .1) * weaponSystem.module.sprintCF, 1-0.001^dt)
				end
			else
				bobOffset = bobOffset:Lerp(CFrame.new(0, -humanoid.CameraOffset.Y/3, 0), 1-0.001^dt)
			end
		end

		for _, v in pairs(camera:GetChildren()) do
			if v:IsA("Model") then
				v:SetPrimaryPartCFrame(camera.CFrame * weaponSystem.module.swayCF * aimCF * bobOffset)
			end
		end
	end

	if isAiming and weaponSystem.viewmodel ~= nil and weaponSystem.module.canAim then
		local offset = weaponSystem.viewmodel.AimPart.CFrame:ToObjectSpace(weaponSystem.viewmodel.PrimaryPart.CFrame)
		aimCF = aimCF:Lerp(offset, 1 - weaponSystem.module.aimSmooth ^ dt)
	else
		local offset = CFrame.new()
		aimCF = aimCF:Lerp(offset, 1 - weaponSystem.module.aimSmooth ^ dt)
	end
end)

UIS.InputBegan:Connect(function(input)
	if canChange then
		if input.KeyCode == Enum.KeyCode.One then
			if weaponSystem.currentSlot ~= 1 and not isReloading then
				if weaponSystem.inventory[1] ~= "Nil" then
					loadSlot(weaponSystem.inventory[1])
					isShooting, isReloading = false, false
					weaponSystem.currentSlot = 1
					isEquipedWeapon = true
				end
			end
		end

		if input.KeyCode == Enum.KeyCode.Two then
			if weaponSystem.currentSlot ~= 2 then
				if weaponSystem.inventory[2] ~= "Nil" then
					loadSlot(weaponSystem.inventory[2])
					isShooting, isReloading = false, false
					weaponSystem.currentSlot = 2
					isEquipedWeapon = true
				end
			end
		end

		if input.KeyCode == Enum.KeyCode.Three then
			if weaponSystem.currentSlot ~= 3 then
				if weaponSystem.inventory[3] ~= "Nil" then
					loadSlot(weaponSystem.inventory[3])
					isShooting, isReloading = false, false
					weaponSystem.currentSlot = 3
					isEquipedWeapon = true
				end
			end
		end

		if input.KeyCode == Enum.KeyCode.Four then
			if weaponSystem.currentSlot ~= 4 then
				if weaponSystem.inventory[4] ~= "Nil" then
					loadSlot(weaponSystem.inventory[4])
					isShooting, isReloading = false, false
					weaponSystem.currentSlot = 4
					isEquipedWeapon = true
				end
			end
		end

		if input.KeyCode == Enum.KeyCode.Five then
			if weaponSystem.currentSlot ~= 5 then
				if weaponSystem.inventory[5] ~= "Nil" then
					loadSlot(weaponSystem.inventory[5])
					isShooting, isReloading = false, false
					weaponSystem.currentSlot = 5
					isEquipedWeapon = true
				end
			end
		end

		if input.KeyCode == Enum.KeyCode.Six then
			if weaponSystem.currentSlot ~= 6 then
				if weaponSystem.inventory[6] ~= "Nil" then
					loadSlot(weaponSystem.inventory[6])
					isShooting, isReloading = false, false
					weaponSystem.currentSlot = 6
					isEquipedWeapon = true
				end
			end
		end

		if input.KeyCode == Enum.KeyCode.Seven then
			if weaponSystem.currentSlot ~= 7 then
				if weaponSystem.inventory[7] ~= "Nil" then
					loadSlot(weaponSystem.inventory[7])
					isShooting, isReloading = false, false
					weaponSystem.currentSlot = 7
					isEquipedWeapon = true
				end
			end
		end

		if input.KeyCode == Enum.KeyCode.Eight then
			if weaponSystem.currentSlot ~= 8 then
				if weaponSystem.inventory[8] ~= "Nil" then
					loadSlot(weaponSystem.inventory[8])
					isShooting, isReloading = false, false
					weaponSystem.currentSlot = 8
					isEquipedWeapon = true
				end
			end
		end
	end

	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		isAiming = true
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		isAiming = false
	end
end)

loadSlot(playerWeaponSystem.weaponSystem.inventory[1])



-- playerWeaponSystem.weaponSystem.animations.FirstPerson[1] = Instance.new("Animation")
-- playerWeaponSystem.weaponSystem.animations.FirstPerson[1].Parent = playerWeaponSystem.weaponSystem.viewmodel
-- playerWeaponSystem.weaponSystem.animations.FirstPerson[1].Name = "Fire"
-- playerWeaponSystem.weaponSystem.animations.FirstPerson[1].AnimationId = playerWeaponSystem.weaponSystem.module.fireAnim
-- playerWeaponSystem.weaponSystem.animations.FirstPerson[1] = playerWeaponSystem.weaponSystem.viewmodel.AnimationController.Animator:LoadAnimation(playerWeaponSystem.weaponSystem.animations.FirstPerson[1])

-- playerWeaponSystem.weaponSystem.animations.FirstPerson[2] = Instance.new("Animation")
-- playerWeaponSystem.weaponSystem.animations.FirstPerson[2].Parent = playerWeaponSystem.weaponSystem.viewmodel
-- playerWeaponSystem.weaponSystem.animations.FirstPerson[2].Name = "Equip"
-- playerWeaponSystem.weaponSystem.animations.FirstPerson[2].AnimationId = playerWeaponSystem.weaponSystem.module.equipAnim
-- playerWeaponSystem.weaponSystem.animations.FirstPerson[2] = playerWeaponSystem.weaponSystem.viewmodel.AnimationController.Animator:LoadAnimation(playerWeaponSystem.weaponSystem.animations.FirstPerson[2])

-- playerWeaponSystem.weaponSystem.animations.FirstPerson[3] = Instance.new("Animation")
-- playerWeaponSystem.weaponSystem.animations.FirstPerson[3].Parent = playerWeaponSystem.weaponSystem.viewmodel
-- playerWeaponSystem.weaponSystem.animations.FirstPerson[3].Name = "Deequip"
-- playerWeaponSystem.weaponSystem.animations.FirstPerson[3].AnimationId = playerWeaponSystem.weaponSystem.module.deequipAnim
-- playerWeaponSystem.weaponSystem.animations.FirstPerson[3] = playerWeaponSystem.weaponSystem.viewmodel.AnimationController.Animator:LoadAnimation(playerWeaponSystem.weaponSystem.animations.FirstPerson[3])

-- playerWeaponSystem.weaponSystem.animations.FirstPerson[4] = Instance.new("Animation")
-- playerWeaponSystem.weaponSystem.animations.FirstPerson[4].Parent = playerWeaponSystem.weaponSystem.viewmodel
-- playerWeaponSystem.weaponSystem.animations.FirstPerson[4].Name = "EmptyFire"
-- playerWeaponSystem.weaponSystem.animations.FirstPerson[4].AnimationId = playerWeaponSystem.weaponSystem.module.emptyFireAnim
-- playerWeaponSystem.weaponSystem.animations.FirstPerson[4] = playerWeaponSystem.weaponSystem.viewmodel.AnimationController.Animator:LoadAnimation(playerWeaponSystem.weaponSystem.animations.FirstPerson[4])

-- playerWeaponSystem.weaponSystem.animations.FirstPerson[5] = Instance.new("Animation")
-- playerWeaponSystem.weaponSystem.animations.FirstPerson[5].Parent = playerWeaponSystem.weaponSystem.viewmodel
-- playerWeaponSystem.weaponSystem.animations.FirstPerson[5].Name = "Reload"
-- playerWeaponSystem.weaponSystem.animations.FirstPerson[5].AnimationId = playerWeaponSystem.weaponSystem.module.reloadAnim
-- playerWeaponSystem.weaponSystem.animations.FirstPerson[5] = playerWeaponSystem.weaponSystem.viewmodel.AnimationController.Animator:LoadAnimation(playerWeaponSystem.weaponSystem.animations.FirstPerson[5])

-- playerWeaponSystem.weaponSystem.animations.FirstPerson[6] = Instance.new("Animation")
-- playerWeaponSystem.weaponSystem.animations.FirstPerson[6].Parent = playerWeaponSystem.weaponSystem.viewmodel
-- playerWeaponSystem.weaponSystem.animations.FirstPerson[6].Name = "EmptyReload"
-- playerWeaponSystem.weaponSystem.animations.FirstPerson[6].AnimationId = playerWeaponSystem.weaponSystem.module.emptyReloadAnim
-- playerWeaponSystem.weaponSystem.animations.FirstPerson[6] = playerWeaponSystem.weaponSystem.viewmodel.AnimationController.Animator:LoadAnimation(playerWeaponSystem.weaponSystem.animations.FirstPerson[6])

-- playerWeaponSystem.weaponSystem.animations.FirstPerson[7] = Instance.new("Animation")
-- playerWeaponSystem.weaponSystem.animations.FirstPerson[7].Parent = playerWeaponSystem.weaponSystem.viewmodel
-- playerWeaponSystem.weaponSystem.animations.FirstPerson[7].Name = "Inspect"
-- playerWeaponSystem.weaponSystem.animations.FirstPerson[7].AnimationId = playerWeaponSystem.weaponSystem.module.inspectAnim
-- playerWeaponSystem.weaponSystem.animations.FirstPerson[7] = playerWeaponSystem.weaponSystem.viewmodel.AnimationController.Animator:LoadAnimation(playerWeaponSystem.weaponSystem.animations.FirstPerson[7])

-- playerWeaponSystem.weaponSystem.animations.FirstPerson[8] = Instance.new("Animation")
-- playerWeaponSystem.weaponSystem.animations.FirstPerson[8].Parent = playerWeaponSystem.weaponSystem.viewmodel
-- playerWeaponSystem.weaponSystem.animations.FirstPerson[8].Name = "Idle"
-- playerWeaponSystem.weaponSystem.animations.FirstPerson[8].AnimationId = playerWeaponSystem.weaponSystem.module.idleAnim
-- playerWeaponSystem.weaponSystem.animations.FirstPerson[8] = playerWeaponSystem.weaponSystem.viewmodel.AnimationController.Animator:LoadAnimation(playerWeaponSystem.weaponSystem.animations.FirstPerson[8])

-- playerWeaponSystem.weaponSystem.animations.ThirdPerson[7] = Instance.new("Animation")
-- playerWeaponSystem.weaponSystem.animations.ThirdPerson[7].Parent = player.Character
-- playerWeaponSystem.weaponSystem.animations.ThirdPerson[7].Name = "IdleAnim"
-- playerWeaponSystem.weaponSystem.animations.ThirdPerson[7].AnimationId = playerWeaponSystem.weaponSystem.module.tpIdleAnim
-- playerWeaponSystem.weaponSystem.animations.ThirdPerson[7] = character.Humanoid.Animator:LoadAnimation(playerWeaponSystem.weaponSystem.animations.ThirdPerson[7])
-- playerWeaponSystem.weaponSystem.animations.ThirdPerson[7]:Play()

-- playerWeaponSystem.weaponSystem.animations.ThirdPerson[1] = Instance.new("Animation")
-- playerWeaponSystem.weaponSystem.animations.ThirdPerson[1].Parent = player.Character
-- playerWeaponSystem.weaponSystem.animations.ThirdPerson[1].Name = "ShootAnim"
-- playerWeaponSystem.weaponSystem.animations.ThirdPerson[1].AnimationId = playerWeaponSystem.weaponSystem.module.tpShootAnim
-- playerWeaponSystem.weaponSystem.animations.ThirdPerson[1] = character.Humanoid.Animator:LoadAnimation(playerWeaponSystem.weaponSystem.animations.ThirdPerson[1])

-- playerWeaponSystem.weaponSystem.animations.ThirdPerson[4] = Instance.new("Animation")
-- playerWeaponSystem.weaponSystem.animations.ThirdPerson[4].Parent = player.Character
-- playerWeaponSystem.weaponSystem.animations.ThirdPerson[4].Name = "ReloadAnim"
-- playerWeaponSystem.weaponSystem.animations.ThirdPerson[4].AnimationId = playerWeaponSystem.weaponSystem.module.tpReloadAnim
-- playerWeaponSystem.weaponSystem.animations.ThirdPerson[4] = character.Humanoid.Animator:LoadAnimation(playerWeaponSystem.weaponSystem.animations.ThirdPerson[4])

-- playerWeaponSystem.weaponSystem.animations.ThirdPerson[5] = Instance.new("Animation")
-- playerWeaponSystem.weaponSystem.animations.ThirdPerson[5].Parent = player.Character
-- playerWeaponSystem.weaponSystem.animations.ThirdPerson[5].Name = "EmptyReloadAnim"
-- playerWeaponSystem.weaponSystem.animations.ThirdPerson[5].AnimationId = playerWeaponSystem.weaponSystem.module.tpEmptyReloadAnim
-- playerWeaponSystem.weaponSystem.animations.ThirdPerson[5] = character.Humanoid.Animator:LoadAnimation(playerWeaponSystem.weaponSystem.animations.ThirdPerson[5])

-- playerWeaponSystem.weaponSystem.animations.ThirdPerson[6] = Instance.new("Animation")
-- playerWeaponSystem.weaponSystem.animations.ThirdPerson[6].Parent = player.Character
-- playerWeaponSystem.weaponSystem.animations.ThirdPerson[6].Name = "InspectAnim"
-- playerWeaponSystem.weaponSystem.animations.ThirdPerson[6].AnimationId = playerWeaponSystem.weaponSystem.module.tpInspectAnim
-- playerWeaponSystem.weaponSystem.animations.ThirdPerson[6] = character.Humanoid.Animator:LoadAnimation(playerWeaponSystem.weaponSystem.animations.ThirdPerson[6])

-- playerWeaponSystem.weaponSystem.animations.ThirdPerson[2] = Instance.new("Animation")
-- playerWeaponSystem.weaponSystem.animations.ThirdPerson[2].Parent = player.Character
-- playerWeaponSystem.weaponSystem.animations.ThirdPerson[2].Name = "EquipAnim"
-- playerWeaponSystem.weaponSystem.animations.ThirdPerson[2].AnimationId = playerWeaponSystem.weaponSystem.module.tpEquipAnim
-- playerWeaponSystem.weaponSystem.animations.ThirdPerson[2] = character.Humanoid.Animator:LoadAnimation(playerWeaponSystem.weaponSystem.animations.ThirdPerson[2])

-- playerWeaponSystem.weaponSystem.animations.ThirdPerson[3] = Instance.new("Animation")
-- playerWeaponSystem.weaponSystem.animations.ThirdPerson[3].Parent = player.Character
-- playerWeaponSystem.weaponSystem.animations.ThirdPerson[3].Name = "DeequipAnim"
-- playerWeaponSystem.weaponSystem.animations.ThirdPerson[3].AnimationId = playerWeaponSystem.weaponSystem.module.tpDeequipAnim
-- playerWeaponSystem.weaponSystem.animations.ThirdPerson[3] = character.Humanoid.Animator:LoadAnimation(playerWeaponSystem.weaponSystem.animations.ThirdPerson[3])