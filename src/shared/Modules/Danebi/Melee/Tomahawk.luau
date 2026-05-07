local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AmmoList = require(ReplicatedStorage.Shared.Modules.Ammos:WaitForChild("AmmoList"))

local data = {
	name = "Tomahawk",

	animations = {
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
	},

	sounds = {
		"rbxassetid://129384861068765";
		"rbxassetid://122795737772215";
		"rbxassetid://134817048219417";
		"rbxassetid://134817048219417";
		"rbxassetid://127619339252879";
		"rbxassetid://127619339252879";

		attachmentSounds = {};
	};

	scopeData = {
		currentScope = "Empty",

		defaultScope = "Empty",

		allowedScopes = {
			RedDot = false,
			Holo = false,
			ACOG = false,
			PulsarThermion2 = false,
		};
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
	canSemi = false,
	canFullAuto = false,
	ammo = 0,        
	maxAmmo = 0,
	fireMode = "nil",

	sprintCF = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-95/5), math.rad(95/4), math.rad(95/5)),

	aimCF = CFrame.new(),
	currentSwayAMT = -0.15,
	swayAMT = -0.25,
	aimSwayAMT = 0.1,
	swayCF = CFrame.new(0, 0, 0),
	lastCameraCF = CFrame.new(0, 0, 0),

	durable = 560,    
	isStackable = false,
	maxStack = 5,

	canPenetrate = true,
	maxDepth = 2.8,
	damageFalloff = 0.7,

	canAddSight = false,
	canAddLaser = false,
	canAddExtendedMag = false,

	damage = 32,
	headshot = 64,
	debounce = 0.065,
	reloadTime = 2.9,
	emptyReloadTime = 2.9,
	jamChance = 0.015,
	value = 6000,
	weight = 1.0,

	fireRate = 0.08,

	recoilSprings = {
        rotFrequency = 35,
        rotDamping = 3,
        posFrequency = 35,
        posDamping = 3.5,
        camFrequency = 100,
        camDamping = 6,
    },
    
    recoilForce = {
        rot = Vector3.new(0, 0, 0),
        pos = Vector3.new(0, 0, 0),
        camera = Vector3.new(0, 0, 0),
    },

	serverRecoilPattern = {
		{x = 0, y = 0},
	},
		
	bulletSpeed = 310,
	maxDistanceTravel = 500;
	dragCoefficient = 0.00022,

	slotType = "Equipment",
	ammoType = "0",
	canBeStored = false,
	loadedBulletType = "Zero";

	isGrenade = false,
	isMelee = true,
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

return data