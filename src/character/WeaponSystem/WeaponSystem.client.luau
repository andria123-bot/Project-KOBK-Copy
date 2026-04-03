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

local LoadViewmodel = require(script.Parent.LoadViewmodel)
local PlayerWeaponSystem = require(script.Parent.PlayerWeaponSystemData)
local ViewmodelRotation = require(script.Parent.ViewmodelRotation)
local GrenadeFunc = require(script.Parent.Grenade)

local playerWeaponSystemData = PlayerWeaponSystem
local weaponSystem = PlayerWeaponSystem.weaponSystem -- player module

local SpringModule = require(ReplicatedStorage.Shared.Modules.Spring)

local recoilSpring = SpringModule.new(Vector3.new(0,0,0), 0.5, 50)
recoilSpring.Damping = 5

local weaponData

SendInventory.OnClientEvent:Connect(function(savedInventory)
    weaponSystem.inventory = weaponSystem.inventory or {}

    for i = 1, #savedInventory do
        weaponSystem.inventory[i] = savedInventory[i] or ""
    end

    print("Inventory synced:", weaponSystem.inventory)
end)

RequestInventory:FireServer()

local dof = game.Lighting.DepthOfField

local bobOffset = CFrame.new()

local AimHelper = require(script.Parent.Aim)
local PlayerWeaponSystemData = require(script.Parent.PlayerWeaponSystemData)
local aimHelper = AimHelper

local debounce = false

local isEquipedWeapon = false

function stopAllAnims()
	for _, v in pairs(weaponSystem.animations.FirstPerson) do
		if v ~= nil and v.IsPlaying then
			v:Stop()
		end
	end

	for _, v in pairs(weaponSystem.animations.ThirdPerson) do
		if v ~= nil and v.IsPlaying then
			v:Stop()
		end
	end
end

function loadSlot(Item)
	weaponSystem.loadSlot = loadSlot
	if weaponSystem.state == weaponSystem.states[1] 
	or weaponSystem.state == weaponSystem.states[3] 
	or weaponSystem.state == weaponSystem.states[4] then
		PlayerWeaponSystemData:setState(weaponSystem.states[7])

		weaponSystem.modifiers.IsAiming = false
		weaponSystem.modifiers.IsInspecting = false
		weaponSystem.modifiers.IsReloading = false
		weaponSystem.modifiers.IsShooting = false

		if player.Character:FindFirstChild("IdleAnim") then 
			weaponSystem.animations.ThirdPerson[7]:Destroy()
			weaponSystem.animations.FirstPerson[3]:Play()
			player.Character.IdleAnim:Destroy()
		end

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

		weaponSystem.viewmodel = LoadViewmodel.GetViewmodel(Item):Clone()
		weaponSystem.viewmodel.Parent = camera

		if weaponSystem.viewmodel then
			local animData = RequestWeaponData:InvokeServer(Item)
			local animator = weaponSystem.viewmodel.AnimationController.Animator
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
				animation.Parent = weaponSystem.viewmodel
				animation.Name = anim.name
				animation.AnimationId = anim.id
				weaponSystem.animations.FirstPerson[anim.index] = animator:LoadAnimation(animation)
			end

			for _, anim in ipairs(thirdPersonAnims) do
				local animation = Instance.new("Animation")
				animation.Parent = player.Character
				animation.Name = anim.name
				animation.AnimationId = anim.id
				weaponSystem.animations.ThirdPerson[anim.index] = characterAnimator:LoadAnimation(animation)
			end

			weaponSystem.animations.ThirdPerson[7]:Play()
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

			for _, v in pairs(weaponSystem.viewmodel:GetDescendants()) do
				if v:IsA("Part") or v:IsA("BasePart") or v:IsA("MeshPart") then
					v.Transparency = 1
				end
			end

			weaponSystem.animations.FirstPerson[2]:Play()
			weaponSystem.animations.ThirdPerson[2]:Play()

			ReplicatedStorage.Shared.Remotes.ItemFoley:FireServer(script.Parent.Parent:WaitForChild("UpperTorso"):WaitForChild("Deequip"))

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

			PlayerWeaponSystemData:setState(weaponSystem.states[1])
			aimHelper:Init(weaponData.aimData, weaponSystem.viewmodel)

			ViewmodelRotation:Init(true, weaponSystem.viewmodel)
		end
	end
