-- InventoryUIController.client.luau
local InventoryUIController = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(game:GetService("ReplicatedStorage").Packages:WaitForChild("Knit"))
local RequestModule = ReplicatedStorage.Shared.Remotes.Requests:WaitForChild("RequestModule")
local DraggableObject = require(ReplicatedStorage.Shared.Modules.DraggableObject)

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
    UDim2.fromOffset(500, 125),
    UDim2.fromOffset(500, 245),
    UDim2.fromOffset(500, 363),
    UDim2.fromOffset(500, 487),
}

InventoryUIController.priority = {"Armor", "TShirt", "Pants"}
InventoryUIController.activeRows = {}
InventoryUIController.slotItems = {}  -- Store item names per slot
InventoryUIController.draggers = {}

function InventoryUIController:InitGearSlots()
    self.slots.Gear = {}
    self.slots.WeaponSlots = {}
    self.slots.Utils = {}

    local nextSlotId = 16

    local function sortedChildren(parent)
        local children = {}
        for _, child in pairs(parent:GetChildren()) do
            table.insert(children, child)
        end
        table.sort(children, function(a, b) return a.Name < b.Name end)
        return children
    end

    for _, row in ipairs(sortedChildren(equipmentFrame)) do
        if row:IsA("Frame") then
            local slotContainer = row:FindFirstChild("SlotRow") or row
            local rowName = row.Name

            for _, slotFrame in ipairs(sortedChildren(slotContainer)) do
                if slotFrame:IsA("Frame") then
                    if rowName == "Weapons" then
                        table.insert(self.slots.WeaponSlots, slotFrame)
                        self.slots.All[nextSlotId] = {frame = slotFrame, type = "weapon", index = nextSlotId, slotName = slotFrame.Name}
                    elseif rowName == "Utils" then
                        table.insert(self.slots.Utils, slotFrame)
                        self.slots.All[nextSlotId] = {frame = slotFrame, type = "utils", index = nextSlotId, slotName = slotFrame.Name}
                    else
                        table.insert(self.slots.Gear, slotFrame)
                        self.slots.All[nextSlotId] = {frame = slotFrame, type = "gear", index = nextSlotId, slotName = slotFrame.Name}
                    end
                    nextSlotId += 1
                end
            end
        end
    end
end

function InventoryUIController:GetItemFromSlot(slotFrame)
    -- Find which clothing item this slot belongs to
    local slotRow = slotFrame.Parent  -- SlotRow
    local row = slotRow.Parent  -- 6B45Row, WorkingTShirtRow, etc.
    local rowName = row.Name
    local clothingName = rowName:gsub("Row", "")
    
    -- Get the slot number
    local slotNumber = tonumber(slotFrame.Name:match("%d+"))
    if not slotNumber then return nil end
    
    -- Find the clothing item in ReplicatedStorage
    local playersFolder = ReplicatedStorage:FindFirstChild("Players")
    local playerFolder = playersFolder and playersFolder:FindFirstChild(player.Name)
    local clothingFolder = playerFolder and playerFolder:FindFirstChild("Clothing")
    local clothingItem = clothingFolder and clothingFolder:FindFirstChild(clothingName)
    
    if clothingItem then
        local invFolder = clothingItem:FindFirstChild("Inventory")
        if invFolder then
            for _, subItem in pairs(invFolder:GetChildren()) do
                if subItem:IsA("StringValue") then
                    -- subItem.Value is like "Armor1", "TShirt2", etc.
                    local itemSlotNum = tonumber(subItem.Value:match("%d+"))
                    if itemSlotNum == slotNumber then
                        return subItem.Name
                    end
                end
            end
        end
    end
    return nil
end

