local UIHelpers = {}

local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local gearPlaceholders = {}

function UIHelpers.getMousePosition()
    local mousePos = UserInputService:GetMouseLocation()
    local guiInset = GuiService:GetGuiInset()
    return Vector2.new(mousePos.X, mousePos.Y - guiInset.Y)
end

function UIHelpers.isMouseOverFrame(frame, mousePos)
    if not frame then return false end
    local pos = frame.AbsolutePosition
    local size = frame.AbsoluteSize
    return mousePos.X >= pos.X and mousePos.X <= pos.X + size.X
        and mousePos.Y >= pos.Y and mousePos.Y <= pos.Y + size.Y
end

function UIHelpers.getSlotRanges(clothingFolder, clothingOrder)
    local ranges = {}
    local currentSlot = 1

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

    return ranges, currentSlot - 1
end

function UIHelpers.getAbsoluteSlotNumber(ranges, clothingType, relativeSlot)
    local range = ranges[clothingType]
    if range then
        return range.start + relativeSlot - 1
    end
    return nil
end

function UIHelpers.getClothingTypeFromSlot(ranges, absoluteSlot)
    for clothingType, range in pairs(ranges) do
        if absoluteSlot >= range.start and absoluteSlot < range.start + range.count then
            return clothingType, absoluteSlot - range.start + 1
        end
    end
    return nil, nil
end

function UIHelpers.getItemIconFromProperties(item)
    local props = item:FindFirstChild("ItemProperties")
    if props then
        local icon = props:FindFirstChild("IconImage")
        if icon and icon.Value ~= "" then
            return icon.Value
        end
    end
    return nil
end

function UIHelpers.cacheGearPlaceholders(slots)
    gearPlaceholders = {}
    for _, slotInfo in pairs(slots.All) do
        if slotInfo.type ~= "inventory" and slotInfo.slotName then
            local frame = slotInfo.frame
            local itemIcon = frame and frame:FindFirstChild("ItemIcon")
            if itemIcon and itemIcon.Image ~= "" then
                gearPlaceholders[slotInfo.slotName] = itemIcon.Image
            end
        end
    end
    return gearPlaceholders
end

function UIHelpers.getStoredGearImage(slotName)
    return gearPlaceholders[slotName]
end

function UIHelpers.cacheItemIcon(itemName, iconId, cache)
    if itemName and iconId then
        cache[itemName] = iconId
    end
end

function UIHelpers.getCachedIcon(itemName, cache)
    return cache[itemName]
end

return UIHelpers