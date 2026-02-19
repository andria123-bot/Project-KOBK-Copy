local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Magazines = require(Modules.MagazineAmmos.Magazines)
local Ammos = require(Modules.MagazineAmmos.Ammos)
local Weapons = require(Modules.MagazineAmmos.Weapons)

local StarterGear = {
	{ slot = 1, item = Weapons.HK416 },    
	{ slot = 2, item = Magazines.HK416Mag },   
	{ slot = 3, item = Ammos["5.56x45"], qty = Ammos["5.56x45"].stackSize },
	{ slot = 4, item = Weapons.AR15 },
	{ slot = 5, item = Magazines.AR15Mag },
	{ slot = 6, item = Weapons.SCARH },
	{ slot = 7, item = Magazines.SCARHMag },
	{ slot = 8, item = Ammos["7.62x51"], qty = Ammos["7.62x51"].stackSize },
}

return StarterGear
