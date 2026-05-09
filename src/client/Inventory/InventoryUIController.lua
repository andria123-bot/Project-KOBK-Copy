local InventoryUIController = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RequestWeaponSystemData = ReplicatedStorage.Shared.Remotes.Requests:WaitForChild("RequestWeaponSystemData")
local RequestModule = ReplicatedStorage.Shared.Remotes.Requests:WaitForChild("RequestModule")

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
}

InventoryUIController.sizes = {
    UDim2.fromOffset(500, 125),
    UDim2.fromOffset(500, 245),
    UDim2.fromOffset(500, 363),
    UDim2.fromOffset(500, 487),
}

InventoryUIController.priority = {"Armor", "TShirt", "Pants"}

function InventoryUIController:InitGearSlots()
    task.wait()
    
    self.slots.Gear = {}
    self.slots.WeaponSlots = {}
    self.slots.Utils = {}
    
    for _, row in pairs(equipmentFrame:GetChildren()) do
        if row:IsA("Frame") then
            
            local slotContainer = row:FindFirstChild("SlotRow") or row
            
            for _, slotFrame in pairs(slotContainer:GetChildren()) do
                if slotFrame:IsA("Frame") then
                    
                    local rowName = row.Name
                    local slotName = slotFrame.Name
                    
                    if rowName:find("Weapon") or slotName:find("Weapon") or slotName:find("Slot") then
                        self.slots.WeaponSlots[slotName] = slotFrame
                    elseif rowName:find("Util") or rowName:find("Tool") or slotName:find("Melee") then
                        self.slots.Utils[slotName] = slotFrame
                    else
                        self.slots.Gear[slotName] = slotFrame
                    end
                end
            end
        end
    end
end

function InventoryUIController:InitSlots()
    task.wait()

    local globalIndex = 1
    self.slots.Inventory = {}

    for _, row in pairs(rowsParent:GetChildren()) do
        if row:IsA("Frame") and row.Name ~= "EquipmentRow" then
            local container = row:FindFirstChild("SlotRow")
            if container then
                for _, slot in pairs(container:GetChildren()) do
                    if slot:IsA("Frame") then
                        self.slots.Inventory[globalIndex] = slot
                        slot.Name = "Slot" .. tostring(globalIndex)
                        local itemIcon = slot:FindFirstChild("ItemIcon")
                        if itemIcon then
                            itemIcon.Image = ""
                            itemIcon.Visible = true
                        end
                        globalIndex += 1
                    end
                end
            end
        end
    end

    return globalIndex - 1
end

function InventoryUIController:ApplyInventoryData(inventoryTable)
    if not inventoryTable then return end
    self.cachedData = inventoryTable
    
    for i = 1, inventoryTable.SlotCount do
        playerInventoryData[i] = inventoryTable.PlayerInventory[i] or ""
    end

    self:ApplyParentSize()
    self:ApplyRows()
    self:InitSlots()
    self:InitGearSlots()
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
            print("ApplyRows: added row for", gearName)
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
    print("ApplyParentSize: rows =", rowCount)
end

function InventoryUIController:GetEquippedClothing()
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

    print("Equipped clothing:", equipped)
    return equipped
end


return InventoryUIController