local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

script.Parent.Parent.Inventory.Parent = player.PlayerGui:WaitForChild("Menu").MainParent

local RequestModule = ReplicatedStorage.Shared.Remotes:WaitForChild("RequestModule")

local MoveItem = ReplicatedStorage.Shared.Remotes.InventoryEvents:WaitForChild("MoveItem")

local SlotInitializer = require(script.Parent.SlotInitializer)
SlotInitializer:InitSys()
SlotInitializer:ApplyParentSize()
SlotInitializer:ApplyRows()

local SendInventory = ReplicatedStorage.Shared.Remotes.InventoryEvents:WaitForChild("SendInventory")

local templateSlot = ReplicatedStorage.GUIS:WaitForChild("Slot")

local slots = SlotInitializer.slots

MoveItem:FireServer("Slot6", "Slot7")