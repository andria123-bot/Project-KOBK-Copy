local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait() or script.Parent
local humanoid = character:WaitForChild("Humanoid")

local camera = game.Workspace.CurrentCamera
local mouse = player:GetMouse()

local ViewmodelFinder = require(script.Parent.LoadViewmodel)
local ModuleFinder = require(script.Parent.LoadModule)
local PlayerWeaponSystem = require(script.Parent.PlayerWeaponSystemData)
local WeaponCategories = require(script.Parent.WeaponCategories)
local ViewmoduleRotation = require(script.Parent.ViewmodelRotation)

local weaponSystem = PlayerWeaponSystem.weaponSystem -- module

local canShoot = true
local canAim = true
local canReload = true
local canInspect = true
local canSprint = true
local canChange = true

local isAiming = false
local isReloading = false
local isSprinting = false
local isInspecting = false
local isEquipedWeapon = false
local isShooting = false

local fireSound

local bobOffset = CFrame.new()

local AimHelper = require(script.Parent.Aim)
local ViewmodelRotation = require(script.Parent.ViewmodelRotation)
local aimHelper = AimHelper

local debounce = false

local defaultFOV = 70
local currentAimPart = 1

function loadSlot(Item)
	if isReloading == false then
		local newViewmodel = ViewmodelFinder.GetViewmodel(Item)
		local newModule = ModuleFinder.GetModule(Item)

		for _, v in pairs(camera:GetChildren()) do
			if v:IsA("Model") and v.Name ~= Item then
				v:Destroy()
			end
		end

		if newViewmodel and newModule and character then
			weaponSystem.viewmodel = newViewmodel
			weaponSystem.module = newModule

			weaponSystem.animations.FirstPerson[1] = Instance.new("Animation")
			weaponSystem.animations.FirstPerson[1].Parent = weaponSystem.viewmodel
			weaponSystem.animations.FirstPerson[1].Name = "Fire"
			weaponSystem.animations.FirstPerson[1].AnimationId = weaponSystem.module.fireAnim
			weaponSystem.animations.FirstPerson[1] = weaponSystem.viewmodel.AnimationController.Animator:LoadAnimation(weaponSystem.animations.FirstPerson[1])

			weaponSystem.animations.FirstPerson[2] = Instance.new("Animation")
			weaponSystem.animations.FirstPerson[2].Parent = weaponSystem.viewmodel
			weaponSystem.animations.FirstPerson[2].Name = "Equip"
			weaponSystem.animations.FirstPerson[2].AnimationId = weaponSystem.module.equipAnim
			weaponSystem.animations.FirstPerson[2] = weaponSystem.viewmodel.AnimationController.Animator:LoadAnimation(weaponSystem.animations.FirstPerson[2])

			game.ReplicatedStorage.Shared.Remotes.LoadSlot:FireServer(weaponSystem.module.sounds[2], .1)

			canShoot, canAim, canInspect, canReload = true, true, true, true
			aimHelper:Init(weaponSystem.module, weaponSystem.viewmodel)
			ViewmodelRotation:Init(weaponSystem.module, weaponSystem.viewmodel)
		end
	end
end

function Shoot()
	canSprint = false

	if canShoot then
		if character and weaponSystem.module and weaponSystem.viewmodel and weaponSystem.module.ammo > 0 then
			if weaponSystem.module.fireMode == "Semi" then
				weaponSystem.animations.FirstPerson[1]:Play()
				weaponSystem.module.ammo -= 1

				ReplicatedStorage.Shared.Remotes.Shoot:FireServer()

				debounce = true

				wait(weaponSystem.module.debounce)

				debounce = false
			end

			if weaponSystem.module.fireMode == "Full Auto" then
				isShooting = true
			end
		end
	end

end

