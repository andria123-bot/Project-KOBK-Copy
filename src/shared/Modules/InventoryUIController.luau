local InventoryUIController = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local playerGui = player:WaitForChild("PlayerGui")
local Menu = playerGui:WaitForChild("Menu")
local MainParent = Menu.MainParent
local rowsParent = MainParent.InventoryParent.InventoryItemsFrame.SingleRowParent
local equipmentFrame = MainParent.InventoryParent.EquipmentParent.EquipmentFrame

local TemplateInvRow = ReplicatedStorage.GUIS.TemplateInvRow

InventoryUIController.cachedData = nil

local playerInventoryData = {}

InventoryUIController.slots = {
	Inventory = {},
	Gear = {},
	WeaponSlots = {},
	Utils = {},
	All = {},
}

InventoryUIController.sizes = {
	UDim2.fromOffset(500, 125),
	UDim2.fromOffset(500, 245),
	UDim2.fromOffset(500, 363),
	UDim2.fromOffset(500, 487),
}

InventoryUIController.priority = {"Armor", "TShirt", "Pants", "Backpack"}

local SLOT_START = {
	INVENTORY = 1,
	WEAPONS = 16,
	GEAR = 19,
	UTILS = 27,
}

local SLOT_MAPPINGS = {
	--[16] = {"rbxassetid://116460202128729"},
	--[17] = {"rbxassetid://116460202128729"},
	--[18] = {"rbxassetid://116460202128729"},
	--[19] = {"rbxassetid://131689103359132"},
	--[20] = {"rbxassetid://138566981597980"},
	--[21] = {"rbxassetid://76798103842404"},
	--[22] = {"rbxassetid://116460202128729"},
	--[23] = {"rbxassetid://140060749395813"},
	--[24] = {"rbxassetid://106536134525419"},
	--[25] = {"rbxassetid://127049093744923"},
	--[26] = {"rbxassetid://72916872741117"},
	--[27] = {"rbxassetid://132850954017584"},
	--[28] = {"rbxassetid://80638653462369"},
	--[29] = {"rbxassetid://109094995752217"},
	--[30] = {"rbxassetid://97881204816864"},
	--[31] = {"rbxassetid://71615413080701"},
}

