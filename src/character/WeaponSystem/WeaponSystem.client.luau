local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait() or script.Parent.Parent
local humanoid = character:WaitForChild("Humanoid")

local camera = game.Workspace.CurrentCamera
local mouse = player:GetMouse()

local RequestInventory = ReplicatedStorage.Shared.Remotes.InventoryEvents:WaitForChild("RequestInventory")
local SendInventory = ReplicatedStorage.Shared.Remotes.InventoryEvents:WaitForChild("SendInventory")
local RequestModule = ReplicatedStorage.Shared.Remotes.Requests:WaitForChild("RequestModule")
local RequestWeaponData = ReplicatedStorage.Shared.Remotes.Requests:WaitForChild("RequestWeaponData")
local RequestWeaponSystemData = ReplicatedStorage.Shared.Remotes.Requests:WaitForChild("RequestWeaponSystemData")
local UpdateWeaponStateRemote = ReplicatedStorage.Shared.Remotes:WaitForChild("UpdateWeaponState")
local RequestShoot = ReplicatedStorage.Shared.Remotes.Requests:WaitForChild("RequestShoot")
local LoadViewmodel = require(script.Parent.LoadViewmodel)
local ViewmodelRotation = require(script.Parent.ViewmodelRotation)

local SpringModule = require(ReplicatedStorage.Shared.Modules.Spring)

local recoilSpring = SpringModule.new(Vector3.new(0,0,0), 0.5, 50)
recoilSpring.Damping = 5

local weaponSystem = RequestWeaponSystemData:InvokeServer()
local weaponData

SendInventory.OnClientEvent:Connect(function(savedInventory)
    weaponSystem[1].inventory = weaponSystem[1].inventory or {}

    for i = 1, #savedInventory do
        weaponSystem[1].inventory[i] = savedInventory[i] or ""
    end

    print("Inventory synced:", weaponSystem[1].inventory)
end)

RequestInventory:FireServer()

local dof = game.Lighting.DepthOfField

local bobOffset = CFrame.new()

local AimHelper = require(script.Parent.Aim)
local aimHelper = AimHelper

local debounce = false

local isEquipedWeapon = false

function stopAllAnims()
	for _, v in pairs(weaponSystem[1].animations.FirstPerson) do
		if v ~= nil and v.IsPlaying then
			v:Stop()
		end
	end

	for _, v in pairs(weaponSystem[1].animations.ThirdPerson) do
		if v ~= nil and v.IsPlaying then
			v:Stop()
		end
	end
end

