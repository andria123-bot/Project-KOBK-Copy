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

local TemplateInvRow = ReplicatedStorage.GUIS.TemplateInvRow

InventoryUIController.cachedData = nil

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
    local equipped = {}

    for slotName, slotData in pairs(clothing) do
        if slotData.equipped and slotData.name ~= "" then
            table.insert(equipped, {
                slot = slotName,
                name = slotData.name
            })
        end
    end

    print("Equipped clothing:", equipped)
    return equipped
end

function InventoryUIController:GetPlayerSlotRows()
    if not self.cachedData then
        self:FetchData()
    end

    local count = 0

    if self.cachedData then
        for i, v in pairs(self.cachedData.Equipment.Clothing) do
            if (i == "Armor" or i == "TShirt" or i == "Pants") and v.equipped then
                count = count + 1
            elseif i == "Backpack" and v.equipped and v.name then
                print("Equipped backpack:", v.name)
            end
        end
    end

    return count
end

function InventoryUIController:ApplyParentSize()
    local count = self:GetPlayerSlotRows()
    local clamped = math.clamp(count, 1, #self.sizes)
    rowsParent.Size = self.sizes[clamped]
    print("ApplyParentSize: rows =", count, "size =", rowsParent.Size)
end

function InventoryUIController:ApplyRows()
    -- Clear existing rows, keep EquipmentRow
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

function InventoryUIController:InitSlots()
    -- Wait a frame so ApplyRows layout settles before scanning
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

    print("InitSlots: total slots registered =", globalIndex - 1)
    return globalIndex - 1
end

function InventoryUIController:UpdateSlot(index)
    local slot = self.slots.Inventory[index]
    if not slot then return end

    local itemIcon = slot:FindFirstChild("ItemIcon")
    if not itemIcon then return end

    -- Always restore visibility when updating
    itemIcon.Visible = true

    local itemName = playerInventoryData[index]
    if itemName and itemName ~= "" then
        if itemImageCache[itemName] then
            itemIcon.Image = itemImageCache[itemName]
            return
        end

        if not itemImageCache[itemName .. "_loading"] then
            itemImageCache[itemName .. "_loading"] = true
            task.spawn(function()
                local success, mod = pcall(function()
                    return RequestModule:InvokeServer(itemName)
                end)
                if success and mod and mod.imageIconId then
                    itemImageCache[itemName] = mod.imageIconId
                    local currentSlot = self.slots.Inventory[index]
                    if currentSlot then
                        local currentIcon = currentSlot:FindFirstChild("ItemIcon")
                        if currentIcon and playerInventoryData[index] == itemName then
                            currentIcon.Image = mod.imageIconId
                        end
                    end
                end
                itemImageCache[itemName .. "_loading"] = nil
            end)
        end
    else
        itemIcon.Image = ""
    end
end

function InventoryUIController:RenderItems()
    for i = 1, #self.slots.Inventory do
        self:UpdateSlot(i)
    end
end

function InventoryUIController:ApplyInventoryData(inventoryTable)
    if not inventoryTable then return end
    playerInventoryData = {}
    for i = 1, #self.slots.Inventory do
        playerInventoryData[i] = inventoryTable[i] or ""
    end
    self:RenderItems()
end

function InventoryUIController:InitSys()
    self:FetchData()
    self:GetEquippedClothing()
    self:ApplyParentSize()
    self:ApplyRows()
    self:InitSlots()
    self:RenderItems()
end

player.CharacterAdded:Connect(function()
    task.wait(0.5)
    InventoryUIController:InitSys()
end)

return InventoryUIController