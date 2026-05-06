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

local InventoryFunctions = require(script.Parent.Parent.Inventory.InventoryFunctions)

local forcedKit = true
local SAVE_DEBOUNCE = 2
local PERIODIC_SAVE = 60
local SLOT_COUNT = 15
local MOVE_RATE_LIMIT = 0.2
local DROP_RATE_LIMIT = 0.5
local MAX_PICKUP_DISTANCE = 10  -- studs

local STARTER_KIT = {"HK416", "Khrissy10R", "Tomahawk", "MK2"}

-- Whitelist of valid item names — add all your items here
-- This is the single most important anti-cheat measure
local VALID_ITEMS = {
    HK416 = true,
    Khrissy10R = true,
    Tomahawk = true,
    MK2 = true,
    -- add more items here
}

local function isValidItem(itemName)
    if typeof(itemName) ~= "string" then return false end
    if itemName == "" then return false end
    return VALID_ITEMS[itemName] == true
end

local function normalizeToDense(inventory)
    local dense = {}
    for i = 1, SLOT_COUNT do
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
            }
        })
    end)
    if not success then
        warn("Failed to save inventory for", player.Name, ":", err)
    end
    return success
end

local function DebouncedSave(player)
    -- Don't reset timer if one is already pending within debounce window
    -- This prevents move spam from blocking saves indefinitely
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

local function applyStarterKit(inventory)
    for i = 1, SLOT_COUNT do
        inventory.PlayerInventory[i] = ""
    end
    for i, item in ipairs(STARTER_KIT) do
        inventory.PlayerInventory[i] = item
    end
end

function InventoryService:CreatePlayerInventory()
    local newInventory = {
        PlayerInventory = {},
        StorageInventory = {},
        Equipment = {
            Clothing = {},
            Utils = {},
            Weapons = {},
        },
        SlotCount = SLOT_COUNT,
    }
    for i = 1, SLOT_COUNT do
        newInventory.PlayerInventory[i] = ""
    end
    return newInventory
end

function InventoryService:GetPlayerData(player)
    return PlayerInventories[player]
end

-- SERVER ONLY — never expose this directly as a Client method
function InventoryService:AddItem(player, itemName)
    -- Always validate item exists in whitelist
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

-- SERVER ONLY — called by your pickup logic scripts, never by client directly
-- Pass the item instance so we can do proximity check
function InventoryService:PickupItem(player, itemName, itemPosition)
    local playerData = PlayerInventories[player]
    if not playerData then return false, "No player data" end

    -- Validate item name against whitelist
    if not isValidItem(itemName) then
        warn("PickupItem: invalid item:", itemName, "player:", player.Name)
        return false, "Invalid item"
    end

    -- Proximity check — make sure player is actually near the item
    if itemPosition then
        local character = player.Character
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local distance = (hrp.Position - itemPosition).Magnitude
            if distance > MAX_PICKUP_DISTANCE then
                warn("PickupItem: player too far from item:", player.Name, "distance:", distance)
                return false, "Too far away"
            end
        end
    end

    return self:AddItem(player, itemName)
end

local DROPPED_ITEMS_FOLDER_NAME = "DroppedItems"

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
        warn("PickupItem: item not found in workspace, dropId:", dropId, "player:", player.Name)
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

function InventoryService:DropItem(player, slot)
    local playerData = PlayerInventories[player]
    if not playerData then return false, nil end

    if typeof(slot) ~= "number" or slot < 1 or slot > SLOT_COUNT then
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

-- Client methods — these are what exploiters can call
-- Keep them minimal and always validated server-side

function InventoryService.Client:GetInventory(player)
    local playerData = self.Server:GetPlayerData(player)
    if not playerData then return nil end
    normalizeToDense(playerData.Inventory)
    return playerData.Inventory
end

function InventoryService.Client:MoveItem(player, fromSlot, toSlot)
    local playerData = PlayerInventories[player]
    if not playerData then return false end

    -- Type check
    if typeof(fromSlot) ~= "number" or typeof(toSlot) ~= "number" then return false end

    -- Bounds check
    if fromSlot < 1 or fromSlot > SLOT_COUNT then return false end
    if toSlot < 1 or toSlot > SLOT_COUNT then return false end
    if fromSlot == toSlot then return false end

    -- Rate limit
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
    -- Rate limit drops
    local now = tick()
    if lastDropTime[player] and now - lastDropTime[player] < DROP_RATE_LIMIT then
        return false, nil
    end
    lastDropTime[player] = now

    return self.Server:DropItem(player, slot)
end

-- DO NOT expose PickupItem or AddItem as Client methods
-- Pickup should be triggered by server-side touched/proximity events only

local function initPlayer(player)
    local playerInventory = InventoryService:CreatePlayerInventory()

    if forcedKit then
        applyStarterKit(playerInventory)
    else
        local savedInventory = defaultInventory.loadSavedInventory(player)
        if savedInventory and type(savedInventory) == "table" then
            local source = savedInventory.PlayerInventory or savedInventory
            for i, item in pairs(source) do
                if item and item ~= "" then
                    -- Validate saved items against whitelist too
                    if isValidItem(item) then
                        playerInventory.PlayerInventory[i] = item
                    else
                        warn("initPlayer: skipping invalid saved item:", item)
                    end
                end
            end
            print("Loaded saved inventory for:", player.Name)
        else
            applyStarterKit(playerInventory)
            print("No saved inventory, gave starter kit for:", player.Name)
        end
    end

    normalizeToDense(playerInventory)

    PlayerInventories[player] = {
        Inventory = playerInventory,
        gear = {},
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

    task.delay(1, function()
        if PlayerInventories[player] then
            InventoryService.Client.InventoryUpdated:Fire(player, playerInventory)
        end
    end)

    print("Inventory initialized for:", player.Name)
end

-- Periodic backup
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
end)

game:BindToClose(function()
    print("BindToClose: saving all players...")

    local saveTasks = {}
    for player, playerData in pairs(PlayerInventories) do
        if playerData and playerData.Inventory then
            table.insert(saveTasks, task.spawn(function()
                saveInventoryNow(player, playerData.Inventory)
                print("BindToClose save done for:", player.Name)
            end))
        end
    end

    -- Wait for all save threads to finish
    for _, t in ipairs(saveTasks) do
        repeat task.wait() until coroutine.status(t) == "dead"
    end

    print("BindToClose: all saves completed")
end)

function InventoryService:KnitStart()
    print("InventoryService started")
end

function InventoryService:KnitInit() end

return InventoryService