function loadSlot(Item)
	-- print(weaponSystem)
	-- weaponSystem[1].loadSlot = loadSlot
	if weaponSystem[1].state == weaponSystem[1].states[1] 
	or weaponSystem[1].state == weaponSystem[1].states[3] 
	or weaponSystem[1].state == weaponSystem[1].states[4] then
		-- weaponSystem:setState(weaponSystem[1].states[7])
		UpdateWeaponStateRemote:FireServer(weaponSystem[1].states[7])
		weaponSystem[1].IsAiming = false
		weaponSystem[1].IsInspecting = false
		weaponSystem[1].IsReloading = false
		weaponSystem[1].IsShooting = false

		if player.Character:FindFirstChild("IdleAnim") then 
			weaponSystem[1].animations.ThirdPerson[7]:Destroy()
			weaponSystem[1].animations.FirstPerson[3]:Play()
			player.Character.IdleAnim:Destroy()
		end

		for _, v in pairs(camera:GetChildren()) do
			if v:IsA("Model") then
				stopAllAnims()

				if weaponSystem[1].animations.FirstPerson[3] then
					weaponSystem[1].animations.FirstPerson[3]:Play()
					repeat task.wait() until weaponSystem[1].animations.FirstPerson[3].IsPlaying == false
				end

				v:Destroy()
			end
		end

		weaponSystem[1].viewmodel = LoadViewmodel.GetViewmodel(Item):Clone()
		weaponSystem[1].viewmodel.Parent = camera

		if weaponSystem[1].viewmodel then
			local animData = RequestWeaponData:InvokeServer(Item)
			print(animData)
			local animator = weaponSystem[1].viewmodel.AnimationController.Animator
			local characterAnimator = character.Humanoid.Animator

			ReplicatedStorage.Shared.Remotes.LoadSlot:FireServer(Item)
			weaponData = RequestWeaponData:InvokeServer(Item)

			local firstPersonAnims = {
				{index = 1, name = "Fire", id = animData.animations.fireAnim},
				{index = 2, name = "Equip", id = animData.animations.equipAnim},
				{index = 3, name = "Deequip", id = animData.animations.deequipAnim},
				{index = 4, name = "EmptyFire", id = animData.animations.emptyFireAnim},
				{index = 5, name = "Reload", id = animData.animations.reloadAnim},
				{index = 6, name = "EmptyReload", id = animData.animations.emptyReloadAnim},
				{index = 7, name = "Inspect", id = animData.animations.inspectAnim},
				{index = 8, name = "Idle", id = animData.animations.idleAnim}
			}

			local thirdPersonAnims = {
				{index = 1, name = "ShootAnim", id = animData.animations.tpShootAnim},
				{index = 2, name = "EquipAnim", id = animData.animations.tpEquipAnim},
				{index = 3, name = "DeequipAnim", id = animData.animations.tpDeequipAnim},
				{index = 4, name = "ReloadAnim", id = animData.animations.tpReloadAnim},
				{index = 5, name = "EmptyReloadAnim", id = animData.animations.tpEmptyReloadAnim},
				{index = 6, name = "InspectAnim", id = animData.animations.tpInspectAnim},
				{index = 7, name = "IdleAnim", id = animData.animations.tpIdleAnim}
			}

			for _, anim in ipairs(firstPersonAnims) do
				local animation = Instance.new("Animation")
				animation.Parent = weaponSystem[1].viewmodel
				animation.Name = anim.name
				animation.AnimationId = anim.id
				weaponSystem[1].animations.FirstPerson[anim.index] = animator:LoadAnimation(animation)
			end

			for _, anim in ipairs(thirdPersonAnims) do
				local animation = Instance.new("Animation")
				animation.Parent = player.Character
				animation.Name = anim.name
				animation.AnimationId = anim.id
				weaponSystem[1].animations.ThirdPerson[anim.index] = characterAnimator:LoadAnimation(animation)
			end

			weaponSystem[1].animations.ThirdPerson[7]:Play()
			local sounds = RequestWeaponData:InvokeServer(Item).sounds

			if character then
				if character.UpperTorso:FindFirstChildWhichIsA("Sound") then
					sounds[1] = character.UpperTorso:FindFirstChild("Equip")
					sounds[2] = character.UpperTorso:FindFirstChild("Shoot")
					sounds[3] = character.UpperTorso:FindFirstChild("Reload")
					sounds[4] = character.UpperTorso:FindFirstChild("EmptyReload")
					sounds[5] = character.UpperTorso:FindFirstChild("Inspect")
					sounds[6] = character.UpperTorso:FindFirstChild("Deequip")
				end
			end

			for _, v in pairs(weaponSystem[1].viewmodel:GetDescendants()) do
				if v:IsA("Part") or v:IsA("BasePart") or v:IsA("MeshPart") then
					v.Transparency = 1
				end
			end

			weaponSystem[1].animations.FirstPerson[2]:Play()
			weaponSystem[1].animations.ThirdPerson[2]:Play()

			ReplicatedStorage.Shared.Remotes.ItemFoley:FireServer(script.Parent.Parent:WaitForChild("UpperTorso"):WaitForChild("Deequip"))

			task.wait(.1)

			for _, v in pairs(weaponSystem[1].viewmodel:GetDescendants()) do
				if v:IsA("Part") or v:IsA("BasePart") or v:IsA("MeshPart") then
					if not (v.Parent:IsA("Folder") 
					or v.Name == "Main" 
					or v.Name == "FakeCamera" 
					or v.Name == "AimPart" 
					or v.Name == "AimPart2" 
					or v.Name == "HumanoidRootPart" 
					or v.Name == "CasingEject" 
					or v.Name == "Muzzle") then
						v.Transparency = 0
					end
				end
			end

			UpdateWeaponStateRemote:FireServer(weaponSystem[1].states[1])
			aimHelper:Init(weaponData.aimData, weaponSystem[1].viewmodel)

			ViewmodelRotation:Init(true, weaponSystem[1].viewmodel)
			-- print(weaponData)
		end
	end
