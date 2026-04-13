local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local RequestInventory = ReplicatedStorage.Shared.Remotes.InventoryEvents:WaitForChild("RequestInventory")
local SendInventory = ReplicatedStorage.Shared.Remotes.InventoryEvents:WaitForChild("SendInventory")
local MoveItem = ReplicatedStorage.Shared.Remotes.Requests:WaitForChild("MoveItem")
local RequestGear = ReplicatedStorage.Shared.Remotes.Requests:WaitForChild("RequestGear")
local PlayerSlotData = ReplicatedStorage.Shared.Remotes.InventoryEvents:WaitForChild("PlayerSlotData")

local WeaponCategories = require(script.Parent.Parent.ModuleHandler.WeaponCategories)
local defaultInventory = require(script.Parent.Parent.DataSave.loadStarterInventory)
local PlayerInventories = {}
local playerSlots = {}
local lastMoveTime = {}

local GearModule = require(script.Parent.GearsSetup)
local gearSlots = {}

Players.PlayerAdded:Connect(function(player)
	local savedInventory = defaultInventory.loadSavedInventory(player)
	local playerData = { weaponSystem = { inventory = {} } }

	defaultInventory.mergeInventory(playerData, savedInventory)
	PlayerInventories[player] = playerData.weaponSystem.inventory

	SendInventory:FireClient(player, playerData.weaponSystem.inventory)

	gearSlots[player] = GearModule.new()
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
	playerSlots[player] = slotData
end)

RequestInventory.OnServerEvent:Connect(function(player)
	if PlayerInventories[player] then
		SendInventory:FireClient(player, PlayerInventories[player])
	end
end)

MoveItem.OnServerInvoke = function(player, fromSlot, toSlot)
	local inventory = PlayerInventories[player]
	
	-- Validate
	if typeof(fromSlot) ~= "number" or typeof(toSlot) ~= "number" then return false end
	if fromSlot < 1 or toSlot < 1 then return false end
	if fromSlot == toSlot then return false end
	if not inventory[fromSlot] or inventory[fromSlot] == "" then return false end
	
	if playerSlots[player] and playerSlots[player].slots then
		local slotKey = "Slot" .. fromSlot
		if playerSlots[player].slots[slotKey] ~= inventory[fromSlot] then
			print(player.Name, "item mismatch!")
			player:Kick("Cheating detected")
			return false
		end
	end
	
	local now = tick()
	if lastMoveTime[player] and now - lastMoveTime[player] < 0.1 then
		return false
	end
	lastMoveTime[player] = now
	
	if not inventory[toSlot] then
		inventory[toSlot] = ""
	end

	local fromItem = inventory[fromSlot]
	local toItem = inventory[toSlot]

	if toItem ~= "" then
		-- Swap
		inventory[fromSlot] = toItem
		inventory[toSlot] = fromItem
	else
		-- Move
		inventory[toSlot] = fromItem
		inventory[fromSlot] = ""
	end

	defaultInventory.saveInventory(player, { weaponSystem = { inventory = inventory } })
	SendInventory:FireClient(player, inventory)
	
	return true
end

RequestGear.OnServerInvoke = function(player)
	return gearSlots[player]
end
