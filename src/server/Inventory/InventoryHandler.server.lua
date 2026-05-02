print("=== INVENTORY HANDLER SERVER SCRIPT LOADED ===")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local RequestInventory = ReplicatedStorage.Shared.Remotes.InventoryEvents:WaitForChild("RequestInventory")
local SendInventory = ReplicatedStorage.Shared.Remotes.InventoryEvents:WaitForChild("SendInventory")
local MoveItem = ReplicatedStorage.Shared.Remotes.Requests:WaitForChild("MoveItem")
local SaveInventoryRequest = ReplicatedStorage.Shared.Remotes:WaitForChild("SaveInventory")
local PlayerSlotData = ReplicatedStorage.Shared.Remotes.InventoryEvents:WaitForChild("PlayerSlotData")
local RequestPlayerData = ReplicatedStorage.Shared.Remotes.Bindables:WaitForChild("RequestPlayerData")
local SendServerInventoryBindable = ReplicatedStorage.Shared.Remotes.Bindables:WaitForChild("SendServerInventory")

local WeaponCategories = require(script.Parent.Parent.ModuleHandler.WeaponCategories)
local defaultInventory = require(script.Parent.Parent.DataSave.loadStarterInventory)

local PlayerInventories = {}
local playerSlots = {}
local lastMoveTime = {}
local saveTimers = {}

local SAVE_DEBOUNCE = 2
local PERIODIC_SAVE = 60

local templateData = RequestPlayerData:Invoke()

local function createPlayerInventory()
    local templateInventory = templateData.Inventory
    
    local newInventory = {
        PlayerInventory = {},
        StorageInventory = {},
        Equipment = {
            Clothing = {},
            Utils = {},
            Weapons = {},
        },
        SlotCount = templateInventory.SlotCount or 15
    }
    
    for i = 1, newInventory.SlotCount do
        newInventory.PlayerInventory[i] = ""
    end
    
    for k, v in pairs(templateInventory.Equipment.Clothing) do
        newInventory.Equipment.Clothing[k] = { equipped = v.equipped, name = v.name }
    end
    
    for k, v in pairs(templateInventory.Equipment.Utils) do
        newInventory.Equipment.Utils[k] = { equipped = v.equipped, name = v.name }
    end
    
    for k, v in pairs(templateInventory.Equipment.Weapons) do
        newInventory.Equipment.Weapons[k] = { equipped = v.equipped, item = v.item }
    end
    
    return newInventory
end

local function DebouncedSave(player, inventory)
    print("DebouncedSave called for:", player.Name)
    if saveTimers[player] then
        task.cancel(saveTimers[player])
    end
    
    saveTimers[player] = task.delay(SAVE_DEBOUNCE, function()
        local success = pcall(function()
            defaultInventory.saveInventory(player, { weaponSystem = { Inventory = { PlayerInventory = inventory } } })
        end)
        if success then
            print("Debounced save for:", player.Name)
        end
        saveTimers[player] = nil
    end)
end

function OnInventoryChanged(player)
    local playerData = PlayerInventories[player]
    if playerData and playerData.Inventory then
        DebouncedSave(player, playerData.Inventory.PlayerInventory)
    end
end

local function initPlayer(player)
    local playerInventory = createPlayerInventory()
    
    local savedInventory = defaultInventory.loadSavedInventory(player)
    
    if savedInventory and type(savedInventory) == "table" then
        if savedInventory.PlayerInventory then
            for i, item in pairs(savedInventory.PlayerInventory) do
                playerInventory.PlayerInventory[i] = item
            end
        else
            for i, item in pairs(savedInventory) do
                playerInventory.PlayerInventory[i] = item
            end
        end
        print("Loaded saved inventory for:", player.Name)
    else
        local starterKit = {"HK416", "Khrissy10R", "Tomahawk", "MK2"}
        for i, item in ipairs(starterKit) do
            playerInventory.PlayerInventory[i] = item
        end
        print("Gave starter kit to:", player.Name)
    end
    
    PlayerInventories[player] = {
        Inventory = playerInventory,
        gear = {
            Backpack = nil,
            Leggings = nil,
            TShirt = nil,
            Helmet = nil,
            Pants = nil,
            Armor = nil,
            Mask = nil,
        },
        animations = templateData.animations,
        sounds = templateData.sounds,
        lastShotTime = 0,
        bulletId = 0,
        state = "Idle",
        states = templateData.states,
        modifiers = templateData.modifiers,
        viewmodel = nil,
        currentSlot = 0,
    } -- Send Original inventory to client/servers
    
    SendInventory:FireClient(player, playerInventory)
    SendServerInventoryBindable:Fire(player, playerInventory)
    print("Inventory sent to:", player.Name)
