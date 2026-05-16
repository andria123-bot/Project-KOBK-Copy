local InventoryUIController = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RequestModule = ReplicatedStorage.Shared.Remotes.Requests:WaitForChild("RequestModule")

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local playerGui = player:WaitForChild("PlayerGui")
local Menu = playerGui:WaitForChild("Menu")
local MainParent = Menu.MainParent
local rowsParent = MainParent.InventoryParent.InventoryItemsFrame.SingleRowParent
local equipmentFrame = MainParent.InventoryParent.EquipmentParent.EquipmentFrame
local inventoryItemsFrame = MainParent.InventoryParent.InventoryItemsFrame

local TemplateInvRow = ReplicatedStorage.GUIS.TemplateInvRow

InventoryUIController.slots = {
    Inventory = {},
    Gear = {},
    WeaponSlots = {},
    Utils = {},
    All = {},
}

InventoryUIController.sizes = {
    UDim2.fromOffset(500, 125),   -- 1 row
    UDim2.fromOffset(500, 245),   -- 2 rows
    UDim2.fromOffset(500, 363),   -- 3 rows
    UDim2.fromOffset(500, 487),   -- 4 rows
}

InventoryUIController.priority = {"Armor", "TShirt", "Pants"}

-- Store row references
InventoryUIController.activeRows = {}

