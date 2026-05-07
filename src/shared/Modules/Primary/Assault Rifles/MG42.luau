local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AmmoList = require(ReplicatedStorage.Shared.Modules.Ammos:WaitForChild("AmmoList"))

local data = {
	name = "MG42",

	animations = {
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
	},

	sounds = {
		"rbxassetid://127619339252879";
		"rbxassetid://1245969465";
		"rbxassetid://134817048219417";
		"rbxassetid://134817048219417";
		"rbxassetid://127619339252879";
		"rbxassetid://127619339252879";

		attachmentSounds = {
			"rbxassetid://17589930440";
		};
	},

	scopeData = {
		currentScope = "Empty",

		defaultScope = "Holo",

		allowedScopes = {
			RedDot = false,
			Holo = true,
			ACOG = false,
			PulsarThermion2 = false,
		};
	},

	imageIconId = "rbxassetid://91662687299133",

	canAim = true,
	aimSmooth = 0.005,
	canSemi = false,
	canFullAuto = true,
	ammo = 75,        
	maxAmmo = 75,
	fireMode = "Full Auto",

	sprintCF = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-95/5), math.rad(95/4), math.rad(95/5)),

	aimCF = CFrame.new(),
	currentSwayAMT = 0.1,
	swayAMT = 0.2,
	aimSwayAMT = -0.9,
	swayCF = CFrame.new(0, 0, 0),
	lastCameraCF = CFrame.new(0, 0, 0),

	durable = 1800,    
	isStackable = false,
	maxStack = 1,

	canPenetrate = true,
	maxDepth = 3.0,
	damageFalloff = 0.85,

	canAddSight = false,
	canAddLaser = false,
	canAddExtendedMag = false,

	damage = 44.9,  
	headshot = 78.9,
	debounce = 0.05,
	reloadTime = 5.2,
	emptyReloadTime = 6.4,
	jamChance = 0.01,
	value = 7500,
	weight = 11.6,

	fireRate = 0.0083, -- ~1200 RPM (MG42 known for extreme fire rate)

	recoilSprings = {
        rotFrequency = 25,
        rotDamping = 2.5,
        posFrequency = 25,
        posDamping = 3.0,
        camFrequency = 80,
        camDamping = 5.0,
    },
    
    recoilForce = {
        rot = Vector3.new(0.15, 0.10, 0.05),
        pos = Vector3.new(0, 0, 65.0),
        camera = Vector3.new(6.5, 6.5, 6.5),
    },

	serverRecoilPattern = {
		{x = 0.012, y = 0.010},
		{x = 0.018, y = 0.012},
		{x = 0.024, y = 0.014},
		{x = 0.030, y = 0.010},
		{x = 0.028, y = 0.005},
		{x = 0.025, y = -0.005},
		{x = 0.022, y = -0.010},
		{x = 0.018, y = -0.008},
		{x = 0.015, y = -0.005},
	},
		
	bulletSpeed = 3100,
	maxDistanceTravel = 2000;
	dragCoefficient = 0.00028,

	slotType = "Loadout",
	ammoType = "7.92x57mm",
	canBeStored = false,
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

data:SetBulletType("7.92x57 M")

return data