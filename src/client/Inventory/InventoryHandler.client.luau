local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

script.Parent.InventoryHandler.Parent = player.PlayerGui:WaitForChild("Toolbar").MainFrame

local moduleFinder = require(game:GetService("StarterPlayer").StarterCharacterScripts.WeaponSystem.LoadModule)

local SendInventory = ReplicatedStorage.Shared.Remotes:WaitForChild("SendInventory")

local playerGui = player:WaitForChild("PlayerGui")
local toolbar = playerGui:WaitForChild("Toolbar")
local MainFrame = toolbar.MainFrame

SendInventory.OnClientEvent:Connect(function(inventory)
	for i = 1, 8 do
		local slot = MainFrame:FindFirstChild("Slot" .. i, true)
		local itemName = inventory[i]
		
		if slot then
			if itemName and itemName ~= "" then
				local weaponModule = moduleFinder.GetModule(itemName)
				if weaponModule and weaponModule.imageIconId then
					slot.ItemIcon.Image = weaponModule.imageIconId
				end
				slot.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
			else
				slot.ItemIcon.Image = ""
				slot.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
			end
		end
	end
end)