function InventoryUIController:InitSlots()
    local globalIndex = 1
    self.slots.Inventory = {}
    self.slots.All = {}
    self.slotItems = {}  -- FIX 2: clear old data so no ghost items on rejoin

    for _, dragger in pairs(self.draggers) do
        dragger:Disable()
    end
    self.draggers = {}

    -- FIX 1: sort rows and slots for consistent ordering
    local function sortedChildren(parent)
        local children = {}
        for _, child in pairs(parent:GetChildren()) do
            table.insert(children, child)
        end
        table.sort(children, function(a, b) return a.Name < b.Name end)
        return children
    end

    for _, row in ipairs(sortedChildren(rowsParent)) do
        if row:IsA("Frame") and row.Name ~= "EquipmentRow" then
            local container = row:FindFirstChild("SlotRow")
            if container then
                for _, slot in ipairs(sortedChildren(container)) do
                    if slot:IsA("Frame") then
                        self.slots.Inventory[globalIndex] = slot
                        self.slots.All[globalIndex] = {frame = slot, type = "inventory", index = globalIndex}
                        slot.Name = "Slot" .. tostring(globalIndex)

                        local itemIcon = slot:FindFirstChild("ItemIcon")
                        if itemIcon then
                            itemIcon.Image = ""
                            itemIcon.Visible = true

                            local itemInSlot = self:GetItemFromSlot(slot)
                            self.slotItems[slot.Name] = itemInSlot or ""

                            if itemInSlot and itemInSlot ~= "" then
                                self:PopulateSlot(slot, itemInSlot, 1)
                            end

                            -- FIX 3: parent clone to MainParent so it renders above all rows
                            local dragger = DraggableObject.new(itemIcon, MainParent)

                            dragger.OnDragStart = function(sourceSlot)
                                self.dragSource = {
                                    slotFrame = slot,
                                    slotName = slot.Name,
                                    itemName = self.slotItems[sourceSlot]
                                }
                            end

                            dragger.OnDragEnd = function(sourceSlot, targetFrame)
                                if targetFrame then
                                    local targetSlotName = targetFrame.Name
                                    if targetSlotName and targetSlotName ~= sourceSlot then
                                        local itemName = self.slotItems[sourceSlot]
                                        if itemName and itemName ~= "" then
                                            local InventoryService = Knit.GetService("InventoryService")
                                            if InventoryService then
                                                local targetItem = self.slotItems[targetSlotName]
                                                self.slotItems[targetSlotName] = itemName
                                                self.slotItems[sourceSlot] = targetItem or ""

                                                local sourceIdx = tonumber(sourceSlot:match("%d+"))
                                                local targetIdx = tonumber(targetSlotName:match("%d+"))
                                                local sourceInfo = sourceIdx and self.slots.All[sourceIdx]
                                                local targetInfo = targetIdx and self.slots.All[targetIdx]

                                                if sourceInfo then self:PopulateSlot(sourceInfo.frame, self.slotItems[sourceSlot], 1) end
                                                if targetInfo then self:PopulateSlot(targetInfo.frame, self.slotItems[targetSlotName], 1) end

                                                InventoryService:MoveItem(sourceSlot, targetSlotName)
                                            end
                                        end
                                    end
                                end
                                self.dragSource = nil
                            end

                            dragger:Enable(slot.Name)
                            table.insert(self.draggers, dragger)
                        end

                        globalIndex += 1
                    end
                end
            end
        end
    end
end

function InventoryUIController:GetEquippedClothingFromReplicated()
    local playersFolder = ReplicatedStorage:FindFirstChild("Players")
    if not playersFolder then
        return {}
    end
    
    local playerFolder = playersFolder:FindFirstChild(player.Name)
    if not playerFolder then
        return {}
    end
    
    local clothingFolder = playerFolder:FindFirstChild("Clothing")
    if not clothingFolder then
        return {}
    end
    
    local equipped = {}
    for _, clothingItem in pairs(clothingFolder:GetChildren()) do
        if clothingItem:IsA("StringValue") and clothingItem.Value ~= "" then
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

