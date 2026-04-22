local data = {
	name = "AR15",
	
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
		"rbxassetid://127619339252879"; -- equip/draw
		"rbxassetid://18335135825"    ; -- Shoot/use
		"rbxassetid://134817048219417"; -- reload
		"rbxassetid://134817048219417"; -- empty reload
		"rbxassetid://127619339252879"; -- inspect
		"rbxassetid://127619339252879"; -- deequip/holster
		--"rbxassetid://6812913751"     ; -- emptyFire
		
		attachmentSounds = {
			"rbxassetid://17589930440" -- Suppresor
			
		}
	};
	
	imageIconId = "rbxassetid://87925256700259",
	
	canAim = true,
	aimSmooth = .00025,
	canSemi = true,
	canFullAuto = true,
	ammo = 30,
	maxAmmo = 30,
	fireMode = "Full Auto",

	fireRate = .08,

	sprintCF = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-95/5), math.rad(95/4), math.rad(95/5));

	durable = 560,
	isStackable = false,
	maxStack = 1,

	--Piercing
	canPenetrate = true,
	maxDepth = 2.8,
	damageFalloff = 0.7,

	-- Can Add Attachments
	canAddSight = true,
	canAddLaser = true,
	canAddExtendedMag = true,

	damage = 33.3,
	headshot = 80,
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

	slotType = "Loadout",
	ammoType = "5.56x45",
	canBeStored = false,
	
	isGranade = false,
	isMelee = false,
	isShootgun = false,
}

return data
