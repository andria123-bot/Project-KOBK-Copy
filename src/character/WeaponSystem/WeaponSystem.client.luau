local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait() or script.Parent.Parent
local humanoid = character:WaitForChild("Humanoid")

local camera = game.Workspace.CurrentCamera
local mouse = player:GetMouse()

local LoadViewmodel = require(script.Parent.LoadViewmodel)
local LoadModule = require(script.Parent.LoadModule)
local PlayerWeaponSystem = require(script.Parent.PlayerWeaponSystemData)
local WeaponCategories = require(script.Parent.WeaponCategories)
local ViewmodelRotation = require(script.Parent.ViewmodelRotation)

local playerWeaponSystemData = PlayerWeaponSystem
local weaponSystem = PlayerWeaponSystem.weaponSystem -- player module

local dof = game.Lighting.DepthOfField

local bobOffset = CFrame.new()

local AimHelper = require(script.Parent.Aim)
local PlayerWeaponSystemData = require(script.Parent.PlayerWeaponSystemData)
local aimHelper = AimHelper

local debounce = false

local isEquipedWeapon = false

local defaultFOV = 70

function stopAllAnims()
	for i, v in pairs(weaponSystem.animations.FirstPerson) do
		if v ~= nil and v.IsPlaying then
			v:Stop()
		end
	end

	for i, v in pairs(weaponSystem.animations.ThirdPerson) do
		if v ~= nil and v.IsPlaying then
			v:Stop()
		end
	end
end

