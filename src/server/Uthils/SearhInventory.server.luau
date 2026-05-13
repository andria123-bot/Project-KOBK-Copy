-- ServerScriptService.Utils.SearhInventory
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function SearhInventory(player, slotName)
    local playerFolder = ReplicatedStorage.Players:FindFirstChild(player.Name)
    if not playerFolder then return nil end
    
    -- Pattern 1: Equipment slots (Armor, Helmet, Gun1, Melee, etc.)
    local equipmentSlots = {
        Armor = true, Helmet = true, TShirt = true, Pants = true,
        Backpack = true, Mask = true, Gloves = true, Leggings = true,
        Gun1 = true, Gun2 = true, Gun3 = true, Melee = true,
        GPS = true, Map = true, Compass = true, Radio = true
    }
    
    if equipmentSlots[slotName] then
        -- For clothing items, return Clothing folder
        if slotName == "Armor" or slotName == "Helmet" or slotName == "TShirt" or 
           slotName == "Pants" or slotName == "Backpack" or slotName == "Mask" or
           slotName == "Gloves" or slotName == "Leggings" then
            return playerFolder:FindFirstChild("Clothing")
        end
        -- For weapons and tools, return Equipment folder
        return playerFolder:FindFirstChild("Equipment")
    end
    
    -- Pattern 2: Container inventory slots (Backpack1, Shirt2, Pants3, etc.)
    local containerMatch = string.match(slotName, "^(Backpack|Shirt|Pants|Armor)(%d+)$")
    if containerMatch then
        local containerType = containerMatch  -- "Backpack", "Shirt", etc.
        local slotNumber = tonumber(containerMatch)  -- 1, 2, 3, etc.
        
        -- Find the clothing item that has this container
        local clothingFolder = playerFolder:FindFirstChild("Clothing")
        if clothingFolder then
            -- Map container type to slot name
            local slotTypeMap = {
                Backpack = "Backpack",
                Shirt = "TShirt",
                Pants = "Pants",
                Armor = "Armor"
            }
            local slotType = slotTypeMap[containerType]
            
            local clothingItem = clothingFolder:FindFirstChild(slotType)
            if clothingItem then
                local invFolder = clothingItem:FindFirstChild("Inventory")
                if invFolder then
                    return invFolder
                end
            end
        end
        return nil
    end
    
    -- Pattern 3: Container view slots (ContainerBackpack1, etc.)
    local containerViewMatch = string.match(slotName, "^Container(Backpack|Shirt|Pants)(%d+)$")
    if containerViewMatch then
        -- For container view, return the container's Inventory folder
        -- Used when looting another player or container
        local containerType = containerViewMatch
        -- Implementation depends on your container system
        return nil
    end
    
    -- Pattern 4: Inventory slots (1, 2, 3, etc.) - backpack main inventory
    local inventoryNumber = tonumber(slotName)
    if inventoryNumber then
        local inventoryFolder = playerFolder:FindFirstChild("Inventory")
        if inventoryFolder then
            return inventoryFolder
        end
        return nil
    end
    
    return nil
end

--[[
Slot Name	Returns
"Armor"	Players[player].Clothing
"Gun1"	Players[player].Equipment
"Backpack3"	Players[player].Clothing.Backpack.Inventory
"1"	Players[player].Inventory
]]

return SearhInventory