end

function Shoot()
	if weaponSystem[1].viewmodel and character then
		if weaponData.modifiers.fireMode == "Semi Auto" then
			local success, recoilData, data = RequestShoot:InvokeServer(weaponSystem[1].inventory[weaponSystem[1].currentSlot])
			if success then
				weaponSystem[1].animations.FirstPerson[2]:Stop()
				weaponSystem[1].animations.FirstPerson[5]:Stop()
				weaponSystem[1].animations.FirstPerson[6]:Stop()
				weaponSystem[1].animations.FirstPerson[7]:Stop()
				weaponSystem[1].animations.FirstPerson[8]:Stop()

				weaponSystem[1].animations.ThirdPerson[2]:Stop()
				weaponSystem[1].animations.ThirdPerson[4]:Stop()
				weaponSystem[1].animations.ThirdPerson[5]:Stop()
				weaponSystem[1].animations.ThirdPerson[6]:Stop()

				local muzzleFlash = game.ReplicatedStorage.Objects.MuzzleFlash:Clone()
				muzzleFlash.Parent = game.Workspace
				muzzleFlash.CFrame = weaponSystem[1].viewmodel.Muzzle.CFrame

				for i, v in pairs(muzzleFlash:GetChildren()) do
					if v:IsA("ParticleEmitter") then
						v:Emit(1)
					end
				end

				game:GetService("Debris"):AddItem(muzzleFlash, .07)

				-- ReplicatedStorage.Shared.Remotes.ItemFoley:FireServer(script.Parent.Parent:WaitForChild("UpperTorso"):WaitForChild("Shoot"))

				camera.CFrame = camera.CFrame * CFrame.Angles(recoilData.x, recoilData.y, recoilData.z)

				debounce = true
				task.wait(data.debounce)
				debounce = false
			end
		end

		if weaponData.modifiers.fireMode == "Full Auto" then
			weaponSystem[1].modifiers.IsShooting = true
			UpdateWeaponStateRemote:FireServer(weaponSystem[1].states[2])
		end
	end
end

function Inspect()
	if weaponSystem[1].animations and weaponSystem[1].viewmodel and weaponSystem.module and not weaponSystem[1].modifiers.IsReloading then
		-- PlayerWeaponSystemData:setState(weaponSystem.states[4])
		weaponSystem[1].modifiers.IsInspecting = true
		if weaponSystem[1].state == weaponSystem[1].states[4] and weaponSystem[1].modifiers.IsInspecting then 
			weaponSystem[1].animations.FirstPerson[8]:Stop()
			weaponSystem[1].animations.FirstPerson[7]:Play()

			dof.FarIntensity = 1
			dof.FocusDistance = 10.44
			dof.InFocusRadius = 25.215
			dof.NearIntensity = 0.183
			weaponSystem[1].animations.FirstPerson[7]:Play()
			weaponSystem[1].animations.ThirdPerson[6]:Play()
			
			ReplicatedStorage.Shared.Remotes.ItemFoley:FireServer(script.Parent.Parent:WaitForChild("UpperTorso"):WaitForChild("Inspect"))
			repeat task.wait() until weaponSystem[1].animations.FirstPerson[7].IsPlaying == false

			weaponSystem[1].animations.FirstPerson[7]:Stop()
			dof.FarIntensity = .1
			dof.FocusDistance = .05
			dof.InFocusRadius = 30
			dof.NearIntensity = .75

			if weaponSystem[1].state == weaponSystem[1].states[4] then
				weaponSystem[1].modifiers.IsInspecting = false
				-- PlayerWeaponSystemData:setState(weaponSystem[1].states[1])
				UpdateWeaponStateRemote:FireServer(weaponSystem[1].states[1])
			end
		end
	end	
