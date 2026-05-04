-- local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- local Players = game:GetService("Players")

-- local RequestInventory = ReplicatedStorage.Shared.Remotes.InventoryEvents:WaitForChild("RequestInventory")
-- local SendInventory = ReplicatedStorage.Shared.Remotes.InventoryEvents:WaitForChild("SendInventory")
-- local MoveItem = ReplicatedStorage.Shared.Remotes.Requests:WaitForChild("MoveItem")
-- local SaveInventoryRequest = ReplicatedStorage.Shared.Remotes:WaitForChild("SaveInventory")
-- local PlayerSlotData = ReplicatedStorage.Shared.Remotes.InventoryEvents:WaitForChild("PlayerSlotData")
-- local RequestPlayerData = ReplicatedStorage.Shared.Remotes.Bindables:WaitForChild("RequestPlayerData")
-- local SendServerInventoryBindable = ReplicatedStorage.Shared.Remotes.Bindables:WaitForChild("SendServerInventory")

-- local WeaponCategories = require(script.Parent.Parent.ModuleHandler.WeaponCategories)
-- local defaultInventory = require(script.Parent.Parent.DataSave.loadStarterInventory)

-- local forcedKit = false -- Set false to load saved inventories normally
-- local STARTER_KIT = {"HK416", "Khrissy10R", "Tomahawk", "MK2"}
-- local SAVE_DEBOUNCE = 2
-- local PERIODIC_SAVE = 60

-- local PlayerInventories = {}
-- local playerSlots = {}
-- local lastMoveTime = {}
-- local saveTimers = {}

-- local templateData = RequestPlayerData:Invoke()

-- local function createPlayerInventory()
--     local templateInventory = templateData.Inventory
    
--     local newInventory = {
--         PlayerInventory = {},
--         StorageInventory = {},
--         Equipment = {
--             Clothing = {},
--             Utils = {},
--             Weapons = {},
--         },
--         SlotCount = 0
--     }
    
--     -- CRITICAL: Initialize ALL slots with empty strings
--     for i = 1, newInventory.SlotCount do
--         newInventory.PlayerInventory[i] = ""
--     end
    
--     -- Then fill starter kit in slots 1-4
--     local starterKit = {"HK416", "Khrissy10R", "Tomahawk", "MK2"}
--     for i = 1, #starterKit do
--         newInventory.PlayerInventory[i] = starterKit[i]
--     end
    
--     -- Copy equipment...
--     for k, v in pairs(templateInventory.Equipment.Clothing) do
--         newInventory.Equipment.Clothing[k] = { equipped = v.equipped, name = v.name }
--     end
    
--     for k, v in pairs(templateInventory.Equipment.Utils) do
--         newInventory.Equipment.Utils[k] = { equipped = v.equipped, name = v.name }
--     end
    
--     for k, v in pairs(templateInventory.Equipment.Weapons) do
--         newInventory.Equipment.Weapons[k] = { equipped = v.equipped, item = v.item }
--     end
    
--     print("Created new inventory with starter kit and equipment", newInventory)
--     return newInventory
-- end

-- local function applyStarterKit(inventory)
--     for i = 1, inventory.SlotCount do
--         inventory.PlayerInventory[i] = ""
--     end
--     for i, item in ipairs(STARTER_KIT) do
--         inventory.PlayerInventory[i] = item
--     end
-- end

-- local function saveInventoryNow(player, inventory)
--     local success, err = pcall(function()
--         defaultInventory.saveInventory(player, {
--             weaponSystem = {
--                 Inventory = inventory
--             }
--         })
--     end)
--     if not success then
--         warn("Failed to save inventory for", player.Name, ":", err)
--     end
--     return success
-- end

-- local function DebouncedSave(player, inventoryData)
--     if saveTimers[player] then
--         task.cancel(saveTimers[player])
--     end

--     saveTimers[player] = task.delay(SAVE_DEBOUNCE, function()
--         local playerData = PlayerInventories[player]
--         if not playerData then return end -- player left, skip

--         local success = saveInventoryNow(player, playerData.Inventory)
--         if success then
--             print("Debounced save completed for:", player.Name)
--         end
--         saveTimers[player] = nil
--     end)
-- end

-- local function OnInventoryChanged(player)
--     local playerData = PlayerInventories[player]
--     if playerData and playerData.Inventory then
--         DebouncedSave(player, playerData.Inventory.PlayerInventory)
--     end
-- end

-- local function initPlayer(player)
--     local playerInventory = createPlayerInventory()

--     if forcedKit then
--         applyStarterKit(playerInventory)
--     else
--         local savedInventory = defaultInventory.loadSavedInventory(player)

--         if savedInventory and type(savedInventory) == "table" then
--             local source = savedInventory.PlayerInventory or savedInventory
--             for i, item in pairs(source) do
--                 playerInventory.PlayerInventory[i] = item
--             end
--         else
--             applyStarterKit(playerInventory)
--         end
--     end

