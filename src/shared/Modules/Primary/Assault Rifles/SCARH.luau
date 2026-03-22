local data = {
	name = "ScarH",

	fireAnim = "rbxassetid://95024054063945",
	emptyFireAnim = "rbxassetid://133514477466822",
	equipAnim = "rbxassetid://133514477466822",
	deequipAnim = "rbxassetid://96095541989669",
	reloadAnim = "rbxassetid://92598864979265",
	emptyReloadAnim = "rbxassetid://124067485668980",
	inspectAnim = "rbxassetid://80262626757998",
	idleAnim = "rbxassetid://131819337932852",

	tpIdleAnim = "rbxassetid://131819337932852",
	tpShootAnim = "rbxassetid://131819337932852",
	tpReloadAnim = "rbxassetid://131819337932852",
	tpEmptyReloadAnim = "rbxassetid://131819337932852",
	tpInspectAnim = "rbxassetid://131819337932852",
	tpEquipAnim = "rbxassetid://131819337932852",
	tpDeequipAnim = "rbxassetid://131819337932852",

	sounds = {
		"rbxassetid://127619339252879"; -- equip/draw
		"rbxassetid://108346912683295"; -- Shoot/use
		"rbxassetid://799959310"      ; -- reload
		"rbxassetid://134817048219417"; -- empty reload
		"rbxassetid://127619339252879"; -- inspect
		"rbxassetid://127619339252879"; -- deequip/holster

		attachmentSounds = {
			"rbxassetid://96681333046767" -- Suppresor
		}
	};

	imageIconId = "rbxassetid://104982169567164",

	canAim = true,
	aimSmooth = .00025,
	canSemi = true,
	canFullAuto = true,
	ammo = 20,       
	maxAmmo = 20,
	fireMode = "Full Auto",

	fireRate = 0.1,   

	sprintCF = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-95/5), math.rad(95/4), math.rad(95/5));

	durable = 560,
	isStackable = false,
	maxStack = 1,

	-- Piercing
	canPenetrate = true,
	maxDepth = 3.2,   
	damageFalloff = 0.8, 

	-- Attachments
	canAddSight = true,
	canAddLaser = true,
	canAddExtendedMag = true,

	-- Damage
	damage = 41,         -- 2-3 shot kill torso
	headshot = 95,       -- OHK with headshot
	debounce = 0.08,
	reloadTime = 2.6,
	jamChance = 0.01,
	value = 7200,

	-- Recoil (heavier than 5.56 rifles)
	x = 1.8,
	y = 0.15,

	-- Spread
	hipfire = 3.1,
	aimed = 0.6,
	increasePerShot = 0.35,
	maxSpread = 6.2,
	bulletSpeed = 360,   -- faster than 5.56
	bulletDistance = 650,

	slotType = "Loadout",
	ammoType = "7.62x51",
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
