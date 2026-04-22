local data = {
	name = "MG42",

	-- Animations (unchanged)
	fireAnim = "rbxassetid://95024054063945",
	emptyFireAnim = "rbxassetid://95024054063945",
	equipAnim = "rbxassetid://133514477466822",
	deequipAnim = "rbxassetid://96095541989669",
	reloadAnim = "rbxassetid://98970778537699",
	emptyReloadAnim = "rbxassetid://86389481538214",
	inspectAnim = "rbxassetid://80262626757998",
	idleAnim = "rbxassetid://90962731439428",
	
	--[[	fireAnim = "rbxassetid://95024054063945",
	emptyFireAnim = "rbxassetid://95024054063945",
	equipAnim = "rbxassetid://133514477466822",
	deequipAnim = "rbxassetid://96095541989669",
	reloadAnim = "rbxassetid://98970778537699",
	emptyReloadAnim = "rbxassetid://86389481538214",
	inspectAnim = "rbxassetid://80262626757998",
	idleAnim = "rbxassetid://90962731439428",]]

	tpIdleAnim = "rbxassetid://131819337932852",
	tpShootAnim = "rbxassetid://131819337932852",
	tpReloadAnim = "rbxassetid://131819337932852",
	tpEmptyReloadAnim = "rbxassetid://131819337932852",
	tpInspectAnim = "rbxassetid://131819337932852",
	tpEquipAnim = "rbxassetid://131819337932852",
	tpDeequipAnim = "rbxassetid://131819337932852",

	-- Sounds (unchanged)
	sounds = {
		"rbxassetid://127619339252879"; -- equip/draw
		"rbxassetid://1245969465"; -- Shoot/use
		"rbxassetid://134817048219417"; -- reload
		"rbxassetid://134817048219417"; -- empty reload
		"rbxassetid://127619339252879"; -- inspect
		"rbxassetid://127619339252879"; -- deequip/holster

		attachmentSounds = {
			"rbxassetid://17589930440" -- Suppressor
		}
	},

	imageIconId = "rbxassetid://91662687299133",

	-- Weapon behavior
	canAim = true,
	aimSmooth = 0.005,
	canSemi = false,
	canFullAuto = true,
	ammo = 75,        
	maxAmmo = 75,
	fireMode = "Full Auto",

	fireRate = 0.05,  

	sprintCF = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-95/5), math.rad(95/4), math.rad(95/5)),
	
	aimCF = CFrame.new(),
	currentSwayAMT = .1,
	swayAMT = .2,
	aimSwayAMT = -.9,
	swayCF = CFrame.new(0, 0, 0),
	lastCameraCF = CFrame.new(0, 0, 0),

	-- Durability
	durable = 1800,
	isStackable = false,
	maxStack = 1,

	-- Piercing
	canPenetrate = true,
	maxDepth = 3.0,
	damageFalloff = 0.85,

	-- Attachments
	canAddSight = false,
	canAddLaser = false,
	canAddExtendedMag = false,

	-- Damage
	damage = 44.9,
	headshot = 78.9,
	debounce = 0.05,
	reloadTime = 5.2,
	jamChance = 0.01,
	value = 7500,

	-- Recoil
	x = 1.8,
	y = 0.12,
	currentRecoilCycle = 1,

	hipfire = 3.5,
	aimed = 0.9,
	increasePerShot = 0.35,
	maxSpread = 8.0,
	bulletSpeed = 400,
	bulletDistance = 800,

	slotType = "Loadout",
	ammoType = "7.92x57mm",
	canBeStored = false,

	isGrenade = false,
	isMelee = false,
	isShootgun = false,
}

data.recoil = {}

for i = 1, data.maxAmmo do
	local up = math.clamp(2 - (i * 0.05), 0.2, 2) * data.x
	local side = math.sin(i * 0.4) * 1.2 * data.y + math.random(-5, 5) / 50

	table.insert(data.recoil, CFrame.Angles(math.rad(up), math.rad(side), 90))
end

return data
