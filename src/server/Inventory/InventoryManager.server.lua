local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local defaultInventory = require(script.Parent.Parent.DataSave.loadStarterInventory)
local SendInventory = ReplicatedStorage.Shared.Remotes.InventoryEvents:WaitForChild("SendInventory")
local RequestPlayerData = ReplicatedStorage.Shared.Remotes.Bindables:WaitForChild("RequestPlayerData")

local data = RequestPlayerData:Invoke()

local defaultInventory = require(script.Parent.Parent.DataSave.loadStarterInventory)

Players.PlayerAdded:Connect(function(player)
    local playerData = {
        weaponSystem = {
            Inventory = {
                PlayerInventory = {},
                StorageInventory = {},
                Equipment = data.Inventory.Equipment, 
                SlotCount = data.Inventory.SlotCount
            }
        }
    }
    
    local savedInventory = defaultInventory.loadSavedInventory(player)
    
    defaultInventory.mergeInventory(playerData, savedInventory)

    SendInventory:FireClient(player, playerData.weaponSystem.Inventory.PlayerInventory)
end)