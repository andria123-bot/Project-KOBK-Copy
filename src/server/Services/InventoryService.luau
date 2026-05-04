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
local saveTimers = {}

local forcedKit = false
local SAVE_DEBOUNCE = 2
local PERIODIC_SAVE = 60
local STARTER_KIT = {"HK416", "Khrissy10R", "Tomahawk", "MK2"}
local SLOT_COUNT = 15

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
    if saveTimers[player] then
        task.cancel(saveTimers[player])
    end
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

function InventoryService:AddItem(player, itemName)
    local playerData = PlayerInventories[player]
    if not playerData then return false, nil end

    local inventory = playerData.Inventory.PlayerInventory
    for i = 1, SLOT_COUNT do
        if inventory[i] == "" then
            inventory[i] = itemName
            normalizeToDense(playerData.Inventory)
            InventoryService.Client.InventoryUpdated:Fire(player, playerData.Inventory)
            DebouncedSave(player)
            return true, i
        end
    end
    return false, nil
end

function InventoryService:RemoveItem(player, slot)
    local playerData = PlayerInventories[player]
    if not playerData then return false, nil end

    local inventory = playerData.Inventory.PlayerInventory
    local item = inventory[slot]
    if item and item ~= "" then
        inventory[slot] = ""
        normalizeToDense(playerData.Inventory)
        InventoryService.Client.InventoryUpdated:Fire(player, playerData.Inventory)
        DebouncedSave(player)
        return true, item
    end
    return false, nil
end

-- Client-facing methods (player is auto-injected by Knit)
function InventoryService.Client:GetInventory(player)
    local playerData = self.Server:GetPlayerData(player)
    if not playerData then return nil end
    normalizeToDense(playerData.Inventory)
    return playerData.Inventory
end

function InventoryService.Client:MoveItem(player, fromSlot, toSlot)
    local playerData = PlayerInventories[player]
    if not playerData then return false end

    -- Type and bounds validation
    if typeof(fromSlot) ~= "number" or typeof(toSlot) ~= "number" then return false end
    if fromSlot < 1 or toSlot < 1 or fromSlot > SLOT_COUNT or toSlot > SLOT_COUNT then return false end
    if fromSlot == toSlot then return false end

    -- Rate limit
    local now = tick()
    if lastMoveTime[player] and now - lastMoveTime[player] < 0.2 then
        return false
    end
    lastMoveTime[player] = now

    local inventory = playerData.Inventory.PlayerInventory
    local fromItem = inventory[fromSlot]
    if not fromItem or fromItem == "" then return false end

    local toItem = inventory[toSlot] or ""
    inventory[fromSlot] = toItem
    inventory[toSlot] = fromItem

    -- Normalize before firing so client always gets dense array
    normalizeToDense(playerData.Inventory)

    DebouncedSave(player)
    InventoryService.Client.InventoryUpdated:Fire(player, playerData.Inventory)

    return true
end

function InventoryService.Client:AddItem(player, itemName)
    return self.Server:AddItem(player, itemName)
end

function InventoryService.Client:RemoveItem(player, slot)
    return self.Server:RemoveItem(player, slot)
end

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
                    playerInventory.PlayerInventory[i] = item
                end
            end
            print("Loaded saved inventory for:", player.Name)
        else
            applyStarterKit(playerInventory)
            print("No saved inventory, gave starter kit for:", player.Name)
        end
    end

    -- Always normalize after loading to ensure dense array
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

    -- Small delay so client has time to connect the signal
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
end)

game:BindToClose(function()
    print("BindToClose: saving all players...")
    local threads = {}

    for player, playerData in pairs(PlayerInventories) do
        if playerData and playerData.Inventory then
            table.insert(threads, task.spawn(function()
                saveInventoryNow(player, playerData.Inventory)
                print("BindToClose save done for:", player.Name)
            end))
        end
    end

    -- Wait for all saves to finish
    for _, thread in ipairs(threads) do
        task.wait() -- yields to let threads run
    end

    -- Extra buffer for DataStore requests to fully complete
    task.wait(2)
    print("BindToClose: all saves completed")
end)

function InventoryService:KnitStart()
    print("InventoryService started")
end

function InventoryService:KnitInit()
end

return InventoryService