function InventoryUIController:InitGearSlots()
    self.slots.Gear = {}
    self.slots.WeaponSlots = {}
    self.slots.Utils = {}
    
    local nextSlotId = 16 -- Start after inventory slots
    
    for _, row in pairs(equipmentFrame:GetChildren()) do
        if row:IsA("Frame") then
            local slotContainer = row:FindFirstChild("SlotRow") or row
            local rowName = row.Name
            
            for _, slotFrame in pairs(slotContainer:GetChildren()) do
                if slotFrame:IsA("Frame") then
                    if rowName == "Weapons" then
                        table.insert(self.slots.WeaponSlots, slotFrame)
                        self.slots.All[nextSlotId] = {frame = slotFrame, type = "weapon", index = nextSlotId}
                        nextSlotId = nextSlotId + 1
                    elseif rowName == "Utils" then
                        table.insert(self.slots.Utils, slotFrame)
                        self.slots.All[nextSlotId] = {frame = slotFrame, type = "utils", index = nextSlotId}
                        nextSlotId = nextSlotId + 1
                    else
                        table.insert(self.slots.Gear, slotFrame)
                        self.slots.All[nextSlotId] = {frame = slotFrame, type = "gear", index = nextSlotId}
                        nextSlotId = nextSlotId + 1
                    end
                end
            end
        end
    end
    
    print("Total All slots:", #self.slots.All)
end

function InventoryUIController:InitSlots()
    local globalIndex = 1
    self.slots.Inventory = {}
    self.slots.All = {}

    for _, row in pairs(rowsParent:GetChildren()) do
        if row:IsA("Frame") and row.Name ~= "EquipmentRow" then
            local container = row:FindFirstChild("SlotRow")
            if container then
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
                        globalIndex = globalIndex + 1
                    end
                end
            end
        end
    end

    print("InitSlots: total slots registered =", globalIndex - 1)
    return globalIndex - 1
end

-- Get equipped clothing from ReplicatedStorage (not cached data)
function InventoryUIController:GetEquippedClothingFromReplicated()
    local playersFolder = ReplicatedStorage:FindFirstChild("Players")
    if not playersFolder then return {} end
    
    local playerFolder = playersFolder:FindFirstChild(player.Name)
    if not playerFolder then return {} end
    
    local clothingFolder = playerFolder:FindFirstChild("Clothing")
    if not clothingFolder then return {} end
    
    local equipped = {}
    for _, clothingItem in pairs(clothingFolder:GetChildren()) do
        if clothingItem:IsA("StringValue") and clothingItem.Value ~= "" then
            -- clothingItem.Value is the slot type: "Armor", "TShirt", "Pants"
            local slotType = clothingItem.Value
            equipped[slotType] = {
                equipped = true,
                slot = slotType,
                name = clothingItem.Name,
                item = clothingItem
            }
        end
    end
    
    return equipped
end

-- Get slot count from item module
function InventoryUIController:GetSlotCount(itemName)
    local success, module = pcall(function()
        return RequestModule:InvokeServer(itemName)
    end)
    
    if success and module and module.slotCount then
        return module.slotCount
    end
    return 5 -- default
end

-- Populate a row with items from clothing's Inventory folder
function InventoryUIController:PopulateRow(row, clothingItem)
    local slotCount = self:GetSlotCount(clothingItem.Name)
    local slots = self:GetSlotsFromRow(row)
    
    -- Hide extra slots
    for i = slotCount + 1, #slots do
        slots[i].Visible = false
    end
    
    -- Load items from Inventory folder
    local invFolder = clothingItem:FindFirstChild("Inventory")
    if invFolder then
        local itemIndex = 0
        for _, subItem in pairs(invFolder:GetChildren()) do
            if subItem:IsA("StringValue") then
                itemIndex = itemIndex + 1
                if itemIndex <= slotCount then
                    self:PopulateSlot(slots[itemIndex], subItem.Name, 1)
                end
            end
        end
    end
end

function InventoryUIController:GetSlotsFromRow(row)
    local slots = {}
    local slotRow = row:FindFirstChild("SlotRow")
    if slotRow then
        for _, child in pairs(slotRow:GetChildren()) do
            if child.Name == "Slot" then
                table.insert(slots, child)
            end
        end
    end
    return slots
end

function InventoryUIController:PopulateSlot(slotFrame, itemName, amount)
    local itemIcon = slotFrame:FindFirstChild("ItemIcon")
    local itemNameLabel = slotFrame:FindFirstChild("ItemName")
    local itemQty = slotFrame:FindFirstChild("ItemQty")
    
    if itemName and itemName ~= "" then
        local success, module = pcall(function()
            return RequestModule:InvokeServer(itemName)
        end)
        
        if success and module then
            if itemIcon then
                itemIcon.Image = module.imageIconId or "rbxassetid://0"
                itemIcon.Visible = true
            end
        else
            if itemIcon then
                itemIcon.Image = "rbxassetid://0"
                itemIcon.Visible = true
            end
        end
        
        if itemNameLabel then
            itemNameLabel.Text = itemName
        end
        
        if itemQty then
            itemQty.Text = amount and amount > 1 and tostring(amount) or ""
            itemQty.Visible = amount and amount > 1
        end
    else
        if itemIcon then
            itemIcon.Image = ""
            itemIcon.Visible = false
        end
        if itemNameLabel then
            itemNameLabel.Text = ""
        end
        if itemQty then
            itemQty.Text = ""
        end
    end
end

function InventoryUIController:ApplyRows()
    -- Clear existing rows (keep EquipmentRow if it exists in rowsParent)
    for _, child in pairs(rowsParent:GetChildren()) do
        if child:IsA("Frame") and child.Name ~= "EquipmentRow" then
            child:Destroy()
        end
    end
    
    -- Get equipped clothing from ReplicatedStorage
    local equipped = self:GetEquippedClothingFromReplicated()
    
    -- Create rows in priority order
    for _, gearType in ipairs(self.priority) do
        local gearData = equipped[gearType]
        if gearData and gearData.equipped then
            local newRow = TemplateInvRow:Clone()
            newRow.Name = gearData.name .. "Row"
            newRow.Parent = rowsParent
            newRow.RowLabel.Text = gearType
            
            -- Populate the row with items
            self:PopulateRow(newRow, gearData.item)
            
            self.activeRows[gearType] = newRow
            print("ApplyRows: added row for", gearData.name)
        end
    end
end

function InventoryUIController:ApplyParentSize()
    local equipped = self:GetEquippedClothingFromReplicated()
    local rowCount = 0
    
    for _, gearType in ipairs(self.priority) do
        if equipped[gearType] then
            rowCount = rowCount + 1
        end
    end
    
    -- At least 1 row for proper sizing
    rowCount = math.max(rowCount, 1)
    local clamped = math.min(rowCount, #self.sizes) + 1
    print(clamped)
    print(inventoryItemsFrame)
    inventoryItemsFrame.SingleRowParent.Size = self.sizes[clamped]
    print("ApplyParentSize: rows =", rowCount, "size =", self.sizes[clamped])
end

function InventoryUIController:Refresh()
    self:ApplyParentSize()
    self:ApplyRows()
    self:InitSlots()
    self:InitGearSlots()
end

return InventoryUIController