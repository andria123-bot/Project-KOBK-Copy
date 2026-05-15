-- ItemUtils.luau
-- Helper functions for item manipulation (moving, stacking, attaching, etc.)

local SlotMappings = require(script.Parent.Parent.Data.SlotMappings)
local SlotManager = require(script.Parent.SlotManager)

local ItemUtils = {}

-- ============================================================
-- ITEM MOVEMENT
-- ============================================================

-- Move an item to a new slot
-- Returns: boolean success, string errorMessage
function ItemUtils.MoveItem(manager, sourceItem, targetSlot)
    local sourceData = manager:getItem(sourceItem.Name)
    if not sourceData then
        return false, "Source item not found"
    end
    
    -- Check if target slot is compatible
    local compatible = SlotManager.IsSlotCompatible(manager, sourceItem, targetSlot)
    if not compatible then
        return false, "Slot incompatible"
    end
    
    -- Check if target slot is empty
    local existingItem = manager:getItem(targetSlot)
    if existingItem then
        return false, "Target slot occupied"
    end
    
    -- Update the item's slot value
    sourceItem.Value = targetSlot
    
    -- Move to new parent folder
    local targetFolder = ItemUtils.GetTargetFolder(manager, targetSlot)
    if targetFolder then
        sourceItem.Parent = targetFolder
    end
    
    -- Refresh manager state
    manager:refresh()
    
    return true, "Success"
end

-- Swap two items
function ItemUtils.SwapItems(manager, itemASlot, itemBSlot)
    local itemAData = manager:getItem(itemASlot)
    local itemBData = manager:getItem(itemBSlot)
    
    if not itemAData or not itemBData then
        return false, "One or both items not found"
    end
    
    local itemA = itemAData.Item
    local itemB = itemBData.Item
    
    -- Swap their slot values
    local tempSlot = itemA.Value
    itemA.Value = itemB.Value
    itemB.Value = tempSlot
    
    -- Swap their parents (if different)
    local parentA = itemA.Parent
    local parentB = itemB.Parent
    
    if parentA ~= parentB then
        itemA.Parent = parentB
        itemB.Parent = parentA
    end
    
    manager:refresh()
    return true, "Success"
end

-- Get the target folder for a slot
function ItemUtils.GetTargetFolder(manager, slotName)
    local baseSlot = SlotMappings.GetBaseSlot(slotName)
    
    -- Check if it's a container slot (Backpack1, Pants3, etc.)
    local containerType, slotNumber = SlotMappings.ParseNumberedSlot(slotName)
    if containerType and slotNumber then
        local inventoryData = manager:getInventory(containerType)
        if inventoryData and inventoryData.Inventory then
            return inventoryData.Inventory
        end
    end
    
    -- Check equipment slots
    if SlotMappings.IsEquipmentSlot(slotName) then
        if string.find(slotName, "Gun") then
            return manager.sessionProfile:FindFirstChild("Inventory")
        end
        return manager.sessionProfile:FindFirstChild("Clothing")
    end
    
    -- Default to Inventory folder
    return manager.sessionProfile:FindFirstChild("Inventory")
end

-- ============================================================
-- STACKING SYSTEM
-- ============================================================

-- Merge stack if possible
-- Returns: boolean didMerge, amount remaining
function ItemUtils.TryMergeStacks(sourceItem, targetItem, amountToMove)
    local sourceProps = sourceItem:FindFirstChild("ItemProperties")
    local targetProps = targetItem:FindFirstChild("ItemProperties")
    
    if not sourceProps or not targetProps then
        return false, amountToMove
    end
    
    local sourceAmount = sourceProps:GetAttribute("Amount") or 1
    local targetAmount = targetProps:GetAttribute("Amount") or 1
    local maxStack = targetProps:GetAttribute("StackSize") or 1
    
    local spaceLeft = maxStack - targetAmount
    if spaceLeft <= 0 then
        return false, amountToMove
    end
    
    local canMove = math.min(amountToMove or sourceAmount, spaceLeft)
    
    -- Update amounts
    targetProps:SetAttribute("Amount", targetAmount + canMove)
    sourceProps:SetAttribute("Amount", sourceAmount - canMove)
    
    -- Destroy source if empty
    if sourceAmount - canMove <= 0 then
        sourceItem:Destroy()
    end
    
    return true, sourceAmount - canMove
end

-- Split a stack
function ItemUtils.SplitStack(manager, sourceItem, targetSlot, amount)
    local sourceProps = sourceItem:FindFirstChild("ItemProperties")
    if not sourceProps then
        return false, "No item properties"
    end
    
    local sourceAmount = sourceProps:GetAttribute("Amount") or 1
    if amount >= sourceAmount then
        return false, "Cannot split entire stack"
    end
    
    -- Reduce source amount
    sourceProps:SetAttribute("Amount", sourceAmount - amount)
    
    -- Clone the item
    local clonedItem = sourceItem:Clone()
    local clonedProps = clonedItem:FindFirstChild("ItemProperties")
    if clonedProps then
        clonedProps:SetAttribute("Amount", amount)
    end
    
    -- Position the clone
    clonedItem.Value = targetSlot
    clonedItem.Parent = ItemUtils.GetTargetFolder(manager, targetSlot)
    
    manager:refresh()
    return true, "Success"