--     PlayerInventories[player] = {
--         Inventory = playerInventory,
--         gear = {
--             Backpack = nil,
--             Leggings = nil,
--             TShirt = nil,
--             Helmet = nil,
--             Pants = nil,
--             Armor = nil,
--             Mask = nil,
--         },
--         animations = templateData.animations,
--         sounds = templateData.sounds,
--         lastShotTime = 0,
--         bulletId = 0,
--         state = "Idle",
--         states = templateData.states,
--         modifiers = templateData.modifiers,
--         viewmodel = nil,
--         currentSlot = 0,
--     }

--     local saved = saveInventoryNow(player, playerInventory)
--     if saved then
--         print("Initial inventory saved to DataStore for:", player.Name)
--     end

--     SendInventory:FireClient(player, playerInventory)
--     SendServerInventoryBindable:Fire(player, playerInventory)
--     print("Inventory sent to:", player.Name)
-- end

-- task.spawn(function()
--     while true do
--         task.wait(PERIODIC_SAVE)
--         for player, playerData in pairs(PlayerInventories) do
--             if playerData and playerData.Inventory then
--                 saveInventoryNow(player, playerData.Inventory)
--             end
--         end
--         print("Periodic backup completed")
--     end
-- end)

-- Players.PlayerAdded:Connect(function(player)
--     task.spawn(function()
--         initPlayer(player)
--     end)
-- end)

-- for _, player in pairs(Players:GetPlayers()) do
--     task.spawn(function()
--         initPlayer(player)
--     end)
-- end

-- Players.PlayerRemoving:Connect(function(player)
--     if saveTimers[player] then
--         task.cancel(saveTimers[player])
--         saveTimers[player] = nil
--     end

--     local playerData = PlayerInventories[player]
--     if playerData and playerData.Inventory then
--         saveInventoryNow(player, playerData.Inventory)
--     end

--     PlayerInventories[player] = nil
--     playerSlots[player] = nil
--     lastMoveTime[player] = nil
-- end)

-- PlayerSlotData.OnServerEvent:Connect(function(player, slotData)
--     playerSlots[player] = slotData
-- end)

-- RequestInventory.OnServerEvent:Connect(function(player)
--     local playerData = PlayerInventories[player]
--     if playerData and playerData.Inventory then
--         SendInventory:FireClient(player, playerData.Inventory)
--     end
-- end)

-- SaveInventoryRequest.OnServerEvent:Connect(function(player, inventoryData)
--     local playerData = PlayerInventories[player]
--     if not playerData or not playerData.Inventory then return end

--     if inventoryData and type(inventoryData) == "table" then
--         for i, item in pairs(inventoryData) do
--             if typeof(i) == "number" and typeof(item) == "string" then
--                 playerData.Inventory.PlayerInventory[i] = item
--             end
--         end
--     end

--     DebouncedSave(player, playerData.Inventory.PlayerInventory)
-- end)

-- MoveItem.OnServerInvoke = function(player, fromSlot, toSlot)
--     local playerData = PlayerInventories[player]
--     if not playerData or not playerData.Inventory then return false end
    
--     local inventory = playerData.Inventory.PlayerInventory
    
--     if typeof(fromSlot) ~= "number" or typeof(toSlot) ~= "number" then return false end
--     if fromSlot < 1 or toSlot < 1 then return false end
--     if fromSlot == toSlot then return false end
--     if not inventory[fromSlot] or inventory[fromSlot] == "" then return false end
    
--     if playerSlots[player] and playerSlots[player].slots then
--         local slotKey = "Slot" .. fromSlot
--         print("mismatch check - server expects:", inventory[fromSlot], "client says:", playerSlots[player].slots[slotKey])
--         if playerSlots[player].slots[slotKey] ~= inventory[fromSlot] then
--             print("REJECTED - item mismatch")
--             return false
--         end
--     else
--         print("no playerSlots data, skipping mismatch check")
--     end
    
--     local now = tick()
--     if lastMoveTime[player] and now - lastMoveTime[player] < 0.2 then
--         print("REJECTED - rate limit")
--         return false
--     end
--     lastMoveTime[player] = now
    
--     if not inventory[toSlot] then
--         inventory[toSlot] = ""
--     end

--     local fromItem = inventory[fromSlot]
--     local toItem = inventory[toSlot]

--     if toItem ~= "" then
--         inventory[fromSlot] = toItem
--         inventory[toSlot] = fromItem
--     else
--         inventory[toSlot] = fromItem
--         inventory[fromSlot] = ""
--     end

--     SendInventory:FireClient(player, playerData.Inventory)
--     OnInventoryChanged(player)
    
--     return true
-- end