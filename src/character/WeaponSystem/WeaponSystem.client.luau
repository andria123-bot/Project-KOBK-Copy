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
local RequestWeaponData = ReplicatedStorage.Shared.Remotes.Requests:WaitForChild("RequestWeaponData")
local RequestWeaponSystemData = ReplicatedStorage.Shared.Remotes.Requests:WaitForChild("RequestWeaponSystemData")
local UpdateWeaponStateRemote = ReplicatedStorage.Shared.Remotes:WaitForChild("UpdateWeaponState")
local RequestShoot = ReplicatedStorage.Shared.Remotes.Requests:WaitForChild("RequestShoot")
local RequestReload = ReplicatedStorage.Shared.Remotes.Requests:WaitForChild("RequestReload")
local UpdateClientState = ReplicatedStorage.Shared.Remotes:WaitForChild("UpdateClientState")
local PlayerRespawned = ReplicatedStorage.Shared.Remotes:WaitForChild("PlayerRespawned")
local LoadViewmodel = require(script.Parent.LoadViewmodel)
local ViewmodelRotation = require(script.Parent.ViewmodelRotation)
local Scope = require(script.Parent.Scope)

local SpringModule = require(ReplicatedStorage.Shared.Modules.Spring)

local recoilSpring = SpringModule.new(Vector3.new(0,0,0), 0.5, 50)
recoilSpring.Damping = 5

local viewmodelKickOffset = CFrame.new()
local kickReturnTime = 0

local RequiredWeaponSystem = RequestWeaponSystemData:InvokeServer()
local weaponSystem = RequiredWeaponSystem[1]
local weaponData
local currentAmmo = 0
local currentMaxAmmo = 0

UpdateClientState.OnClientEvent:Connect(function(newState)
    weaponSystem.state = newState
end)

SendInventory.OnClientEvent:Connect(function(savedInventory)
    weaponSystem.inventory = weaponSystem.inventory or {}

    for i = 1, #savedInventory do
        weaponSystem.inventory[i] = savedInventory[i] or ""
    end

    -- print("Inventory synced:", weaponSystem.inventory)
end)

RequestInventory:FireServer()

local dof = game.Lighting.DepthOfField

local bobOffset = CFrame.new()

local AimHelper = require(script.Parent.Aim)
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

local hud = player.PlayerGui:WaitForChild("HUD")

function updateHUD(state, data)
	if hud and data then
		if weaponSystem.viewmodel and weaponSystem.module and isEquipedWeapon then
			if weaponSystem.modifiers.isMelee or weaponSystem.modifiers.isGrenade then
				hud.Enabled = false
			end

			if state == true then
				hud.MainParent.Ammo.Text = data.ammoLeft
				hud.MainParent.MaxAmmo.Text = data.maxAmmo
			else
				hud.Enabled = true
				hud.MainParent.GunName.Text = data.name
				hud.MainParent.Ammo.Text = data.ammoLeft
				hud.MainParent.MaxAmmo.Text = data.maxAmmo
				hud.MainParent.GunIcon.Image = data.imageIconId
				hud.MainParent.GunIcon.ImageColor3 =  Color3.new(0, 0, 0)
				hud.MainParent.FireMode.Text = data.fireMode
				hud.MainParent.AmmoType.Text = data.ammoType
			end
		end
	else
		hud.Enabled = false
	end
end