end

function Shoot()
	if weaponSystem.viewmodel and character then
		if weaponData.modifiers.fireMode == "Semi Auto" then
			weaponSystem.animations.FirstPerson[2]:Stop()
			weaponSystem.animations.FirstPerson[5]:Stop()
			weaponSystem.animations.FirstPerson[6]:Stop()
			weaponSystem.animations.FirstPerson[7]:Stop()
			weaponSystem.animations.FirstPerson[8]:Stop()

			weaponSystem.animations.ThirdPerson[2]:Stop()
			weaponSystem.animations.ThirdPerson[4]:Stop()
			weaponSystem.animations.ThirdPerson[5]:Stop()
			weaponSystem.animations.ThirdPerson[6]:Stop()

			-- local muzzleFlash = game.ReplicatedStorage.Objects.MuzzleFlash:Clone()
			-- muzzleFlash.Parent = game.Workspace
			-- muzzleFlash.CFrame = weaponSystem.viewmodel.Muzzle.CFrame

			-- for i, v in pairs(muzzleFlash:GetChildren()) do
			-- 	if v:IsA("ParticleEmitter") then
			-- 		v:Emit(1)
			-- 	end
			-- end

			ReplicatedStorage.Shared.Remotes.Shoot:FireServer(weaponSystem.viewmodel.Muzzle.Position, camera.CFrame.LookVector, weaponSystem.inventory[weaponSystem.currentSlot], weaponSystem.viewmodel:FindFirstChild("Muzzle").CFrame)
			ReplicatedStorage.Shared.Remotes.ItemFoley:FireServer(script.Parent.Parent:WaitForChild("UpperTorso"):WaitForChild("Shoot"))

		end

		if weaponData.modifiers.fireMode == "Full Auto" then
			weaponSystem.modifiers.IsShooting = true
			PlayerWeaponSystemData:setState(weaponSystem.states[2])
		end
	end
end

function Inspect()
	if weaponSystem.animations and weaponSystem.viewmodel and weaponSystem.module and not weaponSystem.modifiers.IsReloading then
		PlayerWeaponSystemData:setState(weaponSystem.states[4])
		weaponSystem.modifiers.IsInspecting = true
		if weaponSystem.state == weaponSystem.states[4] and weaponSystem.modifiers.IsInspecting then 
			weaponSystem.animations.FirstPerson[8]:Stop()
			weaponSystem.animations.FirstPerson[7]:Play()

			dof.FarIntensity = 1
			dof.FocusDistance = 10.44
			dof.InFocusRadius = 25.215
			dof.NearIntensity = 0.183
			weaponSystem.animations.FirstPerson[7]:Play()
			weaponSystem.animations.ThirdPerson[6]:Play()
			
			ReplicatedStorage.Shared.Remotes.ItemFoley:FireServer(script.Parent.Parent:WaitForChild("UpperTorso"):WaitForChild("Inspect"))
			repeat task.wait() until weaponSystem.animations.FirstPerson[7].IsPlaying == false

			weaponSystem.animations.FirstPerson[7]:Stop()
			dof.FarIntensity = .1
			dof.FocusDistance = .05
			dof.InFocusRadius = 30
			dof.NearIntensity = .75

			if weaponSystem.state == weaponSystem.states[4] then
				weaponSystem.modifiers.IsInspecting = false
				PlayerWeaponSystemData:setState(weaponSystem.states[1])
			end
		end
	end	
end

function grenade(grenade)
	repeat task.wait() until weaponSystem.animations.FirstPerson[1].isPlaying == true

	local grenadeThrown = false

	weaponSystem.animations.FirstPerson[1]:GetMarkerReachedSignal("GremadeThrow"):Connect(function()

		if not grenadeThrown then
			camera:FindFirstChildWhichIsA("Model").Grenade.Transparency = 1

			game.ReplicatedStorage.Remotes.Main.Grenade:FireServer(grenade, camera:FindFirstChildWhichIsA("Model").Grenade.Position, camera.CFrame.LookVector, weaponSystem.module.sounds[2], 1)
			
			grenadeThrown = true
		end
	end)

	weaponSystem.animations.FirstPerson[1].Ended:Connect(function()
		weaponSystem.inventory[weaponSystem.currentSlot] = "Nil"
		weaponSystem.currentSlot = 1
		loadSlot(weaponSystem.inventory[weaponSystem.currentSlot])
	end)
