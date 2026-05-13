local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local playersFolder = ReplicatedStorage.Players

local PlayerData = require(script.Parent.PlayerWeaponSystemData)
local Helpers = require(script.Parent.Helpers)
local extraInventories = {"Armor", "TShirt", "Pants", "Backpack"}

local function setupPlayerFolder(player, inventory)
	if not player then return end
	local existingFolder = playersFolder:FindFirstChild(player.Name)
	if existingFolder then existingFolder:Destroy() end

	local playerFolder = Instance.new("Folder")
	playerFolder.Name = player.Name
	playerFolder.Parent = playersFolder

	local clothingFolder = Instance.new("Folder")
	clothingFolder.Name = "Clothing"
	clothingFolder.Parent = playerFolder

	local equipped = Helpers.returnEquippedClothes(inventory) 
	for slotType, slotData in pairs(equipped) do
		local stringValue = Helpers.createStringValue(clothingFolder, slotType, slotData.name)

		for _, extraInventory in pairs(extraInventories) do
			if slotType == extraInventory then
				Helpers.createFolder(stringValue, "Inventory")
				Helpers.setupInventoryFolder(player, stringValue, inventory)
				Helpers.createItemProperties(stringValue, slotData.name)
				break
			end
		end
	end
end

Players.PlayerAdded:Connect(function(player)
	setupPlayerFolder(player, PlayerData.weaponSystem.Inventory)
end)

Players.PlayerRemoving:Connect(function(player)
	Helpers.cleanUpPlayerFolder(player)
end)