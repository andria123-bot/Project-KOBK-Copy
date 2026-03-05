local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remoteManagers = require(ReplicatedStorage.Shared.Remotes.RemoteManagers.RemoteManager)

ReplicatedStorage.Shared.Remotes.LoadSlot.OnServerEvent:Connect(function(player, item)
	if player.Character then
		for i, v in pairs(player.Character:WaitForChild("UpperTorso"):GetChildren()) do
			if v:isA("Sound") then
				v:Destroy()
			end
		end

		local weapons = ReplicatedStorage.Weapons -- flder of weapons to clone to my hand

		for i,v in pairs(player.Character:GetChildren()) do
			if v:IsA("Model") and weapons:FindFirstChild(v.Name) then
				v:Destroy()
			end
		end

		if weapons:FindFirstChild(item) then
			local gun = weapons:FindFirstChild(item):Clone()
			gun.Parent = player.Character

			local joint = Instance.new("Motor6D")
			joint.Parent = gun
			joint.Part0 = player.Character:FindFirstChild("Right Arm")
			joint.Part1 = gun.PrimaryPart
		end
		
		local module

		for i, v in pairs(ReplicatedStorage.Shared.Modules:GetDescendants()) do
            if v:FindFirstChild(item) then
                module = require(v:FindFirstChild(item))
            end
		end	    
		
		local function createSound(name, id, volume)
			local sound = Instance.new("Sound")
			sound.Parent = player.Character.UpperTorso
			sound.Name = name
			sound.SoundId = id
			sound.Volume = volume
		end

		if module then
			createSound("Equip", module.sounds[1], 1)
			createSound("Shoot", module.sounds[2], 1)
			createSound("Reload", module.sounds[3], 1)
			createSound("EmptyReload", module.sounds[4], 1)
			createSound("Inspect", module.sounds[5], 1)
			createSound("Deequip", module.sounds[6], 1)
		end
	end
end)

game.Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		character:FindFirstChild("Humanoid").Died:Connect(function()
			if character.PrimaryPart:FindFirstChild("Owner") and character.PrimaryPart:FindFirstChild("Owner").Value ~= nil then
				if character.PrimaryPart:FindFirstChild("Assist") and character.PrimaryPart:FindFirstChild("Assist").Value ~= nil then
					ReplicatedStorage.Shared.Remotes.Killed:FireAllClients(player.DisplayName, (character.PrimaryPart.Owner.Value).DisplayName, character.PrimaryPart.Assist.Value.Name)
				else
					ReplicatedStorage.Shared.Remotes.Killed:FireAllClients(player.DisplayName, (character.PrimaryPart.Owner.Value).DisplayName, nil)
				end
				local owner = character.PrimaryPart.Owner.Value

				if owner ~= nil then
					for i, v in pairs(owner:GetChildren()) do
						if v.Name == "leaderstats" then
							v.Kills.Value += 1
							break						
						end
					end
				end
			else
				ReplicatedStorage.Shared.Remotes.Killed:FireAllClients(player.Name, nil, nil)
				-- Died Not killed
			end
			
			if character.PrimaryPart:FindFirstChild("Assist") then
				local assist = character.PrimaryPart.Assist.Value
				
				if assist ~= nil then
					for i, v in pairs(assist:GetChildren()) do
						if v.Name == "leaderstats" then
							v.assist.Value += 1
							break						
						end
					end
				end
			end
			
			ReplicatedStorage.Shared.Remotes.PlayerDied:FireClient(player)
		end)

		wait(.1)

		local forceField = character:FindFirstChild("ForceField")

		if forceField then
			forceField:Destroy()
		end
	end)
end)

ReplicatedStorage.Shared.Remotes.Shoot.OnServerEvent:Connect(function(player, MuzzlePos, lookPos, damage, headshot, item, muzzleCF)
	if player.Character then
		local sound = player.Character:WaitForChild("UpperTorso"):FindFirstChild("Shoot")
		if sound then
			sound:Play()
		end
		
		for i, v in pairs(ReplicatedStorage.Modules:GetDescendants()) do
			if v:IsA("ModuleScript") and v.Name == item then
				require(v):Fire(player, player.Character, MuzzlePos, lookPos, 1000, muzzleCF)
			end
		end
	end
end)

ReplicatedStorage.Shared.Remotes.ItemFoley.OnServerEvent:Connect(function(player, sound)
	local UpperTorso = player.Character:WaitForChild("UpperTorso")
	
	for i, v in pairs(UpperTorso:GetDescendants()) do
		if v:IsA("Sound") then
			if v.Name == tostring(sound) then
				v:Play()
			end
		end
	end
end)

ReplicatedStorage.Shared.Remotes.Melee.OnServerEvent:Connect(function(player, lightStab, damage, criticalDamage, origin, direction)
	local character = player.Character
	
	local sound = player.Character:WaitForChild("UpperTorso"):FindFirstChild("Shoot")

	if sound then
		sound:Play()
	end

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = {character}

	local ray = workspace:Raycast(origin, direction * 5, raycastParams)

	if ray then
		local hit = ray.Instance

		if hit then
			if hit.Parent:FindFirstChildWhichIsA("Humanoid") then
				if lightStab then
					hit.Parent.Humanoid:TakeDamage(damage)
				else
					hit.Parent.Humanoid:TakeDamage(criticalDamage)
				end
				
				local sound = Instance.new("Sound")
				sound.Parent = hit
				sound.SoundId = require(ReplicatedStorage.Modules.Misc).HumanImpactSound
				sound.Volume = 1
				sound:Play()
				
				game:GetService("Debris"):AddItem(sound, 10)
			else
				local bulletHole = game.ReplicatedStorage.Objects.BulletHole:Clone()
				bulletHole.CFrame = CFrame.new(ray.Position, ray.Position + ray.Normal)
				
				local bulletHolesFolder = Instance.new("Folder")
				bulletHolesFolder.Parent = game.Workspace
				bulletHolesFolder.Name = "BulletHolesFolder"
				
				if game.Workspace:FindFirstChild("BulletHole") then
					if game.Workspace:FindFirstChild("bulletHolesFolder") then
						bulletHole.Parent = bulletHolesFolder
					end
				end
				
				bulletHole.Impact:Play()

				game:GetService("Debris"):AddItem(bulletHole, 15)
			end
		end
	end
end)

ReplicatedStorage.Shared.Remotes.Grenade.OnServerEvent:Connect(function(player, grenadeType, origin, direction, id, volume)
	local grenade = game.ReplicatedStorage:FindFirstChild(grenadeType)
	
	if grenade then
		grenade = grenade:Clone()
		grenade.Parent = game.Workspace
		grenade:SetNetworkOwner(player)
		grenade.CFrame = CFrame.new(origin, direction) * CFrame.new(0, 0, 2)
		grenade.Velocity = direction * 250
		
		task.wait(5)
		
		local grenadeNoise = Instance.new("Part")
		grenadeNoise.Parent = game.Workspace
		grenadeNoise.Name = "GrenadeNoise"
		grenadeNoise.Anchored = true
		grenadeNoise.Transparency = 1
		grenadeNoise.CFrame = grenade.CFrame
		
		local sound = Instance.new("Sound")
		sound.Parent = grenadeNoise
		sound.SoundId = id
		sound.Volume = volume
		sound:Play()
		
		local explosion = Instance.new("Explosion")
		explosion.Position = grenade.Position
		explosion.BlastRadius = 35
		explosion.Parent = grenade
		
		game:GetService("Debris"):AddItem(grenade, 10)
		game:GetService("Debris"):AddItem(grenadeNoise, 10)
	end
end)