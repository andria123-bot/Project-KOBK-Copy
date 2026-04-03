local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local RequestInventory = ReplicatedStorage.Shared.Remotes.InventoryEvents:WaitForChild("RequestInventory")
local SendInventory = ReplicatedStorage.Shared.Remotes.InventoryEvents:WaitForChild("SendInventory")
local MoveItem = ReplicatedStorage.Shared.Remotes.InventoryEvents:WaitForChild("MoveItem")
local RequestGear = ReplicatedStorage.Shared.Remotes.Requests:WaitForChild("RequestGear")
local PlayerSlotData = ReplicatedStorage.Shared.Remotes.InventoryEvents:WaitForChild("PlayerSlotData")

local WeaponCategories = require(script.Parent.Parent.ModuleHandler.WeaponCategories)
local defaultInventory = require(script.Parent.Parent.DataSave.loadStarterInventory)
local PlayerInventories = {}

local GearModule = require(script.Parent.GearsSetup)
local inventories = {}

Players.PlayerAdded:Connect(function(player)
	local savedInventory = defaultInventory.loadSavedInventory(player)
	local playerData = { weaponSystem = { inventory = {} } }

	defaultInventory.mergeInventory(playerData, savedInventory)
	PlayerInventories[player] = playerData.weaponSystem.inventory

	SendInventory:FireClient(player, playerData.weaponSystem.inventory)

	inventories[player] = GearModule.new()
end)

Players.PlayerRemoving:Connect(function(player)
	local inventory = PlayerInventories[player]

	if inventory then
		local success, err = pcall(function()
			defaultInventory.saveInventory(player, { weaponSystem = { inventory = inventory } })
		end)

		if success then
			print("Saved inventory for", player.Name)
		else
			warn("Failed to save inventory for", player.Name, err)
		end
	end
end)

PlayerSlotData.OnServerEvent:Connect(function(player, slotData)
	print(slotData)
end)

RequestInventory.OnServerEvent:Connect(function(player)
	if PlayerInventories[player] then
		SendInventory:FireClient(player, PlayerInventories[player])
	end
end)

MoveItem.OnServerEvent:Connect(function(player, fromSlot, toSlot)
	local inventory = PlayerInventories[player]

	if typeof(fromSlot) ~= "number" or typeof(toSlot) ~= "number" then return end
	if fromSlot < 1 or toSlot < 1 then return end
	if fromSlot == toSlot then return end
	if not inventory[fromSlot] or inventory[fromSlot] == "" then return end

	-- Initialize toSlot if it doesn't exist
	if not inventory[toSlot] then
		inventory[toSlot] = ""
	end

	local item = inventory[fromSlot]

	if inventory[toSlot] then -- Swap items
		local temp = inventory[fromSlot]
		inventory[fromSlot] = inventory[toSlot]
		inventory[toSlot] = temp
	else -- Move item
		inventory[toSlot] = item
		inventory[fromSlot] = ""
	end

	defaultInventory.saveInventory(player, { weaponSystem = { inventory = inventory } })
	SendInventory:FireClient(player, inventory)
end)

RequestGear.OnServerInvoke = function(player)
	return inventories[player]
end
