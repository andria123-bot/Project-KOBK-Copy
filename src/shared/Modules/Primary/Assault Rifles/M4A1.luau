local data = {
	name = "M4A1",

	fireAnim = "rbxassetid://95024054063945",
	emptyFireAnim = "rbxassetid://95024054063945", -- Wrong anim 
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
		"rbxassetid://18968266298"    ; -- Shoot/use
		"rbxassetid://134817048219417"; -- reload
		"rbxassetid://134817048219417"; -- empty reload
		"rbxassetid://127619339252879"; -- inspect
		"rbxassetid://127619339252879"; -- deequip/holster

		attachmentSounds = {
			"rbxassetid://17589930440" -- Suppressor
		}
	};

	imageIconId = "rbxassetid://135495631168523",

	canAim = true,
	aimSmooth = .00025,
	canSemi = true,
	canFullAuto = true,
	ammo = 30,
	maxAmmo = 30,
	fireMode = "Full Auto",

	fireRate = 0.085,

	sprintCF = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-95/5), math.rad(95/4), math.rad(95/5)),

	aimCF = CFrame.new(),
	currentSwayAMT = -.35,
	swayAMT = -.28,
	aimSwayAMT = .45,
	swayCF = CFrame.new(0, 0, 0),
	lastCameraCF = CFrame.new(0, 0, 0),

	durable = 550,
	isStackable = false,
	maxStack = 1,

	-- Piercing
	canPenetrate = true,
	maxDepth = 2.0,
	damageFalloff = 0.72,

	-- Attachments
	canAddSight = true,
	canAddLaser = true,
	canAddExtendedMag = true,

	-- Damage
	damage = 26,
	headshot = 64,
	debounce = 0.065,
	reloadTime = 2.9,
	jamChance = 0.006,
	value = 5200,

	-- Recoil
	x = 0.85,
	y = 0.05,

	-- Spread
	hipfire = 2.0,
	aimed = 0.28,
	increasePerShot = 0.20,
	maxSpread = 4.2,
	bulletSpeed = 340,
	bulletDistance = 540,

	slotType = "Loadout",
	ammoType = "5.56x45",
	canBeStored = false,

	isGrenade = false,
	isMelee = false,
	isShootgun = false,
}

return data
