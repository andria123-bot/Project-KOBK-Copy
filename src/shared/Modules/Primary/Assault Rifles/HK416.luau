local ReplicatedStorage = game:GetService("ReplicatedStorage")

local data = {
	name = "HK416",

	animations = {
		fireAnim = "rbxassetid://95024054063945",
		emptyFireAnim = "rbxassetid://95024054063945", -- 88699433754390
		equipAnim = "rbxassetid://133514477466822",
		deequipAnim = "rbxassetid://96095541989669",
		reloadAnim = "rbxassetid://98970778537699",
		emptyReloadAnim = "rbxassetid://86389481538214",
		inspectAnim = "rbxassetid://80262626757998",
		idleAnim = "rbxassetid://90962731439428",

		tpIdleAnim = "rbxassetid://101943279476475",
		tpShootAnim = "rbxassetid://131819337932852",
		tpReloadAnim = "rbxassetid://131819337932852",
		tpEmptyReloadAnim = "rbxassetid://131819337932852",
		tpInspectAnim = "rbxassetid://131819337932852",
		tpEquipAnim = "rbxassetid://131819337932852",
		tpDeequipAnim = "rbxassetid://131819337932852",
	},

	sounds = {
		"rbxassetid://129384861068765"; -- equip/draw
		"rbxassetid://79126872857479" ; -- Shoot/use
		"rbxassetid://134817048219417"; -- reload
		"rbxassetid://134817048219417"; -- empty reload
		"rbxassetid://127619339252879"; -- inspect
		"rbxassetid://127619339252879"; -- deequip/holster

		attachmentSounds = {
			"rbxassetid://17589930440"; -- Suppressor
		};
	};

	scopeData = {
		currentScope = "Empty",

		defaultScope = "Holo",

		allowedScopes = {
			RedDot = true,
			Holo = true,
			ACOG = true,
			PulsarThermion2 = true,
		};
	};

	imageIconId = "rbxassetid://103687899724625",

	canAim = true,
	aimSmooth = .00025,
	canSemi = true,
	canFullAuto = true,
	ammo = 30,        
	maxAmmo = 30,
	fireMode = "Full Auto",

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

	canAddSight = true,
	canAddLaser = true,
	canAddExtendedMag = true,

	-- Damage
	damage = 28.6,  
	headshot = 67.67,
	debounce = 0.1,
	reloadTime = 2.9,  
	emptyReloadTime = 3.67,
	jamChance = 0.0005,
	value = 5800,
	weight = 3.02, -- kg

	fireRate = 0.008, 
	-- Recoil
	x = .2,
	y = 0.8,
	z = .4;
	
	bulletSpeed = 1500,
	maxDistanceTravel = 1500;
	dragCoefficient = 0.00022,

	slotType = "Loadout",
	ammoType = "5.56x45",
	canBeStored = false,
	loadedBulletType = "Tracer"; -- T / AP

	isGrenade = false,
	isMelee = false,
	isShootgun = false,
}

return data