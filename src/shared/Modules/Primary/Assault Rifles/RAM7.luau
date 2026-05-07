local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AmmoList = require(ReplicatedStorage.Shared.Modules.Ammos:WaitForChild("AmmoList"))

local data = {
	name = "Ram7",

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
		"rbxassetid://17589930440";
		"rbxassetid://134817048219417";
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
			ACOG = true,
			PulsarThermion2 = true,
		};
	},

	imageIconId = "rbxassetid://100881304376013",

	canAim = true,
	aimSmooth = .00025,
	canSemi = true,
	canFullAuto = true,
	ammo = 30,        
	maxAmmo = 30,
	fireMode = "Full Auto",

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

	canPenetrate = true,
	maxDepth = 2.4,
	damageFalloff = 0.72,

	canAddSight = true,
	canAddLaser = true,
	canAddExtendedMag = true,

	damage = 28,  
	headshot = 65,
	debounce = 0.065,
	reloadTime = 3.3,
	emptyReloadTime = 4.1,
	jamChance = 0.007,
	value = 5600,
	weight = 3.3,

	fireRate = 0.00625, -- 960 RPM (RAM-7 in MW2019 fires fast)

	recoilSprings = {
        rotFrequency = 32,
        rotDamping = 3.1,
        posFrequency = 32,
        posDamping = 3.6,
        camFrequency = 95,
        camDamping = 6.2,
    },
    
    recoilForce = {
        rot = Vector3.new(0.09, 0.07, 0.04),
        pos = Vector3.new(0, 0, 46.5),
        camera = Vector3.new(5.0, 5.0, 5.0),
    },

	serverRecoilPattern = {
		{x = 0.007, y = 0.007},
		{x = 0.010, y = 0.010},
		{x = 0.012, y = 0.012},
		{x = 0.014, y = 0.009},
		{x = 0.013, y = 0.005},
		{x = 0.011, y = -0.003},
		{x = 0.009, y = -0.007},
		{x = 0.006, y = -0.005},
		{x = 0.004, y = -0.003},
	},
		
	bulletSpeed = 1525,
	maxDistanceTravel = 1500;
	dragCoefficient = 0.00022,

	slotType = "Loadout",
	ammoType = "5.56x45",
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

data:SetBulletType("5.56x45 T")

return data