end

-- periodic backup
task.spawn(function()
    while true do
        task.wait(PERIODIC_SAVE)
        for player, playerData in pairs(PlayerInventories) do
            if playerData and playerData.Inventory then
                pcall(function()
                    defaultInventory.saveInventory(player, { weaponSystem = { Inventory = playerData.Inventory } })
                end)
            end
        end
        print("Periodic backup completed")
    end
end)

Players.PlayerAdded:Connect(function(player)
    task.spawn(function()
        initPlayer(player)
    end)
end)

for _, player in pairs(Players:GetPlayers()) do
    task.spawn(function()
        initPlayer(player)
    end)
end

Players.PlayerRemoving:Connect(function(player)
    if saveTimers[player] then
        task.cancel(saveTimers[player])
    end
    local playerData = PlayerInventories[player]
    print(playerData, playerData.Inventory)
    if playerData and playerData.Inventory then
        pcall(function()
            defaultInventory.saveInventory(player, { weaponSystem = { Inventory = playerData.Inventory } })
            print("Leave save for:", player.Name)
        end)
    end
    
    PlayerInventories[player] = nil
    playerSlots[player] = nil
end)

PlayerSlotData.OnServerEvent:Connect(function(player, slotData)
    playerSlots[player] = slotData
end)

RequestInventory.OnServerEvent:Connect(function(player)
    if PlayerInventories[player] then
        SendInventory:FireClient(player, PlayerInventories[player].Inventory)
    end
end)

SaveInventoryRequest.OnServerEvent:Connect(function(player, inventoryData)
    local playerData = PlayerInventories[player]
    if playerData and playerData.Inventory then
        DebouncedSave(player, inventoryData)
    end
end)

MoveItem.OnServerInvoke = function(player, fromSlot, toSlot)
    local playerData = PlayerInventories[player]
    if not playerData or not playerData.Inventory then return false end
    
    local inventory = playerData.Inventory.PlayerInventory
    
    if typeof(fromSlot) ~= "number" or typeof(toSlot) ~= "number" then return false end
    if fromSlot < 1 or toSlot < 1 then return false end
    if fromSlot == toSlot then return false end
    if not inventory[fromSlot] or inventory[fromSlot] == "" then return false end
    
    if playerSlots[player] and playerSlots[player].slots then
        local slotKey = "Slot" .. fromSlot
        if playerSlots[player].slots[slotKey] ~= inventory[fromSlot] then
            print(player.Name, "item mismatch - rejecting move")
            return false
        end
    end
    
    local now = tick()
    if lastMoveTime[player] and now - lastMoveTime[player] < 0.2 then
        return false
    end
    lastMoveTime[player] = now
    
    if not inventory[toSlot] then
        inventory[toSlot] = ""
    end

    local fromItem = inventory[fromSlot]
    local toItem = inventory[toSlot]

    if toItem ~= "" then
        inventory[fromSlot] = toItem
        inventory[toSlot] = fromItem
    else
        inventory[toSlot] = fromItem
        inventory[fromSlot] = ""
    end

    SendInventory:FireClient(player, playerData.Inventory)
    OnInventoryChanged(player)
    
    return true
end

-- game:BindToClose(function()
--     print("Server shutting down, saving all inventories")
--     for player, playerData in pairs(PlayerInventories) do
--         if playerData and playerData.Inventory then
--             pcall(function()
--                 defaultInventory.saveInventory(player, { weaponSystem = { Inventory = playerData.Inventory } })
--             end)
--         end
--     end
-- end)