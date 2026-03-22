local data = {
	name = "Tomahawk",

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
		"rbxassetid://129384861068765"; -- equip/draw
		"rbxassetid://122795737772215"    ; -- Shoot/use
		"rbxassetid://134817048219417"; -- reload
		"rbxassetid://134817048219417"; -- empty reload
		"rbxassetid://127619339252879"; -- inspect
		"rbxassetid://127619339252879"; -- deequip/holster
		--"rbxassetid://6812913751"     ; -- emptyFire
	};

	damages = {
		damage = 32,
		heavyBody = 48,
		headshot = 64,
		heavyHead = 100
	};

	imageIconId = "rbxassetid://81487743965976",

	canAim = false,
	aimSmooth = 0,
	canSemi = 0,
	canFullAuto = 0,
	ammo = 0,
	maxAmmo = 0,
	fireMode = "nil",

	fireRate = .08,

	sprintCF = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-95/5), math.rad(95/4), math.rad(95/5));

	aimCF = CFrame.new(),
	currentSwayAMT = -0.15,
	swayAMT = -0.25,
	aimSwayAMT = 0.1,
	swayCF = CFrame.new(0, 0, 0),
	lastCameraCF = CFrame.new(0, 0, 0),

	durable = 560,
	isStackable = false,
	maxStack = 5,

	--Piercing
	canPenetrate = true,
	maxDepth = 2.8,
	damageFalloff = 0.7,

	-- Can Add Attachments
	canAddSight = true,
	canAddLaser = true,
	canAddExtendedMag = true,

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

	slotType = "Equipment",
	ammoType = "0",
	canBeStored = false,

	isGrenade = false,
	isMelee = true,
}

return data