end

function grenade(grenade)
	repeat task.wait() until weaponSystem[1].animations.FirstPerson[1].isPlaying == true

	local grenadeThrown = false

	weaponSystem[1].animations.FirstPerson[1]:GetMarkerReachedSignal("GremadeThrow"):Connect(function()

		if not grenadeThrown then
			camera:FindFirstChildWhichIsA("Model").Grenade.Transparency = 1

			game.ReplicatedStorage.Remotes.Main.Grenade:FireServer(grenade, camera:FindFirstChildWhichIsA("Model").Grenade.Position, camera.CFrame.LookVector, weaponSystem[1].module.sounds[2], 1)
			
			grenadeThrown = true
		end
	end)

	weaponSystem[1].animations.FirstPerson[1].Ended:Connect(function()
		weaponSystem[1].inventory[weaponSystem[1].currentSlot] = "Nil"
		weaponSystem[1].currentSlot = 1
		loadSlot(weaponSystem[1].inventory[weaponSystem[1].currentSlot])
	end)
end

function melee(isLightStab) 
	if isLightStab then
		weaponSystem[1].animations.FirstPerson[1]:Play()
		weaponSystem[1].animations.ThirdPerson[1]:Play()
	else
		weaponSystem[1].animations.FirstPerson[4]:Play()
		weaponSystem[1].animations.ThirdPerson[5]:Play()
	end

	ReplicatedStorage.Shared.Remotes.Melee:FireServer(isLightStab, weaponSystem.module, camera.CFrame.Position, camera.CFrame.LookVector)
end

function Reload()
	if weaponSystem.module and weaponSystem[1].viewmodel and not weaponSystem[1].modifiers.IsShooting then 
		if weaponSystem[1].modifiers.IsReloading then return end

		if weaponSystem.module.ammo < weaponSystem.module.maxAmmo then
			weaponSystem[1].modifiers.IsReloading = true
			-- PlayerWeaponSystemData:setState(weaponSystem[1].states[3])
			UpdateWeaponStateRemote:FireServer(weaponSystem[1].states[3])

			weaponSystem[1].modifiers.IsInspecting = false
			-- camera.FieldOfView = camera.FieldOfView + (defaultFOV - camera.FieldOfView) * 0.1

			weaponSystem[1].animations.FirstPerson[2]:Stop()
			weaponSystem[1].animations.FirstPerson[5]:Stop()
			weaponSystem[1].animations.ThirdPerson[4]:Stop()
			weaponSystem[1].animations.FirstPerson[6]:Stop()
			weaponSystem[1].animations.FirstPerson[7]:Stop()
			weaponSystem[1].animations.ThirdPerson[7]:Stop()
			weaponSystem[1].animations.FirstPerson[8]:Stop()

			if weaponSystem.module.ammo > 0 then
				weaponSystem[1].animations.FirstPerson[5]:Play()
				weaponSystem[1].animations.ThirdPerson[4]:Play()
				ReplicatedStorage.Shared.Remotes.ItemFoley:FireServer(script.Parent.Parent:WaitForChild("UpperTorso"):WaitForChild("Reload"))
			else
				weaponSystem[1].animations.FirstPerson[6]:Play()
				weaponSystem[1].animations.ThirdPerson[5]:Play()
				ReplicatedStorage.Shared.Remotes.ItemFoley:FireServer(script.Parent.Parent:WaitForChild("UpperTorso"):WaitForChild("EmptyReload"))
			end

			local i = 0

			while i < weaponSystem.module.reloadTime do
				if weaponSystem[1].modifiers.IsShooting then
					weaponSystem[1].modifiers.IsReloading = false
					-- PlayerWeaponSystemData:setState(weaponSystem[1].states[2])
					UpdateWeaponStateRemote:FireServer(weaponSystem[1].states[2])
					return
				end

				task.wait(0.05)
				i = i + 0.05
			end
			
			weaponSystem.module.ammo = weaponSystem.module.maxAmmo
			weaponSystem[1].modifiers.IsReloading = false
			-- PlayerWeaponSystemData:setState(weaponSystem.states[1])
			UpdateWeaponStateRemote:FireServer(weaponSystem[1].states[1])
		end
	end