function loadSlot(Item)
	-- weaponSystem.loadSlot = loadSlot idk wtf is ts
	if weaponSystem.state == weaponSystem.states[1] 
	or weaponSystem.state == weaponSystem.states[3] 
	or weaponSystem.state == weaponSystem.states[4] then
		UpdateWeaponStateRemote:FireServer(weaponSystem.states[7])
		weaponSystem.IsAiming = false
		weaponSystem.IsInspecting = false
		weaponSystem.IsReloading = false
		weaponSystem.IsShooting = false

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
			local readyData = animData.animations
			local animator = weaponSystem.viewmodel.AnimationController.Animator
			local characterAnimator = character.Humanoid.Animator

			ReplicatedStorage.Shared.Remotes.LoadSlot:FireServer(Item)
			weaponData = RequestWeaponData:InvokeServer(Item)

			local firstPersonAnims = {
				{index = 1, name = "Fire", id = readyData.fireAnim},
				{index = 2, name = "Equip", id = readyData.equipAnim},
				{index = 3, name = "Deequip", id = readyData.deequipAnim},
				{index = 4, name = "EmptyFire", id = readyData.emptyFireAnim},
				{index = 5, name = "Reload", id = readyData.reloadAnim},
				{index = 6, name = "EmptyReload", id = readyData.emptyReloadAnim},
				{index = 7, name = "Inspect", id = readyData.inspectAnim},
				{index = 8, name = "Idle", id = readyData.idleAnim}
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

			isEquipedWeapon = true

			updateHUD(false, {
				ammoLeft = weaponData.currentAmmo,
				maxAmmo = weaponData.maxAmmo,
				imageIconId = weaponData.imageIconId,
				fireMode = weaponData.modifiers.fireMode,
				ammoType = weaponData.ammoType,
				name = weaponData.name,
			})

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
					or v.Name == "Muzzle"
					or v.Name == "ScopePos") then
						v.Transparency = 0
					end
				end
			end

			UpdateWeaponStateRemote:FireServer(weaponSystem.states[1])
			aimHelper:Init(weaponData, weaponSystem.viewmodel, weaponSystem)
			ViewmodelRotation:Init(true, weaponSystem.viewmodel)
			Scope:Init(weaponData, weaponSystem)
		end
	end
end

function Shoot()
	if weaponSystem.viewmodel and character then
		if weaponSystem.state == weaponSystem.states[6] then
			return
		end
		print(weaponData.name)
		-- if weaponData.modifiers.fireMode == "Semi Auto" then
		-- 	local success, recoilData, data = RequestShoot:InvokeServer(weaponSystem.inventory[weaponSystem.currentSlot])
		-- 	if success then
		-- 		weaponSystem.animations.FirstPerson[2]:Stop()
		-- 		weaponSystem.animations.FirstPerson[5]:Stop()
		-- 		weaponSystem.animations.FirstPerson[6]:Stop()
		-- 		weaponSystem.animations.FirstPerson[7]:Stop()
		-- 		weaponSystem.animations.FirstPerson[8]:Stop()

		-- 		weaponSystem.animations.ThirdPerson[2]:Stop()
		-- 		weaponSystem.animations.ThirdPerson[4]:Stop()
		-- 		weaponSystem.animations.ThirdPerson[5]:Stop()
		-- 		weaponSystem.animations.ThirdPerson[6]:Stop()

		-- 		local muzzleFlash = game.ReplicatedStorage.Objects.MuzzleFlash:Clone()
		-- 		muzzleFlash.Parent = game.Workspace
		-- 		muzzleFlash.CFrame = weaponSystem.viewmodel.Muzzle.CFrame

		-- 		for i, v in pairs(muzzleFlash:GetChildren()) do
		-- 			if v:IsA("ParticleEmitter") then
		-- 				v:Emit(1)
		-- 			end
		-- 		end

		-- 		game:GetService("Debris"):AddItem(muzzleFlash, .07)

		-- 		camera.CFrame = camera.CFrame * CFrame.Angles(recoilData.x, recoilData.y, recoilData.z)

		-- 		debounce = true
		-- 		wait(data.debounce)
		-- 		debounce = false
		-- 	end
		-- end

		if weaponData.modifiers.fireMode == "Full Auto" then
			if weaponSystem.state == weaponSystem.states[6] then return end
			if weaponSystem.state ~= weaponSystem.states[3] then
				weaponSystem.modifiers.IsShooting = true
				UpdateWeaponStateRemote:FireServer(weaponSystem.states[2])
			end
		end
	end
