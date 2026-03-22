local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

script.Parent.Parent.Inventory.Parent = player.PlayerGui:WaitForChild("Menu").MainParent

local RequestModule = ReplicatedStorage.Shared.Remotes:WaitForChild("RequestModule")

-- local InventoryInitializer = require(script.Parent.InventoryInitializer)

local SlotInitializer = require(script.Parent.SlotInitializer)
SlotInitializer:InitSys()
SlotInitializer:ApplyParentSize()
SlotInitializer:ApplyRows()

local SendInventory = ReplicatedStorage.Shared.Remotes.InventoryEvents:WaitForChild("SendInventory")

local templateSlot = ReplicatedStorage.GUIS:WaitForChild("Slot")

local slots = SlotInitializer.slots

SendInventory.OnClientEvent:Connect(function(inventory)
    if not inventory then return end


end)