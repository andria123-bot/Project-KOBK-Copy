-- local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
-- local InventoryService = Knit.CreateService({
--     Name = "InventoryService",
--     Client = {
--         MoveItem = Knit.CreateRemote(),
--         DropItem = Knit.CreateRemote(),
--         PickupItem = Knit.CreateRemote(),
--     },
-- })

-- local HashManager = require(script.Parent.Parent.Inventory.Core.HashManager)
-- local SlotManager = require(script.Parent.Parent.Inventory.Core.SlotManager)
-- local ItemUtils = require(script.Parent.Parent.Inventory.Core.ItemUtils)
-- local DropItem = require(script.Parent.Parent.Inventory.Actions.DropItem)
-- local TakeItem = require(script.Parent.Parent.Inventory.Actions.TakeItem)
-- local InventoryMoveHandler = require(script.Parent.Parent.Inventory.InventoryMoveHandler) -- Add this

-- function InventoryService.Client:MoveItem(player, fromSlot, toSlot)
--     local manager = HashManager.getPlayer(player)
--     if not manager then return false end
    
--     -- Use the existing SlotInteraction from InventoryMoveHandler
--     return InventoryMoveHandler.SlotInteraction(player, manager, fromSlot, toSlot)
-- end

-- function InventoryService.Client:DropItem(player, slotName)
--     return DropItem.DropItem(player, slotName)
-- end

-- function InventoryService.Client:PickupItem(player)
--     -- Get the player's character position
--     local character = player.Character
--     if not character then return false end
    
--     local rootPart = character:FindFirstChild("HumanoidRootPart")
--     if not rootPart then return false end
    
--     local playerPos = rootPart.Position
    
--     -- Find all dropped items
--     local droppedFolder = workspace:FindFirstChild("DroppedItems")
--     if not droppedFolder then return false end
    
--     local closestItem = nil
--     local closestDist = 10 -- Max pickup distance (studs)
    
--     for _, item in pairs(droppedFolder:GetChildren()) do
--         -- Get the item's primary part or first part
--         local primaryPart = item:FindFirstChildWhichIsA("BasePart")
--         if primaryPart then
--             local dist = (primaryPart.Position - playerPos).Magnitude
--             if dist < closestDist then
--                 closestDist = dist
--                 closestItem = item
--             end
--         end
--     end
    
--     if closestItem then
--         return TakeItem.TakeLoot(player, closestItem)
--     end
    
--     return false
-- end

-- return InventoryService