end

function Inspect()
    if weaponSystem.animations and weaponSystem.viewmodel and weaponData and not weaponSystem.modifiers.IsReloading then
        if weaponSystem.modifiers.IsInspecting then return end
        weaponSystem.modifiers.IsInspecting = true
        
        UpdateWeaponStateRemote:FireServer(weaponSystem.states[4])
        
        weaponSystem.animations.FirstPerson[8]:Stop()
        weaponSystem.animations.FirstPerson[7]:Play()

        dof.FarIntensity = 1
        dof.FocusDistance = 10.44
        dof.InFocusRadius = 25.215
        dof.NearIntensity = 0.183
        weaponSystem.animations.ThirdPerson[6]:Play()
        
        ReplicatedStorage.Shared.Remotes.ItemFoley:FireServer(script.Parent.Parent:WaitForChild("UpperTorso"):WaitForChild("Inspect"))
        
        repeat task.wait() until weaponSystem.animations.FirstPerson[7].IsPlaying == false

        weaponSystem.animations.FirstPerson[7]:Stop()
        dof.FarIntensity = .1
        dof.FocusDistance = .05
        dof.InFocusRadius = 30
        dof.NearIntensity = .75

        weaponSystem.modifiers.IsInspecting = false
        
        -- ONLY set to Idle if we're not reloading or shooting
        if not weaponSystem.modifiers.isReloading and not weaponSystem.modifiers.IsShooting then
            UpdateWeaponStateRemote:FireServer(weaponSystem.states[1])
        end
    end
end

function melee(isLightStab) 
	if isLightStab then
		weaponSystem.animations.FirstPerson[1]:Play()
		weaponSystem.animations.ThirdPerson[1]:Play()
	else
		weaponSystem.animations.FirstPerson[4]:Play()
		weaponSystem.animations.ThirdPerson[5]:Play()
	end

	ReplicatedStorage.Shared.Remotes.Melee:FireServer(isLightStab, weaponData, camera.CFrame.Position, camera.CFrame.LookVector)
end

function Reload()
    if currentAmmo >= currentMaxAmmo then
        return
    end
    if weaponSystem.modifiers.IsAiming then
        weaponSystem.modifiers.IsAiming = false
        UpdateWeaponStateRemote:FireServer(weaponSystem.states[1])
        camera.FieldOfView = 70
        if weaponData and weaponData.aimData then
            weaponData.aimData.aimCF = CFrame.new()
        end
    end

    weaponSystem.modifiers.isReloading = true
    UpdateWeaponStateRemote:FireServer(weaponSystem.states[3])

    if weaponSystem.modifiers.IsInspecting then
        if weaponSystem.animations.FirstPerson[7] then
            weaponSystem.animations.FirstPerson[7]:Stop()
        end
        weaponSystem.modifiers.IsInspecting = false
    end
    
    local gun = weaponSystem.inventory[weaponSystem.currentSlot]

    if currentAmmo == 0 then
        weaponSystem.animations.FirstPerson[6]:Play()
        wait(weaponData.reloadTime)
    else
        weaponSystem.animations.FirstPerson[5]:Play()
        wait(weaponData.reloadTime)
    end
    
    local success, data = RequestReload:InvokeServer(gun)
    if success then
        currentAmmo = data.ammoLeft
        currentMaxAmmo = data.maxAmmo
        updateHUD(true, {
            ammoLeft = currentAmmo,
            maxAmmo = currentMaxAmmo
        })
    end
    
    weaponSystem.modifiers.isReloading = false
    UpdateWeaponStateRemote:FireServer(weaponSystem.states[1])
end

local oldCamCF = CFrame.new()

function updateCameraShake()
	local newCamCF = weaponSystem.viewmodel.FakeCamera.CFrame:ToObjectSpace(weaponSystem.viewmodel.PrimaryPart.CFrame)
	camera.CFrame = camera.CFrame * newCamCF:ToObjectSpace(oldCamCF)
	oldCamCF = newCamCF