function InventoryUIController:GetSlotCount(itemName)
    local success, module = pcall(function()
        return RequestModule:InvokeServer(itemName)
    end)
    
    if success and module and module.slotCount then
        return module.slotCount
    end
    return 5
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
    
    local slotName = slotFrame.Name
    self.slotItems[slotName] = itemName or ""
    for k, v in pairs(self.slotItems) do
        print("  ", k, "=", v)
    end
    
    local itemIcon = slotFrame:FindFirstChild("ItemIcon")
    local itemNameLabel = slotFrame:FindFirstChild("ItemName")
    local itemQty = slotFrame:FindFirstChild("ItemQty")
    
    if itemName and itemName ~= "" then
        local iconFound = false
        
        local playersFolder = ReplicatedStorage:FindFirstChild("Players")
        if playersFolder then
            local playerFolder = playersFolder:FindFirstChild(player.Name)
            if playerFolder then
                local clothingFolder = playerFolder:FindFirstChild("Clothing")
                if clothingFolder then
                    for _, clothingItem in pairs(clothingFolder:GetChildren()) do
                        if clothingItem:IsA("StringValue") then
                            local invFolder = clothingItem:FindFirstChild("Inventory")
                            if invFolder then
                                local item = invFolder:FindFirstChild(itemName)
                                if item and item:IsA("StringValue") then
                                    local props = item:FindFirstChild("ItemProperties")
                                    if props then
                                        local iconId = props:FindFirstChild("IconImage")
                                        if iconId and iconId.Value and iconId.Value ~= "" then
                                            itemIcon.Image = iconId.Value
                                            itemIcon.Visible = true
                                            iconFound = true
                                            break
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        
        if not iconFound then
            local success, module = pcall(function()
                return RequestModule:InvokeServer(itemName)
            end)
            if success and module and module.imageIconId then
                itemIcon.Image = module.imageIconId
                itemIcon.Visible = true
            else
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

function InventoryUIController:PopulateRow(row, clothingItem)
    local slotCount = self:GetSlotCount(clothingItem.Name)
    local slots = self:GetSlotsFromRow(row)
    
    for i = slotCount + 1, #slots do
        slots[i].Visible = false
    end
    
    local invFolder = clothingItem:FindFirstChild("Inventory")
    if invFolder then
        local itemIndex = 0
        for _, subItem in pairs(invFolder:GetChildren()) do
            if subItem:IsA("StringValue") and subItem.Name ~= "" then
                itemIndex = itemIndex + 1
                if itemIndex <= slotCount then
                    self:PopulateSlot(slots[itemIndex], subItem.Name, 1)
                end
            end
        end
    else
        print("[DEBUG]: No Inventory folder found for:", clothingItem.Name)
    end
end

function InventoryUIController:ApplyRows()
    
    -- Clear existing rows
    for _, child in pairs(rowsParent:GetChildren()) do
        if child:IsA("Frame") and child.Name ~= "EquipmentRow" then
            child:Destroy()
        end
    end
    
    local equipped = self:GetEquippedClothingFromReplicated()
    
    local rowCount = 0
    for _, gearType in ipairs(self.priority) do
        local gearData = equipped[gearType]
        if gearData and gearData.equipped then
            local newRow = TemplateInvRow:Clone()
            newRow.Name = gearData.name .. "Row"
            newRow.Parent = rowsParent
            newRow.RowLabel.Text = gearType
            
            self:PopulateRow(newRow, gearData.item)
            self.activeRows[gearType] = newRow
            rowCount = rowCount + 1
        end
    end
    
    
    local rowCountForSize = math.max(rowCount, 1)
    local clamped = math.min(rowCountForSize, #self.sizes)
    inventoryItemsFrame.Size = self.sizes[clamped]
end

function InventoryUIController:Refresh()
    self:ApplyRows()
    self:InitSlots()
    self:InitGearSlots()
end

return InventoryUIController    