end

function melee(isLightStab) 
	if isLightStab then
		weaponSystem.animations.FirstPerson[1]:Play()
		weaponSystem.animations.ThirdPerson[1]:Play()
	else
		weaponSystem.animations.FirstPerson[4]:Play()
		weaponSystem.animations.ThirdPerson[5]:Play()
	end

	ReplicatedStorage.Shared.Remotes.Melee:FireServer(isLightStab, weaponSystem.module, camera.CFrame.Position, camera.CFrame.LookVector)
end

function Reload()
	if weaponSystem.module and weaponSystem.viewmodel and not weaponSystem.modifiers.IsShooting then 
		if weaponSystem.modifiers.IsReloading then return end

		if weaponSystem.module.ammo < weaponSystem.module.maxAmmo then
			weaponSystem.modifiers.IsReloading = true
			PlayerWeaponSystemData:setState(weaponSystem.states[3])

			weaponSystem.modifiers.IsInspecting = false
			-- camera.FieldOfView = camera.FieldOfView + (defaultFOV - camera.FieldOfView) * 0.1

			weaponSystem.animations.FirstPerson[2]:Stop()
			weaponSystem.animations.FirstPerson[5]:Stop()
			weaponSystem.animations.ThirdPerson[4]:Stop()
			weaponSystem.animations.FirstPerson[6]:Stop()
			weaponSystem.animations.FirstPerson[7]:Stop()
			weaponSystem.animations.ThirdPerson[7]:Stop()
			weaponSystem.animations.FirstPerson[8]:Stop()

			if weaponSystem.module.ammo > 0 then
				weaponSystem.animations.FirstPerson[5]:Play()
				weaponSystem.animations.ThirdPerson[4]:Play()
				ReplicatedStorage.Shared.Remotes.ItemFoley:FireServer(script.Parent.Parent:WaitForChild("UpperTorso"):WaitForChild("Reload"))
			else
				weaponSystem.animations.FirstPerson[6]:Play()
				weaponSystem.animations.ThirdPerson[5]:Play()
				ReplicatedStorage.Shared.Remotes.ItemFoley:FireServer(script.Parent.Parent:WaitForChild("UpperTorso"):WaitForChild("EmptyReload"))
			end

			local i = 0

			while i < weaponSystem.module.reloadTime do
				if weaponSystem.modifiers.IsShooting then
					weaponSystem.modifiers.IsReloading = false
					PlayerWeaponSystemData:setState(weaponSystem.states[2])
					return
				end

				task.wait(0.05)
				i = i + 0.05
			end
			
			weaponSystem.module.ammo = weaponSystem.module.maxAmmo
			weaponSystem.modifiers.IsReloading = false
			PlayerWeaponSystemData:setState(weaponSystem.states[1])
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
	if humanoid and weaponSystem.viewmodel then

		if hud then
			if weaponSystem.viewmodel and weaponSystem.module and isEquipedWeapon then
				if weaponSystem.module.isMelee or weaponSystem.module.isGrenade then
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
		-- print(weaponData) -- Debugging

		if weaponSystem.viewmodel and weaponData then
			local rot = camera.CFrame:ToObjectSpace(weaponData.aimData.lastCameraCF)
			local X, Y, _ = rot:ToOrientation() 
			weaponData.aimData.swayCF = weaponData.aimData.swayCF:Lerp(CFrame.Angles(math.sin(X) * weaponData.aimData.currentSwayAMT, math.sin(Y) * weaponData.aimData.currentSwayAMT, 0), 1 - 0.001 ^ dt)
			weaponData.aimData.lastCameraCF = camera.CFrame

			if weaponSystem.viewmodel then
				if humanoid.MoveDirection.Magnitude > 0 then
					if humanoid.WalkSpeed == 16 then
						bobOffset = bobOffset:Lerp(CFrame.new(math.cos(tick() * 8) * .02, -humanoid.CameraOffset.Y / 7, -humanoid.CameraOffset.Z / 3) * CFrame.Angles(0, math.cos(tick() * -0) * -.0, math.sin(tick() * -4) * .01), 1 - 0.001 ^ dt)
					elseif humanoid.WalkSpeed == 22 then
						bobOffset = bobOffset:Lerp(CFrame.new(math.cos(tick() * 10) * .1, -humanoid.CameraOffset.Y / 3, -humanoid.CameraOffset.Z / 3) * CFrame.Angles(0, math.cos(tick() * -8) * -.1, math.sin(tick() * -8) * .1) * (weaponData.aimData.sprintCF or CFrame.new()), 1 - 0.001 ^ dt)
					end
				else
					bobOffset = bobOffset:Lerp(CFrame.new(0, -humanoid.CameraOffset.Y / 3, 0), 1 - 0.001 ^ dt)
				end
			end

			local rotOffset = CFrame.Angles(0, 0, ViewmodelRotation:getRotation(dt, weaponSystem.state))

			for _, v in pairs(camera:GetChildren()) do -- apply things to viewmodel
				if v:IsA("Model") then
					v:SetPrimaryPartCFrame(camera.CFrame * weaponData.aimData.swayCF * weaponData.aimData.aimCF * bobOffset * rotOffset)
					updateCameraShake()

					if weaponSystem.animations and weaponSystem.viewmodel then
						if not weaponData.isMelee then
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
				if weaponSystem.inventory[1] ~= "Empty" then
					loadSlot(weaponSystem.inventory[1])
					weaponSystem.currentSlot = 1
					isEquipedWeapon = true
				end
			end
		end

		if input.KeyCode == Enum.KeyCode.Two then
			if weaponSystem.currentSlot ~= 2 and weaponSystem.state ~= weaponSystem.states[3] then
				if weaponSystem.inventory[2] ~= "Empty" then
					loadSlot(weaponSystem.inventory[2])
					print(weaponSystem.inventory)
					weaponSystem.currentSlot = 2
					isEquipedWeapon = true
				end
			end
		end

		if input.KeyCode == Enum.KeyCode.Three then
			if weaponSystem.currentSlot ~= 3 and weaponSystem.state ~= weaponSystem.states[3] then
				if weaponSystem.inventory[3] ~= "Empty" then
					loadSlot(weaponSystem.inventory[3])
					weaponSystem.currentSlot = 3
					isEquipedWeapon = true
				end
			end
		end

		if input.KeyCode == Enum.KeyCode.Four then
			if weaponSystem.currentSlot ~= 4 and weaponSystem.state ~= weaponSystem.states[3] then
				if weaponSystem.inventory[4] ~= "Empty" then
					loadSlot(weaponSystem.inventory[4])
					weaponSystem.currentSlot = 4
					isEquipedWeapon = true
				end
			end
		end

		if input.KeyCode == Enum.KeyCode.Five then
			if weaponSystem.currentSlot ~= 5 and weaponSystem.state ~= weaponSystem.states[3] then
				if weaponSystem.inventory[5] ~= "Empty" then
					loadSlot(weaponSystem.inventory[5])
					weaponSystem.currentSlot = 5
					isEquipedWeapon = true
				end
			end
		end

		if input.KeyCode == Enum.KeyCode.Six then
			if weaponSystem.currentSlot ~= 6 and weaponSystem.state ~= weaponSystem.states[3] then
				if weaponSystem.inventory[6] ~= "Empty" then
					loadSlot(weaponSystem.inventory[6])
					weaponSystem.currentSlot = 6
					isEquipedWeapon = true
				end
			end
		end

		if input.KeyCode == Enum.KeyCode.Seven and weaponSystem.state ~= weaponSystem.states[3] then
			if weaponSystem.currentSlot ~= 7 then
				if weaponSystem.inventory[7] ~= "Empty" then
					loadSlot(weaponSystem.inventory[7])
					weaponSystem.currentSlot = 7
					isEquipedWeapon = true
				end
			end
		end

		if input.KeyCode == Enum.KeyCode.Eight then
			if weaponSystem.currentSlot ~= 8 and weaponSystem.state ~= weaponSystem.states[3] then
				if weaponSystem.inventory[8] ~= "Empty" then
					loadSlot(weaponSystem.inventory[8])
					weaponSystem.currentSlot = 8
					isEquipedWeapon = true
				end
			end
		end
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		if character and weaponSystem.viewmodel and not debounce then
			if weaponSystem.state ~= weaponSystem.states[6] then
				Shoot()
			end
		end

		if weaponSystem.module and weaponSystem.viewmodel and weaponSystem.module.isMelee and not weaponSystem.module.isGrenade then
			melee(true)
		end
	end

	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		if weaponSystem.module and weaponSystem.viewmodel then
			if weaponSystem.state ~= weaponSystem.states[6] then
				if not weaponSystem.module.isGrenade and not weaponSystem.module.isMelee then
					if not weaponSystem.modifiers.IsReloading then
						weaponSystem.modifiers.IsAiming = true
						PlayerWeaponSystemData:setState(PlayerWeaponSystemData.weaponSystem.states[5])
					end
				end
			end
		end	

		if weaponSystem.module and weaponSystem.viewmodel and weaponSystem.module.isMelee and not weaponSystem.module.isGrenade then
			melee(false)
		end
	end

	if input.KeyCode == Enum.KeyCode.R then
		if weaponSystem.module and weaponSystem.viewmodel and not weaponSystem.module.isMelee and not weaponSystem.module.isGrenade then
			Reload()
		end
	end

	if input.KeyCode == Enum.KeyCode.T then
		if weaponSystem.module and weaponSystem.viewmodel then
			AimHelper:switchAimpart()
		end
	end

	if input.KeyCode == Enum.KeyCode.H then
		if weaponSystem.module and weaponSystem.viewmodel then
			Inspect()
		end
	end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
		if weaponSystem.state ~= weaponSystem.states[6] then
			if weaponSystem.module and weaponSystem.viewmodel and not weaponSystem.modifiers.IsReloading then
				weaponSystem.modifiers.IsAiming = false
				PlayerWeaponSystemData:setState(weaponSystem.states[1])
			end	
		end
    end