function InventoryUIController:InitGearSlots()
	print("[DEBUG] InitGearSlots started")
	task.wait()

	self.slots.Gear = {}
	self.slots.WeaponSlots = {}
	self.slots.Utils = {}

	local nextSlotId = SLOT_START.WEAPONS
	print("[DEBUG] Starting equipment slot ID:", nextSlotId)

	for _, row in pairs(equipmentFrame:GetChildren()) do
		if row:IsA("Frame") then
			print("[DEBUG] Found equipment row:", row.Name)
			local slotContainer = row:FindFirstChild("SlotRow") or row
			local rowName = row.Name

			for _, slotFrame in pairs(slotContainer:GetChildren()) do
				if slotFrame:IsA("Frame") then
					print("[DEBUG]   Found slot frame:", slotFrame.Name, "in row:", rowName)

					if rowName == "Weapons" then
						table.insert(self.slots.WeaponSlots, slotFrame)
						self.slots.All[nextSlotId] = {frame = slotFrame, type = "weapon", index = nextSlotId, slotName = slotFrame.Name}
						print("[DEBUG]     Added to WeaponSlots at ID:", nextSlotId)
						nextSlotId = nextSlotId + 1
					elseif rowName == "Utils" then
						table.insert(self.slots.Utils, slotFrame)
						self.slots.All[nextSlotId] = {frame = slotFrame, type = "utils", index = nextSlotId, slotName = slotFrame.Name}
						print("[DEBUG]     Added to Utils at ID:", nextSlotId)
						nextSlotId = nextSlotId + 1
					else
						table.insert(self.slots.Gear, slotFrame)
						self.slots.All[nextSlotId] = {frame = slotFrame, type = "gear", index = nextSlotId, slotName = slotFrame.Name}
						print("[DEBUG]     Added to Gear at ID:", nextSlotId)
						nextSlotId = nextSlotId + 1
					end
				end
			end
		end
	end

	local totalEquipment = #self.slots.All
	print("[DEBUG] Total equipment slots registered:", totalEquipment)
	print("[DEBUG] Total All slots count:", #self.slots.All)
end

function InventoryUIController:InitSlots()
	print("[DEBUG] InitSlots started")
	task.wait()

	local globalIndex = SLOT_START.INVENTORY
	self.slots.Inventory = {}
	self.slots.All = {}

	print("[DEBUG] rowsParent children count:", #rowsParent:GetChildren())

	for _, row in pairs(rowsParent:GetChildren()) do
		if row:IsA("Frame") and row.Name ~= "EquipmentRow" then
			print("[DEBUG] Found inventory row:", row.Name)
			local container = row:FindFirstChild("SlotRow")
			if container then
				print("[DEBUG]   Container has", #container:GetChildren(), "slots")
				for _, slot in pairs(container:GetChildren()) do
					if slot:IsA("Frame") then
						self.slots.Inventory[globalIndex] = slot
						self.slots.All[globalIndex] = {frame = slot, type = "inventory", index = globalIndex}
						slot.Name = "Slot" .. tostring(globalIndex)
						local itemIcon = slot:FindFirstChild("ItemIcon")
						if itemIcon then
							itemIcon.Image = ""
							itemIcon.Visible = true
						end
						print("[DEBUG]     Registered inventory slot", globalIndex, ":", slot.Name)
						globalIndex = globalIndex + 1
					end
				end
			else
				print("[DEBUG]   No SlotRow found in", row.Name)
			end
		end
	end

	print("[DEBUG] InitSlots: total slots registered =", globalIndex - 1)
	return globalIndex - 1
end

function InventoryUIController:LoadFromReplicatedStorage()
	print("[DEBUG] LoadFromReplicatedStorage started")
	local playerFolder = ReplicatedStorage.Players:FindFirstChild(player.Name)
	if not playerFolder then
		print("[DEBUG] No player folder found for:", player.Name)
		return nil
	end
	print("[DEBUG] Found player folder:", playerFolder.Name)

	local data = {
		PlayerInventory = {},
		Equipment = {
			Clothing = {},
			Weapons = {},
			Utils = {},
		},
		SlotCount = 30,
	}

	local clothingFolder = playerFolder:FindFirstChild("Clothing")
	if clothingFolder then
		print("[DEBUG] Clothing folder has", #clothingFolder:GetChildren(), "items")
		for _, item in pairs(clothingFolder:GetChildren()) do
			if item:IsA("StringValue") then
				print("[DEBUG]   Clothing item:", item.Name, "=", item.Value)
				
				data.Equipment.Clothing[item.Value] = {
					equipped = true,
					name = item.Name
				}
			end
		end
	else
		print("[DEBUG] No Clothing folder found")
	end

	local inventoryFolder = playerFolder:FindFirstChild("Inventory")
	if inventoryFolder then
		print("[DEBUG] Inventory folder has", #inventoryFolder:GetChildren(), "items")
		local slotIndex = 1
		for _, item in pairs(inventoryFolder:GetChildren()) do
			if item:IsA("StringValue") then
				print("[DEBUG]   Inventory item:", item.Name, "=", item.Value)
				data.PlayerInventory[slotIndex] = item.Value
				slotIndex = slotIndex + 1
			end
		end
	else
		print("[DEBUG] No Inventory folder found")
	end

	local equipmentFolder = playerFolder:FindFirstChild("Equipment")
	if equipmentFolder then
		print("[DEBUG] Equipment folder has", #equipmentFolder:GetChildren(), "items")
		for _, item in pairs(equipmentFolder:GetChildren()) do
			if item:IsA("StringValue") then
				print("[DEBUG]   Equipment item:", item.Name, "=", item.Value)
				if item.Name:find("Gun") then
					data.Equipment.Weapons[item.Name] = { equipped = true, item = item.Value }
				else
					data.Equipment.Utils[item.Name] = { equipped = true, name = item.Value }
				end
			end
		end
	else
		print("[DEBUG] No Equipment folder found")
	end

	self.cachedData = data
	print("[DEBUG] LoadFromReplicatedStorage complete")
	return data
end

function InventoryUIController:ApplyInventoryData(inventoryTable)
	print("[DEBUG] ApplyInventoryData called")
	if not inventoryTable then
		print("[DEBUG] inventoryTable is nil")
		return
	end

	self.cachedData = inventoryTable

	for i = 1, inventoryTable.SlotCount do
		playerInventoryData[i] = inventoryTable.PlayerInventory[i] or ""
	end
	print("[DEBUG] playerInventoryData populated with", inventoryTable.SlotCount, "slots")

	self:ApplyParentSize()
	self:ApplyRows()
	self:InitSlots()
	self:InitGearSlots()
	self:RefreshAllSlots()
end

function InventoryUIController:RefreshAllSlots()
	local slotCount = 0
	for slotId, _ in pairs(self.slots.All) do
		self:UpdateSlot(slotId)
		slotCount = slotCount + 1
	end
	print("[DEBUG] Refreshed", slotCount, "slots")
end

local cachedImages = {}

function returnFilteredList(slotInfo)
	if slotInfo.frame and slotInfo.frame:FindFirstChild("ItemIcon") then
		local itemIcon = slotInfo.frame.ItemIcon
		if itemIcon.Image ~= "" then
			cachedImages[slotInfo.slotName] = itemIcon.Image
		end
	end
	
	return cachedImages
end

function InventoryUIController:UpdateSlot(slotId)
	local slotInfo = self.slots.All[slotId]
	if not slotInfo or not slotInfo.frame then return end

	local itemIcon = slotInfo.frame:FindFirstChild("ItemIcon")
	if not itemIcon then return end

	local itemName = playerInventoryData[slotId]
	print(returnFilteredList(slotInfo))
	
	
end

function InventoryUIController:ApplyRows()
	print("[DEBUG] ApplyRows started")
	for _, child in pairs(rowsParent:GetChildren()) do
		if child:IsA("Frame") and child.Name ~= "EquipmentRow" then
			child:Destroy()
		end
	end

	for _, gearName in ipairs(self.priority) do
		local clothing = self.cachedData and self.cachedData.Equipment.Clothing
		local gearData = clothing and clothing[gearName]
		if gearData and gearData.equipped then
			local newRow = TemplateInvRow:Clone()
			newRow.Name = gearName .. "Row"
			newRow.Parent = rowsParent
			newRow.RowLabel.Text = gearName
			print("[DEBUG] ApplyRows: added row for", gearName)
		end
	end
end

function InventoryUIController:ApplyParentSize()
	local equipped = self:GetEquippedClothing() 
	local rowCount = 1

	for _, gearName in ipairs(self.priority) do
		if equipped[gearName] then 
			rowCount = rowCount + 1
		end
	end

	local clamped = math.clamp(rowCount, 1, #self.sizes)
	rowsParent.Size = self.sizes[clamped]
	print("[DEBUG] ApplyParentSize: rows =", rowCount)
end

function InventoryUIController:GetEquippedClothing()
	if not self.cachedData then 
		print("[DEBUG] GetEquippedClothing: no cachedData")
		return {}
	end

	local clothing = self.cachedData.Equipment.Clothing
	local equipped = {}

	for slotName, slotData in pairs(clothing) do
		if slotData.equipped and slotData.name ~= "" then
			equipped[slotName] = {
				equipped = slotData.equipped,
				slot = slotName,
				name = slotData.name
			}
		end
	end

	print("[DEBUG] GetEquippedClothing found", #equipped, "items")
	return equipped
end

local function setupListener()
	print("[DEBUG] setupListener started")
	local playersFolder = ReplicatedStorage:FindFirstChild("Players")
	if not playersFolder then 
		print("[DEBUG] No Players folder in ReplicatedStorage")
		return 
	end

	local playerFolder = playersFolder:FindFirstChild(player.Name)
	if not playerFolder then 
		print("[DEBUG] No player folder for:", player.Name)
		return 
	end

	local function onInventoryChanged()
		print("[DEBUG] Inventory changed, reloading...")
		local data = InventoryUIController:LoadFromReplicatedStorage()
		if data then
			InventoryUIController:ApplyInventoryData(data)
		end
	end

	playerFolder.ChildAdded:Connect(onInventoryChanged)
	playerFolder.ChildRemoved:Connect(onInventoryChanged)

	local clothingFolder = playerFolder:FindFirstChild("Clothing")
	if clothingFolder then
		clothingFolder.ChildAdded:Connect(onInventoryChanged)
		clothingFolder.ChildRemoved:Connect(onInventoryChanged)
	end

	local inventoryFolder = playerFolder:FindFirstChild("Inventory")
	if inventoryFolder then
		inventoryFolder.ChildAdded:Connect(onInventoryChanged)
		inventoryFolder.ChildRemoved:Connect(onInventoryChanged)
	end

	print("[DEBUG] setupListener complete")
end

function InventoryUIController:InitSys()
	print("[DEBUG] ========================================")
	print("[DEBUG] InventoryUIController:InitSys called")
	print("[DEBUG] ========================================")

	local data = self:LoadFromReplicatedStorage()
	if data then
		self:ApplyInventoryData(data)
	else
		print("[DEBUG] No data loaded, applying defaults")
		self:ApplyParentSize()
		self:ApplyRows()
		self:InitSlots()
		self:InitGearSlots()
	end

	setupListener()
end

player.CharacterAdded:Connect(function()
	print("[DEBUG] CharacterAdded event fired")
	task.wait(0.5)
	InventoryUIController:InitSys()
end)

task.wait(0.5)
InventoryUIController:InitSys()

return InventoryUIController