-- ServerScriptService.InventoryMoveHandler
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local InventoryMove = ReplicatedStorage.InventoryMove
local InventoryUpdated = ReplicatedStorage.InventoryUpdated

local function getSlotRanges(player)
    local playerFolder = ReplicatedStorage.Players:FindFirstChild(player.Name)
    if not playerFolder then return {} end
    
    local ranges = {}
    local currentSlot = 1
    local clothingOrder = {"Armor", "TShirt", "Pants", "Backpack"}
    
    local clothingFolder = playerFolder:FindFirstChild("Clothing")
    if clothingFolder then
        for _, clothingType in ipairs(clothingOrder) do
            for _, clothingItem in pairs(clothingFolder:GetChildren()) do
                if clothingItem:IsA("StringValue") and clothingItem.Value == clothingType then
                    ranges[clothingType] = { start = currentSlot, count = 5 }
                    currentSlot = currentSlot + 5
                    break
                end
            end
        end
    end
    
    return ranges
end

local function findItemInSlot(player, slotId)
    local playerFolder = ReplicatedStorage.Players:FindFirstChild(player.Name)
    if not playerFolder then return nil, nil end
    
    local slotRanges = getSlotRanges(player)
    
    -- Find which clothing this slot belongs to
    local targetClothingType = nil
    for clothingType, range in pairs(slotRanges) do
        if slotId >= range.start and slotId < range.start + range.count then
            targetClothingType = clothingType
            break
        end
    end
    
    if not targetClothingType then return nil, nil end
    
    local clothingFolder = playerFolder:FindFirstChild("Clothing")
    if clothingFolder then
        for _, clothingItem in pairs(clothingFolder:GetChildren()) do
            if clothingItem:IsA("StringValue") and clothingItem.Value == targetClothingType then
                local invFolder = clothingItem:FindFirstChild("Inventory")
                if invFolder then
                    local range = slotRanges[targetClothingType]
                    local relativeSlot = slotId - range.start + 1
                    local targetSlotName = "Slot" .. tostring(relativeSlot)
                    
                    for _, item in pairs(invFolder:GetChildren()) do
                        if item:IsA("StringValue") and item.Value == targetSlotName then
                            return item, clothingItem
                        end
                    end
                end
            end
        end
    end
    
    return nil, nil
end

local function findTargetFolder(player, targetSlot, sourceItem)
    local playerFolder = ReplicatedStorage.Players:FindFirstChild(player.Name)
    if not playerFolder then return nil, nil, nil end
    
    local slotRanges = getSlotRanges(player)
    
    -- Find which clothing this slot belongs to
    local targetClothingType = nil
    for clothingType, range in pairs(slotRanges) do
        if targetSlot >= range.start and targetSlot < range.start + range.count then
            targetClothingType = clothingType
            break
        end
    end
    
    if not targetClothingType then return nil, nil, nil end
    
    local clothingFolder = playerFolder:FindFirstChild("Clothing")
    if clothingFolder then
        for _, clothingItem in pairs(clothingFolder:GetChildren()) do
            if clothingItem:IsA("StringValue") and clothingItem.Value == targetClothingType then
                local invFolder = clothingItem:FindFirstChild("Inventory")
                if invFolder then
                    local range = slotRanges[targetClothingType]
                    local relativeSlot = targetSlot - range.start + 1
                    local targetSlotName = "Slot" .. tostring(relativeSlot)
                    
                    -- Check if slot is occupied
                    for _, item in pairs(invFolder:GetChildren()) do
                        if item:IsA("StringValue") and item.Value == targetSlotName then
                            return invFolder, clothingItem, item
                        end
                    end
                    
                    return invFolder, clothingItem, nil
                end
            end
        end
    end
    
    return nil, nil, nil
end

InventoryMove.OnServerEvent:Connect(function(player, fromSlot, toSlot)
    local sourceItem, sourceClothing = findItemInSlot(player, fromSlot)
    if not sourceItem then return end
    
    local targetFolder, targetClothing, existingItem = findTargetFolder(player, toSlot, sourceItem)
    if not targetFolder then return end
    
    if existingItem then
        -- Swap items
        local tempValue = sourceItem.Value
        local tempName = sourceItem.Name
        
        sourceItem.Value = existingItem.Value
        sourceItem.Name = existingItem.Name
        
        existingItem.Value = tempValue
        existingItem.Name = tempName
    else
        -- Move to empty slot
        local slotRanges = getSlotRanges(player)
        local targetClothingType = nil
        for clothingType, range in pairs(slotRanges) do
            if toSlot >= range.start and toSlot < range.start + range.count then
                targetClothingType = clothingType
                break
            end
        end
        
        if targetClothingType then
            local range = slotRanges[targetClothingType]
            local relativeSlot = toSlot - range.start + 1
            sourceItem.Value = "Slot" .. tostring(relativeSlot)
            
            if targetFolder ~= sourceItem.Parent then
                sourceItem.Parent = targetFolder
            end
        end
    end
    
    InventoryUpdated:FireClient(player)
end)