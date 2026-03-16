local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

script.Parent.InventoryHandler.Parent = player.PlayerGui:WaitForChild("Toolbar").MainFrame

local moduleFinder = require(game:GetService("StarterPlayer").StarterCharacterScripts.WeaponSystem.LoadModule)

local SendInventory = ReplicatedStorage.Shared.Remotes.InventoryEvents:WaitForChild("SendInventory")

local GearsSetup = require(script.Parent.GearsSetup)

local playerGui = player:WaitForChild("PlayerGui")
local toolbar = playerGui:WaitForChild("Toolbar")
local MainFrame = toolbar.MainFrame

local dragging = {
	active = false,
	fromSlot = nil,
	clone = nil,
}

slots = {
	inventory = {},
	gear = {};
	toolbar = {};
}

function InitSys()
	if GearsSetup.gear.TShirt ~= nil then
		for i = 1, 5 do
			slots.inventory[i] = MainFrame:FindFirstChild("Slot" .. i, true)
		end	
	end

	if GearsSetup.gear.Pants ~= nil then
		for i = 5, 10 do
			slots.inventory[i] = MainFrame:FindFirstChild("Slot" .. i, true)
		end	
	end
end

-- SendInventory.OnClientEvent:Connect(function(inventory)
-- 	for i = 1, 8 do
-- 		local slot = MainFrame:FindFirstChild("Slot" .. i, true)
-- 		local itemName = inventory[i]
		
-- 		if slot then
-- 			if itemName and itemName ~= "" then
-- 				local weaponModule = moduleFinder.GetModule(itemName)
-- 				if weaponModule and weaponModule.imageIconId then
-- 					slot.ItemIcon.Image = weaponModule.imageIconId
-- 				end
-- 				slot.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
-- 			else
-- 				slot.ItemIcon.Image = ""
-- 				slot.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
-- 			end
-- 		end
-- 	end
-- end)