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

function InventoryUIController:ApplyRows()
    for _, child in pairs(rowsParent:GetChildren()) do
        if child:IsA("Frame") and child.Name ~= "EquipmentRow" then
            child:Destroy()
        end
    end

    for _, gearName in ipairs(self.priority) do
        if self.cachedData.Clothing[gearName] then
            local newRow = TemplateInvRow:Clone()
            newRow.Name = gearName .. "Row"
            newRow.Parent = rowsParent
            newRow.RowLabel.Text = gearName
        end
    end
end

function InventoryUIController:ApplyParentSize()
    local rowCount = 1 -- start with base inventory row
    for _, gearName in ipairs(self.priority) do
        if self.cachedData and self.cachedData.Clothing[gearName] then
            rowCount = rowCount + 1
        end
    end
    rowsParent.Size = self.sizes[math.clamp(rowCount, 1, #self.sizes)]
end

function InventoryUIController:LoadFromReplicatedStorage()
    local playerFolder = ReplicatedStorage.Players:FindFirstChild(player.Name)
    if not playerFolder then
        return
    end

    -- Reset cached data to your desired structure
    self.cachedData = {
        Clothing = {},
        Equipment = {},
        Status = {},
        Hotbar = {},
    }

    -- Load clothing (equipped on body)
    local clothingFolder = playerFolder:FindFirstChild("Clothing")
    if clothingFolder then
        for _, item in pairs(clothingFolder:GetChildren()) do
            if item:IsA("StringValue") then
                local clothingType = item.Value  -- "Armor", "TShirt", etc.
                local itemName = item.Name       -- "6B45", "WorkingTShirt"
                self.cachedData.Clothing[clothingType] = {
                    equipped = true,
                    name = itemName,
                }
                -- Cache icon
                local icon = UIHelpers.getItemIconFromProperties(item)
                if icon then
                    itemImageCache[itemName] = icon
                end
            end
        end
    end

    -- Load equipment (GPS, Map, Radio, Compass, etc.)
    local equipmentFolder = playerFolder:FindFirstChild("Equipment")
    if equipmentFolder then
        for _, item in pairs(equipmentFolder:GetChildren()) do
            if item:IsA("StringValue") then
                -- Skip weapon slots (Gun1, Gun2, Gun3) if they are in Equipment folder
                if item.Name ~= "Gun1" and item.Name ~= "Gun2" and item.Name ~= "Gun3" then
                    self.cachedData.Equipment[item.Name] = {
                        equipped = true,
                        name = item.Value,
                    }
                    local icon = UIHelpers.getItemIconFromProperties(item)
                    if icon then
                        itemImageCache[item.Value] = icon
                    end
                end
            end
        end
    end

    -- Weapons (Gun1, Gun2, Gun3) could go into their own field if needed, but not required for now

    -- Update UI rows based on equipped clothing
    self:ApplyParentSize()
    self:ApplyRows()

    return self.cachedData
end

-- Optional: call this when the game starts
task.wait(0.5)
InventoryUIController:LoadFromReplicatedStorage()

return InventoryUIController