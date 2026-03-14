local defaultInventory = {}

local DataStoreService = game:GetService("DataStoreService")
local inventoryStore = DataStoreService:GetDataStore("InventoryStore")

local starterKit = {
    "HK416";
    "KHRISSY10R";
    "Tomahawk";
    "MK2";
}

function defaultInventory.loadDefaultInventory(playerData)
    if not playerData.weaponSystem then return false end

    local inventory = playerData.weaponSystem.inventory
    local hasItems = false
    for _, item in ipairs(inventory) do
        if item and item ~= "" then
            hasItems = true
            break
        end
    end

    if not hasItems then
        for i = 1, #starterKit do
            inventory[i] = starterKit[i]
        end
        for i = #starterKit + 1, 9 do
            inventory[i] = ""
        end
        return true
    end

    return false
end

function defaultInventory.mergeInventory(playerData, savedInventory)
    if not playerData.weaponSystem then return false end

    local inventory = playerData.weaponSystem.inventory
    if savedInventory then
        for i = 1, #savedInventory do
            inventory[i] = savedInventory[i] or ""
        end
        return true
    else
        return defaultInventory.loadDefaultInventory(playerData)
    end
end

function defaultInventory.loadSavedInventory(player)
    local success, data = pcall(function()
        return inventoryStore:GetAsync(player.UserId)
    end)
    if not success then
        warn("Failed to load inventory for player:", player.UserId)
    end
    return data
end

function defaultInventory.saveInventory(player, playerData)
    pcall(function()
        inventoryStore:SetAsync(player.UserId, playerData.weaponSystem.inventory)
    end)
end

return defaultInventory