end

local oldCamCF = CFrame.new()

function updateCameraShake()
	local newCamCF = weaponSystem[1].viewmodel.FakeCamera.CFrame:ToObjectSpace(weaponSystem[1].viewmodel.PrimaryPart.CFrame)
	camera.CFrame = camera.CFrame * newCamCF:ToObjectSpace(oldCamCF)
	oldCamCF = newCamCF
end

local hud = player.PlayerGui:WaitForChild("HUD")

RunService.RenderStepped:Connect(function(dt)
	if humanoid and weaponSystem[1].viewmodel then

		if hud then
			if weaponSystem[1].viewmodel and weaponSystem[1].module and isEquipedWeapon then
				if weaponSystem[1].modifiers.isMelee or weaponSystem[1].modifiers.isGrenade then
					hud.Enabled = false
				else
					-- hud.Enabled = true
					-- hud.MainParent.GunName.Text = weaponSystem.inventory[weaponSystem.currentSlot]
					-- hud.MainParent.Ammo.Text = weaponSystem.module.ammo
					-- hud.MainParent.MaxAmmo.Text = weaponSystem.module.maxAmmo
					-- hud.MainParent.GunIcon.Image = weaponSystem.module.imageIconId
					-- hud.MainParent.GunIcon.ImageColor3 =  Color3.new(0, 0, 0)
					-- hud.MainParent.FireMode.Text = weaponSystem.module.fireMode
					-- hud.MainParent.AmmoType.Text = weaponSystem.module.ammoType
					print(":3")
				end
			else
				hud.Enabled = false
			end
		end
			
		-- print(weaponSystem.state) -- Debugging
		-- print(weaponData) -- Debugging

		if weaponSystem[1].viewmodel and weaponData then
			local rot = camera.CFrame:ToObjectSpace(weaponData.aimData.lastCameraCF)
			local X, Y, _ = rot:ToOrientation() 
			weaponData.aimData.swayCF = weaponData.aimData.swayCF:Lerp(CFrame.Angles(math.sin(X) * weaponData.aimData.currentSwayAMT, math.sin(Y) * weaponData.aimData.currentSwayAMT, 0), 1 - 0.001 ^ dt)
			weaponData.aimData.lastCameraCF = camera.CFrame

			if humanoid.MoveDirection.Magnitude > 0 then
				if humanoid.WalkSpeed == 16 then
					bobOffset = bobOffset:Lerp(CFrame.new(math.cos(tick() * 8) * .02, -humanoid.CameraOffset.Y / 7, -humanoid.CameraOffset.Z / 3) * CFrame.Angles(0, math.cos(tick() * -0) * -.0, math.sin(tick() * -4) * .01), 1 - 0.001 ^ dt)
				elseif humanoid.WalkSpeed == 22 then
					bobOffset = bobOffset:Lerp(CFrame.new(math.cos(tick() * 10) * .1, -humanoid.CameraOffset.Y / 3, -humanoid.CameraOffset.Z / 3) * CFrame.Angles(0, math.cos(tick() * -8) * -.1, math.sin(tick() * -8) * .1) * (weaponData.aimData.sprintCF or CFrame.new()), 1 - 0.001 ^ dt)
				end
			else
				bobOffset = bobOffset:Lerp(CFrame.new(0, -humanoid.CameraOffset.Y / 3, 0), 1 - 0.001 ^ dt)
			end

			local rotOffset = CFrame.Angles(0, 0, ViewmodelRotation:getRotation(dt, weaponSystem[1].state))

			for _, v in pairs(camera:GetChildren()) do -- apply things to viewmodel
				if v:IsA("Model") then
					v:SetPrimaryPartCFrame(camera.CFrame * weaponData.aimData.swayCF * weaponData.aimData.aimCF * bobOffset * rotOffset)
					updateCameraShake()

					if weaponSystem[1].animations and weaponSystem[1].viewmodel then
						if not weaponData.isMelee then
							if not weaponSystem[1].animations.FirstPerson[1].IsPlaying and not weaponSystem[1].animations.FirstPerson[4].IsPlaying and not weaponSystem[1].animations.FirstPerson[2].IsPlaying and not weaponSystem[1].animations.FirstPerson[6].IsPlaying and not weaponSystem[1].animations.FirstPerson[5].IsPlaying and not weaponSystem[1].animations.FirstPerson[7].IsPlaying and not weaponSystem[1].animations.FirstPerson[3].IsPlaying then
								if not weaponSystem[1].animations.FirstPerson[8].IsPlaying then
									weaponSystem[1].animations.FirstPerson[8]:Play()
								end
							else
								weaponSystem[1].animations.FirstPerson[8]:Stop()
							end
						end
					end
				end
			end

			-- aimHelper:Aim(dt)
		end
	end
end)

