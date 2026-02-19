local ReplicatedStorage = game:GetService("ReplicatedStorage")

local module = {}

local loadedItems = {}

for _, v in pairs(ReplicatedStorage.Modules:GetDescendants()) do
	if v:IsA("ModuleScript") and v.Name ~= "FastCastRedux" and v.Name ~= "ActiveSignal" and v.Name ~= "Signal" and v.Name ~= "Table" and v.Name ~= "TypeDefinitions"  and v.Name ~= "TypeMarshaller" and v.Name ~= "Misc" then
		local item = require(v)
		if item and item.name then
			loadedItems[item.name] = item
		end
	end
end

module.Items = {
	Legendary = loadedItems["AsVal"],
	Epic = loadedItems["DesertTechMDR"],
	Rare = loadedItems["Gry14"],
	Common = loadedItems["Glock19"],
}

module.Rarities = {
	Legendary = 1,
	Epic = 19,
	Rare = 30,
	Common = 50,
}

function module.choiceRandomItem()
	local randomNum = math.random(1, 100)
	local counter = 0

	for rarity, weight in pairs(module.Rarities) do
		counter += weight
		if randomNum <= counter then
			return module.Items[rarity]
		end
	end
end

return module