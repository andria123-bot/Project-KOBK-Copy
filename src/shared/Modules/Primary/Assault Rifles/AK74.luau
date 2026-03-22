local data = {
	name = "AR15",
	
	fireAnim = "rbxassetid://138696896875898",
	emptyFireAnim = "rbxassetid://95185641654916",
	equipAnim = "rbxassetid://117019852871783",
	deequipAnim = "rbxassetid://104609114979469",
	reloadAnim = "rbxassetid://104555090232424",
	emptyReloadAnim = "rbxassetid://104555090232424",
	inspectAnim = "rbxassetid://138303612553510",
	idleAnim = "rbxassetid://131819337932852",

	tpIdleAnim = "rbxassetid://131819337932852",
	tpShootAnim = "rbxassetid://131819337932852",
	tpReloadAnim = "rbxassetid://131819337932852",
	tpEmptyReloadAnim = 'rbxassetid://131819337932852',
	tpInspectAnim = "rbxassetid://131819337932852",
	tpEquipAnim = "rbxassetid://131819337932852",
	tpDeequipAnim = "rbxassetid://131819337932852",
	
	sounds = {
		"rbxassetid://127619339252879"; -- equip/draw
		"rbxassetid://18335135825"    ; -- Shoot/use
		"rbxassetid://134817048219417"; -- reload
		"rbxassetid://134817048219417"; -- empty reload
		"rbxassetid://127619339252879"; -- inspect
		"rbxassetid://127619339252879"; -- deequip/holster
		--"rbxassetid://6812913751"     ; -- emptyFire
		
		attachmentSounds = {
			"rbxassetid://17589930440" -- Suppresor
			
		}
	};
	
	imageIconId = "rbxassetid://83047383316925",
	
	canAim = true,
	aimSmooth = .00025,
	canSemi = true,
	canFullAuto = true,
	ammo = 30,
	maxAmmo = 30,
	fireMode = "Full Auto",

	fireRate = .08,

	sprintCF = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-95/5), math.rad(95/4), math.rad(95/5));

	durable = 560,
	isStackable = false,
	maxStack = 1,

	--Piercing
	canPenetrate = true,
	maxDepth = 2.8,
	damageFalloff = 0.7,

	-- Can Add Attachments
	canAddSight = true,
	canAddLaser = true,
	canAddExtendedMag = true,

	damage = 33.3,
	headshot = 80,
	debounce = 0.065,
	reloadTime = 2.9,
	jamChance = 0.015,
	value = 6000,

	-- Recoil
	x = 1.4,
	y = 0.1,

	-- Spread
	hipfire = 2.8,
	aimed = 0.5,
	increasePerShot = 0.3,
	maxSpread = 5.5,
	bulletSpeed = 310,
	bulletDistance = 500,

	slotType = "Loadout",
	ammoType = "5.56x45",
	canBeStored = false,
	
	isGranade = false,
	isMelee = false,
	isShootgun = false,
}

local fastcast = require(game.ReplicatedStorage.Modules.FastCastRedux)
local caster = fastcast.new()
fastcast.VisualizeCasts = false

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
			print("ISShootgun")
			local xOffset = math.random(-10, 10)
			xOffset = xOffset / 50

			local yOffset = math.random(-10, 10)
			yOffset = yOffset / 50

			local zOffset = math.random(-10, 10)
			zOffset = zOffset / 50

			caster:Fire(origin, direction + Vector3.new(xOffset, yOffset, zOffset), velocity, casterBehaviour)
		end
	else
		caster:Fire(origin, direction, velocity, casterBehaviour)
	end

	local muzzleFlash = game.ReplicatedStorage.Objects.MuzzleFlash:Clone()
	muzzleFlash.Parent = game.Workspace
	muzzleFlash.CFrame = muzzleCF
	muzzleFlash.Orientation += Vector3.new(0, math.random(90, 359), 0)

	game:GetService("Debris"):AddItem(muzzleFlash, .05)
end

caster.RayHit:Connect(function(activeCast, result)
	local hit = result.Instance

	if hit then
		if hit.Parent:FindFirstChild("Humanoid") then
			if hit.Name == "Head" then
				hit.Parent.Humanoid:TakeDamage(data.headshot)
			else
				hit.Parent.Humanoid:TakeDamage(data.damage)
			end

		else
			local bulletHole = game.ReplicatedStorage.Objects.BulletHole:Clone()
			bulletHole.CFrame = CFrame.new(result.Position, result.Position + result.Normal)

			if game.Workspace:FindFirstChild("BulletHoles") then
				bulletHole.Parent = game.Workspace:FindFirstChild("BulletHoles")
			else
				local bulletHoles = Instance.new("Folder", game.Workspace)
				bulletHole.Parent = bulletHoles
			end

			bulletHole.Impact:Play()

			game:GetService("Debris"):AddItem(bulletHole, 15)
		end
	end
end)

return data
