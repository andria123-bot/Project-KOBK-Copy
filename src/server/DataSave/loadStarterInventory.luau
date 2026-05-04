local defaultInventory = {}

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local inventoryStore = DataStoreService:GetDataStore("InventoryStore")

local SendInventory = ReplicatedStorage.Shared.Remotes.InventoryEvents:WaitForChild("SendInventory")

local starterKit = {
    "HK416";
    "Khrissy10R";
    "Tomahawk";
    "MK2";
}

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
    
    if savedInventory and type(savedInventory) == "table" then
        -- Load saved data (even if empty slots)
        for i = 1, #savedInventory do
            if savedInventory[i] and savedInventory[i] ~= "" then
                inventory[i] = savedInventory[i]
            else
                inventory[i] = ""
            end
        end
        
        -- Check if saved inventory has ANY items
        local hasAnyItem = false
        for _, item in pairs(inventory) do
            if item and item ~= "" then
                hasAnyItem = true
                break
            end
        end
        
        -- ONLY give starter kit if NO items AND no saved data found
        if not hasAnyItem then
            -- Check if saved file actually existed
            if savedInventory._exists then
                -- Saved file existed but was empty, don't give starter kit
                print("Player has empty inventory, not giving starter kit")
            else
                return defaultInventory.loadDefaultInventory(playerData)
            end
        end
        
        return true
    else
        -- No saved file at all, give starter kit
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

function defaultInventory.initPlayerInventory(player, playerData)
    defaultInventory.ensureWeaponSystem(playerData)
    
    local savedInventory = defaultInventory.loadSavedInventory(player)
    
    local success = defaultInventory.mergeInventory(playerData, savedInventory)
    
    if success then
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
    
    task.wait(0.5)
    
    local inventory = playerData.weaponSystem.Inventory.PlayerInventory
    print("Sending inventory to client:", player.Name, "Items:", #inventory)
    
    local cleanInventory = {}
    for i = 1, #inventory do
        cleanInventory[i] = inventory[i] or ""
    end
    
    SendInventory:FireClient(player, cleanInventory)  -- was InventoryUpdate
    return true
end

function defaultInventory.getInventory(playerData)
    defaultInventory.ensureWeaponSystem(playerData)
    return playerData.weaponSystem.Inventory.PlayerInventory
end

function defaultInventory.addItem(playerData, itemName)
    defaultInventory.ensureWeaponSystem(playerData)
    local inventory = playerData.weaponSystem.Inventory.PlayerInventory
    
    for i = 1, #inventory do
        if not inventory[i] or inventory[i] == "" then
            inventory[i] = itemName
            return true, i
        end
    end
    
    table.insert(inventory, itemName)
    return true, #inventory
end

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