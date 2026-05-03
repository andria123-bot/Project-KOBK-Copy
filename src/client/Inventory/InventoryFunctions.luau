local InventoryFunctions = {}

function InventoryFunctions.HasItem(playerInventoryData, itemName)
    for _, item in pairs(playerInventoryData) do
        if item == itemName then
            return true
        end
    end
    return false
end

return InventoryFunctions