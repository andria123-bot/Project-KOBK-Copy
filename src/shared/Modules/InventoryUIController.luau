-- Client - InventoryUIController (with full debugging)
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
    WEAPONS   = 16,
    GEAR      = 19,
    UTILS     = 27,
}

local function getSlotRanges()
    local playerFolder = ReplicatedStorage.Players:FindFirstChild(player.Name)
    if not playerFolder then 
        print("[DEBUG] getSlotRanges: No player folder")
        return {}, 0 
    end
    local clothingFolder = playerFolder:FindFirstChild("Clothing")
    local ranges, total = UIHelpers.getSlotRanges(clothingFolder, InventoryUIController.priority)
    print("[DEBUG] getSlotRanges: ranges =", ranges, "total slots =", total)
    return ranges, total
end

function InventoryUIController:GetSlotUnderMouse()
    local mousePos = UIHelpers.getMousePosition()
    for slotId, slotInfo in pairs(self.slots.All) do
        if slotInfo.frame and UIHelpers.isMouseOverFrame(slotInfo.frame, mousePos) then
            print("[DEBUG] GetSlotUnderMouse: slot =", slotId)
            return slotId
        end
    end
    return nil
end

function InventoryUIController:GetEquippedClothing()
    if not self.cachedData then 
        print("[DEBUG] GetEquippedClothing: no cachedData")
        return {} 
    end
    local clothing = self.cachedData.Equipment and self.cachedData.Equipment.Clothing
    if not clothing then 
        print("[DEBUG] GetEquippedClothing: no clothing in cachedData")
        return {} 
    end

    local equipped = {}
    for slotName, slotData in pairs(clothing) do
        if slotData.equipped and slotData.name ~= "" then
            equipped[slotName] = { equipped = true, slot = slotName, name = slotData.name }
        end
    end
    print("[DEBUG] GetEquippedClothing:", equipped)
    return equipped
end

function InventoryUIController:GetTotalSlotCount()
    local equipped = self:GetEquippedClothing()
    local count = 0
    for _ in pairs(equipped) do
        count = count + 5
    end
    print("[DEBUG] GetTotalSlotCount:", count)
    return count
end

function InventoryUIController:SetupDragDrop()
    local DraggableObject = require(script.Parent.DraggableObject)

    for slotId, slotInfo in pairs(self.slots.All) do
        local itemIcon = slotInfo.frame:FindFirstChild("ItemIcon")
        if itemIcon and not itemIcon:GetAttribute("DragSetup") then
            itemIcon:SetAttribute("DragSetup", true)

            local draggable = DraggableObject.new(itemIcon, MainParent)

            draggable.CanDrag = function()
                local itemName = playerInventoryData[slotId]
                return itemName and itemName ~= ""
            end

            draggable.DragStarted = function()
                self.draggingFromSlot = slotId
            end

            draggable.DragEnded = function()
                if not self.draggingFromSlot then
                    return
                end
                
                local targetSlot = self:GetSlotUnderMouse()
                if targetSlot and targetSlot ~= self.draggingFromSlot then
                    local fromItem = playerInventoryData[self.draggingFromSlot]
                    local toItem = playerInventoryData[targetSlot]
                    
                    playerInventoryData[self.draggingFromSlot] = toItem
                    playerInventoryData[targetSlot] = fromItem
                    
                    self:UpdateSlot(self.draggingFromSlot)
                    self:UpdateSlot(targetSlot)
                    
                    ReplicatedStorage.InventoryMove:FireServer(self.draggingFromSlot, targetSlot)
                end
                self.draggingFromSlot = nil
            end

            draggable:Enable()
        end
    end
end

function InventoryUIController:InitSlots()
    task.wait()

    local globalIndex = SLOT_START.INVENTORY
    self.slots.Inventory = {}
    self.slots.All = {}

    print("[DEBUG] InitSlots: scanning rowsParent...")
    for _, row in pairs(rowsParent:GetChildren()) do
        if row:IsA("Frame") and row.Name ~= "EquipmentRow" then
            local container = row:FindFirstChild("SlotRow")
            if container then
                local rowClothing = row.Name:gsub("Row", "")
                local equipped = self:GetEquippedClothing()

                print("[DEBUG] InitSlots: row =", row.Name, "rowClothing =", rowClothing, "equipped =", equipped[rowClothing] ~= nil)

                if equipped[rowClothing] then
                    row.Visible = true
                    for _, slot in pairs(container:GetChildren()) do
                        if slot:IsA("Frame") then
                            self.slots.Inventory[globalIndex] = slot
                            self.slots.All[globalIndex] = {
                                frame = slot,
                                type = "inventory",
                                index = globalIndex,
                                slotName = slot.Name,
                            }
                            slot.Name = "Slot" .. tostring(globalIndex)
                            local itemIcon = slot:FindFirstChild("ItemIcon")
                            if itemIcon then
                                itemIcon.Image = ""
                                itemIcon.Visible = true
                            end
                            print("[DEBUG] InitSlots: registered slot", globalIndex)
                            globalIndex = globalIndex + 1
                        end
                    end
                else
                    row.Visible = false
                    print("[DEBUG] InitSlots: hiding row", row.Name)
                end
            end
        end
    end
    print("[DEBUG] InitSlots: total slots registered =", globalIndex - 1)
