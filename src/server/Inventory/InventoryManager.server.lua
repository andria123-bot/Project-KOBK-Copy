local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local defaultInventory = require(script.Parent.Parent.DataSave.loadStarterInventory)
local SendInventory = ReplicatedStorage.Shared.Remotes.InventoryEvents:WaitForChild("SendInventory")
local RequestPlayerData = ReplicatedStorage.Shared.Remotes.Bindables:WaitForChild("RequestPlayerData")

local data = RequestPlayerData:Invoke()

Players.PlayerAdded:Connect(function(player)
    local playerInventory = {
        PlayerInventory = {},
        StorageInventory = {},
        Equipment = data.Inventory.Equipment,
        SlotCount = data.Inventory.SlotCount
    }
    
    local savedInventory = defaultInventory.loadSavedInventory(player)
    if savedInventory then
        for i, item in pairs(savedInventory) do
            playerInventory.PlayerInventory[i] = item
        end
    else
        local starterKit = {"HK416", "Khrissy10R", "Tomahawk", "MK2"}
        for i, item in pairs(starterKit) do
            playerInventory.PlayerInventory[i] = item
        end
    end
    
    wait(1.2)
    SendInventory:FireClient(player, playerInventory)
end)