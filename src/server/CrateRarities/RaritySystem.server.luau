local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local moduleTable = require(script.ItemsRarityData)
local TransferItems = ReplicatedStorage.Remotes.Crates:WaitForChild("TransferItems")

local SmallMilCrateScFrame = ReplicatedStorage.GUIS.MilCrates.SmallMilCrateScrollingFrame

local slots = {}
for _, v in pairs(SmallMilCrateScFrame.Frame:GetDescendants()) do
	if v:IsA("ImageButton") then
		table.insert(slots, v)
	end
end

local currentCrateItems = {}

local function generateCrateItems()
	local maxItem = math.random(2, 4)
	local crateItems = {}

	for i = 1, maxItem do
		local itemData = moduleTable.choiceRandomItem()
		crateItems[i] = itemData
	end

	return crateItems
end

-- Generate items every 5 seconds and send to all players
while true do
	currentCrateItems = generateCrateItems()
	for _, player in pairs(Players:GetPlayers()) do
		TransferItems:FireClient(player, currentCrateItems)
	end
	wait(5)
end

-- When a new player joins, send the current crate items
Players.PlayerAdded:Connect(function(player)
	if #currentCrateItems > 0 then
		TransferItems:FireClient(player, currentCrateItems)
	end
end)
