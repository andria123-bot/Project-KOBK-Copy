local defaultInventory = {}

local DataStoreService = game:GetService("DataStoreService")
local inventoryStore = DataStoreService:GetDataStore("InventoryStore")

function defaultInventory.loadSavedInventory(player)
    local success, data = pcall(function()
        return inventoryStore:GetAsync(tostring(player.UserId))
    end)

    if not success then
        warn("Failed to load inventory for player:", player.UserId, data)
        return nil
    end

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

return defaultInventory