function Reload()
	if weaponSystem.viewmodel and weaponSystem.module and weaponSystem.module.isMelee == false and weaponSystem.module.isGrenade == false and isReloading == false and canReload and weaponSystem.module.ammo < weaponSystem.module.maxAmmo and isAiming == false then
		camera.FieldOfView = camera.FieldOfView + (defaultFOV - camera.FieldOfView) * 0.1
		canShoot = false
		canInspect = false
		isReloading = true
		-- canChange = true

		-- weaponSystem.animations.FirstPerson[1]:Stop()
		-- weaponSystem.animations.FirstPerson[2]:Stop()
		-- weaponSystem.animations.FirstPerson[3]:Stop()
		-- weaponSystem.animations.FirstPerson[7]:Stop()
		-- weaponSystem.animations.ThirdPerson[6]:Stop()
		-- weaponSystem.animations.FirstPerson[8]:Stop()

		-- if weaponSystem.module.ammo > 0 then
		-- 	-- weaponSystem.animations.FirstPerson[5]:Play()
		-- 	-- weaponSystem.animations.ThirdPerson[4]:Play()
		-- 	-- ReplicatedStorage.Shared.Remotes:WaitForChild("itemFoley"):FireServer(script.Parent:WaitForChild("UpperTorso"):WaitForChild("Reload"))
		-- else
		-- 	-- weaponSystem.animations.FirstPerson[6]:Play()
		-- 	-- weaponSystem.animations.ThirdPerson[5]:Play()
		-- 	-- ReplicatedStorage.Shared.Remotes:WaitForChild("itemFoley"):FireServer(script.Parent:WaitForChild("UpperTorso"):WaitForChild("EmptyReload"))
		-- end

		camera.FieldOfView = camera.FieldOfView + (defaultFOV - camera.FieldOfView) * 0.1
		wait(weaponSystem.module.reloadTime)

		canShoot = true
		canInspect = true
		isReloading = false
		weaponSystem.module.ammo = weaponSystem.module.maxAmmo
	end
end

local oldCamCF = CFrame.new()

function updateCameraShake()
	local newCamCF = weaponSystem.viewmodel.FakeCamera.CFrame:ToObjectSpace(weaponSystem.viewmodel.PrimaryPart.CFrame)
	camera.CFrame = camera.CFrame * newCamCF:ToObjectSpace(oldCamCF)
	oldCamCF = newCamCF
end

local hud = player.PlayerGui:WaitForChild("HUD")

RunService.RenderStepped:Connect(function(dt)
	if humanoid and weaponSystem.module and weaponSystem.viewmodel then

		if hud then
			if weaponSystem.viewmodel and weaponSystem.module and isEquipedWeapon then
				if weaponSystem.viewmodel and weaponSystem.module and weaponSystem.module.isMelee or weaponSystem.module.isGrenade then
					hud.Enabled = false
				else
					hud.Enabled = true
					hud.MainParent.GunName.Text = weaponSystem.inventory[weaponSystem.currentSlot]
					hud.MainParent.Ammo.Text = weaponSystem.module.ammo
					hud.MainParent.MaxAmmo.Text = weaponSystem.module.maxAmmo
					hud.MainParent.GunIcon.Image = weaponSystem.module.imageIconId
					hud.MainParent.GunIcon.ImageColor3 =  Color3.new(0, 0, 0)
					hud.MainParent.FireMode.Text = weaponSystem.module.fireMode
					hud.MainParent.AmmoType.Text = weaponSystem.module.ammoType
				end
			else
				hud.Enabled = false
			end
		end

		local rot = camera.CFrame:ToObjectSpace(weaponSystem.module.lastCameraCF)
		local X,Y,_ = rot:ToOrientation() 
		weaponSystem.module.swayCF = weaponSystem.module.swayCF:Lerp(CFrame.Angles(math.sin(X) * weaponSystem.module.currentSwayAMT, math.sin(Y) * weaponSystem.module.currentSwayAMT, 0), 1-0.001^dt)
		weaponSystem.module.lastCameraCF = camera.CFrame

		if weaponSystem.viewmodel ~= nil and weaponSystem.module ~= nil then
			if humanoid.MoveDirection.Magnitude > 0 then
				if humanoid.WalkSpeed == 16 then
					bobOffset = bobOffset:Lerp(CFrame.new(math.cos(tick() * 8) * .02, -humanoid.CameraOffset.Y/7, -humanoid.CameraOffset.Z/3) * CFrame.Angles(0, math.cos(tick() * -0) * -.0, math.sin(tick() * -4) * .01), 1-0.001^dt)
					isSprinting = false
				elseif humanoid.WalkSpeed == 22 then
					bobOffset = bobOffset:Lerp(CFrame.new(math.cos(tick() * 10) * .1, -humanoid.CameraOffset.Y/3, -humanoid.CameraOffset.Z/3) * CFrame.Angles(0, math.cos(tick() * -8) * -.1, math.sin(tick() * -8) * .1) * weaponSystem.module.sprintCF, 1-0.001^dt)
					isSprinting = true
				end
			else
				bobOffset = bobOffset:Lerp(CFrame.new(0, -humanoid.CameraOffset.Y/3, 0), 1-0.001^dt)
				isSprinting = false
			end
		end

		local moveDir = humanoid.MoveDirection
		local rotOffset = CFrame.Angles(0, 0, ViewmodelRotation:getRotation(dt, moveDir, isAiming))


		for _, v in pairs(camera:GetChildren()) do -- apply things to viewmodel
			if v:IsA("Model") then
				v:SetPrimaryPartCFrame(camera.CFrame * weaponSystem.module.swayCF * weaponSystem.module.aimCF * bobOffset * rotOffset)
				updateCameraShake()
			end
		end

		aimHelper:Aim(dt, {
			isAiming = isAiming,
			isSprinting = isSprinting,
			isReloading = isReloading,
			isInspecting = isInspecting,
			currentAimPart = currentAimPart
		})
	end
end)