UIS.InputBegan:Connect(function(input, gpe)
	if gpe then return end

	if (weaponSystem[1].state == weaponSystem[1].states[1] 
	or weaponSystem[1].state == weaponSystem[1].states[3] 
	or weaponSystem[1].state == weaponSystem[1].states[4]) 
	and weaponSystem[1].state ~= weaponSystem[1].states[8] then
		if input.KeyCode == Enum.KeyCode.One then
			if weaponSystem[1].currentSlot ~= 1 and weaponSystem[1].state ~= weaponSystem[1].states[3] then
				if weaponSystem[1].inventory[1] ~= "Empty" then
					loadSlot(weaponSystem[1].inventory[1])
					weaponSystem[1].currentSlot = 1
					isEquipedWeapon = true
				end
			end
		end

		if input.KeyCode == Enum.KeyCode.Two then
			if weaponSystem[1].currentSlot ~= 2 and weaponSystem[1].state ~= weaponSystem[1].states[3] then
				if weaponSystem[1].inventory[2] ~= "Empty" then
					loadSlot(weaponSystem[1].inventory[2])
					weaponSystem[1].currentSlot = 2
					isEquipedWeapon = true
				end
			end
		end

		if input.KeyCode == Enum.KeyCode.Three then
			if weaponSystem[1].currentSlot ~= 3 and weaponSystem[1].state ~= weaponSystem[1].states[3] then
				if weaponSystem[1].inventory[3] ~= "Empty" then
					loadSlot(weaponSystem[1].inventory[3])
					weaponSystem[1].currentSlot = 3
					isEquipedWeapon = true
				end
			end
		end

		-- if input.KeyCode == Enum.KeyCode.Four then
		-- 	if weaponSystem[1].currentSlot ~= 4 and weaponSystem[1].state ~= weaponSystem[1].states[3] then
		-- 		if weaponSystem[1].inventory[4] ~= "Empty" then
		-- 			loadSlot(weaponSystem[1].inventory[4])
		-- 			weaponSystem[1].currentSlot = 4
		-- 			isEquipedWeapon = true
		-- 		end
		-- 	end
		-- end

		-- if input.KeyCode == Enum.KeyCode.Five then
		-- 	if weaponSystem[1].currentSlot ~= 5 and weaponSystem[1].state ~= weaponSystem[1].states[3] then
		-- 		if weaponSystem[1].inventory[5] ~= "Empty" then
		-- 			loadSlot(weaponSystem[1].inventory[5])
		-- 			weaponSystem[1].currentSlot = 5
		-- 			isEquipedWeapon = true
		-- 		end
		-- 	end
		-- end

		-- if input.KeyCode == Enum.KeyCode.Six then
		-- 	if weaponSystem[1].currentSlot ~= 6 and weaponSystem[1].state ~= weaponSystem[1].states[3] then
		-- 		if weaponSystem[1].inventory[6] ~= "Empty" then
		-- 			loadSlot(weaponSystem[1].inventory[6])
		-- 			weaponSystem[1].currentSlot = 6
		-- 			isEquipedWeapon = true
		-- 		end
		-- 	end
		-- end

		-- if input.KeyCode == Enum.KeyCode.Seven and weaponSystem[1].state ~= weaponSystem[1].states[3] then
		-- 	if weaponSystem[1].currentSlot ~= 7 then
		-- 		if weaponSystem[1].inventory[7] ~= "Empty" then
		-- 			loadSlot(weaponSystem[1].inventory[7])
		-- 			weaponSystem[1].currentSlot = 7
		-- 			isEquipedWeapon = true
		-- 		end
		-- 	end
		-- end

		-- if input.KeyCode == Enum.KeyCode.Eight then
		-- 	if weaponSystem[1].currentSlot ~= 8 and weaponSystem[1].state ~= weaponSystem[1].states[3] then
		-- 		if weaponSystem[1].inventory[8] ~= "Empty" then
		-- 			loadSlot(weaponSystem[1].inventory[8])
		-- 			weaponSystem[1].currentSlot = 8
		-- 			isEquipedWeapon = true
		-- 		end
		-- 	end
		-- end
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		if character and weaponSystem[1].viewmodel and not debounce then
			if weaponSystem[1].state ~= weaponSystem[1].states[6]  then
				print(debug.traceback())
				Shoot()
			end
		end

		if weaponSystem.module and weaponSystem[1].viewmodel and weaponSystem.module.isMelee and not weaponSystem.module.isGrenade then
			melee(true)
		end
	end

	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		if weaponSystem[1].module and weaponSystem[1].viewmodel then
			if weaponSystem[1].state ~= weaponSystem[1].states[6] then
				if not weaponSystem[1].module.isGrenade and not weaponSystem[1].module.isMelee then
					if not weaponSystem[1].modifiers.IsReloading then
						weaponSystem[1].modifiers.IsAiming = true
						UpdateWeaponStateRemote:FireServer(weaponSystem[1].states[5])
					end
				end
			end
		end	

		if weaponSystem.module and weaponSystem[1].viewmodel and weaponSystem.module.isMelee and not weaponSystem.module.isGrenade then
			melee(false)
		end
	end

	if input.KeyCode == Enum.KeyCode.R then
		if weaponSystem.module and weaponSystem[1].viewmodel and not weaponSystem.module.isMelee and not weaponSystem.module.isGrenade then
			Reload()
		end
	end

	if input.KeyCode == Enum.KeyCode.T then
		if weaponSystem.module and weaponSystem[1].viewmodel then
			AimHelper:switchAimpart()
		end
	end

	if input.KeyCode == Enum.KeyCode.H then
		if weaponSystem.module and weaponSystem[1].viewmodel then
			Inspect()
		end
	end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
		if weaponSystem[1].state ~= weaponSystem[1].states[6] then
			if weaponSystem.module and weaponSystem[1].viewmodel and not weaponSystem[1].modifiers.IsReloading then
				weaponSystem[1].modifiers.IsAiming = false
				UpdateWeaponStateRemote:FireServer(weaponSystem[1].states[1])
			end	
		end
    end
end)

