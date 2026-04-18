local InventoryUIController = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RequestWeaponSystemData = ReplicatedStorage.Shared.Remotes.Requests:WaitForChild("RequestWeaponSystemData")
local SendInventory = ReplicatedStorage.Shared.Remotes.InventoryEvents:WaitForChild("SendInventory")
local RequestModule = ReplicatedStorage.Shared.Remotes.Requests:WaitForChild("RequestModule")
local PlayerSlotData = ReplicatedStorage.Shared.Remotes.InventoryEvents:WaitForChild("PlayerSlotData")

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local playerGui = player:WaitForChild("PlayerGui")
local Menu = playerGui:WaitForChild("Menu")
local MainParent = Menu.MainParent
local rowsParent = MainParent.InventoryParent.InventoryGui.InventoryItemsFrame.SingleRowParent

local TemplateInvRow = ReplicatedStorage.GUIS.TemplateInvRow

InventoryUIController.cachedData = nil
local equipped = {}

InventoryUIController.slots = {
    Inventory = {},
    Gear = {},
    WeaponSlots = {},
    Utils = {},
}

InventoryUIController.sizes = {
    UDim2.fromOffset(413, 100),
    UDim2.fromOffset(413, 210),
    UDim2.fromOffset(413, 322),
    UDim2.fromOffset(413, 432),
}

InventoryUIController.priority = {"Armor", "TShirt", "Pants"}

local playerInventoryData = {}
local itemImageCache = {}

function InventoryUIController:FetchData()
    local success, result = pcall(function()
        return RequestWeaponSystemData:InvokeServer()
    end)
    
    if success and result then
        self.cachedData = result[1].Inventory
        return result
    else
        warn("Failed to fetch weapon system data:", result)
        return nil
    end
end

function InventoryUIController:GetEquippedClothing()
    if not self.cachedData then
        self:FetchData()
    end
    
    if not self.cachedData then
        return {}
    end
    
    local clothing = self.cachedData.Equipment.Clothing
    equipped = {}

    for slotName, slotData in pairs(clothing) do
        if slotData.equipped and slotData.name ~= "" then
            table.insert(equipped, {
                slot = slotName,
                name = slotData.name
            })
        end
    end

    return equipped
end

function InventoryUIController:InitSlots()
    local globalIndex = 1
    self.slots.Inventory = {}

    for _, row in pairs(rowsParent:GetChildren()) do
        if row:IsA("Frame") and row.Name ~= "EquipmentRow" then
            local container = row:FindFirstChild("RowsParent")
            if container then
                for _, slot in pairs(container:GetChildren()) do
                    if slot:IsA("Frame") then
                        self.slots.Inventory[globalIndex] = slot
                        slot.Name = "Slot" .. tostring(globalIndex)
                        local itemIcon = slot:FindFirstChild("ItemIcon")
                        if itemIcon then
                            itemIcon.Image = ""
                        end
                        globalIndex += 1
                    end
                end
            end
        end
    end

    return globalIndex - 1
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

function InventoryUIController:GetPlayerSlotRows()
    local count = 1
    
    if not self.cachedData then
        self:FetchData()
    end
    
    if self.cachedData then
        for i, v in pairs(self.cachedData.Equipment.Clothing) do
            if (i == "Armor" or i == "TShirt" or i == "Pants") and v.equipped then
                count = count + 1
            elseif i == "Backpack" and v.equipped and v.name then
                print("Equipped backpack", v.name)
            end
        end
    end

    return count
end

function InventoryUIController:ApplyParentSize()
    local count = self:GetPlayerSlotRows()
    rowsParent.Size = self.sizes[math.clamp(count, 1, #self.sizes)]
end

function InventoryUIController:UpdateSlot(index)
    local slot = self.slots.Inventory[index]
    if not slot then return end
    
    local itemIcon = slot:FindFirstChild("ItemIcon")
    if not itemIcon then return end
    
    local itemName = playerInventoryData[index]
    
    if itemName and itemName ~= "" then
        if itemImageCache[itemName] then
            itemIcon.Image = itemImageCache[itemName]
        else
            task.spawn(function()
                local success, module = pcall(function()
                    return RequestModule:InvokeServer(itemName)
                end)
                if success and module and module.imageIconId then
                    itemImageCache[itemName] = module.imageIconId
                    if self.slots.Inventory[index] then
                        itemIcon.Image = module.imageIconId
                    end
                end
            end)
        end
    else
        itemIcon.Image = ""
    end
end

function InventoryUIController:RenderItems()
    for index, _ in pairs(playerInventoryData) do
        self:UpdateSlot(index)
    end
end

SendInventory.OnClientEvent:Connect(function(savedInventory)
    if type(savedInventory) == "table" and savedInventory.PlayerInventory then
        playerInventoryData = savedInventory.PlayerInventory
    else
        playerInventoryData = savedInventory or {}
    end
    
    task.wait(0.1)
    InventoryUIController:RenderItems()
end)

function InventoryUIController:InitSys()
    self:FetchData()
    self:GetEquippedClothing()
    self:ApplyParentSize()
    self:ApplyRows()
    self:InitSlots()
    self:RenderItems()
end

return InventoryUIController