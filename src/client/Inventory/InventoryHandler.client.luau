local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local player = Players.LocalPlayer

script.Parent.Parent.Inventory.Parent = player.PlayerGui:WaitForChild("Menu").MainParent

local RequestModule = ReplicatedStorage.Shared.Remotes:WaitForChild("RequestModule")
local MoveItem = ReplicatedStorage.Shared.Remotes.InventoryEvents:WaitForChild("MoveItem")
local SendInventory = ReplicatedStorage.Shared.Remotes.InventoryEvents:WaitForChild("SendInventory")
local templateSlot = ReplicatedStorage.GUIS:WaitForChild("Slot")