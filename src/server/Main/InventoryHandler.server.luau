local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local RequestInventory = ReplicatedStorage.Shared.Remotes.InventoryEvents:WaitForChild("RequestInventory")
local SendInventory = ReplicatedStorage.Shared.Remotes.InventoryEvents:WaitForChild("SendInventory")
local MoveItem = ReplicatedStorage.Shared.Remotes.Requests:WaitForChild("MoveItem")
local PlayerSlotData = ReplicatedStorage.Shared.Remotes.InventoryEvents:WaitForChild("PlayerSlotData")
local RequestPlayerData = ReplicatedStorage.Shared.Remotes.Bindables:WaitForChild("RequestPlayerData")

local WeaponCategories = require(script.Parent.Parent.ModuleHandler.WeaponCategories)
local defaultInventory = require(script.Parent.Parent.DataSave.loadStarterInventory)

local PlayerInventories = {}  -- Stores full weaponSystem for each player
local playerSlots = {}
local lastMoveTime = {}

-- Get template data
local templateData = RequestPlayerData:Invoke()
print("Template data loaded:", templateData)

-- Helper to create fresh inventory for a player
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
    
    -- Copy Clothing
    for k, v in pairs(templateInventory.Equipment.Clothing) do
        newInventory.Equipment.Clothing[k] = { equipped = v.equipped, name = v.name }
    end
    
    -- Copy Utils
    for k, v in pairs(templateInventory.Equipment.Utils) do
        newInventory.Equipment.Utils[k] = { equipped = v.equipped, name = v.name }
    end
    
    -- Copy Weapons
    for k, v in pairs(templateInventory.Equipment.Weapons) do
        newInventory.Equipment.Weapons[k] = { equipped = v.equipped, item = v.item }
    end
    
    return newInventory
end

Players.PlayerAdded:Connect(function(player)
    print("Player joined:", player.Name)
    
    -- Create fresh inventory for player
    local playerInventory = createPlayerInventory()
    
    -- Load saved inventory from DataStore
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
        -- Give starter kit
        local starterKit = {"HK416", "Khrissy10R", "Tomahawk", "MK2"}
        for i, item in ipairs(starterKit) do
            playerInventory.PlayerInventory[i] = item
        end
        print("Gave starter kit to:", player.Name)
    end
    
    -- Store full weaponSystem for player
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
    }
    
    -- Send inventory to client
    SendInventory:FireClient(player, playerInventory)
end)

Players.PlayerRemoving:Connect(function(player)
    local playerData = PlayerInventories[player]
    
    if playerData and playerData.Inventory then
        local success, err = pcall(function()
            defaultInventory.saveInventory(player, { weaponSystem = { Inventory = playerData.Inventory } })
        end)
        
        if success then
            print("Saved inventory for", player.Name)
        else
            warn("Failed to save inventory for", player.Name, err)
        end
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

MoveItem.OnServerInvoke = function(player, fromSlot, toSlot)
	print("[SERVER] ===== MoveItem INVOKED ===== by:", player.Name)
    print("[SERVER] fromSlot:", fromSlot, "toSlot:", toSlot)
    
    local playerData = PlayerInventories[player]
    if not playerData or not playerData.Inventory then return false end
    
    local inventory = playerData.Inventory.PlayerInventory
    
    -- Validate
    if typeof(fromSlot) ~= "number" or typeof(toSlot) ~= "number" then return false end
    if fromSlot < 1 or toSlot < 1 then return false end
    if fromSlot == toSlot then return false end
    if not inventory[fromSlot] or inventory[fromSlot] == "" then return false end
    
    -- Anti-cheat validation
    if playerSlots[player] and playerSlots[player].slots then
        local slotKey = "Slot" .. fromSlot
        if playerSlots[player].slots[slotKey] ~= inventory[fromSlot] then
            print(player.Name, "item mismatch - cheating detected!")
            player:Kick("Cheating detected")
            return false
        end
    end
    
    -- Rate limiting
    local now = tick()
    if lastMoveTime[player] and now - lastMoveTime[player] < 0.1 then
        return false
    end
    lastMoveTime[player] = now
    
    -- Ensure destination slot exists
    if not inventory[toSlot] then
        inventory[toSlot] = ""
    end

    local fromItem = inventory[fromSlot]
    local toItem = inventory[toSlot]

    if toItem ~= "" then
        -- Swap items
        inventory[fromSlot] = toItem
        inventory[toSlot] = fromItem
    else
        -- Move item
        inventory[toSlot] = fromItem
        inventory[fromSlot] = ""
    end

    -- Save and sync
    defaultInventory.saveInventory(player, { weaponSystem = { Inventory = playerData.Inventory } })
    SendInventory:FireClient(player, playerData.Inventory)
    
    return true
end