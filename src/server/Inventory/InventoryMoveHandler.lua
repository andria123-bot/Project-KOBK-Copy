-- InventoryMoveHandler.server.lua
-- Main router for all inventory actions (move, swap, split, attach, detach)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder", ReplicatedStorage)
local InventoryMoveEvent = Remotes:FindFirstChild("InventoryMove") or Instance.new("RemoteEvent", Remotes)
InventoryMoveEvent.Name = "InventoryMove"

local HashManager = require(script.Parent.Core.HashManager)
local SlotMappings = require(script.Parent.Data.SlotMappings)
local SlotManager = require(script.Parent.Core.SlotManager)
local ItemUtils = require(script.Parent.Core.ItemUtils)

-- ============================================================
-- MAIN ROUTER
-- ============================================================

function RouteInteraction(player, itemId, targetSlot, paramA, paramB, paramC)
    local manager = HashManager.getPlayer(player)
    
    if not manager then
        warn("No manager found for player:", player.Name)
        return false
    end
    
    -- Determine which action to perform based on parameters
    -- paramA = split amount
    -- paramB = attachment unequip (slot to move to)
    -- paramC = attachment equip (slot type: Sight, Muzzle, Extra)
    
    if targetSlot and paramC then
        -- Attachment Equip (dragging attachment onto weapon)
        return AttachmentEquip(player, manager, itemId, targetSlot, paramC)
        
    elseif targetSlot and paramB then
        -- Attachment Unequip (removing attachment from weapon)
        return AttachmentUnequip(player, manager, itemId, targetSlot, paramB)
        
    elseif targetSlot and paramA then
        -- Split Interaction (splitting a stack)
        return SplitInteraction(player, manager, itemId, targetSlot, tonumber(paramA))
        
    elseif targetSlot then
        -- Regular Move/Swap
        return SlotInteraction(player, manager, itemId, targetSlot)
    end
    
    warn("Invalid interaction parameters")
    return false
end

-- ============================================================
-- SLOT INTERACTION (Move / Swap)
-- ============================================================

function SlotInteraction(player, manager, sourceSlot, targetSlot)
    -- Get source item
    local sourceData = manager:getItem(sourceSlot)
    if not sourceData then
        return false
    end
    
    local sourceItem = sourceData.Item
    
    -- Get target item (if any)
    local targetData = manager:getItem(targetSlot)
    local targetItem = targetData and targetData.Item
    
    -- Check if trying to stack same items
    if targetItem and sourceItem.Name == targetItem.Name then
        -- Try to merge stacks
        local didMerge, remaining = ItemUtils.TryMergeStacks(sourceItem, targetItem)
        if didMerge then
            manager:refresh()
            return true
        end
    end
    
    -- Check if target slot is empty
    if not targetItem then
        -- Move to empty slot
        local success, errorMsg = ItemUtils.MoveItem(manager, sourceItem, targetSlot)
        if success then
            manager:refresh()
            return true
        else
            warn("Move failed:", errorMsg)
            return false
        end
    end
    
    -- Both slots have items - swap them
    local success, errorMsg = ItemUtils.SwapItems(manager, sourceSlot, targetSlot)
    if success then
        manager:refresh()
        return true
    else
        warn("Swap failed:", errorMsg)
        return false
    end
end

-- ============================================================
-- SPLIT INTERACTION
-- ============================================================

function SplitInteraction(player, manager, sourceSlot, targetSlot, amount)
    if not amount or amount <= 0 then
        return false
    end
    
    local sourceData = manager:getItem(sourceSlot)
    if not sourceData then
        return false
    end
    
    local sourceItem = sourceData.Item
    local sourceProps = sourceItem:FindFirstChild("ItemProperties")
    
    if not sourceProps then
        return false
    end
    
    local currentAmount = sourceProps:GetAttribute("Amount") or 1
    if amount >= currentAmount then
        return false
    end
    
    -- Check if target slot exists and is compatible
    local targetData = manager:getItem(targetSlot)
    
    if targetData then
        -- Target has item - try to merge
        local targetItem = targetData.Item
        if targetItem.Name == sourceItem.Name then
            local didMerge, remaining = ItemUtils.TryMergeStacks(sourceItem, targetItem, amount)
            if didMerge then
                manager:refresh()
                return true
            end
        end
        return false
    end
    
    -- Target empty - split stack
    local success, errorMsg = ItemUtils.SplitStack(manager, sourceItem, targetSlot, amount)
    if success then
        manager:refresh()
        return true
    end
    
    return false
end

-- ============================================================
-- ATTACHMENT EQUIP
-- ============================================================

function AttachmentEquip(player, manager, attachmentSlot, weaponSlot, attachType)
    -- Get attachment
    local attachmentData = manager:getItem(attachmentSlot)
    if not attachmentData then
        return false
    end
    
    local attachment = attachmentData.Item
    
    -- Validate attachment type
    if not ItemUtils.IsAttachment(attachment) then
        return false
    end
    
    -- Get weapon
    local weaponData = manager:getItem(weaponSlot)
    if not weaponData then
        return false
    end
    
    local weapon = weaponData.Item
    
    -- Validate weapon
    if not ItemUtils.IsWeapon(weapon) then
        return false
    end
    
    -- Attach to weapon
    local success, errorMsg = ItemUtils.AttachToWeapon(manager, attachment, weapon, attachType)
    if success then
        manager:refresh()
        return true
    end
    
    return false
end

-- ============================================================
-- ATTACHMENT UNEQUIP
-- ============================================================

function AttachmentUnequip(player, manager, weaponSlot, targetSlot, attachType)
    -- Get weapon
    local weaponData = manager:getItem(weaponSlot)
    if not weaponData then
        return false
    end
    
    local weapon = weaponData.Item
    
    -- Validate weapon
    if not ItemUtils.IsWeapon(weapon) then
        return false
    end
    
    -- Check target slot is empty
    local targetData = manager:getItem(targetSlot)
    if targetData then
        return false
    end
    
    -- Detach from weapon
    local success, errorMsg = ItemUtils.DetachFromWeapon(manager, weapon, attachType, targetSlot)
    if success then
        manager:refresh()
        return true
    end
    
    return false
end

-- ============================================================
-- CONNECTION
-- ============================================================

InventoryMoveEvent.OnServerEvent:Connect(function(player, itemId, targetSlot, paramA, paramB, paramC)
    local success = RouteInteraction(player, itemId, targetSlot, paramA, paramB, paramC)
    
    -- Optionally send result back to client
    if not success then
        -- Could fire a failure event back to client
        print("Inventory move failed for:", player.Name)
    end
end)

game.Players.PlayerAdded:Connect(function(player)
    local manager = HashManager.getPlayer(player)  -- This creates the folder structure
end)

return {
    RouteInteraction = RouteInteraction,
    SlotInteraction = SlotInteraction,
    SplitInteraction = SplitInteraction,
    AttachmentEquip = AttachmentEquip,
    AttachmentUnequip = AttachmentUnequip,
}