--[[
    Loads default kit for new players from DefaultInventory
]]

local defaultInventory = {}

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local inventoryStore = DataStoreService:GetDataStore("InventoryStore")

local InventoryUpdate = ReplicatedStorage.Shared.Remotes.InventoryEvents:WaitForChild("InventoryUpdate")
local PlayerSlotData = ReplicatedStorage.Shared.Remotes.InventoryEvents:WaitForChild("PlayerSlotData")

PlayerSlotData.OnServerEvent:Connect(function(player, slotData)
    local slots = slotData
    for i, v in pairs(slots) do
        print(i, v)
    end
end)

local starterKit = {
    "HK416";
    "Khrissy10R";
    "Tomahawk";
    "MK2";
}

-- Helper function to ensure weaponSystem exists
function defaultInventory.ensureWeaponSystem(playerData)
    if not playerData.weaponSystem then
        playerData.weaponSystem = {
            Inventory = {
                PlayerInventory = {}
            }
        }
        return false
    elseif not playerData.weaponSystem.Inventory then
        playerData.weaponSystem.Inventory = {
            PlayerInventory = {}
        }
        return false
    elseif not playerData.weaponSystem.Inventory.PlayerInventory then
        playerData.weaponSystem.Inventory.PlayerInventory = {}
        return false
    end
    return true
end

function defaultInventory.loadDefaultInventory(playerData)
    defaultInventory.ensureWeaponSystem(playerData)
    
    local inventory = playerData.weaponSystem.Inventory.PlayerInventory
    
    -- Clear existing inventory first (optional)
    for i = 1, #inventory do
        inventory[i] = nil
    end
    
    -- Load starter kit
    for i = 1, #starterKit do
        inventory[i] = starterKit[i]
    end
    
    return true
end

function defaultInventory.mergeInventory(playerData, savedInventory)
    defaultInventory.ensureWeaponSystem(playerData)
    
    local inventory = playerData.weaponSystem.Inventory.PlayerInventory
    
    if savedInventory and type(savedInventory) == "table" and #savedInventory > 0 then
        -- Has valid saved data, use it
        for i = 1, #savedInventory do
            if savedInventory[i] and savedInventory[i] ~= "" then
                inventory[i] = savedInventory[i]
            else
                inventory[i] = ""
            end
        end
        
        -- Check if saved inventory is empty
        local hasItems = false
        for _, item in ipairs(inventory) do
            if item and item ~= "" then
                hasItems = true
                break
            end
        end
        
        if not hasItems then
            return defaultInventory.loadDefaultInventory(playerData)
        end
        
        return true
    else
        -- NO saved data or invalid saved data, give starter kit
        return defaultInventory.loadDefaultInventory(playerData)
    end
end

function defaultInventory.loadSavedInventory(player)
    local success, data = pcall(function()
        return inventoryStore:GetAsync(tostring(player.UserId))
    end)
    
    if not success then
        warn("Failed to load inventory for player:", player.UserId, data)
        return nil
    end
    
    -- Validate the data structure
    if data and type(data) == "table" then
        return data
    end
    
    return nil
end

function defaultInventory.saveInventory(player, playerData)
    if not player or not playerData or not playerData.weaponSystem or 
       not playerData.weaponSystem.Inventory or 
       not playerData.weaponSystem.Inventory.PlayerInventory then
        warn("Cannot save inventory: Invalid data structure for player:", player and player.UserId)
        return false
    end
    
    local success, err = pcall(function()
        inventoryStore:SetAsync(tostring(player.UserId), playerData.weaponSystem.Inventory.PlayerInventory)
    end)
    
    if not success then
        warn("Failed to save inventory for player:", player.UserId, err)
        return false
    end
    
    return true
end

-- Main function to initialize player inventory
function defaultInventory.initPlayerInventory(player, playerData)
    defaultInventory.ensureWeaponSystem(playerData)
    
    -- Try to load saved inventory
    local savedInventory = defaultInventory.loadSavedInventory(player)
    
    -- Merge saved inventory or load default
    local success = defaultInventory.mergeInventory(playerData, savedInventory)
    
    if success then
        -- Send to client after inventory is properly loaded
        defaultInventory.sendInventoryToClient(player, playerData)
        return true
    else
        warn("Failed to initialize inventory for player:", player.UserId)
        return false
    end
end

function defaultInventory.sendInventoryToClient(player, playerData)
    if not player or not player.Parent then
        warn("Cannot send inventory: Player is nil or not in game")
        return false
    end
    
    if not playerData or not playerData.weaponSystem or 
       not playerData.weaponSystem.Inventory or 
       not playerData.weaponSystem.Inventory.PlayerInventory then
        warn("Cannot send inventory: Invalid playerData structure")
        return false
    end
    
    -- Small delay to ensure player is fully loaded
    task.wait(0.5)
    
    local inventory = playerData.weaponSystem.Inventory.PlayerInventory
    print("Sending inventory to client:", player.Name, "Items:", #inventory)
    
    -- Convert any nil values to empty strings for client
    local cleanInventory = {}
    for i = 1, #inventory do
        cleanInventory[i] = inventory[i] or ""
    end
    
    InventoryUpdate:FireClient(player, cleanInventory)
    return true
end

-- Helper function to check current inventory
function defaultInventory.getInventory(playerData)
    defaultInventory.ensureWeaponSystem(playerData)
    return playerData.weaponSystem.Inventory.PlayerInventory
end

-- Helper function to add an item to inventory
function defaultInventory.addItem(playerData, itemName)
    defaultInventory.ensureWeaponSystem(playerData)
    local inventory = playerData.weaponSystem.Inventory.PlayerInventory
    
    -- Find first empty slot
    for i = 1, #inventory do
        if not inventory[i] or inventory[i] == "" then
            inventory[i] = itemName
            return true, i
        end
    end
    
    -- Add to next slot if all slots are filled
    table.insert(inventory, itemName)
    return true, #inventory
end

-- Helper function to remove item from inventory
function defaultInventory.removeItem(playerData, slotIndex)
    defaultInventory.ensureWeaponSystem(playerData)
    local inventory = playerData.weaponSystem.Inventory.PlayerInventory
    
    if slotIndex and inventory[slotIndex] then
        inventory[slotIndex] = ""
        return true
    end
    
    return false
end

return defaultInventory