end

RunService.RenderStepped:Connect(function(dt)
	if humanoid and weaponSystem.viewmodel then
		print(weaponSystem.state) -- Debugging

		if tick() > kickReturnTime and viewmodelKickOffset ~= CFrame.new() then
			viewmodelKickOffset = CFrame.new()
		end

		if weaponSystem.viewmodel and weaponData then
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

			local rotOffset = CFrame.Angles(0, 0, ViewmodelRotation:getRotation(dt, weaponSystem.state))

			for _, v in pairs(camera:GetChildren()) do -- apply things to viewmodel
				if v:IsA("Model") then
					v:SetPrimaryPartCFrame(camera.CFrame * weaponData.aimData.swayCF * weaponData.aimData.aimCF * bobOffset * rotOffset * viewmodelKickOffset)
					updateCameraShake()

					if weaponSystem.animations and weaponSystem.viewmodel then
						if not weaponSystem.modifiers.isMelee then
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
			if weaponSystem.currentSlot ~= 1 and weaponSystem.state ~= weaponSystem.states[3] and weaponSystem.state ~= weaponSystem.states[8] then
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

		-- if input.KeyCode == Enum.KeyCode.Four then
		-- 	if weaponSystem.currentSlot ~= 4 and weaponSystem.state ~= weaponSystem.states[3] then
		-- 		if weaponSystem.inventory[4] ~= "Empty" then
		-- 			loadSlot(weaponSystem.inventory[4])
		-- 			weaponSystem.currentSlot = 4
		-- 			isEquipedWeapon = true
		-- 		end
		-- 	end
		-- end

		-- if input.KeyCode == Enum.KeyCode.Five then
		-- 	if weaponSystem.currentSlot ~= 5 and weaponSystem.state ~= weaponSystem.states[3] then
		-- 		if weaponSystem.inventory[5] ~= "Empty" then
		-- 			loadSlot(weaponSystem.inventory[5])
		-- 			weaponSystem.currentSlot = 5
		-- 			isEquipedWeapon = true
		-- 		end
		-- 	end
		-- end

		-- if input.KeyCode == Enum.KeyCode.Six then
		-- 	if weaponSystem.currentSlot ~= 6 and weaponSystem.state ~= weaponSystem.states[3] then
		-- 		if weaponSystem.inventory[6] ~= "Empty" then
		-- 			loadSlot(weaponSystem.inventory[6])
		-- 			weaponSystem.currentSlot = 6
		-- 			isEquipedWeapon = true
		-- 		end
		-- 	end
		-- end

		-- if input.KeyCode == Enum.KeyCode.Seven and weaponSystem.state ~= weaponSystem.states[3] then
		-- 	if weaponSystem.currentSlot ~= 7 then
		-- 		if weaponSystem.inventory[7] ~= "Empty" then
		-- 			loadSlot(weaponSystem.inventory[7])
		-- 			weaponSystem.currentSlot = 7
		-- 			isEquipedWeapon = true
		-- 		end
		-- 	end
		-- end

		-- if input.KeyCode == Enum.KeyCode.Eight then
		-- 	if weaponSystem.currentSlot ~= 8 and weaponSystem.state ~= weaponSystem.states[3] then
		-- 		if weaponSystem.inventory[8] ~= "Empty" then
		-- 			loadSlot(weaponSystem.inventory[8])
		-- 			weaponSystem.currentSlot = 8
		-- 			isEquipedWeapon = true
		-- 		end
		-- 	end
		-- end
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		if character and weaponSystem.viewmodel 
		and weaponSystem.state ~= weaponSystem.states[3] and not weaponSystem.modifiers.isReloading then
			print("Shooting Clicked")
			Shoot()
		end

		if weaponData and weaponSystem.viewmodel and weaponData.modifiers.isMelee and not weaponData.modifiers.isGrenade then
			melee(true)
		end
	end

	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		if weaponData and weaponSystem.viewmodel then
			if weaponSystem.modifiers.isReloading then return end
			if weaponSystem.state ~= weaponSystem.states[6] 
				and weaponSystem.state ~= weaponSystem.states[3] 
				and weaponSystem.state ~= weaponSystem.states[8]
				and weaponSystem.state ~= weaponSystem.states[4] then 
				if not weaponSystem.module.isGrenade and not weaponSystem.module.isMelee then
					if not weaponSystem.modifiers.IsReloading then
						weaponSystem.modifiers.IsAiming = true
						if not weaponSystem.modifiers.IsShooting then
							UpdateWeaponStateRemote:FireServer(weaponSystem.states[5])
						end
					end
				end
			end
		end   

		if weaponData and weaponSystem.viewmodel and weaponData.modifiers.isMelee and not weaponData.modifiers.isMelee then
			melee(false)
		end
	end

	if input.KeyCode == Enum.KeyCode.R then
		if weaponSystem.viewmodel and not weaponData.modifiers.isMelee and not weaponData.modifiers.isGrenade then
			if not weaponSystem.modifiers.IsReloading 
			   and weaponSystem.state ~= weaponSystem.states[2] 
			   and weaponSystem.state ~= weaponSystem.states[3] then
				Reload()
			end
		end
	end

	if input.KeyCode == Enum.KeyCode.T then
		if weaponData and weaponSystem.viewmodel then
			AimHelper:switchAimpart()
		end
	end

	if input.KeyCode == Enum.KeyCode.H then
		if weaponData and weaponSystem.viewmodel
		and weaponSystem.state ~= weaponSystem.states[3] then
			UpdateWeaponStateRemote:FireServer(weaponSystem.states[4])
			Inspect()
		end
	end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        if weaponSystem.viewmodel then
            if weaponSystem.state == weaponSystem.states[6] then return end
            if weaponSystem.state ~= weaponSystem.states[3]
                and weaponSystem.state ~= weaponSystem.states[8] then 
                if weaponData and weaponSystem.viewmodel and not weaponSystem.modifiers.IsReloading then
                    weaponSystem.modifiers.IsAiming = false
                    
	                    if not weaponSystem.modifiers.IsShooting then
                        UpdateWeaponStateRemote:FireServer(weaponSystem.states[1])
                    end
                end   
            end
        end
    end
end)

