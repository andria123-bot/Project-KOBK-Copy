local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AmmoList = require(ReplicatedStorage.Shared.Modules.Ammos:WaitForChild("AmmoList"))

local data = {
	name = "Khrissy10R",

	animations = {
		fireAnim = 'rbxassetid://95024054063945';
		emptyFireAnim = 'rbxassetid://102934817879819';
		equipAnim = 'rbxassetid://75940248615882';
		deequipAnim = 'rbxassetid://107938692974708';
		reloadAnim = 'rbxassetid://98970778537699';
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
		"rbxassetid://129384861068765";
		"rbxassetid://93598508552874";
		"rbxassetid://8740433183";
		"rbxassetid://134817048219417";
		"rbxassetid://127619339252879";
		"rbxassetid://127619339252879";

		attachmentSounds = {
			"rbxassetid://17589930440"
		};
	},

	scopeData = {
		currentScope = "Empty",

		defaultScope = "Holo",

		allowedScopes = {
			RedDot = true,
			Holo = true,
			ACOG = false,
			PulsarThermion2 = false,
		};
	},

	imageIconId = "rbxassetid://120213357895445",

	canAim = true,
	aimSmooth = .00025,
	canSemi = true,
	canFullAuto = false,
	ammo = 21,        
	maxAmmo = 21,
	fireMode = "Semi Auto",

	sprintCF = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-95/5), math.rad(95/4), math.rad(95/5)),

	aimCF = CFrame.new(),
	currentSwayAMT = -.25,
	swayAMT = -.25,
	aimSwayAMT = .45,
	swayCF = CFrame.new(0, 0, 0),
	lastCameraCF = CFrame.new(0, 0, 0),

	durable = 100,    
	isStackable = false,
	maxStack = 1,

	canPenetrate = true,
	maxDepth = 1.2,
	damageFalloff = 0.8,

	canAddSight = false,
	canAddLaser = true,
	canAddExtendedMag = true,

	damage = 55,  
	headshot = 73,
	debounce = .15,
	reloadTime = 2.3,
	emptyReloadTime = 2.9,
	jamChance = 0.005,
	value = 3000,
	weight = 1.3,

	fireRate = 0.25,

	recoilSprings = {
        rotFrequency = 35,
        rotDamping = 3,
        posFrequency = 35,
        posDamping = 3.5,
        camFrequency = 100,
        camDamping = 6,
    },
    
    recoilForce = {
        rot = Vector3.new(0.12, 0.05, 0.02),
        pos = Vector3.new(0, 0, 35.0),
        camera = Vector3.new(3.5, 3.5, 3.5),
    },

	serverRecoilPattern = {
		{x = 0.010, y = 0.008},
		{x = 0.008, y = 0.006},
		{x = 0.006, y = 0.004},
		{x = 0.004, y = 0.002},
		{x = 0.002, y = 0.001},
	},
		
	bulletSpeed = 450,
	maxDistanceTravel = 130;
	dragCoefficient = 0.00025,

	slotType = "Loadout",
	ammoType = "0.9mm",
	canBeStored = true,
	loadedBulletType = "Zero",

	isGrenade = false,
	isMelee = false,
	isShootgun = false,
}

function data:SetBulletType(bullType)
    local ammoData = AmmoList[bullType]
    if ammoData then
        self.loadedBulletType = bullType
        self.damage = ammoData.damage
        self.headshot = ammoData.headshot
        self.muzzleVelocity = ammoData.muzzleVelocity
        self.dragCoefficient = ammoData.dragCoefficient
        self.gravity = ammoData.gravity
        self.hipSpread = ammoData.hipSpread
        self.aimingSpread = ammoData.aimingSpread
        self.spreadRecovery = ammoData.spreadRecovery
        self.armorPen = ammoData.armorPen
        self.penetrationPower = ammoData.penetrationPower
    else
        warn("Ammo type not found: " .. bullType)
    end
end

data:SetBulletType("0.9mm")

return data