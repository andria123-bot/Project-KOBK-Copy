-- Init.client.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = Players.LocalPlayer

local InventoryController = require(script.Parent.Controllers.InventoryController)

-- Wait for player data folder
local function waitForPlayerData()
    local playersFolder = ReplicatedStorage:FindFirstChild("Players")
    if not playersFolder then
        playersFolder = Instance.new("Folder")
        playersFolder.Name = "Players"
        playersFolder.Parent = ReplicatedStorage
    end
    
    local playerFolder = playersFolder:FindFirstChild(Player.Name)
    while not playerFolder do
        task.wait(0.1)
        playerFolder = playersFolder:FindFirstChild(Player.Name)
    end
    
    return playerFolder
end

-- Wait for player folder to be ready
local playerFolder = waitForPlayerData()

-- Start the inventory controller (it will find its own UI containers)

print("[Init]: Inventory system started")