ReplicatedStorage.Shared.Remotes.PlayerDied.OnClientEvent:Connect(function()
	for _, v in pairs(camera:GetDescendants()) do
		if v:IsA("Model") then
			v:Destroy()
		end
	end

	UpdateWeaponStateRemote:FireServer(weaponSystem.states[8])
	
	for _, v in pairs(game.ReplicatedStorage.Shared.Modules:GetDescendants()) do
		if v:IsA("ModuleScript") and v.Name ~= "FastCastRedux" and v.Name ~= "ActiveSignal" and v.Name ~= "Signal" and v.Name ~= "Table" and v.Name ~= "TypeDefinitions"  and v.Name ~= "TypeMarshaller" and v.Name ~= "Misc" then
			require(v).ammo = require(v).maxAmmo -- should use requestModule
		end
	end

	if weaponSystem.viewmodel and weaponData then
		weaponData = nil
		weaponSystem.viewmodel:Destroy()
		hud.Enabled = false
	end
end)


PlayerRespawned.OnClientEvent:Connect(function()
    UpdateWeaponStateRemote:FireServer(weaponSystem.states[1])
    weaponSystem.modifiers.IsAiming = false
    weaponSystem.modifiers.IsShooting = false
    weaponSystem.modifiers.IsReloading = false
    weaponSystem.modifiers.IsInspecting = false
    
    if weaponSystem.viewmodel then
        weaponSystem.viewmodel:Destroy()
        weaponSystem.viewmodel = nil
    end
    
    weaponData = nil
    isEquipedWeapon = false
    currentAmmo = 0
    currentMaxAmmo = 0
    
    PlayerRespawned:FireServer()
    
    if hud then
        hud.Enabled = false
    end
end)

