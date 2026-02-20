local data = {
	name = "Khrissy10R",

	fireAnim = 'rbxassetid://95024054063945';
	emptyFireAnim = 'rbxassetid://102934817879819';
	equipAnim = 'rbxassetid://75940248615882';
	deequipAnim = 'rbxassetid://107938692974708';
	reloadAnim = 'rbxassetid://98970778537699'; -- Aq davtove
	emptyReloadAnim = 'rbxassetid://86389481538214';
	inspectAnim = "rbxassetid://80262626757998";
	idleAnim = "rbxassetid://90962731439428",

	tpIdleAnim = "rbxassetid://131819337932852",
	tpShootAnim = "rbxassetid://131819337932852",
	tpReloadAnim = "rbxassetid://131819337932852",
	tpInspectAnim = "rbxassetid://131819337932852",
	tpEmptyReloadAnim = "rbxassetid://131819337932852",
	tpEquipAnim = "rbxassetid://131819337932852",
	tpDeequipAnim = "rbxassetid://131819337932852",

	sounds = {
		"rbxassetid://127619339252879"; -- equip/draw
		"rbxassetid://93598508552874" ; -- Shoot/use
		"rbxassetid://8740433183"     ; -- reload
		"rbxassetid://134817048219417"; -- empty reload
		"rbxassetid://127619339252879"; -- inspect
		"rbxassetid://127619339252879"; -- deequip/holster
		--"rbxassetid://6812913751"   ; -- emptyFire

		attachmentSounds = {
			"rbxassetid://17589930440" -- Suppresor
		}
	};

	sprintCF = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-95/5), math.rad(95/4), math.rad(95/5));

	imageIconId = "rbxassetid://120213357895445",

	canAim = true,
	aimSmooth = .00025,
	canSemi = true,
	canFullAuto = false,

	ammo = 21,
	maxAmmo = 21,
	fireMode = "Semi Auto",
	fireRate = 0.25,

	durable = 100,
	isStackable = false,
	maxStack = 1,

	--Piercing
	canPenetrate = true,
	maxDepth = 1.2,
	damageFalloff = 0.8,

	-- Can Add Attachments
	canAddSight = false,
	canAddLaser = true,
	canAddExtendedMag = true,
	canReload = true,

	damage = 55,
	headshot = 73,
	debounce = 0.1,
	reloadTime = 2.3,
	jamChance = 0.005,
	value = 3000,
	weight = 1.3,

	-- Recoil
	x = 1.2,
	y = 0.5,
	z = 1.7,
	
	recoil = {
		CFrame.Angles(math.rad(4), math.rad(1), 0),
		CFrame.Angles(math.rad(2), math.rad(.5), 0),
		CFrame.Angles(math.rad(.5), math.rad(.25), 0),
	},
	currentRecoilCycle = 1,

	-- Spread
	hipfire = 3.0,
	aimed = 0.7,
	increasePerShot = 0.6,
	maxSpread = 7.0,

	bulletSpeed = 450,
	bulletDistance = 130,
	slotType = "Loadout",
	ammoType = ".9",
	canBeStored = true,

	isGrenade = false,
	isMelee = false,
	isShootgun = false,
}

data.recoil = {}
for i = 1, data.maxAmmo do
	local up = math.clamp(3 - (i * 0.05), 0.5, 3) -- vertical kick decreases over time
	local side = math.random(-10, 10) / 20        -- slight left/right sway
	table.insert(data.recoil, CFrame.Angles(math.rad(up), math.rad(side), 0))
end

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

			caster:Fire(origin, direction + Vector3.new(xOffset, yOffset, zOffset), velocity, casterBehaviour)
		end
	else
		caster:Fire(origin, direction, velocity, casterBehaviour)
	end
	-- Just make bullet traectory visible 
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

