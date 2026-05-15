-- SlotMappings.luau
-- Defines all slot types, mappings, and helper functions for the inventory system

local SlotMappings = {}

-- ============================================================
-- SLOT MAPPINGS (UI Name -> Internal Type)
-- ============================================================

SlotMappings.EquipmentSlots = {
    -- Clothing
    ClothingShirt = "Shirt",
    ClothingPants = "Pants",
    ClothingChestRig = "ChestRig",
    ClothingBackpack = "Backpack",
    ClothingHeadware = "Headware",
    ClothingMask = "Mask",
    ClothingGloves = "Gloves",
    ClothingLegArmor = "LegArmor",
    
    -- Weapon Slots (Hotbar - equipped weapons)
    ItemHip1 = "ItemHip1",
    ItemHip2 = "ItemHip2",
    ItemHip3 = "ItemHip3",
    
    -- Hotbar Utility Slots
    Hotbar4 = "Hotbar4",
    Hotbar5 = "Hotbar5",
    Hotbar6 = "Hotbar6",
    Hotbar7 = "Hotbar7",
    Hotbar8 = "Hotbar8",
    
    -- Weapon Inventory Slots (storage)
    InventoryItemHip1 = "InventoryItemHip1",
    InventoryItemHip2 = "InventoryItemHip2",
    InventoryItemHip3 = "InventoryItemHip3",
    
    -- Tool Slots
    Melee = "Melee",
    EquipmentGPS = "GPS",
    EquipmentMap = "Map",
    EquipmentLighter = "Lighter",
    EquipmentCompass = "Compass",
}

-- Reverse mapping
SlotMappings.ReverseEquipment = {}
for uiName, internalType in pairs(SlotMappings.EquipmentSlots) do
    SlotMappings.ReverseEquipment[internalType] = uiName
end

-- ============================================================
-- HOTBAR SLOTS LISTS
-- ============================================================

-- Equipped weapon slots (hotbar)
SlotMappings.EquippedWeaponSlots = {"ItemHip1", "ItemHip2", "ItemHip3"}

-- Utility hotbar slots
SlotMappings.UtilityHotbarSlots = {"Hotbar4", "Hotbar5", "Hotbar6", "Hotbar7", "Hotbar8"}

-- All hotbar slots
SlotMappings.HotbarSlots = {
    "ItemHip1", "ItemHip2", "ItemHip3",
    "Hotbar4", "Hotbar5", "Hotbar6", "Hotbar7", "Hotbar8"
}

-- Weapon inventory slots (storage)
SlotMappings.WeaponInventorySlots = {
    "InventoryItemHip1", "InventoryItemHip2", "InventoryItemHip3"
}

-- ============================================================
-- WEAPON SLOT COMPATIBILITY
-- ============================================================

SlotMappings.WeaponSlotCompatibility = {
    -- Equipped slots
    ItemHip1 = { "Pistol", "SMG", "AssaultRifle", "DMR", "Shotgun" },
    ItemHip2 = { "Pistol", "SMG", "AssaultRifle", "DMR", "Shotgun" },
    ItemHip3 = { "Pistol", "SMG", "AssaultRifle", "DMR", "Shotgun" },
    
    -- Storage slots
    InventoryItemHip1 = { "Pistol", "SMG", "AssaultRifle", "DMR", "Shotgun" },
    InventoryItemHip2 = { "Pistol", "SMG", "AssaultRifle", "DMR", "Shotgun" },
    InventoryItemHip3 = { "Pistol", "SMG", "AssaultRifle", "DMR", "Shotgun" },
}

-- ============================================================
-- TOOL SLOT COMPATIBILITY
-- ============================================================

SlotMappings.ToolSlotCompatibility = {
    Melee = { "Melee", "Knife", "Axe" },
    EquipmentGPS = { "GPS" },
    EquipmentMap = { "Map" },
    EquipmentLighter = { "Lighter" },
    EquipmentCompass = { "Compass" },
}

-- ============================================================
-- CONTAINER SYSTEM
-- ============================================================

SlotMappings.ContainerPrefix = "Container"

SlotMappings.ContainerSlots = {
    "ContainerBackpack",
    "ContainerShirt", 
    "ContainerPants",
    "ContainerChestRig",
}

-- ============================================================
-- INVENTORY TYPES
-- ============================================================

SlotMappings.InventoryTypes = {
    Shirt = "Shirt",
    Pants = "Pants", 
    ChestRig = "ChestRig",
    Backpack = "Backpack",
    Container = "Container",
    Vault = "Vault",
}

-- ============================================================
-- HELPER FUNCTIONS
-- ============================================================

function SlotMappings.IsEquipmentSlot(slotName)
    return SlotMappings.EquipmentSlots[slotName] ~= nil
end

function SlotMappings.IsContainerSlot(slotName)
    return string.sub(slotName, 1, #SlotMappings.ContainerPrefix) == SlotMappings.ContainerPrefix
end

function SlotMappings.IsHotbarSlot(slotName)
    for _, s in pairs(SlotMappings.HotbarSlots) do
        if s == slotName then
            return true
        end
    end
    return false
end

function SlotMappings.IsWeaponInventorySlot(slotName)
    for _, s in pairs(SlotMappings.WeaponInventorySlots) do
        if s == slotName then
            return true
        end
    end
    return false
end

function SlotMappings.IsEquippedWeaponSlot(slotName)
    for _, s in pairs(SlotMappings.EquippedWeaponSlots) do
        if s == slotName then
            return true
        end
    end
    return false
end

function SlotMappings.GetBaseSlot(slotName)
    if SlotMappings.IsContainerSlot(slotName) then
        return string.sub(slotName, #SlotMappings.ContainerPrefix + 1)
    end
    return slotName
end

function SlotMappings.GetInternalType(uiSlotName)
    local base = SlotMappings.GetBaseSlot(uiSlotName)
    return SlotMappings.EquipmentSlots[base] or base
end

function SlotMappings.GetUISlotName(internalType, isContainer)
    local uiName = SlotMappings.ReverseEquipment[internalType] or internalType
    if isContainer then
        return SlotMappings.ContainerPrefix .. uiName
    end
    return uiName
end

function SlotMappings.IsWeaponCompatible(slotName, weaponType)
    local compatible = SlotMappings.WeaponSlotCompatibility[slotName]
    if not compatible then
        return false
    end
    
    for _, t in pairs(compatible) do
        if t == weaponType then
            return true
        end
    end
    return false
end

function SlotMappings.IsToolCompatible(slotName, toolType)
    local compatible = SlotMappings.ToolSlotCompatibility[slotName]
    if not compatible then
        return false
    end
    
    for _, t in pairs(compatible) do
        if t == toolType then
            return true
        end
    end
    return false
end

function SlotMappings.ParseNumberedSlot(slotName)
    local base = SlotMappings.GetBaseSlot(slotName)
    local number = string.match(base, "%d+$")
    local slotType = string.gsub(base, "%d+$", "")
    
    if number then
        return slotType, tonumber(number)
    end
    return base, nil
end

function SlotMappings.AreSlotsCompatible(sourceSlot, targetSlot)
    if sourceSlot == targetSlot then
        return false
    end
    
    if sourceSlot == "Melee" or targetSlot == "Melee" then
        return false
    end
    
    return true
end

return SlotMappings