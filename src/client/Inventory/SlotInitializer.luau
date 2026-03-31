local SlotInitializer = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local playerGui = player:WaitForChild("PlayerGui")
local Menu = playerGui:WaitForChild("Menu")
local MainParent = Menu.MainParent
local RowsParent = MainParent.InventoryParent.InventoryGui.InventoryItemsFrame.SingleRowParent
local RequestModule = ReplicatedStorage.Shared.Remotes:WaitForChild("RequestModule")

local Toolbar = playerGui:WaitForChild("Toolbar")
local MainFrame = Toolbar.MainFrame

local TemplateInvRow = ReplicatedStorage.GUIS.TemplateInvRow

local RequestGear = ReplicatedStorage.Shared.Remotes.RequestGear

SlotInitializer.rowsParent = RowsParent

SlotInitializer.slots = {
	inventory = {}, -- slots based on player's clothes/backpack/armor
	gear = {}, -- helmet, armor, backpack, etc.
	utils = {}, -- slots for grenades, throwables, etc.(4-8)
}

SlotInitializer.sizes = {
	UDim2.fromOffset(413, 100),
	UDim2.fromOffset(413, 210),
	UDim2.fromOffset(413, 322),
	UDim2.fromOffset(413, 432),
}

SlotInitializer.priority = {"Armor", "TShirt", "Pants"}

function SlotInitializer:InitGearGUI()
    local gearGUI = MainParent.GearParent.GearGUI
    if not gearGUI then return end
    
    self.slots.gearGUI = {}
    
    local gearSlotNames = {"Helmet", "Mask", "ChestRig", "Backpack", "TShirt", "Pants", "Leggings", "Melee", "Slot1", "Slot2", "Slot3"}
    
    for _, slotName in pairs(gearSlotNames) do
        local slot = gearGUI:FindFirstChild(slotName)
        if slot and slot:IsA("Frame") then
            self.slots.gearGUI[slotName] = slot
            table.insert(self.slots.gearGUI, slot) -- store by index for easier iteration
        end
    end
    
    return #self.slots.gearGUI
end

function SlotInitializer:InitToolbarSlots()
	local toolbarContainer = MainFrame.Loadout
	local toolbarIndex = 1

	for _, slot in pairs(toolbarContainer:GetChildren()) do -- just change the icon of slot
		if slot:IsA("Frame") and slot.Name:find("Slot") and toolbarIndex <= 3 then
			self.slots.toolbar[toolbarIndex] = slot
			slot.Name = "ToolbarSlot" .. toolbarIndex
			slot.ItemIcon.Image = ""
			toolbarIndex += 1
		end
	end

	return toolbarIndex - 1
end

function SlotInitializer:InitToolbarUtils()
	local toolbarContainer = MainFrame.Utils
	local utilsIndex = 1

	for _, slot in pairs(toolbarContainer:GetChildren()) do
		if slot:IsA("Frame") and slot.Name:find("Slot") and utilsIndex <= 5 then
			self.slots.utils[utilsIndex] = slot
			slot.Name = "UtilsSlot" .. utilsIndex
			slot.ItemIcon.Image = ""
			utilsIndex += 1
		end
	end

	return utilsIndex - 1
end

function SlotInitializer:InitSlots()
	local globalIndex = 1

	for _, row in pairs(self.rowsParent:GetChildren()) do
		if row:IsA("Frame") and row.Name ~= "EquipmentRow" then
			local container = row:FindFirstChild("RowsParent")
			if container then
				for _, slot in pairs(container:GetChildren()) do
					if slot:IsA("Frame") then
						self.slots.inventory[globalIndex] = slot
						slot.Name = "Slot" .. tostring(globalIndex)
						slot.ItemIcon.Image = ""
						globalIndex += 1
					end
				end
			end
		end
	end

	return globalIndex - 1
end

function SlotInitializer:InitAllSlots()
	local toolbarCount = self:InitToolbarSlots()
	local utilsCount = self:InitToolbarUtils()
	local inventoryCount = self:InitSlots()

	return {
		toolbar = toolbarCount,
		utils = utilsCount,
		inventory = inventoryCount
	}
end

local function GetBackpackModule(backpackName)
	if backpackName then
		return RequestModule:InvokeServer(backpackName)
	end
	return nil
end

function SlotInitializer:GetPlayerSlotRows()
	local count = 1

	for i, v in pairs(self.gearData or {}) do
		if (i == "TShirt" or i == "Pants" or i == "Armor") and v.equipped then
			count += 1
		elseif i == "Backpack" and v.equipped and v.name then
			local backpackModule = GetBackpackModule(v.name)
			if backpackModule then
				print("Equipped Backpack: ", v.name)
			end
		end
	end

	return count
end

function SlotInitializer:ApplyParentSize()
	local count = self:GetPlayerSlotRows()
	self.rowsParent.Size = self.sizes[math.clamp(count, 1, #self.sizes)]
end

function SlotInitializer:ApplyRows()
	for _, child in pairs(self.rowsParent:GetChildren()) do
		if child:IsA("Frame") and child.Name ~= "EquipmentRow" then
			child:Destroy()
		end
	end

	for _, gearName in ipairs(self.priority) do
		local equipped = self.gearData and self.gearData[gearName]
		if equipped and equipped.equipped then
			local newRow = TemplateInvRow:Clone()
			newRow.Name = gearName .. "Row"
			newRow.Parent = self.rowsParent
			newRow.RowLabel.Text = gearName
		end
	end
end

function SlotInitializer:LoadGear()
	self.gearData = RequestGear:InvokeServer()
end

function SlotInitializer:InitSys()
	self:InitToolbarSlots()
	self:InitToolbarUtils()

	task.spawn(function()
		self:LoadGear()
		self:ApplyRows()
		self:ApplyParentSize()
		self:InitSlots()
	end)
end

return SlotInitializer