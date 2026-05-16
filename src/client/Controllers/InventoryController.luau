-- InventoryController.client.luau
local InventoryUIController = require(script.Parent.Parent.Inventory.InventoryUIController)
local Player = game:GetService("Players").LocalPlayer

local InventoryController = {}

local function refreshInventory()
    InventoryUIController:Refresh()
end

-- Watch for changes in ReplicatedStorage
local playersFolder = game:GetService("ReplicatedStorage"):FindFirstChild("Players")
if playersFolder then
    local playerFolder = playersFolder:FindFirstChild(Player.Name)
    if playerFolder then
        local clothingFolder = playerFolder:FindFirstChild("Clothing")
        if clothingFolder then
            clothingFolder.ChildAdded:Connect(refreshInventory)
            clothingFolder.ChildRemoved:Connect(refreshInventory)
        end
    end
end

-- Initial refresh
refreshInventory()

return InventoryController