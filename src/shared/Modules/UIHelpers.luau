-- ReplicatedStorage.Modules.UIHelpers
local UIHelpers = {}

-- Get mouse position adjusted for GUI inset
function UIHelpers.getMousePosition()
    local UserInputService = game:GetService("UserInputService")
    local GuiService = game:GetService("GuiService")
    local mousePos = UserInputService:GetMouseLocation()
    local guiInset = GuiService:GetGuiInset()
    return Vector2.new(mousePos.X, mousePos.Y - guiInset.Y)
end

-- Check if mouse is over a frame
function UIHelpers.isMouseOverFrame(frame, adjustedMousePos)
    if not frame then return false end
    local pos = frame.AbsolutePosition
    local size = frame.AbsoluteSize
    return adjustedMousePos.X >= pos.X and adjustedMousePos.X <= pos.X + size.X and
           adjustedMousePos.Y >= pos.Y and adjustedMousePos.Y <= pos.Y + size.Y
end

-- Create a drag clone
function UIHelpers.createDragClone(original, parent, mousePos)
    local clone = original:Clone()
    clone.Parent = parent
    clone.ZIndex = 999
    clone.AnchorPoint = Vector2.new(0.5, 0.5)
    clone.Size = UDim2.fromOffset(original.AbsoluteSize.X, original.AbsoluteSize.Y)
    
    local parentPos = parent.AbsolutePosition
    clone.Position = UDim2.fromOffset(
        mousePos.X - parentPos.X,
        mousePos.Y - parentPos.Y
    )
    return clone
end

-- Calculate slot ranges based on equipped clothing
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

-- Get absolute slot number from clothing type and relative slot
function UIHelpers.getAbsoluteSlotNumber(ranges, clothingType, relativeSlot)
    if ranges[clothingType] then
        return ranges[clothingType].start + relativeSlot - 1
    end
    return nil
end

-- Get clothing type from slot number
function UIHelpers.getClothingTypeFromSlot(ranges, absoluteSlot)
    for clothingType, range in pairs(ranges) do
        if absoluteSlot >= range.start and absoluteSlot < range.start + range.count then
            return clothingType, absoluteSlot - range.start + 1
        end
    end
    return nil, nil
end

-- Load item icon from ItemProperties
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

-- Cache item icon
function UIHelpers.cacheItemIcon(itemName, iconId, cache)
    cache[itemName] = iconId
end

-- Get cached icon
function UIHelpers.getCachedIcon(itemName, cache)
    return cache[itemName]
end

return UIHelpers