end

function InventoryUIController:InitGearSlots()
    task.wait()

    self.slots.Gear = {}
    self.slots.WeaponSlots = {}
    self.slots.Utils = {}

    local nextSlotId = SLOT_START.WEAPONS
    print("[DEBUG] InitGearSlots: starting at slot", nextSlotId)

    for _, row in pairs(equipmentFrame:GetChildren()) do
        if row:IsA("Frame") then
            local slotContainer = row:FindFirstChild("SlotRow") or row
            local rowName = row.Name
            print("[DEBUG] InitGearSlots: processing row", rowName)

            for _, slotFrame in pairs(slotContainer:GetChildren()) do
                if slotFrame:IsA("Frame") then
                    local slotType

                    if rowName == "Weapons" then
                        slotType = "weapon"
                        table.insert(self.slots.WeaponSlots, slotFrame)
                    elseif rowName == "Utils" then
                        slotType = "utils"
                        table.insert(self.slots.Utils, slotFrame)
                    else
                        slotType = "gear"
                        table.insert(self.slots.Gear, slotFrame)
                    end

                    self.slots.All[nextSlotId] = {
                        frame    = slotFrame,
                        type     = slotType,
                        index    = nextSlotId,
                        slotName = slotFrame.Name,
                    }
                    print("[DEBUG] InitGearSlots: registered", slotType, "slot", nextSlotId, "name =", slotFrame.Name)
                    nextSlotId = nextSlotId + 1
                end
            end
        end
    end
    print("[DEBUG] InitGearSlots: total equipment slots =", nextSlotId - SLOT_START.WEAPONS)
end

-- In InventoryUIController:UpdateSlot() - Fix gear slot display
function InventoryUIController:UpdateSlot(slotId)
    local slotInfo = self.slots.All[slotId]
    if not slotInfo or not slotInfo.frame then return end
    
    local itemIcon = slotInfo.frame:FindFirstChild("ItemIcon")
    if not itemIcon then return end
    
    local itemName = nil
    
    -- Handle gear slots (equipment on body)
    if slotInfo.type == "gear" and slotInfo.slotName then
        local clothing = self.cachedData and self.cachedData.Equipment.Clothing
        if clothing then
            -- Try exact match first
            local gearData = clothing[slotInfo.slotName]
            if not gearData then
                -- Try case-insensitive or common variations
                for key, value in pairs(clothing) do
                    if string.lower(key) == string.lower(slotInfo.slotName) then
                        gearData = value
                        break
                    end
                end
            end
            if gearData and gearData.name and gearData.name ~= "" then
                itemName = gearData.name
            end
        end
    elseif slotInfo.type == "weapon" and slotInfo.slotName then
        local weapons = self.cachedData and self.cachedData.Equipment.Weapons
        local weaponData = weapons and weapons[slotInfo.slotName]
        if weaponData and weaponData.item and weaponData.item ~= "" then
            itemName = weaponData.item
        end
    elseif slotInfo.type == "utils" and slotInfo.slotName then
        local utils = self.cachedData and self.cachedData.Equipment.Utils
        local utilData = utils and utils[slotInfo.slotName]
        if utilData and utilData.name and utilData.name ~= "" then
            itemName = utilData.name
        end
    else
        -- Inventory slot
        itemName = playerInventoryData[slotId]
    end
    
    if itemName and itemName ~= "" then
        local icon = UIHelpers.getCachedIcon(itemName, itemImageCache)
        if icon and icon ~= "" then
            itemIcon.Image = icon
        else
            itemIcon.Image = "rbxassetid://default_icon"
        end
        itemIcon.Visible = true
    else
        if slotInfo.type ~= "inventory" then
            local placeholder = "rbxassetid://000"  -- for leater use UIHelpers.getStoredGearImage(slotInfo.slotName)
            if placeholder then
                itemIcon.Image = placeholder
            else
                itemIcon.Image = ""
            end
        else
            itemIcon.Image = ""
        end
        itemIcon.Visible = true
    end
end

function InventoryUIController:RefreshAllSlots()
    print("[DEBUG] RefreshAllSlots: refreshing", self:GetTotalSlotCount(), "slots")
    for slotId in pairs(self.slots.All) do
		print(self.slots)
        self:UpdateSlot(slotId)
    end
end