mouse.Button1Up:Connect(function()
    if weaponSystem.viewmodel and weaponData then
        if weaponSystem.state == weaponSystem.states[6] then return end
        if weaponSystem.state ~= weaponSystem.states[8]
            and weaponSystem.state ~= weaponSystem.states[3] then 
             
            weaponSystem.modifiers.IsShooting = false

            if weaponSystem.modifiers.IsAiming then
                UpdateWeaponStateRemote:FireServer(weaponSystem.states[5])
            else
                UpdateWeaponStateRemote:FireServer(weaponSystem.states[1])   
            end
        end
    end
end)

while wait() do
	if weaponData and weaponSystem.viewmodel and weaponSystem.modifiers.IsShooting then
		local success, recoilData, data = RequestShoot:InvokeServer(weaponSystem.inventory[weaponSystem.currentSlot], camera.CFrame.LookVector, weaponSystem.viewmodel.Muzzle.Position)
		
		if success and recoilData and data then
			weaponSystem.animations.FirstPerson[2]:Stop()
			weaponSystem.animations.FirstPerson[5]:Stop()
			weaponSystem.animations.FirstPerson[6]:Stop()
			weaponSystem.animations.FirstPerson[7]:Stop()
			weaponSystem.animations.FirstPerson[8]:Stop()
			weaponSystem.animations.ThirdPerson[2]:Stop()
			weaponSystem.animations.ThirdPerson[4]:Stop()
			weaponSystem.animations.ThirdPerson[5]:Stop()
			weaponSystem.animations.ThirdPerson[6]:Stop()

			local muzzleFlash = game.ReplicatedStorage.Objects.MuzzleFlash:Clone()
			muzzleFlash.Parent = game.Workspace
			muzzleFlash.CFrame = weaponSystem.viewmodel.Muzzle.CFrame
			for i, v in pairs(muzzleFlash:GetDescendants()) do
				if v:IsA("ParticleEmitter") then
					v:Emit(1)
				elseif v:IsA("Light") then
					v.Enabled = true
					task.delay(0.07, function()
						v.Enabled = false
					end)
				end
			end
			game:GetService("Debris"):AddItem(muzzleFlash, 1)

			viewmodelKickOffset = CFrame.new(0, 0, 0.2)
			kickReturnTime = tick() + 0.08
			task.spawn(function()
				task.wait(0.08)
				viewmodelKickOffset = CFrame.new()
			end)

			if SpringModule then
				local hugeRecoil = Vector3.new(math.random(-1, 1), .8, -.45)
				recoilSpring:Impulse(hugeRecoil * 2000000)
				camera.CFrame = camera.CFrame * CFrame.Angles(math.rad(recoilData.rx), math.rad(recoilData.ry), math.rad(recoilData.rz))
			end

			currentAmmo = data.ammoLeft
			currentMaxAmmo = data.maxAmmo
			updateHUD(true, {
				ammoLeft = currentAmmo,
				maxAmmo = currentMaxAmmo,
			})

			if data.isLastBullet then
				weaponSystem.animations.FirstPerson[1]:Stop()
				weaponSystem.animations.ThirdPerson[1]:Stop()
				weaponSystem.animations.FirstPerson[4]:Play()
			else
				weaponSystem.animations.FirstPerson[1]:Stop()
				weaponSystem.animations.FirstPerson[1]:Play()
				weaponSystem.animations.ThirdPerson[1]:Play()
			end

			if data.ammoLeft == 0 then
				weaponSystem.modifiers.IsShooting = false
				wait(.4)
				Reload()
			end

			wait(data.fireRate)
		end
	end
end