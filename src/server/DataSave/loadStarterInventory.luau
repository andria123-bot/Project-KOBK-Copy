
--[[
    Loads default kit for new players from DefaultInventory

]]

local defaultInventory = {}

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local inventoryStore = DataStoreService:GetDataStore("InventoryStore")

local InventoryUpdate = ReplicatedStorage.Shared.Remotes.InventoryEvents:WaitForChild("InventoryUpdate")

local starterKit = {
    "HK416";
    "Khrissy10R";
    "Tomahawk";
    "MK2";
    "Empty";
    "Empty";
    "Empty";
    "Empty";
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
        -- Has saved data, use it
        for i = 1, #savedInventory do
            inventory[i] = savedInventory[i] or ""
        end
        return true
    else
        -- NO saved data, give starter kit
        return defaultInventory.loadDefaultInventory(playerData)  -- This gives starter items
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

local function sendInventoryToClient(player, playerData)
    InventoryUpdate:FireClient(player, playerData.weaponSystem.inventory)
end

return defaultInventory