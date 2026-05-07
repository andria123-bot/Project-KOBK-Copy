local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AmmoList = require(ReplicatedStorage.Shared.Modules.Ammos:WaitForChild("AmmoList"))

local data = {
	name = "M4A1",

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
		"rbxassetid://127619339252879"; -- equip/draw
		"rbxassetid://18968266298"    ; -- Shoot/use
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

	imageIconId = "rbxassetid://135495631168523",

	canAim = true,
	aimSmooth = .00025,
	canSemi = true,
	canFullAuto = true,
	ammo = 30,        
	maxAmmo = 30,
	fireMode = "Full Auto",

	sprintCF = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-95/5), math.rad(95/4), math.rad(95/5));

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
	maxDepth = 2.0,
	damageFalloff = 0.72,

	canAddSight = true,
	canAddLaser = true,
	canAddExtendedMag = true,

	damage = 26.0,  
	headshot = 64.0,
	debounce = 0.065,
	reloadTime = 2.7,
	emptyReloadTime = 3.45,
	jamChance = 0.0006,
	value = 5200,
	weight = 2.95,   

	fireRate = 0.0075,

	recoilSprings = {
        rotFrequency = 38,
        rotDamping = 3.2,   
        posFrequency = 38,  
        posDamping = 3.8,   
        camFrequency = 110, 
        camDamping = 6.5,   
    },
    
    recoilForce = {
        rot = Vector3.new(0.05, 0.04, 0.02),  
        pos = Vector3.new(0, 0, 42.5),        
        camera = Vector3.new(4.0, 4.0, 4.0), 
    },

	serverRecoilPattern = {
		{x = 0.003, y = 0.003},
		{x = 0.005, y = 0.005},
		{x = 0.007, y = 0.007},
		{x = 0.007, y = 0.006},
		{x = 0.008, y = 0.005},
		{x = 0.006, y = 0.005},
		{x = 0.004, y = 0.004},
		{x = 0.003, y = 0.003},
		{x = 0.002, y = 0.002},
	},
		
	bulletSpeed = 1470,  
	maxDistanceTravel = 1500;
	dragCoefficient = 0.00023,

	slotType = "Loadout",
	ammoType = "5.56x45",
	canBeStored = false,
	loadedBulletType = "Zero";

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