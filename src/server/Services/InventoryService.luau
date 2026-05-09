local Knit = require(game:GetService("ReplicatedStorage").Packages:WaitForChild("Knit"))
local Players = game:GetService("Players")
local defaultInventory = require(script.Parent.Parent.DataSave.loadStarterInventory)

local InventoryService = Knit.CreateService({
    Name = "InventoryService",
    Client = {
        InventoryUpdated = Knit.CreateSignal(),
    },
})

local PlayerInventories = {}
local lastMoveTime = {}
local lastDropTime = {}
local saveTimers = {}
local inventoryReady = {}

local InventoryFunctions = require(script.Parent.Parent.Inventory.InventoryFunctions)

local forcedKit = true
local SAVE_DEBOUNCE = 2
local PERIODIC_SAVE = 60
local MOVE_RATE_LIMIT = 0.2
local DROP_RATE_LIMIT = 0.2
local MAX_PICKUP_DISTANCE = 10
local DROPPED_ITEMS_FOLDER_NAME = "DroppedItems"

local STARTER_KIT = {"HK416", "Khrissy10R", "Tomahawk", "MK2"}

local VALID_ITEMS = {
    HK416 = true,
    Khrissy10R = true,
    Tomahawk = true,
    MK2 = true,
}

local function isValidItem(itemName)
    if typeof(itemName) ~= "string" then return false end
    if itemName == "" then return false end
    return VALID_ITEMS[itemName] == true
end

local function normalizeToDense(inventory)
    local dense = {}
    for i = 1, inventory.SlotCount do
        dense[i] = inventory.PlayerInventory[i] or ""
    end
    inventory.PlayerInventory = dense
    return inventory
end

local function saveInventoryNow(player, inventory)
    if not player or not player.UserId then
        warn("saveInventoryNow: invalid player")
        return false
    end
    if not inventory or not inventory.PlayerInventory then
        warn("saveInventoryNow: invalid inventory for", player.Name)
        return false
    end

    local playerData = PlayerInventories[player]
    if not playerData then return false end

    normalizeToDense(inventory)
    local success, err = pcall(function()
        defaultInventory.saveInventory(player, {
            weaponSystem = {
                Inventory = {
                    PlayerInventory = inventory.PlayerInventory,
                    StorageInventory = inventory.StorageInventory or {},
                    Equipment = inventory.Equipment, 
                    SlotCount = inventory.SlotCount,
                },
                gear = playerData.gear, 
                animations = playerData.animations,
                sounds = playerData.sounds,
                lastShotTime = playerData.lastShotTime,
                bulletId = playerData.bulletId,
                state = playerData.state,
                states = playerData.states,
                modifiers = playerData.modifiers,
                viewmodel = playerData.viewmodel,
                currentSlot = playerData.currentSlot,
            }
        })
    end)
    if not success then
        warn("Failed to save inventory for", player.Name, ":", err)
    end
    return success
end

local function DebouncedSave(player)
    if saveTimers[player] then return end

    saveTimers[player] = task.delay(SAVE_DEBOUNCE, function()
        local playerData = PlayerInventories[player]
        if playerData and playerData.Inventory then
            saveInventoryNow(player, playerData.Inventory)
            print("Debounced save completed for:", player.Name)
        end
        saveTimers[player] = nil
    end)
end