function loadSlot(Item)
	if weaponSystem.state == weaponSystem.states[1] 
	or weaponSystem.state == weaponSystem.states[3] 
	or weaponSystem.state == weaponSystem.states[4] then

		PlayerWeaponSystem:setState(weaponSystem.states[7])

		weaponSystem.modifiers.IsAiming = false
		weaponSystem.modifiers.IsInspecting = false
		weaponSystem.modifiers.IsReloading = false
		weaponSystem.modifiers.IsShooting = false

		weaponSystem.module = LoadModule.GetModule(Item)

		for _, v in pairs(camera:GetChildren()) do
			if v:IsA("Model") then
				stopAllAnims()

				if weaponSystem.animations.FirstPerson[3] then
					weaponSystem.animations.FirstPerson[3]:Play()
					repeat task.wait() until weaponSystem.animations.FirstPerson[3].IsPlaying == false
				end

				v:Destroy()
			end
		end

		if weaponSystem.module then
			weaponSystem.viewmodel = LoadViewmodel.GetViewmodel(Item):Clone()
			weaponSystem.viewmodel.Parent = camera

			if weaponSystem.viewmodel then
				local animator = weaponSystem.viewmodel.AnimationController.Animator

				weaponSystem.animations.FirstPerson[1] = Instance.new("Animation")
				weaponSystem.animations.FirstPerson[1].Parent = weaponSystem.viewmodel
				weaponSystem.animations.FirstPerson[1].Name = "Fire"
				weaponSystem.animations.FirstPerson[1].AnimationId = weaponSystem.module.fireAnim
				weaponSystem.animations.FirstPerson[1] = animator:LoadAnimation(weaponSystem.animations.FirstPerson[1])

				weaponSystem.animations.FirstPerson[2] = Instance.new("Animation")
				weaponSystem.animations.FirstPerson[2].Parent = weaponSystem.viewmodel
				weaponSystem.animations.FirstPerson[2].Name = "Equip"
				weaponSystem.animations.FirstPerson[2].AnimationId = weaponSystem.module.equipAnim
				weaponSystem.animations.FirstPerson[2] = animator:LoadAnimation(weaponSystem.animations.FirstPerson[2])

				weaponSystem.animations.FirstPerson[3] = Instance.new("Animation")
				weaponSystem.animations.FirstPerson[3].Parent = weaponSystem.viewmodel
				weaponSystem.animations.FirstPerson[3].Name = "Deequip"
				weaponSystem.animations.FirstPerson[3].AnimationId = weaponSystem.module.deequipAnim
				weaponSystem.animations.FirstPerson[3] = animator:LoadAnimation(weaponSystem.animations.FirstPerson[3])

				weaponSystem.animations.FirstPerson[4] = Instance.new("Animation")
				weaponSystem.animations.FirstPerson[4].Parent = weaponSystem.viewmodel
				weaponSystem.animations.FirstPerson[4].Name = "EmptyFire"
				weaponSystem.animations.FirstPerson[4].AnimationId = weaponSystem.module.emptyFireAnim
				weaponSystem.animations.FirstPerson[4] = animator:LoadAnimation(weaponSystem.animations.FirstPerson[4])

				weaponSystem.animations.FirstPerson[5] = Instance.new("Animation")
				weaponSystem.animations.FirstPerson[5].Parent = weaponSystem.viewmodel
				weaponSystem.animations.FirstPerson[5].Name = "Reload"
				weaponSystem.animations.FirstPerson[5].AnimationId = weaponSystem.module.reloadAnim
				weaponSystem.animations.FirstPerson[5] = animator:LoadAnimation(weaponSystem.animations.FirstPerson[5])

				weaponSystem.animations.FirstPerson[6] = Instance.new("Animation")
				weaponSystem.animations.FirstPerson[6].Name = "EmptyReload"
				weaponSystem.animations.FirstPerson[6].AnimationId = weaponSystem.module.emptyReloadAnim
				weaponSystem.animations.FirstPerson[6] = animator:LoadAnimation(weaponSystem.animations.FirstPerson[6])

				weaponSystem.animations.FirstPerson[7] = Instance.new("Animation")
				weaponSystem.animations.FirstPerson[7].Parent = weaponSystem.viewmodel
				weaponSystem.animations.FirstPerson[7].Name = "Inspect"
				weaponSystem.animations.FirstPerson[7].AnimationId = weaponSystem.module.inspectAnim
				weaponSystem.animations.FirstPerson[7] = animator:LoadAnimation(weaponSystem.animations.FirstPerson[7])

				weaponSystem.animations.FirstPerson[8] = Instance.new("Animation")
				weaponSystem.animations.FirstPerson[8].Parent = weaponSystem.viewmodel
				weaponSystem.animations.FirstPerson[8].Name = "Idle"
				weaponSystem.animations.FirstPerson[8].AnimationId = weaponSystem.module.idleAnim
				weaponSystem.animations.FirstPerson[8] = animator:LoadAnimation(weaponSystem.animations.FirstPerson[8])



				weaponSystem.animations.ThirdPerson[7] = Instance.new("Animation")
				weaponSystem.animations.ThirdPerson[7].Parent = player.Character
				weaponSystem.animations.ThirdPerson[7].Name = "IdleAnim"
				weaponSystem.animations.ThirdPerson[7].AnimationId = weaponSystem.module.tpIdleAnim
				weaponSystem.animations.ThirdPerson[7] = weaponSystem.viewmodel.AnimationController.Animator:LoadAnimation(weaponSystem.animations.ThirdPerson[7])

				if weaponSystem.animations.ThirdPerson[7] and weaponSystem.module.tpIdleAnim ~= nil then
					player.Character:FindFirstChild("IdleAnim").AnimationId = weaponSystem.module.tpIdleAnim
					weaponSystem.animations.ThirdPerson[7] = character.Humanoid:LoadAnimation(player.Character:FindFirstChild("IdleAnim"))
					weaponSystem.animations.ThirdPerson[7]:Play()
				else
					weaponSystem.animations.ThirdPerson[7] = Instance.new("Animation")
					weaponSystem.animations.ThirdPerson[7].Parent = player.Character
					weaponSystem.animations.ThirdPerson[7].Name = "IdleAnim"
					weaponSystem.animations.ThirdPerson[7].AnimationId = weaponSystem.module.tpIdleAnim
					weaponSystem.animations.ThirdPerson[7] = character.Humanoid:LoadAnimation(weaponSystem.animations.ThirdPerson[7])
					weaponSystem.animations.ThirdPerson[7]:Play()
				end

				ReplicatedStorage.Shared.Remotes.LoadSlot:FireServer(Item)

				if character then
					if character.UpperTorso:FindFirstChildWhichIsA("Sound") then
						weaponSystem.module.sounds[1] = character.UpperTorso:FindFirstChild("Equip")
						weaponSystem.module.sounds[2] = character.UpperTorso:FindFirstChild("Shoot")
						weaponSystem.module.sounds[3] = character.UpperTorso:FindFirstChild("Reload")
						weaponSystem.module.sounds[4] = character.UpperTorso:FindFirstChild("EmptyReload")
						weaponSystem.module.sounds[5] = character.UpperTorso:FindFirstChild("Inspect")
						weaponSystem.module.sounds[6] = character.UpperTorso:FindFirstChild("Deequip")
					end
				end

				for _, v in pairs(weaponSystem.viewmodel:GetDescendants()) do
					if v:IsA("Part") or v:IsA("BasePart") or v:IsA("MeshPart") then
						v.Transparency = 1
					end
				end

				weaponSystem.animations.FirstPerson[2]:Play()

				task.wait(.1)

				for _, v in pairs(weaponSystem.viewmodel:GetDescendants()) do
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

				PlayerWeaponSystem:setState(weaponSystem.states[1])
				aimHelper:Init(weaponSystem.module, weaponSystem.viewmodel)

				ViewmodelRotation:Init(weaponSystem.module, weaponSystem.viewmodel)
			end
		end
	end
