-- ReplicatedStorage.Modules.InventoryConfig
local InventoryConfig = {}

-- Slot type patterns (for dynamic identification)
InventoryConfig.SLOT_PATTERNS = {
    WEAPON = {"Gun1", "Gun2", "Gun3"},                -- exact names
    CLOTHING = {"Helmet","Backpack","Armor","TShirt","Pants","Leggings","Mask"},
    CONTAINER_CLOTHING = {"Armor","TShirt","Pants","Backpack"},  -- have inventory folders
}

-- Check if a slot name is a weapon slot
function InventoryConfig.IsWeaponSlot(slotName)
    for _, name in ipairs(InventoryConfig.SLOT_PATTERNS.WEAPON) do
        if slotName == name then return true end
    end
    return false
end

-- Check if a slot name is a clothing slot (equipped gear)
function InventoryConfig.IsClothingSlot(slotName)
    for _, name in ipairs(InventoryConfig.SLOT_PATTERNS.CLOTHING) do
        if slotName == name then return true end
    end
    return false
end

-- Check if a clothing type has an inventory container
function InventoryConfig.HasContainer(clothingType)
    for _, name in ipairs(InventoryConfig.SLOT_PATTERNS.CONTAINER_CLOTHING) do
        if clothingType == name then return true end
    end
    return false
end

-- Get the order of clothing for slot range calculation (only container clothing)
function InventoryConfig.GetContainerOrder()
    return InventoryConfig.SLOT_PATTERNS.CONTAINER_CLOTHING
end

-- Given a player's equipped clothing (a table like {Armor=true, TShirt=true, ...}),
-- compute the slot ID for a given clothing and relative slot (1-5).
-- Returns absolute slot number.
function InventoryConfig.GetAbsoluteSlot(equippedContainers, clothingType, relativeSlot)
    local offset = 3  -- weapon slots take 1-3
    for _, ct in ipairs(InventoryConfig.GetContainerOrder()) do
        if equippedContainers[ct] then
            if ct == clothingType then
                return offset + relativeSlot
            end
            offset = offset + 5
        end
    end
    return nil
end

-- Reverse: given an absolute slot ID, find which clothing type and relative slot it belongs to.
function InventoryConfig.GetClothingFromSlot(equippedContainers, absoluteSlot)
    if absoluteSlot >= 1 and absoluteSlot <= 3 then
        return nil, "weapon", absoluteSlot  -- weapon slot index
    end
    local offset = 3
    for _, ct in ipairs(InventoryConfig.GetContainerOrder()) do
        if equippedContainers[ct] then
            if absoluteSlot > offset and absoluteSlot <= offset + 5 then
                return ct, "container", absoluteSlot - offset
            end
            offset = offset + 5
        end
    end
    return nil, nil, nil
end

return InventoryConfig