UIS.InputBegan:Connect(function(input, gpe)
	if gpe then return end

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
			if weaponSystem.currentSlot ~= 2 and not isReloading then
				if weaponSystem.inventory[2] ~= "Nil" then
					loadSlot(weaponSystem.inventory[2])
					isShooting, isReloading = false, false
					weaponSystem.currentSlot = 2
					isEquipedWeapon = true
				end
			end
		end

		if input.KeyCode == Enum.KeyCode.Three then
			if weaponSystem.currentSlot ~= 3 and not isReloading then
				if weaponSystem.inventory[3] ~= "Nil" then
					loadSlot(weaponSystem.inventory[3])
					isShooting, isReloading = false, false
					weaponSystem.currentSlot = 3
					isEquipedWeapon = true
				end
			end
		end

		if input.KeyCode == Enum.KeyCode.Four then
			if weaponSystem.currentSlot ~= 4 and not isReloading then
				if weaponSystem.inventory[4] ~= "Nil" then
					loadSlot(weaponSystem.inventory[4])
					isShooting, isReloading = false, false
					weaponSystem.currentSlot = 4
					isEquipedWeapon = true
				end
			end
		end

		if input.KeyCode == Enum.KeyCode.Five then
			if weaponSystem.currentSlot ~= 5 and not isReloading then
				if weaponSystem.inventory[5] ~= "Nil" then
					loadSlot(weaponSystem.inventory[5])
					isShooting, isReloading = false, false
					weaponSystem.currentSlot = 5
					isEquipedWeapon = true
				end
			end
		end

		if input.KeyCode == Enum.KeyCode.Six then
			if weaponSystem.currentSlot ~= 6 and not isReloading then
				if weaponSystem.inventory[6] ~= "Nil" then
					loadSlot(weaponSystem.inventory[6])
					isShooting, isReloading = false, false
					weaponSystem.currentSlot = 6
					isEquipedWeapon = true
				end
			end
		end

		if input.KeyCode == Enum.KeyCode.Seven and not isReloading then
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
			if weaponSystem.currentSlot ~= 8 and not isReloading then
				if weaponSystem.inventory[8] ~= "Nil" then
					loadSlot(weaponSystem.inventory[8])
					isShooting, isReloading = false, false
					weaponSystem.currentSlot = 8
					isEquipedWeapon = true
				end
			end
		end
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		if character and weaponSystem.viewmodel and weaponSystem.module and weaponSystem.module.ammo ~= 0 and not debounce and not isReloading and canShoot then
			Shoot()
		end
	end

	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		isAiming = true
	end

	if input.KeyCode == Enum.KeyCode.R then
		Reload()
	end

	if input.KeyCode == Enum.KeyCode.V then
		AimHelper:switchAimpart()
	end
end)

UIS.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		isAiming = false
	end
end)

ReplicatedStorage.Shared.Remotes:WaitForChild("PlayerDied").OnClientEvent:Connect(function()
	for i, v in pairs(camera:GetDescendants()) do
		if v:IsA("Model") then
			v:Destroy()
			canChange = false
		end
	end
	
	for i, v in pairs(game.ReplicatedStorage.Shared.Modules:GetDescendants()) do
		if v:IsA("ModuleScript") and v.Name ~= "FastCastRedux" and v.Name ~= "ActiveSignal" and v.Name ~= "Signal" and v.Name ~= "Table" and v.Name ~= "TypeDefinitions"  and v.Name ~= "TypeMarshaller" and v.Name ~= "Misc" then
			require(v).ammo = require(v).maxAmmo
		end
	end

	if weaponSystem.viewmodel and weaponSystem.module then
		weaponSystem.module = nil
		weaponSystem.viewmodel:Destroy()
		canShoot = false
		canInspect = false
		canReload = false
	end
end)