ReplicatedStorage.Shared.Remotes.PlayerDied.OnClientEvent:Connect(function()
	for _, v in pairs(camera:GetDescendants()) do
		if v:IsA("Model") then
			v:Destroy()
			weaponSystem[1].state = weaponSystem[1].states[8]
		end
	end
	
	for _, v in pairs(game.ReplicatedStorage.Shared.Modules:GetDescendants()) do
		if v:IsA("ModuleScript") and v.Name ~= "FastCastRedux" and v.Name ~= "ActiveSignal" and v.Name ~= "Signal" and v.Name ~= "Table" and v.Name ~= "TypeDefinitions"  and v.Name ~= "TypeMarshaller" and v.Name ~= "Misc" then
			require(v).ammo = require(v).maxAmmo
		end
	end

	if weaponSystem[1].viewmodel and weaponSystem.module then
		weaponSystem.module = nil
		weaponSystem[1].viewmodel:Destroy()
		hud.Enabled = false
	end
end)

mouse.Button1Up:Connect(function()
	if weaponSystem[1].viewmodel then
		if weaponSystem[1].state ~= weaponSystem[1].states[6] then
			weaponSystem[1].modifiers.IsShooting = false

			if weaponSystem[1].modifiers.IsAiming then
				UpdateWeaponStateRemote:FireServer(weaponSystem[1].states[5])
			else
				UpdateWeaponStateRemote:FireServer(weaponSystem[1].states[1])
			end
		end
	end
end)

