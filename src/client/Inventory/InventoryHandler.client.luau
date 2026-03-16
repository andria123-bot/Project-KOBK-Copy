local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

script.Parent.InventoryHandler.Parent = player.PlayerGui:WaitForChild("Toolbar").MainFrame

local moduleFinder = require(game:GetService("StarterPlayer").StarterCharacterScripts.WeaponSystem.LoadModule)

local RequestModule = ReplicatedStorage.Shared.Remotes.RequestModuleRemote

local SendInventory = ReplicatedStorage.Shared.Remotes.InventoryEvents:WaitForChild("SendInventory")

local GearsSetup = require(script.Parent.GearsSetup)

local templateSlot = ReplicatedStorage.GUIS:WaitForChild("Slott")

local playerGui = player:WaitForChild("PlayerGui")
local toolbar = playerGui:WaitForChild("Toolbar")
local MainFrame = toolbar.MainFrame

local dragging = {
	active = false,
	fromSlot = nil,
	clone = nil,
}

slots = { -- just visual slots
	inventory = {},
	gear = {};
	toolbar = {};
}

function InitSys()
	if GearsSetup.gear.TShirt ~= nil then
		for i = 1, 5 do
			slots.inventory[i] = MainFrame:FindFirstChild("Slot" .. i, true)
			templateSlot.Parent = MainFrame.InventoryGui.InventoryItemsFrame.TShirtRow
		end	
	end

	if GearsSetup.gear.Pants ~= nil then
		for i = 5, 10 do
			slots.inventory[i] = MainFrame:FindFirstChild("Slot" .. i, true)
			templateSlot.Parent = MainFrame.InventoryGui.InventoryItemsFrame.PantsRow
		end	
	end

	if GearsSetup.gear.Backpack ~= nil then
		local itemModule = RequestModule:FireServer(GearsSetup.gear.Backpack)

		if itemModule then
			for i = 10, itemModule.slotCount do
				slots.inventory[i] = MainFrame
				templateSlot.Parent = MainFrame.InventoryGui.InventoryItemsFrame.BackpackRow
			end
		end
	end

	if GearsSetup.gear.ChestRig ~= nil then
		local itemModule = RequestModule:FireServer(GearsSetup.gear.ChestRig)

		if itemModule then
			for i = 30, itemModule.slotCount do
				slots.inventory[i] = MainFrame
				templateSlot.Parent = MainFrame.InventoryGui.InventoryItemsFrame.BackpackRow
			end
		end
	end
end

function createSlot(index, parent)
	local newSlot = templateSlot:Clone()
    newSlot.Name = "Slot" .. index
    newSlot.Parent = parent
    return newSlot
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