local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

script.Parent.Parent.Inventory.Parent = player.PlayerGui:WaitForChild("Menu").MainParent

-- local moduleFinder = require(game:GetService("StarterPlayer").StarterCharacterScripts.WeaponSystem.LoadModule)
local GearsSetup = require(script.Parent.GearsSetup)

local RequestModule = ReplicatedStorage.Shared.Remotes:WaitForChild("RequestModule")
local SendInventory = ReplicatedStorage.Shared.Remotes.InventoryEvents:WaitForChild("SendInventory")

local templateSlot = ReplicatedStorage.GUIS:WaitForChild("Slot")

local playerGui = player:WaitForChild("PlayerGui")
local Menu = playerGui:WaitForChild("Menu")
local MainParent = Menu.MainParent

local Toolbar = playerGui:WaitForChild("Toolbar")
local MainFrame = Toolbar.MainFrame

local RowsParent = MainParent.InventoryParent.InventoryGui.InventoryItemsFrame.SingleRowParent
local TemplateInvRow = ReplicatedStorage.GUIS.TemplateInvRow:Clone()


local dragging = {
	active = false,
	fromSlot = nil,
	clone = nil,
}

local sizes = {
    UDim2.new(0, 413, 0, 100), -- 1 row
    UDim2.new(0, 413, 0, 210), -- 2 row
    UDim2.new(0, 413, 0, 322), -- 3 row
    UDim2.new(0, 413, 0, 432), -- 4 row
}

local slots = { -- just visual slots
	inventory = {},
	gear = {};
	toolbar = {};
}

local priority = {"BodyArmor", "TShirt", "Pants"}

local function GetBackpackModule(BagName)
	return RequestModule:FireServer(BagName)
end

local function GetPlayerSlotRows()
	local count = 1

	for i, v in pairs(GearsSetup.gear) do
        if (i == "TShirt" or i == "Pants" or i == "Armor") and v.equipped then
            count += 1
        elseif i == "Backpack" and v.equipped then
            local backpackModule = GetBackpackModule(v.name)

			if backpackModule then
				print(1)
				--[[
					Parent the InventorySlotParent
					Parent the slots to InventorySlotParent
				]]
			end
        end
    end

	return count
end

local function ApplyParentSize()
	local availableSlotRows = GetPlayerSlotRows()
	
	local index = math.clamp(availableSlotRows, 1, #sizes)
	RowsParent.Size = sizes[index]
end

local function ApplyRows()
	for _, child in pairs(RowsParent:GetChildren()) do
        if child:IsA("Frame") and child.Name ~= "EquipmentRow" then
            child:Destroy()
        end
    end

    for _, gearName in ipairs(priority) do
        local equipped = GearsSetup.gear[gearName]
        if equipped then
            local newRow = TemplateInvRow:Clone()
            newRow.Name = gearName.."Row"
            newRow.Parent = RowsParent
            newRow.RowLabel.Text = gearName
        end
    end
end

function InitSys()
	ApplyParentSize()
	ApplyRows()
end

InitSys()

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