end

function Shoot()
	if weaponSystem.state ~= weaponSystem.states[1] and weaponSystem.state ~= weaponSystem.states[5] then return end
	playerWeaponSystemData:setState(weaponSystem.states[2])

	if character and weaponSystem.module and weaponSystem.viewmodel and weaponSystem.module.ammo > 0 and weaponSystem.state ~= weaponSystem.states[7] then
		if weaponSystem.module.fireMode == "Semi Auto" then
			weaponSystem.animations.FirstPerson[2]:Stop()
			weaponSystem.animations.FirstPerson[5]:Stop()
			weaponSystem.animations.FirstPerson[6]:Stop()
			weaponSystem.animations.FirstPerson[7]:Stop()
			weaponSystem.animations.FirstPerson[8]:Stop()
			
			if weaponSystem.module.ammo == 1 then
				weaponSystem.animations.FirstPerson[1]:Stop()
				weaponSystem.animations.FirstPerson[4]:Play()
			else
				weaponSystem.animations.FirstPerson[4]:Stop()
				weaponSystem.animations.FirstPerson[1]:Play()

				-- weaponSystem.animations.ThirdPerson[1]:Play()
			end

			weaponSystem.module.ammo -= 1

			local muzzleFlash = game.ReplicatedStorage.Objects.MuzzleFlash:Clone()
			muzzleFlash.Parent = game.Workspace
			muzzleFlash.CFrame = weaponSystem.viewmodel.Muzzle.CFrame

			for i, v in pairs(muzzleFlash:GetChildren()) do
				if v:IsA("ParticleEmitter") then
					v:Emit(1)
				end
			end

			game:GetService("Debris"):AddItem(muzzleFlash, 0.05)

			ReplicatedStorage.Shared.Remotes.Shoot:FireServer(weaponSystem.viewmodel.Muzzle.Position, camera.CFrame.LookVector, weaponSystem.module.damage, weaponSystem.module.headshot, weaponSystem.inventory[weaponSystem.currentSlot], weaponSystem.viewmodel:FindFirstChild("Muzzle").CFrame)
			ReplicatedStorage.Shared.Remotes.ItemFoley:FireServer(script.Parent.Parent:WaitForChild("UpperTorso"):WaitForChild("Shoot"))

			PlayerWeaponSystem:setState(weaponSystem.states[1])

			if weaponSystem.module.ammo == 0 then
				if weaponSystem.state == weaponSystem.states[1] and weaponSystem.module.ammo < weaponSystem.module.maxAmmo then 
					task.wait(.5)

					playerWeaponSystemData:setState(weaponSystem.states[3])
					
					weaponSystem.modifiers.IsInspecting = false
					weaponSystem.modifiers.IsShooting = false
					weaponSystem.modifiers.IsReloading = true
					Reload()
					
					repeat task.wait() until weaponSystem.animations.FirstPerson[6].IsPlaying == false
					debounce = false
				end
			else
				debounce = true

				wait(weaponSystem.module.debounce)

				debounce = false
			end
		end

		if weaponSystem.module.fireMode == "Full Auto" then
			weaponSystem.modifiers.IsShooting = true
			PlayerWeaponSystemData:setState(weaponSystem.states[2])
		end
	end
end