mouse.Button1Up:Connect(function()
	isShooting = false
	canSprint = true
end)

while wait() do
	if isShooting and weaponSystem.module and weaponSystem.module.ammo > 0 and isReloading ~= true and canShoot == true then
		print("Shooting")
		weaponSystem.animations.FirstPerson[1]:Play()
		weaponSystem.module.ammo -= 1

		ReplicatedStorage.Shared.Remotes.Shoot:FireServer()

		-- if weaponSystem.module.ammo == 0 then
		-- 	task.wait(.5)
		-- 	Reload()
		-- 	repeat task.wait() until weaponSystem.animations.FirstPerson[6].IsPlaying == false
		-- 	debounce = false

		-- 	canSprint = true
		-- else
		-- 	debounce = true
		-- 	wait(weaponSystem.module.debounce)
		-- 	debounce = false
		-- end

		wait(weaponSystem.module.fireRate)
	end
end

-- weaponSystem.animations.FirstPerson[1] = Instance.new("Animation")
-- weaponSystem.animations.FirstPerson[1].Parent = weaponSystem.viewmodel
-- weaponSystem.animations.FirstPerson[1].Name = "Fire"
-- weaponSystem.animations.FirstPerson[1].AnimationId = weaponSystem.module.fireAnim
-- weaponSystem.animations.FirstPerson[1] = weaponSystem.viewmodel.AnimationController.Animator:LoadAnimation(weaponSystem.animations.FirstPerson[1])

-- weaponSystem.animations.FirstPerson[2] = Instance.new("Animation")
-- weaponSystem.animations.FirstPerson[2].Parent = weaponSystem.viewmodel
-- weaponSystem.animations.FirstPerson[2].Name = "Equip"
-- weaponSystem.animations.FirstPerson[2].AnimationId = weaponSystem.module.equipAnim
-- weaponSystem.animations.FirstPerson[2] = weaponSystem.viewmodel.AnimationController.Animator:LoadAnimation(weaponSystem.animations.FirstPerson[2])

-- weaponSystem.animations.FirstPerson[3] = Instance.new("Animation")
-- weaponSystem.animations.FirstPerson[3].Parent = weaponSystem.viewmodel
-- weaponSystem.animations.FirstPerson[3].Name = "Deequip"
-- weaponSystem.animations.FirstPerson[3].AnimationId = weaponSystem.module.deequipAnim
-- weaponSystem.animations.FirstPerson[3] = weaponSystem.viewmodel.AnimationController.Animator:LoadAnimation(weaponSystem.animations.FirstPerson[3])

-- weaponSystem.animations.FirstPerson[4] = Instance.new("Animation")
-- weaponSystem.animations.FirstPerson[4].Parent = weaponSystem.viewmodel
-- weaponSystem.animations.FirstPerson[4].Name = "EmptyFire"
-- weaponSystem.animations.FirstPerson[4].AnimationId = weaponSystem.module.emptyFireAnim
-- weaponSystem.animations.FirstPerson[4] = weaponSystem.viewmodel.AnimationController.Animator:LoadAnimation(weaponSystem.animations.FirstPerson[4])

-- weaponSystem.animations.FirstPerson[5] = Instance.new("Animation")
-- weaponSystem.animations.FirstPerson[5].Parent = weaponSystem.viewmodel
-- weaponSystem.animations.FirstPerson[5].Name = "Reload"
-- weaponSystem.animations.FirstPerson[5].AnimationId = weaponSystem.module.reloadAnim
-- weaponSystem.animations.FirstPerson[5] = weaponSystem.viewmodel.AnimationController.Animator:LoadAnimation(weaponSystem.animations.FirstPerson[5])

-- weaponSystem.animations.FirstPerson[6] = Instance.new("Animation")
-- weaponSystem.animations.FirstPerson[6].Name = "EmptyReload"
-- weaponSystem.animations.FirstPerson[6].AnimationId = weaponSystem.module.emptyReloadAnim
-- weaponSystem.animations.FirstPerson[6] = weaponSystem.viewmodel.AnimationController.Animator:LoadAnimation(weaponSystem.animations.FirstPerson[6])