function InventoryService:EquipItem(player, fromSlot, toSlot, itemName, slotType)
    local playerData = PlayerInventories[player]
    if not playerData then 
        return false, "No player data" 
    end
    
    local inventory = playerData.Inventory.PlayerInventory
    
    if inventory[fromSlot] ~= itemName then
        return false, "Item not found in slot"
    end
    
    inventory[fromSlot] = ""
    
    if slotType == "weapon" then
        local currentWeapon = playerData.Inventory.Equipment.Weapons[toSlot]
        if currentWeapon and currentWeapon.equipped then
            local emptySlot = InventoryFunctions.ReturnAvailableSlot(inventory)
            if emptySlot then
                inventory[emptySlot] = currentWeapon.item
            end
        end
        
        playerData.Inventory.Equipment.Weapons[toSlot] = {
            equipped = true,
            item = itemName
        }
        
    elseif slotType == "gear" then
        local currentGear = playerData.Inventory.Equipment.Clothing[toSlot]
        if currentGear and currentGear.equipped then
            local emptySlot = InventoryFunctions.ReturnAvailableSlot(inventory)
            if emptySlot then
                inventory[emptySlot] = currentGear.name
            end
        end
        
        playerData.Inventory.Equipment.Clothing[toSlot] = {
            equipped = true,
            name = itemName
        }
        
    elseif slotType == "utils" then
        local currentUtil = playerData.Inventory.Equipment.Utils[toSlot]
        if currentUtil and currentUtil.equipped then
            local emptySlot = InventoryFunctions.ReturnAvailableSlot(inventory)
            if emptySlot then
                inventory[emptySlot] = currentUtil.name
            end
        end
        
        playerData.Inventory.Equipment.Utils[toSlot] = {
            equipped = true,
            name = itemName
        }
    end
    
    InventoryService.Client.InventoryUpdated:Fire(player, playerData.Inventory)
    DebouncedSave(player)
    
    return true, "Equipped " .. itemName
end

function InventoryService.Client:EquipItem(player, fromSlot, toSlot, itemName, slotType)
    return self.Server:EquipItem(player, fromSlot, toSlot, itemName, slotType)
end

local function applyStarterKit(inventory)
    for i = 1, inventory.SlotCount do
        inventory.PlayerInventory[i] = ""
    end
    for i, item in ipairs(STARTER_KIT) do
        inventory.PlayerInventory[i] = item
    end
end

local function GetSlotCount(equipment)
    local availableSlots = {"Armor", "TShirt", "Pants"}
    local slotCount = 0

    for i, v in pairs(equipment.Clothing) do
        if table.find(availableSlots, i) then 
            if v.equipped then
                print(slotCount)
                slotCount += 5
            end
        end
    end

    return slotCount
end

function InventoryService:CreatePlayerInventory()
    local newInventory = {
        PlayerInventory = {},
        StorageInventory = {},
        Equipment = {
            Clothing = {
                Mask = { equipped = false, name = "" },
                Gloves = { equipped = false, name = "" },
                Armor = { equipped = true, name = "6B45" },
                TShirt = { equipped = true, name = "Default" },
                Pants = { equipped = true, name = "Default" },
                Backpack = { equipped = false, name = "Fieldpack45" },
                Leggings = { equipped = false, name = "" },
                Helmet = { equipped = false, name = "" },
            },
            Utils = {
                Melee = { equipped = true, name = "Tomahawk" },
                GPS = { equipped = false, name = "" },
                Map = { equipped = false, name = "" },
                Compass = { equipped = false, name = "" },
            },
            Weapons = {
                Slot1 = { equipped = true, item = "HK416" },
                Slot2 = { equipped = true, item = "Khrissy10R" },
                Slot3 = { equipped = true, item = "Tomahawk" },
            },
        },
        SlotCount = 0,
    }

    print(newInventory.Equipment)
    local slotCount = GetSlotCount(newInventory.Equipment)
    newInventory.SlotCount = slotCount
    print(newInventory.SlotCount)

    for i = 1, slotCount do
        newInventory.PlayerInventory[i] = ""
    end
    return newInventory
end

function InventoryService.Client:GetInventory(player)
    local elapsed = 0
    while not inventoryReady[player] do
        task.wait(0.1)
        elapsed = elapsed + 0.1
        if elapsed >= 10 then
            warn("GetInventory: timed out waiting for inventory:", player.Name)
            break
        end
    end

    local playerData = self.Server:GetPlayerData(player)
    if not playerData then
        warn("GetInventory: no data for", player.Name)
        return nil
    end

    normalizeToDense(playerData.Inventory)

    print(playerData.Inventory.SlotCount, playerData.Inventory.Equ)
    
    return {
        PlayerInventory = playerData.Inventory.PlayerInventory,
        SlotCount = playerData.Inventory.SlotCount,
        Equipment = playerData.Inventory.Equipment
    }
end

function InventoryService:GetPlayerData(player)
    return PlayerInventories[player]
