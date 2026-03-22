local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InventoryInitializer = {}

local RequestGear = ReplicatedStorage.Shared.Remotes.RequestGear

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Menu = playerGui:WaitForChild("Menu")
local MainParent = Menu.MainParent
local RowsParent = MainParent.InventoryParent.InventoryGui.InventoryItemsFrame.SingleRowParent

local Toolbar = playerGui:WaitForChild("Toolbar")
local MainFrame = Toolbar.MainFrame

function InventoryInitializer:InitInventory()
    print("AAA", RequestGear:InvokeServer())
end

InventoryInitializer:InitInventory()
return InventoryInitializer