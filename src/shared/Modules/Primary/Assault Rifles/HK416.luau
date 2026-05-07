local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AmmoList = require(ReplicatedStorage.Shared.Modules.Ammos:WaitForChild("AmmoList"))

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
	weight = 3.02,

	fireRate = 0.0085, 

	recoilSprings = {
        rotFrequency = 35,  -- How fast camera recoil returns
        rotDamping = 3,     -- How much camera recoil bounces
        posFrequency = 35,  -- How fast viewmodel kickback returns
        posDamping = 3.5,   -- How much kickback bounces
        camFrequency = 100, -- How fast camera shake returns
        camDamping = 6,     -- How much camera shake bounces
    },
    
    recoilForce = {
        rot = Vector3.new(0.07, 0.06, 0.03),   -- rot.X = Camera pitch (up/down recoil) | rot.Y = Camera yaw (left/right recoil) | rot.Z = Camera roll (tilt)
        pos = Vector3.new(0, 0, 44.67),        -- pos.X = Viewmodel horizontal kickback | pos.Y = Viewmodel vertical kickback | pos.Z = Viewmodel backward kickback
        camera = Vector3.new(4.5, 4.5, 4.5),   -- camera.X = Camera horizontal shake | camera.Y = Camera vertical shake | camera.Z = Camera roll shake
    },

	serverRecoilPattern = {
		{x = 0.005, y = 0.005},
		{x = 0.008, y = 0.008},
		{x = 0.01, y = 0.01},
		{x = 0.012, y = 0.008},
		{x = 0.015, y = 0.005},
		{x = 0.012, y = -0.008},
		{x = 0.01, y = -0.01},
		{x = 0.008, y = -0.008},
		{x = 0.005, y = -0.005},
	},
		
	bulletSpeed = 1500,
	maxDistanceTravel = 1500;
	dragCoefficient = 0.00022,

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