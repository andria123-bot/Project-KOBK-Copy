local data = {
	name = "HK416",

	fireAnim = "rbxassetid://95024054063945",
	emptyFireAnim = "rbxassetid://88699433754390", -- 88699433754390
	equipAnim = "rbxassetid://133514477466822",
	deequipAnim = "rbxassetid://96095541989669",
	reloadAnim = "rbxassetid://98970778537699",
	emptyReloadAnim = "rbxassetid://86389481538214",
	inspectAnim = "rbxassetid://80262626757998",
	idleAnim = "rbxassetid://90962731439428",

	tpIdleAnim = "rbxassetid://131819337932852",
	tpShootAnim = "rbxassetid://131819337932852",
	tpReloadAnim = "rbxassetid://131819337932852",
	tpEmptyReloadAnim = "rbxassetid://131819337932852",
	tpInspectAnim = "rbxassetid://131819337932852",
	tpEquipAnim = "rbxassetid://131819337932852",
	tpDeequipAnim = "rbxassetid://131819337932852",

	sounds = {
		"rbxassetid://127619339252879"; -- equip/draw
		"rbxassetid://79126872857479" ; -- Shoot/use
		"rbxassetid://134817048219417"; -- reload
		"rbxassetid://134817048219417"; -- empty reload
		"rbxassetid://127619339252879"; -- inspect
		"rbxassetid://127619339252879"; -- deequip/holster

		attachmentSounds = {
			"rbxassetid://17589930440" -- Suppressor
		}
	};

	imageIconId = "rbxassetid://129066793868859",

	canAim = true,
	aimSmooth = .00025,
	canSemi = true,
	canFullAuto = true,
	ammo = 30,        
	maxAmmo = 30,
	fireMode = "Full Auto",

	fireRate = 0.085, 

	sprintCF = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-95/5), math.rad(95/4), math.rad(95/5));

	aimCF = CFrame.new(),
	currentSwayAMT = -.4,
	swayAMT = -.3,
	aimSwayAMT = .5,
	swayCF = CFrame.new(0, 0, 0),
	lastCameraCF = CFrame.new(0, 0, 0),

	durable = 600,    
	isStackable = false,
	maxStack = 1,

	canPenetrate = true,
	maxDepth = 2.6,
	damageFalloff = 0.75,

	penetrationMaterials = {
		["Wood"] = 0.9,
		["Plastic"] = 1,
		["Glass"] = 1,
		["Metal"] = 0.4,
		["Concrete"] = 0.5,
		["Brick"] = 0.55,
	},

	canAddSight = true,
	canAddLaser = true,
	canAddExtendedMag = true,

	-- Damage
	damage = 30.5,  
	headshot = 70,
	debounce = 0.07,
	reloadTime = 3.7,  
	jamChance = 0.0005,
	value = 5800,
	weight = 3.02, -- kg

	-- Recoil
	x = 1.8,
	y = 0.72,
	z = 1.9;
	
	bulletSpeed = 320,
	bulletDistance = 550,

	slotType = "Loadout",
	ammoType = "5.56x45",
	canBeStored = false,

	isGrenade = false,
	isMelee = false,
	isShootgun = false,
}

local fastcast = require(game.ReplicatedStorage.Modules.FastCastRedux)
local caster = fastcast.new()
fastcast.VisualizeCasts = true

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local casterBehaviour = fastcast.newBehavior()
casterBehaviour.RaycastParams = rayParams
casterBehaviour.AutoIgnoreContainer = true
casterBehaviour.Acceleration = Vector3.new(0, -game.Workspace.Gravity, 0)

function data:Fire(player, character, origin, direction, velocity, muzzleCF)
	rayParams.FilterDescendantsInstances = {character, game.Workspace:FindFirstChild("BulletHoles")}
	
	if data.isShootgun then
		for i = 1, 6, 1 do
			local xOffset = math.random(-10, 10)
			xOffset = xOffset / 50

			local yOffset = math.random(-10, 10)
			yOffset = yOffset / 50

			local zOffset = math.random(-10, 10)
			zOffset = zOffset / 50

			local activeCast = caster:Fire(origin, direction + Vector3.new(xOffset, yOffset, zOffset), velocity, casterBehaviour)
			
			activeCast.UserData["Owner"] = player	
		end
	else
		local activeCast =  caster:Fire(origin, direction, velocity, casterBehaviour)
		activeCast.UserData["Owner"] = player	
		activeCast.UserData["Direction"] = direction.Unit
	end
end

caster.RayHit:Connect(function(activeCast, result)
	local hit = result.Instance
	local mat = hit.Material
	local allowedDepth = data.penetrationMaterials[mat.Name]
	
	if hit and hit.Parent:FindFirstChild("Humanoid") then
		local humanoid = hit.Parent:FindFirstChild("Humanoid")
		local owner = activeCast.UserData.Owner
		
		if hit.Parent.PrimaryPart:FindFirstChild("Owner") then
			if owner == hit.Parent.PrimaryPart.Owner.Value then
				hit.Parent.PrimaryPart.Owner.Value = owner
			else
				hit.Parent.PrimaryPart.Assist.Value = hit.Parent.PrimaryPart.Owner.Value
				hit.Parent.PrimaryPart.Owner.Value = owner
			end
		else		
			local ownerTag = Instance.new("ObjectValue", hit.Parent.PrimaryPart)
			ownerTag.Name = "Owner"
			ownerTag.Value = owner

			local assistTag = Instance.new("ObjectValue", hit.Parent.PrimaryPart)
			assistTag.Name = "Assist"
			assistTag.Value = nil
		end

		if hit.Name == "Head" then
			humanoid:TakeDamage(data.headshot)
		else
			humanoid:TakeDamage(data.damage)
		end

		local bulletHole = game.ReplicatedStorage.Objects.BulletHole:Clone()
		bulletHole.CFrame = CFrame.new(result.Position, result.Position + result.Normal)

		local bulletHolesFolder = workspace:FindFirstChild("BulletHoles")
		if not bulletHolesFolder then
			bulletHolesFolder = Instance.new("Folder")
			bulletHolesFolder.Name = "BulletHoles"
			bulletHolesFolder.Parent = workspace
		end

		bulletHole.Parent = bulletHolesFolder
		bulletHole.Impact:Play()
		game:GetService("Debris"):AddItem(bulletHole, 15)
	elseif hit then -- wallbang
		local origin = result.Position
		local direction = activeCast.UserData["Direction"].Unit
		local material = hit.Material.Name
		local penetrationLimit = data.penetrationMaterials[material]
		
		local insideWallRayCast = workspace:Raycast(origin, direction * penetrationLimit, rayParams)
		
		if insideWallRayCast then
			print("Pierced")
		else
			print("Not Pierced")
		end
	end
end)

return data