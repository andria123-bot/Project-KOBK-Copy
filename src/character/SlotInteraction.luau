-- -- ServerScriptService.SlotInteraction
-- local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- local HashManager = require(script.Parent.Managers.HashManager)
-- local SearhInventory = require(script.Parent.Utils.SearhInventory)

-- local function SlotInteraction(player, fromSlot, toSlot)
--     local manager = HashManager.getPlayer(player)
--     if not manager then return false end
    
--     local sourceItem = manager:getItem(fromSlot)
--     if not sourceItem then return false end
    
--     local targetItem = manager:getItem(toSlot)
    
--     -- Case 1: Same slot - do nothing
--     if fromSlot == toSlot then return false end
    
--     -- Case 2: Stack merge (same item name)
--     if sourceItem and targetItem and sourceItem.name == targetItem.name then
--         local sourceAmount = sourceItem.amount or 1
--         local targetAmount = targetItem.amount or 1
--         local maxStack = targetItem.stackSize or 99
        
--         if targetAmount < maxStack then
--             local canTake = math.min(sourceAmount, maxStack - targetAmount)
--             targetItem.amount = targetAmount + canTake
--             sourceItem.amount = sourceAmount - canTake
            
--             if sourceItem.amount <= 0 then
--                 sourceItem.item:Destroy()
--             end
--             manager:refresh()
--             return true
--         end
--     end
    
--     -- Case 3: Move to empty slot
--     if not targetItem then
--         local targetFolder = SearhInventory(player, toSlot)
--         if targetFolder then
--             sourceItem.item.Parent = targetFolder
--             sourceItem.item.ItemProperties.CurrentFrameName.Value = toSlot
--             manager:refresh()
--             return true
--         end
--         return false
--     end
    
--     -- Case 4: Swap items
--     if sourceItem and targetItem then
--         local sourceFolder = sourceItem.item.Parent
--         local targetFolder = targetItem.item.Parent
        
--         sourceItem.item.Parent = targetFolder
--         targetItem.item.Parent = sourceFolder
        
--         sourceItem.item.ItemProperties.CurrentFrameName.Value = toSlot
--         targetItem.item.ItemProperties.CurrentFrameName.Value = fromSlot
        
--         manager:refresh()
--         return true
--     end
    
--     return false
-- end

-- return SlotInteraction