while wait() do
	if weaponData and weaponSystem[1].viewmodel and weaponData.modifiers.fireMode == "Full Auto" then
		if weaponSystem[1].state == weaponSystem[1].states[2] or weaponSystem[1].modifiers.IsShooting then
			if weaponSystem[1].state ~= weaponSystem[1].states[7] then
				local success, recoilData, data = RequestShoot:InvokeServer(weaponSystem[1].inventory[weaponSystem[1].currentSlot])
				if success then
					weaponSystem[1].animations.FirstPerson[2]:Stop()
					weaponSystem[1].animations.FirstPerson[5]:Stop()
					weaponSystem[1].animations.FirstPerson[6]:Stop()
					weaponSystem[1].animations.FirstPerson[7]:Stop()
					weaponSystem[1].animations.FirstPerson[8]:Stop()

					weaponSystem[1].animations.ThirdPerson[2]:Stop()
					weaponSystem[1].animations.ThirdPerson[4]:Stop()
					weaponSystem[1].animations.ThirdPerson[5]:Stop()
					weaponSystem[1].animations.ThirdPerson[6]:Stop()

					if weaponData.isLastBullet then
						weaponSystem[1].animations.FirstPerson[2]:Play()

						weaponSystem[1].animations.FirstPerson[1]:Stop()
						weaponSystem[1].animations.ThirdPerson[1]:Stop()
					else
						weaponSystem[1].animations.FirstPerson[1]:Stop()
						weaponSystem[1].animations.FirstPerson[1]:Play()
					end
					
					local muzzleFlash = game.ReplicatedStorage.Objects.MuzzleFlash:Clone()
					muzzleFlash.Parent = game.Workspace
					muzzleFlash.CFrame = weaponSystem[1].viewmodel.Muzzle.CFrame

					for i, v in pairs(muzzleFlash:GetChildren()) do
						if v:IsA("ParticleEmitter") then
							v:Emit(1)
						end
					end
					game:GetService("Debris"):AddItem(muzzleFlash, .07)

					if SpringModule then
						local hugeRecoil = Vector3.new(math.random(-1, 1), .8, -.45)
						recoilSpring:Impulse(hugeRecoil * 2000000)

						camera.CFrame = camera.CFrame * CFrame.Angles(math.rad(recoilData.rx), math.rad(recoilData.ry), math.rad(recoilData.rz))
					end

					task.wait(data.fireRate)
				end
			end
		end
	end
end