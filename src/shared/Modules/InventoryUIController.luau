-- Client - InventoryUIController
local InventoryUIController = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local UIHelpers = require(script.Parent.UIHelpers)

local playerGui = player:WaitForChild("PlayerGui")
local Menu = playerGui:WaitForChild("Menu")
local MainParent = Menu.MainParent
local rowsParent = MainParent.InventoryParent.InventoryItemsFrame.SingleRowParent
local equipmentFrame = MainParent.InventoryParent.EquipmentParent.EquipmentFrame

local TemplateInvRow = ReplicatedStorage.GUIS.TemplateInvRow

InventoryUIController.cachedData = nil
local playerInventoryData = {}
local itemImageCache = {}

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

function InventoryUIController:GetTotalSlotCount()
    local equipped = self:GetEquippedClothing()
    local totalSlots = 0
    
    for clothingType, _ in pairs(equipped) do
        totalSlots = totalSlots + 5
    end
    
    return totalSlots
end

function InventoryUIController:GetSlotUnderMouse()
    local mousePos = UIHelpers.getMousePosition()
    
    for slotId, slotInfo in pairs(self.slots.All) do
        if slotInfo.frame and UIHelpers.isMouseOverFrame(slotInfo.frame, mousePos) then
            if slotInfo.type == "gear" then
                return slotInfo.slotName
            else
                return slotId
            end
        end
    end
    return nil
end

function InventoryUIController:SetupDragDrop()
    local DraggableObject = require(script.Parent.DraggableObject)
    
    for slotId, slotInfo in pairs(self.slots.All) do
        local itemIcon = slotInfo.frame:FindFirstChild("ItemIcon")
        if itemIcon and not itemIcon:GetAttribute("DragSetup") then
            itemIcon:SetAttribute("DragSetup", true)
            
            local draggable = DraggableObject.new(itemIcon, MainParent)
            
            draggable.DragStarted = function()
                self.draggingFromSlot = slotId
            end
            
            draggable.DragEnded = function()
                local targetSlot = self:GetSlotUnderMouse()
                if targetSlot and targetSlot ~= self.draggingFromSlot then
                    ReplicatedStorage.InventoryMove:FireServer(self.draggingFromSlot, targetSlot)
                end
                self.draggingFromSlot = nil
            end
            
            draggable:Enable()
        end
    end
end

local function getSlotRanges(player)
    local playerFolder = ReplicatedStorage.Players:FindFirstChild(player.Name)
    if not playerFolder then return {}, 0 end
    
    local clothingOrder = {"Armor", "TShirt", "Pants", "Backpack"}
    local clothingFolder = playerFolder:FindFirstChild("Clothing")
    
    return UIHelpers.getSlotRanges(clothingFolder, clothingOrder)
end

function InventoryUIController:InitGearSlots()
    task.wait()
    self.slots.Gear = {}
    self.slots.WeaponSlots = {}
    self.slots.Utils = {}
    
    local nextSlotId = SLOT_START.WEAPONS
    
    for _, row in pairs(equipmentFrame:GetChildren()) do
        if row:IsA("Frame") then
            local slotContainer = row:FindFirstChild("SlotRow") or row
            local rowName = row.Name
            
            for _, slotFrame in pairs(slotContainer:GetChildren()) do
                if slotFrame:IsA("Frame") then
                    if rowName == "Weapons" then
                        table.insert(self.slots.WeaponSlots, slotFrame)
                        self.slots.All[nextSlotId] = {frame = slotFrame, type = "weapon", index = nextSlotId, slotName = slotFrame.Name}
                        nextSlotId = nextSlotId + 1
                    elseif rowName == "Utils" then
                        table.insert(self.slots.Utils, slotFrame)
                        self.slots.All[nextSlotId] = {frame = slotFrame, type = "utils", index = nextSlotId, slotName = slotFrame.Name}
                        nextSlotId = nextSlotId + 1
                    else
                        table.insert(self.slots.Gear, slotFrame)
                        self.slots.All[nextSlotId] = {frame = slotFrame, type = "gear", index = nextSlotId, slotName = slotFrame.Name}
                        nextSlotId = nextSlotId + 1
                    end
                end
            end
        end
    end
end

function InventoryUIController:InitSlots()
    task.wait()
    
    local totalSlots = self:GetTotalSlotCount()
    local globalIndex = 1
    self.slots.Inventory = {}
    self.slots.All = {}
    
    for _, row in pairs(rowsParent:GetChildren()) do
        if row:IsA("Frame") and row.Name ~= "EquipmentRow" then
            local container = row:FindFirstChild("SlotRow")
            if container then
                local rowClothing = row.Name:gsub("Row", "")
                local equipped = self:GetEquippedClothing()
                
                if equipped[rowClothing] then
                    row.Visible = true
                    for _, slot in pairs(container:GetChildren()) do
                        if slot:IsA("Frame") then
                            self.slots.Inventory[globalIndex] = slot
                            self.slots.All[globalIndex] = {frame = slot, type = "inventory", index = globalIndex}
                            slot.Name = "Slot" .. tostring(globalIndex)
                            globalIndex = globalIndex + 1
                        end
                    end
                else
                    row.Visible = false
                end
            end
        end
    end
    
    print("[DEBUG] InitSlots: total slots registered =", globalIndex - 1)