function Inspect()
	if weaponSystem.animations and weaponSystem.viewmodel and weaponSystem.module then

		if weaponSystem.modifiers.IsInspecting and weaponSystem.state == weaponSystem.states[4] and not weaponSystem.modifiers.IsReloading then
			weaponSystem.modifiers.IsInspecting = true
			weaponSystem.animations.FirstPerson[8]:Stop()
			dof.FarIntensity = 1
			dof.FocusDistance = 10.44
			dof.InFocusRadius = 25.215
			dof.NearIntensity = 0.183
			weaponSystem.animations.FirstPerson[7]:Play()
			-- weaponSystem.animations.ThirdPerson[6]:Play()
			ReplicatedStorage.Shared.Remotes.ItemFoley:FireServer(script.Parent.Parent:WaitForChild("UpperTorso"):WaitForChild("Inspect"))
			repeat task.wait() until weaponSystem.animations.FirstPerson[7].IsPlaying == false

			weaponSystem.animations.FirstPerson[7]:Stop()
			dof.FarIntensity = .1
			dof.FocusDistance = .05
			dof.InFocusRadius = 30
			dof.NearIntensity = .75
			PlayerWeaponSystem:setState(weaponSystem.states[1])
			weaponSystem.modifiers.IsInspecting = false
		end
	end
end

function Reload()
	if weaponSystem.state == weaponSystem.states[3] and weaponSystem.modifiers.IsReloading then
		if weaponSystem.viewmodel and weaponSystem.module and weaponSystem.module.isMelee == false and weaponSystem.module.isGrenade == false and weaponSystem.module.ammo < weaponSystem.module.maxAmmo then
			if weaponSystem.state == weaponSystem.states[3] then
				camera.FieldOfView = camera.FieldOfView + (defaultFOV - camera.FieldOfView) * 0.1
				weaponSystem.animations.FirstPerson[1]:Stop()
				weaponSystem.animations.FirstPerson[2]:Stop()
				weaponSystem.animations.FirstPerson[3]:Stop()
				weaponSystem.animations.FirstPerson[7]:Stop()
				-- weaponSystem.animations.ThirdPerson[6]:Stop()
				weaponSystem.animations.FirstPerson[8]:Stop()


				if weaponSystem.module.ammo > 0 then
					weaponSystem.animations.FirstPerson[5]:Play()
					-- weaponSystem.animations.ThirdPerson[4]:Play()
					ReplicatedStorage.Shared.Remotes.ItemFoley:FireServer(script.Parent.Parent:WaitForChild("UpperTorso"):WaitForChild("Reload"))
				else
					weaponSystem.animations.FirstPerson[6]:Play()
					-- weaponSystem.animations.ThirdPerson[5]:Play()
					ReplicatedStorage.Shared.Remotes.ItemFoley:FireServer(script.Parent.Parent:WaitForChild("UpperTorso"):WaitForChild("EmptyReload"))
				end

				camera.FieldOfView = camera.FieldOfView + (defaultFOV - camera.FieldOfView) * 0.1
				wait(weaponSystem.module.reloadTime)

				weaponSystem.module.ammo = weaponSystem.module.maxAmmo
				weaponSystem.modifiers.IsReloading = false
				playerWeaponSystemData:setState(weaponSystem.states[1])
			else
				print("Wrong State: ", weaponSystem.state)
			end
		end
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
			
		-- print(weaponSystem.state) -- Debugging
		print(weaponSystem.animations.FirstPerson[4].IsPlaying)

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

		local rotOffset = CFrame.Angles(0, 0, ViewmodelRotation:getRotation(dt, weaponSystem.state))

		for _, v in pairs(camera:GetChildren()) do -- apply things to viewmodel
			if v:IsA("Model") then
				v:SetPrimaryPartCFrame(camera.CFrame * weaponSystem.module.swayCF * weaponSystem.module.aimCF * bobOffset * rotOffset)
				updateCameraShake()

				if weaponSystem.module and weaponSystem.animations and weaponSystem.viewmodel then
					if not weaponSystem.module.isMelee then
						if not weaponSystem.animations.FirstPerson[1].IsPlaying and not weaponSystem.animations.FirstPerson[4].IsPlaying and not weaponSystem.animations.FirstPerson[2].IsPlaying and not weaponSystem.animations.FirstPerson[6].IsPlaying and not weaponSystem.animations.FirstPerson[5].IsPlaying and not weaponSystem.animations.FirstPerson[7].IsPlaying and not weaponSystem.animations.FirstPerson[3].IsPlaying then
							if not weaponSystem.animations.FirstPerson[8].IsPlaying then
								weaponSystem.animations.FirstPerson[8]:Play()
							end
						else
							weaponSystem.animations.FirstPerson[8]:Stop()
						end
					end
				end
			end
		end

		if weaponSystem.state == weaponSystem.states[5] or weaponSystem.state == weaponSystem.states[1] or weaponSystem.state == weaponSystem.states[2] then
			aimHelper:Aim(dt)
		end
	end
