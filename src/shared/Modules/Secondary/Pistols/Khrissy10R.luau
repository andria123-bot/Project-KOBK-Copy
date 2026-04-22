local ReplicatedStorage = game:GetService("ReplicatedStorage")

local data = {
	name = "Khrissy10R",

	animations = {
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
	},

	sounds = {
		"rbxassetid://129384861068765"; -- equip/draw
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

	aimCF = CFrame.new(),
	currentSwayAMT = -.25,
	swayAMT = -.25,
	aimSwayAMT = .45,
	swayCF = CFrame.new(0, 0, 0),
	lastCameraCF = CFrame.new(0, 0, 0),

	imageIconId = "rbxassetid://120213357895445",

	canAim = true,
	aimSmooth = .00025,
	canSemi = true,
	canFullAuto = false,

	ammo = 21,
	maxAmmo = 21,
	fireMode = "Semi Auto",
	fireRate = 0.25,
	
	debounce = .15,

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
	ammoType = "0.9mm",
	canBeStored = true,

	isGrenade = false,
	isMelee = false,
	isShootgun = false,
}

return data