end

function InventoryUIController:GetAbsoluteSlotNumber(clothingType, relativeSlot)
    local ranges, _ = getSlotRanges(player)
    return UIHelpers.getAbsoluteSlotNumber(ranges, clothingType, relativeSlot)
end

function InventoryUIController:LoadFromReplicatedStorage()
    local playerFolder = ReplicatedStorage.Players:FindFirstChild(player.Name)
    if not playerFolder then
        return nil
    end
    
    local data = {
        PlayerInventory = {},
        Equipment = {
            Clothing = {},
            Weapons = {},
            Utils = {},
        },
        SlotCount = 0,
    }
    
    local clothingFolder = playerFolder:FindFirstChild("Clothing")
    local ranges, totalSlots = getSlotRanges(player)
    data.SlotCount = totalSlots
    
    if clothingFolder then
        for _, clothingItem in pairs(clothingFolder:GetChildren()) do
            if clothingItem:IsA("StringValue") then
                local slotType = clothingItem.Value
                local invFolder = clothingItem:FindFirstChild("Inventory")
                
                if invFolder and ranges[slotType] then
                    for _, subItem in pairs(invFolder:GetChildren()) do
                        if subItem:IsA("StringValue") then
                            local relativeSlot = tonumber(string.match(subItem.Value, "%d+")) or 1
                            local absoluteSlot = UIHelpers.getAbsoluteSlotNumber(ranges, slotType, relativeSlot)
                            
                            if absoluteSlot then
                                data.PlayerInventory[absoluteSlot] = subItem.Name
                                
                                local icon = UIHelpers.getItemIconFromProperties(subItem)
                                if icon then
                                    UIHelpers.cacheItemIcon(subItem.Name, icon, itemImageCache)
                                end
                            end
                        end
                    end
                end
                
                data.Equipment.Clothing[slotType] = {
                    equipped = true,
                    name = clothingItem.Name
                }
            end
        end
    end
    
    self.cachedData = data
    return data
end

function InventoryUIController:UpdateSlot(slotId)
    local slotInfo = self.slots.All[slotId]
    if not slotInfo or not slotInfo.frame then
        return
    end
    
    local itemIcon = slotInfo.frame:FindFirstChild("ItemIcon")
    if not itemIcon then
        return
    end
    
    local itemName = playerInventoryData[slotId]
    
    if itemName and itemName ~= "" then
        local icon = UIHelpers.getCachedIcon(itemName, itemImageCache)
        if icon and icon ~= "" then
            itemIcon.Image = icon
        else
            itemIcon.Image = "rbxassetid://default_icon"
        end
        itemIcon.Visible = true
    else
        itemIcon.Image = ""
        itemIcon.Visible = true
    end
end

function InventoryUIController:RefreshAllSlots()
    for slotId, _ in pairs(self.slots.All) do
        self:UpdateSlot(slotId)
    end
end

function InventoryUIController:ApplyInventoryData(inventoryTable)
    if not inventoryTable then
        return
    end
    self.cachedData = inventoryTable
    
    local totalSlots = inventoryTable.SlotCount or self:GetTotalSlotCount()
    
    playerInventoryData = {}
    for i = 1, totalSlots do
        playerInventoryData[i] = inventoryTable.PlayerInventory[i] or ""
    end
    
    self:ApplyParentSize()
    self:ApplyRows()
    self:InitSlots()
    self:InitGearSlots()
    self:RefreshAllSlots()
    self:SetupDragDrop()
end

function InventoryUIController:ApplyRows()
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
        end
    end
end

function InventoryUIController:ApplyParentSize()
    local totalSlots = self:GetTotalSlotCount()
    local rowCount = math.ceil(totalSlots / 5)
    rowCount = math.max(rowCount, 1)
    
    rowsParent.Size = self.sizes[math.clamp(rowCount, 1, #self.sizes)]
    print("[DEBUG] ApplyParentSize: rows =", rowCount, "total slots =", totalSlots)
end

function InventoryUIController:GetEquippedClothing()
    if not self.cachedData then
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
    return equipped
end

local function setupListener()
    local playersFolder = ReplicatedStorage:FindFirstChild("Players")
    if not playersFolder then
        return
    end
    
    local playerFolder = playersFolder:FindFirstChild(player.Name)
    if not playerFolder then
        return
    end
    
    local function onInventoryChanged()
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
end

function InventoryUIController:InitSys()
    local data = self:LoadFromReplicatedStorage()
    if data then
        self:ApplyInventoryData(data)
    else
        self:ApplyParentSize()
        self:ApplyRows()
        self:InitSlots()
        self:InitGearSlots()
    end
    setupListener()
    
    ReplicatedStorage.InventoryUpdated.OnClientEvent:Connect(function()
        local newData = self:LoadFromReplicatedStorage()
        if newData then
            self:ApplyInventoryData(newData)
        end
    end)
end

task.wait(0.5)
InventoryUIController:InitSys()

return InventoryUIController