end

function InventoryService:AddItem(player, itemName)
    if not isValidItem(itemName) then
        warn("AddItem: invalid item name:", itemName, "from", player.Name)
        return false, "Invalid item", nil
    end

    local playerData = PlayerInventories[player]
    if not playerData then return false, "No player data", nil end

    local inventory = playerData.Inventory.PlayerInventory
    local emptySlot = InventoryFunctions.ReturnAvailableSlot(inventory)

    if emptySlot then
        inventory[emptySlot] = itemName
        normalizeToDense(playerData.Inventory)
        InventoryService.Client.InventoryUpdated:Fire(player, playerData.Inventory)
        DebouncedSave(player)
        return true, "Added " .. itemName, emptySlot
    else
        return false, "Inventory Full!", nil
    end
end

function InventoryService:DropItem(player, slot)
    local playerData = PlayerInventories[player]
    if not playerData then return false, nil end

    if typeof(slot) ~= "number" or slot < 1 or slot > playerData.Inventory.SlotCount then
        return false, nil
    end

    local inventory = playerData.Inventory.PlayerInventory
    local item = inventory[slot]
    if item and item ~= "" then
        inventory[slot] = ""
        normalizeToDense(playerData.Inventory)
        InventoryService.Client.InventoryUpdated:Fire(player, playerData.Inventory)
        InventoryFunctions.CreateItemClone(player, item)
        DebouncedSave(player)
        return true, item
    end
    return false, nil
end

function InventoryService.Client:MoveItem(player, fromSlot, toSlot)
    local playerData = PlayerInventories[player]
    if not playerData then return false end

    if typeof(fromSlot) ~= "number" or typeof(toSlot) ~= "number" then return false end
    if fromSlot < 1 or fromSlot > playerData.Inventory.SlotCount then return false end
    if toSlot < 1 or toSlot > playerData.Inventory.SlotCount then return false end
    if fromSlot == toSlot then return false end

    local now = tick()
    if lastMoveTime[player] and now - lastMoveTime[player] < MOVE_RATE_LIMIT then
        return false
    end
    lastMoveTime[player] = now

    local inventory = playerData.Inventory.PlayerInventory
    local fromItem = inventory[fromSlot]
    if not fromItem or fromItem == "" then return false end

    local toItem = inventory[toSlot] or ""
    inventory[fromSlot] = toItem
    inventory[toSlot] = fromItem

    normalizeToDense(playerData.Inventory)
    DebouncedSave(player)
    InventoryService.Client.InventoryUpdated:Fire(player, playerData.Inventory)

    return true
end

function InventoryService.Client:DropItem(player, slot)
    local now = tick()
    if lastDropTime[player] and now - lastDropTime[player] < DROP_RATE_LIMIT then
        return false, nil
    end
    lastDropTime[player] = now

    return self.Server:DropItem(player, slot)
end

function InventoryService.Client:PickupItem(player, itemName, dropId)
    if not isValidItem(itemName) then
        warn("PickupItem: invalid item:", itemName, "from:", player.Name)
        return false, "Invalid item"
    end

    if typeof(dropId) ~= "string" then
        warn("PickupItem: invalid dropId from:", player.Name)
        return false, "Invalid dropId"
    end

    local droppedItemsFolder = workspace:FindFirstChild(DROPPED_ITEMS_FOLDER_NAME)
    local droppedItem = nil

    if droppedItemsFolder then
        for _, item in pairs(droppedItemsFolder:GetChildren()) do
            if item:GetAttribute("DropID") == dropId then
                droppedItem = item
                break
            end
        end
    end

    if not droppedItem then
        return false, "Item not found"
    end

    local character = player.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false, "No character" end

    local itemPosition = droppedItem:GetPivot().Position
    local distance = (hrp.Position - itemPosition).Magnitude
    if distance > MAX_PICKUP_DISTANCE then
        warn("PickupItem: too far:", player.Name, "dist:", distance)
        return false, "Too far away"
    end

    local success, message, slot = self.Server:AddItem(player, itemName)

    if success then
        droppedItem:Destroy()
        print("PickupItem: success for", player.Name, "item:", itemName, "slot:", slot)
    end

    return success, message