end

-- ============================================================
-- ATTACHMENT SYSTEM
-- ============================================================

-- Attach an item to a weapon
function ItemUtils.AttachToWeapon(manager, attachmentItem, weaponItem, attachmentSlot)
    -- Validate weapon has Attachments folder
    local weaponAttachments = weaponItem:FindFirstChild("Attachments")
    if not weaponAttachments then
        weaponAttachments = Instance.new("Folder")
        weaponAttachments.Name = "Attachments"
        weaponAttachments.Parent = weaponItem
    end
    
    -- Get or create attachment type folder
    local attachFolder = weaponAttachments:FindFirstChild(attachmentSlot)
    if not attachFolder then
        attachFolder = Instance.new("Folder")
        attachFolder.Name = attachmentSlot
        attachFolder.Parent = weaponAttachments
    end
    
    -- Check if slot is empty
    if #attachFolder:GetChildren() > 0 then
        return false, "Attachment slot occupied"
    end
    
    -- Move attachment into weapon
    local oldSlot = attachmentItem.Value
    attachmentItem.Value = attachmentSlot
    attachmentItem.Parent = attachFolder
    
    manager:refresh()
    return true, "Success"
end

-- Detach an attachment from a weapon
function ItemUtils.DetachFromWeapon(manager, weaponItem, attachmentSlot, targetInventorySlot)
    local weaponAttachments = weaponItem:FindFirstChild("Attachments")
    if not weaponAttachments then
        return false, "No attachments folder"
    end
    
    local attachFolder = weaponAttachments:FindFirstChild(attachmentSlot)
    if not attachFolder then
        return false, "No attachment in slot"
    end
    
    local attachment = attachFolder:GetChildren()[1]
    if not attachment then
        return false, "No attachment found"
    end
    
    -- Check target slot is empty
    local existingItem = manager:getItem(targetInventorySlot)
    if existingItem then
        return false, "Target slot occupied"
    end
    
    -- Move to inventory
    attachment.Value = targetInventorySlot
    attachment.Parent = ItemUtils.GetTargetFolder(manager, targetInventorySlot)
    
    manager:refresh()
    return true, "Success"
end

-- ============================================================
-- EQUIPMENT HELPERS
-- ============================================================

-- Equip clothing item (handles visual updates)
function ItemUtils.EquipClothing(manager, clothingItem)
    -- This would trigger clothing appearance update
    -- For now, just mark as equipped
    print("Equipping clothing:", clothingItem.Name)
    return true
end

-- Unequip clothing item
function ItemUtils.UnequipClothing(manager, clothingItem)
    print("Unequipping clothing:", clothingItem.Name)
    return true
end

-- ============================================================
-- AMMO SYSTEM
-- ============================================================

-- Load ammo into a magazine
function ItemUtils.LoadAmmo(magazineItem, ammoItem, amount)
    local magProps = magazineItem:FindFirstChild("ItemProperties")
    local ammoProps = ammoItem:FindFirstChild("ItemProperties")
    
    if not magProps or not ammoProps then
        return false, 0
    end
    
    local currentAmmo = magProps:GetAttribute("LoadedAmmo") or 0
    local maxAmmo = magProps:GetAttribute("MaxLoadedAmmo") or 0
    local ammoAmount = ammoProps:GetAttribute("Amount") or 1
    
    local spaceLeft = maxAmmo - currentAmmo
    if spaceLeft <= 0 then
        return false, 0
    end
    
    local toLoad = math.min(amount or ammoAmount, spaceLeft)
    
    -- Update magazine
    magProps:SetAttribute("LoadedAmmo", currentAmmo + toLoad)
    
    -- Update or destroy ammo
    local newAmmoAmount = ammoAmount - toLoad
    if newAmmoAmount <= 0 then
        ammoItem:Destroy()
    else
        ammoProps:SetAttribute("Amount", newAmmoAmount)
    end
    
    return true, toLoad
end

-- Unload ammo from a magazine
function ItemUtils.UnloadAmmo(magazineItem, amount)
    local magProps = magazineItem:FindFirstChild("ItemProperties")
    if not magProps then
        return false, 0
    end
    
    local currentAmmo = magProps:GetAttribute("LoadedAmmo") or 0
    if currentAmmo <= 0 then
        return false, 0
    end
    
    local toUnload = math.min(amount or currentAmmo, currentAmmo)
    magProps:SetAttribute("LoadedAmmo", currentAmmo - toUnload)
    
    return true, toUnload
end

-- ============================================================
-- ITEM QUERIES
-- ============================================================

-- Check if an item is a container (has Inventory folder)
function ItemUtils.IsContainer(item)
    return item:FindFirstChild("Inventory") ~= nil
end

-- Check if an item is a weapon
function ItemUtils.IsWeapon(item)
    local props = item:FindFirstChild("ItemProperties")
    if not props then
        return false
    end
    return props:GetAttribute("ItemType") == "RangedWeapon"
end

-- Check if an item is an attachment
function ItemUtils.IsAttachment(item)
    local props = item:FindFirstChild("ItemProperties")
    if not props then
        return false
    end
    local itemType = props:GetAttribute("ItemType")
    return itemType == "Sight" or itemType == "Muzzle" or itemType == "Extra"
end

return ItemUtils