local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InventoryUpdateEvent = ReplicatedStorage.Remotes.Inventory:WaitForChild("InventoryUpdateEvent")
local UpdatedInventoryEvent = ReplicatedStorage.Remotes.Inventory:WaitForChild("UpdatedInventoryEvent")

local StarterGear = require(game:WaitForChild("ServerScriptService").MagsHandler.StarterGear)

local inventoryStore = DataStoreService:GetDataStore("PlayerInventoryStore")
local playerInventories = {}

local function cloneInventory(definition)
	local new = {}
	for i, item in pairs(definition) do
		new[i] = {
			slot = item.slot,
			item = item.item,
			qty = item.qty or 1,
		}
	end
	return new
end

local function sanitizeItem(item)
	local result = {}
	for key, value in pairs(item) do
		if typeof(value) == "string" or typeof(value) == "number" or typeof(value) == "boolean" then
			result[key] = value
		end
	end
	return result
end

local function handlePlayerAdded(player)
	local success, data = pcall(function()
		return inventoryStore:GetAsync(player.UserId)
	end)
	
	data = nil

	if success and data then
		playerInventories[player.UserId] = data
	else
		playerInventories[player.UserId] = cloneInventory(StarterGear)
	end
	
	UpdatedInventoryEvent:FireClient(player, playerInventories[player.UserId])
end

local function handlePlayerRemoving(player)
	local inventory = playerInventories[player.UserId]
	if inventory then
		local cleanInventory = {}
		for i, item in pairs(inventory) do
			cleanInventory[i] = sanitizeItem(item)
		end

		local success, err = pcall(function()
			inventoryStore:SetAsync(player.UserId, cleanInventory)
		end)

		if success then
			print("Saved inventory for", player.Name)
		else
			warn("Failed to save inventory for", player.Name, err)
		end
	end

	playerInventories[player.UserId] = nil
end

Players.PlayerAdded:Connect(handlePlayerAdded)
Players.PlayerRemoving:Connect(handlePlayerRemoving)

InventoryUpdateEvent.OnServerEvent:Connect(function(player, updatedInventory)
	if typeof(updatedInventory) == "table" then
		playerInventories[player.UserId] = updatedInventory
		print("Received updated inventory from", player.Name)
	end
end)