end

local function initPlayer(player)
    local playerInventory = InventoryService:CreatePlayerInventory() -- This already has default Equipment

    local playerGear = {
        Backpack = nil,
        Leggings = nil,
        TShirt = nil,
        Helmet = nil,
        Pants = nil,
        Armor = nil,
        Mask = nil,
    }

    if forcedKit then
        applyStarterKit(playerInventory)
    else
        local savedInventory = defaultInventory.loadSavedInventory(player)
        if savedInventory and type(savedInventory) == "table" then
            local source = savedInventory.PlayerInventory or savedInventory
            for i, item in pairs(source) do
                if item and item ~= "" and isValidItem(item) then
                    playerInventory.PlayerInventory[i] = item
                end
            end
            
            if savedInventory.Equipment then
                if savedInventory.Equipment.Clothing then
                    for slot, data in pairs(savedInventory.Equipment.Clothing) do
                        playerInventory.Equipment.Clothing[slot] = data
                    end
                end
                if savedInventory.Equipment.Utils then
                    for slot, data in pairs(savedInventory.Equipment.Utils) do
                        playerInventory.Equipment.Utils[slot] = data
                    end
                end
                if savedInventory.Equipment.Weapons then
                    for slot, data in pairs(savedInventory.Equipment.Weapons) do
                        playerInventory.Equipment.Weapons[slot] = data
                    end
                end
            else
                print("No saved Equipment, using defaults for:", player.Name)
            end
            
            if savedInventory.gear then
                for slot, value in pairs(savedInventory.gear) do
                    playerGear[slot] = value
                end
            end
        else
            applyStarterKit(playerInventory)
        end
    end

    normalizeToDense(playerInventory)

    PlayerInventories[player] = {
        Inventory = playerInventory,
        gear = playerGear,
        animations = {},
        sounds = {},
        lastShotTime = 0,
        bulletId = 0,
        state = "Idle",
        states = {},
        modifiers = {},
        viewmodel = nil,
        currentSlot = 0,
    }

    saveInventoryNow(player, playerInventory)
    inventoryReady[player] = true

    task.delay(1, function()
        if PlayerInventories[player] then
            InventoryService.Client.InventoryUpdated:Fire(player, playerInventory)
        end
    end)
end

task.spawn(function()
    while true do
        task.wait(PERIODIC_SAVE)
        for player, playerData in pairs(PlayerInventories) do
            if playerData and playerData.Inventory then
                saveInventoryNow(player, playerData.Inventory)
            end
        end
        print("Periodic backup completed")
    end
end)

Players.PlayerAdded:Connect(function(player)
    task.spawn(function() initPlayer(player) end)
end)

for _, player in pairs(Players:GetPlayers()) do
    task.spawn(function() initPlayer(player) end)
end

Players.PlayerRemoving:Connect(function(player)
    if saveTimers[player] then
        task.cancel(saveTimers[player])
        saveTimers[player] = nil
    end

    local playerData = PlayerInventories[player]
    if playerData and playerData.Inventory then
        local success = saveInventoryNow(player, playerData.Inventory)
        print("PlayerRemoving save result for", player.Name, ":", success)
    else
        warn("PlayerRemoving: no inventory data found for", player.Name)
    end

    PlayerInventories[player] = nil
    lastMoveTime[player] = nil
    lastDropTime[player] = nil
    inventoryReady[player] = nil
end)

-- game:BindToClose(function()
--     print("BindToClose: saving all players...")

--     local saveTasks = {}
--     for player, playerData in pairs(PlayerInventories) do
--         if playerData and playerData.Inventory then
--             table.insert(saveTasks, task.spawn(function()
--                 saveInventoryNow(player, playerData.Inventory)
--                 print("BindToClose save done for:", player.Name)
--             end))
--         end
--     end

--     for _, t in ipairs(saveTasks) do
--         repeat task.wait() until coroutine.status(t) == "dead"
--     end

--     print("BindToClose: all saves completed")
-- end)

function InventoryService:KnitStart()
    print("InventoryService started")
end

function InventoryService:KnitInit() end

return InventoryService