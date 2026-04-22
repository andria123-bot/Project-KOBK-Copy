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

return data