-- weaponSystem.animations.FirstPerson[7] = Instance.new("Animation")
-- weaponSystem.animations.FirstPerson[7].Parent = weaponSystem.viewmodel
-- weaponSystem.animations.FirstPerson[7].Name = "Inspect"
-- weaponSystem.animations.FirstPerson[7].AnimationId = weaponSystem.module.inspectAnim
-- weaponSystem.animations.FirstPerson[7] = weaponSystem.viewmodel.AnimationController.Animator:LoadAnimation(weaponSystem.animations.FirstPerson[7])

-- weaponSystem.animations.FirstPerson[8] = Instance.new("Animation")
-- weaponSystem.animations.FirstPerson[8].Parent = weaponSystem.viewmodel
-- weaponSystem.animations.FirstPerson[8].Name = "Idle"
-- weaponSystem.animations.FirstPerson[8].AnimationId = weaponSystem.module.idleAnim
-- weaponSystem.animations.FirstPerson[8] = weaponSystem.viewmodel.AnimationController.Animator:LoadAnimation(weaponSystem.animations.FirstPerson[8])

-- weaponSystem.animations.ThirdPerson[7] = Instance.new("Animation")
-- weaponSystem.animations.ThirdPerson[7].Parent = player.Character
-- weaponSystem.animations.ThirdPerson[7].Name = "IdleAnim"
-- weaponSystem.animations.ThirdPerson[7].AnimationId = weaponSystem.module.tpIdleAnim
-- weaponSystem.animations.ThirdPerson[7]:Play()

-- weaponSystem.animations.ThirdPerson[1] = Instance.new("Animation")
-- weaponSystem.animations.ThirdPerson[1].Parent = player.Character
-- weaponSystem.animations.ThirdPerson[1].Name = "ShootAnim"
-- weaponSystem.animations.ThirdPerson[1].AnimationId = weaponSystem.module.tpShootAnim
-- weaponSystem.animations.ThirdPerson[1] = character.Humanoid.Animator:LoadAnimation(weaponSystem.animations.ThirdPerson[1])

-- weaponSystem.animations.ThirdPerson[4] = Instance.new("Animation")
-- weaponSystem.animations.ThirdPerson[4].Parent = player.Character
-- weaponSystem.animations.ThirdPerson[4].Name = "ReloadAnim"
-- weaponSystem.animations.ThirdPerson[4].AnimationId = weaponSystem.module.tpReloadAnim
-- weaponSystem.animations.ThirdPerson[4] = character.Humanoid.Animator:LoadAnimation(weaponSystem.animations.ThirdPerson[4])

-- weaponSystem.animations.ThirdPerson[5] = Instance.new("Animation")
-- weaponSystem.animations.ThirdPerson[5].Parent = player.Character
-- weaponSystem.animations.ThirdPerson[5].Name = "EmptyReloadAnim"
-- weaponSystem.animations.ThirdPerson[5].AnimationId = weaponSystem.module.tpEmptyReloadAnim
-- weaponSystem.animations.ThirdPerson[5] = character.Humanoid.Animator:LoadAnimation(weaponSystem.animations.ThirdPerson[5])

-- weaponSystem.animations.ThirdPerson[6] = Instance.new("Animation")
-- weaponSystem.animations.ThirdPerson[6].Parent = player.Character
-- weaponSystem.animations.ThirdPerson[6].Name = "InspectAnim"
-- weaponSystem.animations.ThirdPerson[6] = character.Humanoid.Animator:LoadAnimation(weaponSystem.animations.ThirdPerson[6])

-- weaponSystem.animations.ThirdPerson[2] = Instance.new("Animation")
-- weaponSystem.animations.ThirdPerson[2].Parent = player.Character
-- weaponSystem.animations.ThirdPerson[2].Name = "EquipAnim"
-- weaponSystem.animations.ThirdPerson[2].AnimationId = weaponSystem.module.tpEquipAnim
-- weaponSystem.animations.ThirdPerson[2] = character.Humanoid.Animator:LoadAnimation(weaponSystem.animations.ThirdPerson[2])

-- weaponSystem.animations.ThirdPerson[3] = Instance.new("Animation")
-- weaponSystem.animations.ThirdPerson[3].Parent = player.Character
-- weaponSystem.animations.ThirdPerson[3].Name = "DeequipAnim"
-- weaponSystem.animations.ThirdPerson[3].AnimationId = weaponSystem.module.tpDeequipAnim
-- weaponSystem.animations.ThirdPerson[3] = character.Humanoid.Animator:LoadAnimation(weaponSystem.animations.ThirdPerson[3])