end)

UIS.InputBegan:Connect(function(input, gpe)
	if gpe then return end

	if (weaponSystem.state == weaponSystem.states[1] 
	or weaponSystem.state == weaponSystem.states[3] 
	or weaponSystem.state == weaponSystem.states[4]) 
	and weaponSystem.state ~= weaponSystem.states[8] then
		if input.KeyCode == Enum.KeyCode.One then
			if weaponSystem.currentSlot ~= 1 and weaponSystem.state ~= weaponSystem.states[3] then
				if weaponSystem.inventory[1] ~= "Nil" then
					loadSlot(weaponSystem.inventory[1])
					weaponSystem.currentSlot = 1
					isEquipedWeapon = true
				end
			end
		end

		if input.KeyCode == Enum.KeyCode.Two then
			if weaponSystem.currentSlot ~= 2 and weaponSystem.state ~= weaponSystem.states[3] then
				if weaponSystem.inventory[2] ~= "Nil" then
					loadSlot(weaponSystem.inventory[2])
					weaponSystem.currentSlot = 2
					isEquipedWeapon = true
				end
			end
		end

		if input.KeyCode == Enum.KeyCode.Three then
			if weaponSystem.currentSlot ~= 3 and weaponSystem.state ~= weaponSystem.states[3] then
				if weaponSystem.inventory[3] ~= "Nil" then
					loadSlot(weaponSystem.inventory[3])
					weaponSystem.currentSlot = 3
					isEquipedWeapon = true
				end
			end
		end

		if input.KeyCode == Enum.KeyCode.Four then
			if weaponSystem.currentSlot ~= 4 and weaponSystem.state ~= weaponSystem.states[3] then
				if weaponSystem.inventory[4] ~= "Nil" then
					loadSlot(weaponSystem.inventory[4])
					weaponSystem.currentSlot = 4
					isEquipedWeapon = true
				end
			end
		end

		if input.KeyCode == Enum.KeyCode.Five then
			if weaponSystem.currentSlot ~= 5 and weaponSystem.state ~= weaponSystem.states[3] then
				if weaponSystem.inventory[5] ~= "Nil" then
					loadSlot(weaponSystem.inventory[5])
					weaponSystem.currentSlot = 5
					isEquipedWeapon = true
				end
			end
		end

		if input.KeyCode == Enum.KeyCode.Six then
			if weaponSystem.currentSlot ~= 6 and weaponSystem.state ~= weaponSystem.states[3] then
				if weaponSystem.inventory[6] ~= "Nil" then
					loadSlot(weaponSystem.inventory[6])
					weaponSystem.currentSlot = 6
					isEquipedWeapon = true
				end
			end
		end

		if input.KeyCode == Enum.KeyCode.Seven and weaponSystem.state ~= weaponSystem.states[3] then
			if weaponSystem.currentSlot ~= 7 then
				if weaponSystem.inventory[7] ~= "Nil" then
					loadSlot(weaponSystem.inventory[7])
					weaponSystem.currentSlot = 7
					isEquipedWeapon = true
				end
			end
		end

		if input.KeyCode == Enum.KeyCode.Eight then
			if weaponSystem.currentSlot ~= 8 and weaponSystem.state ~= weaponSystem.states[3] then
				if weaponSystem.inventory[8] ~= "Nil" then
					loadSlot(weaponSystem.inventory[8])
					weaponSystem.currentSlot = 8
					isEquipedWeapon = true
				end
			end
		end
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		if character and weaponSystem.viewmodel and weaponSystem.module and weaponSystem.module.ammo ~= 0 and not debounce then
			if weaponSystem.state == weaponSystem.states[1] or weaponSystem.modifiers.IsInspecting or weaponSystem.state == weaponSystem.states[4] then
				weaponSystem.modifiers.IsInspecting = false
				PlayerWeaponSystem:setState(weaponSystem.states[1])
				Shoot()
			end
		end
	end

	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		if weaponSystem.module and weaponSystem.viewmodel and weaponSystem.state ~= weaponSystem.states[4] and weaponSystem.state == weaponSystem.states[1] then
			weaponSystem.modifiers.IsAiming = true
		end	
	end

	if input.KeyCode == Enum.KeyCode.R then
		if weaponSystem.module and weaponSystem.viewmodel and weaponSystem.state == weaponSystem.states[1] and weaponSystem.module.ammo < weaponSystem.module.maxAmmo then
			playerWeaponSystemData:setState(weaponSystem.states[3])
			weaponSystem.modifiers.IsInspecting = false
			weaponSystem.modifiers.IsShooting = false

			weaponSystem.modifiers.IsReloading = true
			Reload()
		end
	end

	if input.KeyCode == Enum.KeyCode.T then
		if weaponSystem.module and weaponSystem.viewmodel then
			AimHelper:switchAimpart()
		end
	end

	if input.KeyCode == Enum.KeyCode.H then
		if weaponSystem.module and weaponSystem.viewmodel and weaponSystem.state == weaponSystem.states[1] then
			PlayerWeaponSystem:setState(weaponSystem.states[4])
			weaponSystem.modifiers.IsInspecting = true
			Inspect()
		end
	end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
		if weaponSystem.module and weaponSystem.viewmodel and (weaponSystem.state ~= weaponSystem.states[4] or weaponSystem.state == weaponSystem.states[1]) then
			weaponSystem.modifiers.IsAiming = false
			PlayerWeaponSystem:setState(weaponSystem.states[1])
		end	
    end
end)

