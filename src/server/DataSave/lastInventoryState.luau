local inventoryStore = game:GetService("DataStoreService"):GetDataStore("PlayerInventories")

local lastInventoryState = {}

function SaveInventory(player, newInventory)
    local oldInventory = lastInventoryState[player]
    
    -- Check if inventory actually changed
    local hasChanged = false
    if not oldInventory then
        hasChanged = true
    else
        for i = 1, #newInventory do
            if newInventory[i] ~= oldInventory[i] then
                hasChanged = true
                break
            end
        end
    end
    
    if not hasChanged then
        print("Inventory unchanged, skipping save")
    end
    
    -- Save to DataStore
    local success = pcall(function()
        inventoryStore:SetAsync(player.UserId, newInventory)
    end)
    
    if success then
        -- Update cached state
        lastInventoryState[player] = {}
        for i, item in pairs(newInventory) do
            lastInventoryState[player][i] = item
        end
        print("Inventory saved for:", player.Name)
    end
    
    return success
end

return lastInventoryState