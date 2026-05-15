-- SlotManager.luau
-- Handles finding available slots and validating slot compatibility

local SlotMappings = require(script.Parent.Parent.Data.SlotMappings)

local SlotManager = {}

-- ============================================================
-- SLOT PRIORITY ORDER
-- ============================================================

-- Priority order for weapon slots (which slot to use first)
local WeaponSlotPriority = {
    "ItemHip1",
    "ItemHip2", 
    "ItemHip3",
}

-- Priority order for finding empty container slots
local ContainerSlotPriority = {
    "Backpack",
    "ChestRig", 
    "Pants",
    "Shirt",
}

-- ============================================================
-- CORE FUNCTIONS
-- ============================================================

-- Find an available slot for an item
-- Parameters: manager, itemName, itemType, slotType
function SlotManager.FindAvailableSlot(manager, itemName, itemType, slotType)
    -- If we don't have type info, we can't find a slot
    if not itemType then
        return nil
    end
    
    -- 1. Handle weapon types (go to weapon slots)
    if itemType == "RangedWeapon" then
        return SlotManager.FindWeaponSlot(manager, slotType)
    end
    
    -- 2. Handle tools (Melee, GPS, Map, etc.)
    if itemType == "Melee" or itemType == "Tool" then
        return SlotManager.FindToolSlot(manager, slotType)
    end
    
    -- 3. Handle clothing
    if itemType == "Clothing" then
        return SlotManager.FindClothingSlot(manager, slotType)
    end
    
    -- 4. Default: find an empty container slot
    return SlotManager.FindEmptyContainerSlot(manager)
end

-- Find an empty weapon slot for a weapon type
function SlotManager.FindWeaponSlot(manager, weaponType)
    -- Check each weapon slot in priority order
    for _, slotName in pairs(WeaponSlotPriority) do
        local existingItem = manager:getItem(slotName)
        
        if not existingItem then
            return slotName
        end
    end
    return nil -- No weapon slots available
end

-- Find an empty tool slot
function SlotManager.FindToolSlot(manager, toolType)
    -- Map tool type to slot name
    local toolSlotMap = {
        Melee = "Melee",
        GPS = "EquipmentGPS",
        Map = "EquipmentMap",
        Lighter = "EquipmentLighter",
        Compass = "EquipmentCompass",
    }
    
    local slotName = toolSlotMap[toolType]
    if not slotName then
        return nil
    end
    
    local existingItem = manager:getItem(slotName)
    if not existingItem then
        return slotName
    end
    return nil
end

-- Find an empty clothing slot
function SlotManager.FindClothingSlot(manager, clothingType)
    -- Map clothing type to slot name
    local clothingSlotMap = {
        Shirt = "ClothingShirt",
        Pants = "ClothingPants",
        ChestRig = "ClothingChestRig",
        Backpack = "ClothingBackpack",
        Headware = "ClothingHeadware",
        Mask = "ClothingMask",
        Gloves = "ClothingGloves",
        LegArmor = "ClothingLegArmor",
    }
    
    local slotName = clothingSlotMap[clothingType]
    if not slotName then
        return nil
    end
    
    local existingItem = manager:getItem(slotName)
    if not existingItem then
        return slotName
    end
    return nil
end

-- Find the first empty slot in containers (Backpack, Pants, etc.)
function SlotManager.FindEmptyContainerSlot(manager)
    -- Check each container type in priority order
    for _, containerType in pairs(ContainerSlotPriority) do
        local inventoryData = manager:getInventory(containerType)
        
        if inventoryData and inventoryData.Inventory then
            local slotNumber = SlotManager.FindEmptySlotInContainer(inventoryData.Inventory, containerType)
            if slotNumber then
                -- Return formatted slot name like "Backpack1", "Pants3", etc.
                return containerType .. slotNumber
            end
        end
    end
    return nil
end

-- Find empty slot number within a specific container
function SlotManager.FindEmptySlotInContainer(inventoryFolder, containerType)
    local maxSlots = inventoryFolder:GetAttribute("Slots") or 0
    
    -- Track which slots are taken
    local takenSlots = {}
    for _, item in pairs(inventoryFolder:GetChildren()) do
        if item:IsA("StringValue") then
            local slotValue = item.Name  -- The slot identifier like "Backpack1"
            -- Extract number from slot name
            local slotNum = tonumber(string.match(slotValue, "%d+"))
            if slotNum then
                takenSlots[slotNum] = true
            end
        end
    end
    
    -- Find first empty slot
    for i = 1, maxSlots do
        if not takenSlots[i] then
            return i
        end
    end
    
    return nil
end

-- ============================================================
-- VALIDATION FUNCTIONS
-- ============================================================

-- Check if an item can go into a specific slot
function SlotManager.IsSlotCompatible(manager, item, targetSlot)
    local itemProperties = item:FindFirstChild("ItemProperties")
    if not itemProperties then
        return false
    end
    
    local itemType = itemProperties:GetAttribute("ItemType")
    local slotType = itemProperties:GetAttribute("SlotType")
    
    -- Get base slot (remove container prefix if present)
    local isContainer = SlotMappings.IsContainerSlot(targetSlot)
    local baseSlot = SlotMappings.GetBaseSlot(targetSlot)
    
    -- Check if target slot is already occupied
    local existingItem = nil
    if isContainer then
        existingItem = manager:getItemTemp(targetSlot)
    else
        existingItem = manager:getItem(targetSlot)
    end
    
    if existingItem then
        return false -- Slot is occupied
    end
    
    -- Validate based on item type
    if itemType == "RangedWeapon" then
        return SlotMappings.IsWeaponCompatible(baseSlot, slotType)
    end
    
    if itemType == "Clothing" then
        local expectedSlot = SlotMappings.GetUISlotName(slotType, false)
        return baseSlot == expectedSlot or baseSlot == slotType
    end
    
    -- For regular items, check if target is a container slot
    if isContainer then
        return true
    end
    
    return false
end

-- Get all items currently in a container
function SlotManager.GetContainerItems(containerItem)
    local items = {}
    local invFolder = containerItem:FindFirstChild("Inventory")
    
    if invFolder then
        for _, item in pairs(invFolder:GetChildren()) do
            if item:IsA("StringValue") then
                table.insert(items, item)
            end
        end
    end
    
    return items
end

-- Get the number of free slots in a container
function SlotManager.GetFreeSlotCount(inventoryFolder)
    local maxSlots = inventoryFolder:GetAttribute("Slots") or 0
    local usedSlots = 0
    
    for _, item in pairs(inventoryFolder:GetChildren()) do
        if item:IsA("StringValue") then
            usedSlots = usedSlots + 1
        end
    end
    
    return maxSlots - usedSlots
end

return SlotManager