ReplicatedStorage.Shared.Remotes.PlayerDied.OnClientEvent:Connect(function()
	for i, v in pairs(camera:GetDescendants()) do
		if v:IsA("Model") then
			v:Destroy()
			weaponSystem.state = weaponSystem.states[8]
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
		hud.Enabled = false
	end
end)

mouse.Button1Up:Connect(function()
	if weaponSystem.module and weaponSystem.viewmodel then
		if weaponSystem.state ~= weaponSystem.states[4] or weaponSystem.state == weaponSystem.states[1] then
			weaponSystem.modifiers.IsInspecting = false
			weaponSystem.modifiers.IsShooting = false
			playerWeaponSystemData:setState(weaponSystem.states[1])
		end
	end
end)

while wait() do
	if weaponSystem.module and weaponSystem.viewmodel then
		if weaponSystem.state == weaponSystem.states[2] or weaponSystem.modifiers.IsShooting then
			if weaponSystem.module and weaponSystem.module.ammo > 0 and weaponSystem.state ~= weaponSystem.states[7] then
				weaponSystem.animations.FirstPerson[2]:Stop()
				weaponSystem.animations.FirstPerson[5]:Stop()
				weaponSystem.animations.FirstPerson[6]:Stop()
				weaponSystem.animations.FirstPerson[7]:Stop()
				weaponSystem.animations.FirstPerson[8]:Stop()

				if weaponSystem.module.ammo == 1 then
					weaponSystem.animations.FirstPerson[4]:Play()
					weaponSystem.animations.FirstPerson[1]:Stop()

					-- weaponSystem.animations.ThirdPerson[1]:Stop()
				else
					weaponSystem.animations.FirstPerson[4]:Stop()
					-- weaponSystem.animations.ThirdPerson[1]:Play()

					weaponSystem.animations.FirstPerson[1]:Play()
				end

				weaponSystem.module.ammo -= 1

				ReplicatedStorage.Shared.Remotes.Shoot:FireServer()

				if weaponSystem.module.ammo == 0 then
					if weaponSystem.state == weaponSystem.states[1] or weaponSystem.state == weaponSystem.states[2] then 
						task.wait(.4)

						playerWeaponSystemData:setState(weaponSystem.states[3])
						weaponSystem.modifiers.IsInspecting = false
						weaponSystem.modifiers.IsShooting = false
						weaponSystem.modifiers.IsReloading = true
						Reload()
					end
				end


				wait(weaponSystem.module.fireRate)
				PlayerWeaponSystemData:setState(weaponSystem.states[1])
			end
		end
	end
end

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