local Magazines = require(game.ReplicatedStorage.Modules.MagazineAmmos.Magazines)
local AmmoTypes = require(game.ReplicatedStorage.Modules.MagazineAmmos.Ammo)

local function LoadMagazine(magazineInstance, ammoInventory)
	local needed = magazineInstance.capacity - magazineInstance.currentAmmo
	if needed <= 0 then
		return false, "Magazine is already full"
	end

	local ammoType = magazineInstance.ammoType
	for _, stack in ipairs(ammoInventory) do
		if stack.type == ammoType and stack.amount > 0 then
			local transfer = math.min(stack.amount, needed)
			magazineInstance.currentAmmo += transfer
			stack.amount -= transfer
			needed -= transfer

			if needed <= 0 then
				break
			end
		end
	end

	if needed > 0 then
		return true, "Magazine partially loaded"
	else
		return true, "Magazine fully loaded"
	end
end

return LoadMagazine
