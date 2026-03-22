local data = {
	name = "Ram7",

	fireAnim = "rbxassetid://95024054063945",
	emptyFireAnim = "rbxassetid://95024054063945",
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
		"rbxassetid://127619339252879";
		"rbxassetid://17589930440";
		"rbxassetid://134817048219417";
		"rbxassetid://134817048219417";
		"rbxassetid://127619339252879";
		"rbxassetid://127619339252879";

		attachmentSounds = {
			"rbxassetid://17589930440"
		}
	};

	imageIconId = "rbxassetid://100881304376013",

	canAim = true,
	aimSmooth = .00025,
	canSemi = true,
	canFullAuto = true,
	ammo = 30,
	maxAmmo = 30,
	fireMode = "Full Auto",

	fireRate = 0.075,       -- ~800 RPM

	sprintCF = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-95/5), math.rad(95/4), math.rad(95/5)),

	durable = 550,
	isStackable = false,
	maxStack = 1,

	-- Piercing
	canPenetrate = true,
	maxDepth = 2.4,
	damageFalloff = 0.72,

	-- Can Add Attachments
	canAddSight = true,
	canAddLaser = true,
	canAddExtendedMag = true,

	-- Damage
	damage = 28,
	headshot = 65,
	debounce = 0.065,
	reloadTime = 3.3,
	jamChance = 0.007,
	value = 5600,

	-- Recoil
	x = 1.1,
	y = 0.07,

	-- Spread
	hipfire = 2.8,
	aimed = 0.4,
	increasePerShot = 0.28,
	maxSpread = 4.8,
	bulletSpeed = 335,
	bulletDistance = 540,

	slotType = "Loadout",
	ammoType = "5.56x45",
	canBeStored = false,

	isGrenade = false,
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