function InventoryUIController:ApplyRows()
    for _, child in pairs(rowsParent:GetChildren()) do
        if child:IsA("Frame") and child.Name ~= "EquipmentRow" then
            child:Destroy()
        end
    end

    for _, gearName in ipairs(self.priority) do
        local clothing = self.cachedData and self.cachedData.Equipment and self.cachedData.Equipment.Clothing
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
    local totalSlots = self:GetTotalSlotCount()
    local rowCount = math.max(math.ceil(totalSlots / 5), 1)
    rowsParent.Size = self.sizes[math.clamp(rowCount, 1, #self.sizes)]
    print("[DEBUG] ApplyParentSize: totalSlots =", totalSlots, "rowCount =", rowCount)
end

function InventoryUIController:LoadFromReplicatedStorage()
    local playerFolder = ReplicatedStorage.Players:FindFirstChild(player.Name)
    if not playerFolder then return nil end

    local data = {
        PlayerInventory = {},
        Equipment = { Clothing = {}, Weapons = {}, Utils = {} },
        SlotCount = 0,
    }

    local clothingFolder = playerFolder:FindFirstChild("Clothing")
    local ranges, totalSlots = getSlotRanges()
    data.SlotCount = totalSlots

    -- Map clothing type to gear slot ID
    local clothingToGearSlot = {
		Mask = 19,
        TShirt = 20,
        Pants = 21,
		Melee = 22,
        Armor = 23,
        Helmet = 24,
		Leggings = 25,
        Backpack = 26,
    }

    if clothingFolder then
        for _, clothingItem in pairs(clothingFolder:GetChildren()) do
            if clothingItem:IsA("StringValue") then
                local slotType = clothingItem.Value  -- "Armor", "TShirt", "Pants"
                local itemName = clothingItem.Name   -- "6B45", "WorkingTShirt", "WorkingPants"
                
                -- Store equipped clothing for equipment tracking
                data.Equipment.Clothing[slotType] = { equipped = true, name = itemName }
                
                -- ✅ ADD CLOTHING ITEM TO GEAR SLOTS (for drag-drop)
                local gearSlotId = clothingToGearSlot[slotType]
                if gearSlotId then
                    data.PlayerInventory[gearSlotId] = itemName
                    local icon = UIHelpers.getItemIconFromProperties(clothingItem)
                    if icon then
                        UIHelpers.cacheItemIcon(itemName, icon, itemImageCache)
                    end
                end

				-- Load items inside clothing's inventory
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
            end
        end
    end

    -- Load equipment folder (weapons and tools)
    local equipmentFolder = playerFolder:FindFirstChild("Equipment")
    if equipmentFolder then
        for _, item in pairs(equipmentFolder:GetChildren()) do
            if item:IsA("StringValue") then
                if item.Name:find("Gun") then
                    data.Equipment.Weapons[item.Name] = { equipped = true, item = item.Value }
                else
                    data.Equipment.Utils[item.Name] = { equipped = true, name = item.Value }
                end
            end
        end
    end

    self.cachedData = data
    return data
end

function InventoryUIController:ApplyInventoryData(inventoryTable)
    print("[DEBUG] ApplyInventoryData: START")
    if not inventoryTable then 
        print("[DEBUG] ApplyInventoryData: inventoryTable is nil")
        return 
    end
    self.cachedData = inventoryTable

    local totalSlots = inventoryTable.SlotCount or self:GetTotalSlotCount()
    print("[DEBUG] ApplyInventoryData: totalSlots =", totalSlots)

    playerInventoryData = {}
    for i = 1, totalSlots do
        playerInventoryData[i] = inventoryTable.PlayerInventory[i] or ""
    end
    print("[DEBUG] ApplyInventoryData: playerInventoryData =", playerInventoryData)

    self:ApplyParentSize()
    self:ApplyRows()

    task.spawn(function()
        self:InitSlots()
        self:InitGearSlots()
        UIHelpers.cacheGearPlaceholders(self.slots)
        self:RefreshAllSlots()
        self:SetupDragDrop()
    end)
end

-- Add this function to get gear placeholders (call this after slots are initialized)
function InventoryUIController:CacheGearPlaceholders()

    for slotId, slotInfo in pairs(self.slots.All) do
        if slotInfo.type ~= "inventory" and slotInfo.slotName then
            local frame = slotInfo.frame
            local itemIcon = frame and frame:FindFirstChild("ItemIcon")
            if itemIcon and itemIcon.Image ~= "" then
                UIHelpers.cacheGearPlaceholder(slotInfo.slotName, itemIcon.Image)
            end
        end
    end
end

local function setupListener()
    local playersFolder = ReplicatedStorage:FindFirstChild("Players")
    if not playersFolder then return end

    local playerFolder = playersFolder:FindFirstChild(player.Name)
    if not playerFolder then return end

    local function onInventoryChanged()
        print("[DEBUG] onInventoryChanged: triggered")
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
    print("[DEBUG] InitSys: START")
    local data = self:LoadFromReplicatedStorage()
    if data then
        self:ApplyInventoryData(data)
    else
        print("[DEBUG] InitSys: No data, applying defaults")
        task.spawn(function()
            self:ApplyParentSize()
            self:ApplyRows()
            self:InitSlots()
            self:InitGearSlots()
        end)
    end

    setupListener()

    ReplicatedStorage.InventoryUpdated.OnClientEvent:Connect(function()
        print("[DEBUG] InventoryUpdated received from server")
        local newData = self:LoadFromReplicatedStorage()
        if newData then
            self:ApplyInventoryData(newData)
        end
    end)
end

task.wait(0.5)
InventoryUIController:InitSys()

return InventoryUIController