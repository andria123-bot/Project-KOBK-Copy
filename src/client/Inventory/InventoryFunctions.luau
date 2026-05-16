-- InventoryFunctions.client.luau (MODULESCRIPT)
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local InventoryFunctions = {}

function InventoryFunctions.PickupItem()
    local InventoryService = Knit.GetService("InventoryService")
    if InventoryService then
        InventoryService:PickupItem():catch(function(err)
            warn("Pickup failed:", err)
        end)
    end
end

return InventoryFunctions