end)

ReplicatedStorage.Shared.Remotes.PlayerDied.OnClientEvent:Connect(function()
	for _, v in pairs(camera:GetDescendants()) do
		if v:IsA("Model") then
			v:Destroy()
			weaponSystem.state = weaponSystem.states[8]
		end
	end
	
	for _, v in pairs(game.ReplicatedStorage.Shared.Modules:GetDescendants()) do
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
	if weaponSystem.viewmodel then
		if weaponSystem.state ~= weaponSystem.states[6] then
			weaponSystem.modifiers.IsShooting = false

			if weaponSystem.modifiers.IsAiming then
				PlayerWeaponSystemData:setState(PlayerWeaponSystemData.weaponSystem.states[5])
			else
				PlayerWeaponSystemData:setState(PlayerWeaponSystemData.weaponSystem.states[1])
			end
		end
	end
end)

while wait() do
	if weaponData and weaponSystem.viewmodel then
		if weaponSystem.state == weaponSystem.states[2] or weaponSystem.modifiers.IsShooting then
			if weaponSystem.state ~= weaponSystem.states[7] then
				weaponSystem.animations.FirstPerson[2]:Stop()
				weaponSystem.animations.FirstPerson[5]:Stop()
				weaponSystem.animations.FirstPerson[6]:Stop()
				weaponSystem.animations.FirstPerson[7]:Stop()
				weaponSystem.animations.FirstPerson[8]:Stop()

				weaponSystem.animations.ThirdPerson[2]:Stop()
				weaponSystem.animations.ThirdPerson[4]:Stop()
				weaponSystem.animations.ThirdPerson[5]:Stop()
				weaponSystem.animations.ThirdPerson[6]:Stop()

				ReplicatedStorage.Shared.Remotes.Shoot:FireServer(weaponSystem.viewmodel.Muzzle.Position, camera.CFrame.LookVector, weaponSystem.inventory[weaponSystem.currentSlot], weaponSystem.viewmodel:FindFirstChild("Muzzle").CFrame)
				ReplicatedStorage.Shared.Remotes.ItemFoley:FireServer(script.Parent.Parent:WaitForChild("UpperTorso"):WaitForChild("Shoot"))

				wait(.1)
			end
		end
	end
end