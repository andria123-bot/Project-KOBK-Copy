local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local InventoryService = Knit.CreateService({
    Name = "InventoryService",
    Client = {
        MoveItem = Knit.CreateSignal(),
        DropItem = Knit.CreateSignal(),
        PickupItem = Knit.CreateSignal(),
    },
})

local HashManager = require(script.Parent.Parent.Inventory.Core.HashManager)
local SlotManager = require(script.Parent.Parent.Inventory.Core.SlotManager)
local ItemUtils = require(script.Parent.Parent.Inventory.Core.ItemUtils)
local DropItem = require(script.Parent.Parent.Inventory.Actions.DropItem)
local TakeItem = require(script.Parent.Parent.Inventory.Actions.TakeItem)
local InventoryMoveHandler = require(script.Parent.Parent.Inventory.InventoryMoveHandler)
local SlotMappings = require(script.Parent.Parent.Inventory.Data.SlotMappings)

function InventoryService:MoveItem(player, fromSlot, toSlot)
    local manager = HashManager.getPlayer(player)
    if not manager then return false end
    
    local fromData = SlotMappings.GetClothingFromUISlot(fromSlot)
    local toData = SlotMappings.GetClothingFromUISlot(toSlot)
    
    if not fromData or not toData then
        return false
    end
    
    local clothingFolder = manager.sessionProfile:FindFirstChild("Clothing")
    if not clothingFolder then return false end
    
    local fromClothing = clothingFolder:FindFirstChild(fromData.clothingName)
    local toClothing = clothingFolder:FindFirstChild(toData.clothingName)
    
    if not fromClothing or not toClothing then return false end

    local fromInv = fromClothing:FindFirstChild("Inventory")
    local toInv = toClothing:FindFirstChild("Inventory")
    
    if not fromInv or not toInv then return false end
    
    local sourceItem = nil
    for _, item in pairs(fromInv:GetChildren()) do
        if item:IsA("StringValue") then
            local itemSlotNum = tonumber(item.Value:match("%d+"))
            if itemSlotNum == fromData.localSlot then
                sourceItem = item
                break
            end
        end
    end
    
    if not sourceItem then return false end
    
    local targetItem = nil
    for _, item in pairs(toInv:GetChildren()) do
        if item:IsA("StringValue") then
            local itemSlotNum = tonumber(item.Value:match("%d+"))
            if itemSlotNum == toData.localSlot then
                targetItem = item
                break
            end
        end
    end
    
    if targetItem then
        local newSourceValue = fromData.slotType .. fromData.localSlot
        targetItem.Value = newSourceValue
        targetItem.Parent = fromInv
    end
    
    local newValue = toData.slotType .. toData.localSlot
    sourceItem.Value = newValue
    sourceItem.Parent = toInv
    
    return true
end

function InventoryService:GetClothingAndSlotFromSlotName(manager, slotName)
    local slotNum = tonumber(slotName:match("%d+"))
    if not slotNum then return nil, nil end
    
    local rowsParent = nil -- You'll need to pass this or find it
    local clothingItems = {}
    local clothingFolder = manager.sessionProfile:FindFirstChild("Clothing")
    if not clothingFolder then return nil, nil end
    
    local priority = {"Armor", "TShirt", "Pants"}
    local clothingOrder = {}
    for _, p in pairs(priority) do
        for _, item in pairs(clothingFolder:GetChildren()) do
            if item:IsA("StringValue") and item.Value == p then
                table.insert(clothingOrder, item)
                break
            end
        end
    end
    
    local currentSlot = 1
    for _, clothing in pairs(clothingOrder) do
        local slotCount = self:GetClothingSlotCount(clothing.Name)
        if slotNum >= currentSlot and slotNum < currentSlot + slotCount then
            local slotIndex = slotNum - currentSlot + 1
            return clothing, slotIndex
        end
        currentSlot = currentSlot + slotCount
    end
    
    return nil, nil
end

function InventoryService:GetClothingSlotCount(clothingName)
    local RequestModule = game:GetService("ReplicatedStorage").Shared.Remotes.Requests.RequestModule
    local success, module = pcall(function()
        return RequestModule:InvokeServer(clothingName)
    end)
    if success and module and module.slotCount then
        return module.slotCount
    end
    return 5
end

function InventoryService:DropItem(player, slotName)
    return DropItem.DropItem(player, slotName)
end

function InventoryService:PickupItem(player)
    
    local character = player.Character
    if not character then return false end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return false end
    
    local playerPos = rootPart.Position
    local droppedFolder = workspace:FindFirstChild("DroppedItems")
    if not droppedFolder then return false end
    
    local closestItem = nil
    local closestDist = 10
    
    for _, item in pairs(droppedFolder:GetChildren()) do
        local primaryPart = item:FindFirstChildWhichIsA("BasePart")
        if primaryPart then
            local dist = (primaryPart.Position - playerPos).Magnitude
            if dist < closestDist then
                closestDist = dist
                closestItem = item
            end
        end
    end
    
    if closestItem then
        return TakeItem.TakeLoot(player, closestItem)
    end
    
    return false
end

function InventoryService.Client:MoveItem(player, fromSlot, toSlot)
    return InventoryService:MoveItem(player, fromSlot, toSlot)
end

function InventoryService.Client:DropItem(player, slotName)
    return InventoryService:DropItem(player, slotName)
end

function InventoryService.Client:PickupItem(player)
    return InventoryService:PickupItem(player)
end

return InventoryService