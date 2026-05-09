local Knit = require(game:GetService("ReplicatedStorage").Packages:WaitForChild("Knit"))
local InventoryController = Knit.CreateController({
    Name = "InventoryController",
})

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local StarterPlayer = game:GetService("StarterPlayer")
local InventoryFunctions = require(StarterPlayer.StarterPlayerScripts.Client.Inventory.InventoryFunctions)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local InventoryService

local InventoryUIController = require(script.Parent.Parent.Inventory:WaitForChild("InventoryUIController"))

local slots = InventoryUIController.slots
print(slots)

local Menu = playerGui:WaitForChild("Menu")
local MainParent = Menu.MainParent
local InventoryParent = MainParent:WaitForChild("InventoryParent")

local playerInventoryData = {}
local itemImageCache = {}
local isMoveInProgress = false
local isMoving = false

local dragging = {
    active = false,
    fromSlot = nil,
    clone = nil,
}

local function getMousePos()
    local mousePos = UserInputService:GetMouseLocation()
    local guiInset = GuiService:GetGuiInset()
    return Vector2.new(mousePos.X, mousePos.Y - guiInset.Y)
end

local function createDragClone(original, slotFrame)
    local clone = original:Clone()
    clone.Parent = MainParent
    clone.ZIndex = 10
    clone.AnchorPoint = Vector2.new(0.5, 0)
    clone.Size = UDim2.new(0, original.AbsoluteSize.X, 0, original.AbsoluteSize.Y)

    local slotPos = slotFrame.AbsolutePosition
    local slotSize = slotFrame.AbsoluteSize
    local mainParentPos = MainParent.AbsolutePosition

    clone.Position = UDim2.new(0,
        slotPos.X + slotSize.X / 2 - mainParentPos.X,
        0,
        slotPos.Y + slotSize.Y / 2 - mainParentPos.Y
    )
    return clone
end

local function getSlotUnderMouse()
    local mousePos = UserInputService:GetMouseLocation()
    local guiInset = GuiService:GetGuiInset()
    local adjustedMousePos = Vector2.new(mousePos.X, mousePos.Y - guiInset.Y)

    -- Check inventory slots
    for index, slot in pairs(slots.Inventory) do
        if slot then
            local slotPos = slot.AbsolutePosition
            local slotSize = slot.AbsoluteSize
            if adjustedMousePos.X >= slotPos.X
                and adjustedMousePos.X <= slotPos.X + slotSize.X
                and adjustedMousePos.Y >= slotPos.Y
                and adjustedMousePos.Y <= slotPos.Y + slotSize.Y
            then
                return index, slot, "inventory"
            end
        end
    end
    
    -- Check weapon slots
    for slotName, slotFrame in pairs(slots.WeaponSlots) do
        if slotFrame and slotFrame:IsA("Frame") then
            local slotPos = slotFrame.AbsolutePosition
            local slotSize = slotFrame.AbsoluteSize
            if adjustedMousePos.X >= slotPos.X
                and adjustedMousePos.X <= slotPos.X + slotSize.X
                and adjustedMousePos.Y >= slotPos.Y
                and adjustedMousePos.Y <= slotPos.Y + slotSize.Y
            then
                return slotName, slotFrame, "weapon"
            end
        end
    end
    
    -- Check gear slots
    for slotName, slotFrame in pairs(slots.Gear) do
        if slotFrame and slotFrame:IsA("Frame") then
            local slotPos = slotFrame.AbsolutePosition
            local slotSize = slotFrame.AbsoluteSize
            if adjustedMousePos.X >= slotPos.X
                and adjustedMousePos.X <= slotPos.X + slotSize.X
                and adjustedMousePos.Y >= slotPos.Y
                and adjustedMousePos.Y <= slotPos.Y + slotSize.Y
            then
                return slotName, slotFrame, "gear"
            end
        end
    end
    
    -- -- Check utils slots
    -- for slotName, slotFrame in pairs(slots.Utils) do -- first 3 slot shoul be not be availabe from equiping directly
    --     if slotFrame and slotFrame:IsA("Frame") then
    --         local slotPos = slotFrame.AbsolutePosition
    --         local slotSize = slotFrame.AbsoluteSize
    --         if adjustedMousePos.X >= slotPos.X
    --             and adjustedMousePos.X <= slotPos.X + slotSize.X
    --             and adjustedMousePos.Y >= slotPos.Y
    --             and adjustedMousePos.Y <= slotPos.Y + slotSize.Y
    --         then
    --             return slotName, slotFrame, "utils"
    --         end
    --     end
    -- end
    
    return nil, nil, nil
end

local function updateSlot(index)
    if not index then return end
    local slot = slots.Inventory[index]
    if not slot then return end
    local itemIcon = slot:FindFirstChild("ItemIcon")
    if not itemIcon then return end

    itemIcon.Visible = true

    local itemName = playerInventoryData[index]
    if itemName and itemName ~= "" then
        if itemImageCache[itemName] then
            itemIcon.Image = itemImageCache[itemName]
            return
        end
        if not itemImageCache[itemName .. "_loading"] then
            itemImageCache[itemName .. "_loading"] = true
            task.spawn(function()
                local RequestModule = ReplicatedStorage.Shared.Remotes.Requests:WaitForChild("RequestModule")
                local success, mod = pcall(function()
                    return RequestModule:InvokeServer(itemName)
                end)
                if success and mod and mod.imageIconId then
                    itemImageCache[itemName] = mod.imageIconId
                    local currentSlot = slots.Inventory[index]
                    if currentSlot then
                        local currentIcon = currentSlot:FindFirstChild("ItemIcon")
                        if currentIcon and playerInventoryData[index] == itemName then
                            currentIcon.Image = mod.imageIconId
                        end
                    end
                end
                itemImageCache[itemName .. "_loading"] = nil
            end)
        end
    else
        itemIcon.Image = ""
    end
end

local function RenderItems(slotCount)
    for i = 1, slotCount do
        updateSlot(i)
    end
end

local function applyInventory(inventory)
    if not inventory or not inventory.PlayerInventory then
        warn("applyInventory: invalid inventory data")
        return
    end

    for i = 1, inventory.SlotCount do
        playerInventoryData[i] = inventory.PlayerInventory[i] or ""
    end

    print("Applying", inventory)
    InventoryUIController:ApplyInventoryData(inventory)
    RenderItems(inventory.SlotCount)
end

local function SlotHandler()
    for index, slotFrame in pairs(slots.Inventory) do
        local itemIcon = slotFrame:FindFirstChild("ItemIcon")
        if itemIcon and not itemIcon:GetAttribute("DragHandlerAttached") then
            itemIcon:SetAttribute("DragHandlerAttached", true)
            itemIcon.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    if isMoving or isMoveInProgress then return end
                    if playerInventoryData[index] and playerInventoryData[index] ~= "" then
                        isMoving = true
                        dragging.fromSlot = index
                        dragging.active = true
                        dragging.clone = createDragClone(itemIcon, slotFrame)
                        itemIcon.Visible = false
                    end
                end
            end)
        end
    end
end

local function setupInventoryListener()
    InventoryService.InventoryUpdated:Connect(function(data)
        if not data or not data.PlayerInventory then return end

        for i = 1, data.SlotCount do
            playerInventoryData[i] = data.PlayerInventory[i] or ""
        end

        for i = 1, data.SlotCount do
            if i ~= dragging.fromSlot then
                updateSlot(i)
            end
        end
    end)
end

-- Add this function to update equipment slots visually
local function updateEquipmentSlot(slotName, itemName)
    local slotFrame = slots.WeaponSlots[slotName] or slots.Gear[slotName] or slots.Utils[slotName]
    if not slotFrame then return end
    
    local itemIcon = slotFrame:FindFirstChild("ItemIcon")
    if not itemIcon then return end
    
    if itemName and itemName ~= "" then
        if itemImageCache[itemName] then
            itemIcon.Image = itemImageCache[itemName]
        else
            -- Load image asynchronously
            task.spawn(function()
                local RequestModule = ReplicatedStorage.Shared.Remotes.Requests:WaitForChild("RequestModule")
                local success, mod = pcall(function()
                    return RequestModule:InvokeServer(itemName)
                end)
                if success and mod and mod.imageIconId then
                    itemImageCache[itemName] = mod.imageIconId
                    if itemIcon and itemIcon.Parent then
                        itemIcon.Image = mod.imageIconId
                    end
                end
            end)
        end
        itemIcon.Visible = true
    else
        itemIcon.Image = ""
        itemIcon.Visible = true
    end
end

-- Then in equipItem, update both the source slot AND the equipment slot:
local function equipItem(fromSlot, toSlot, slotFrame, slotType)
    local fromItem = playerInventoryData[fromSlot]
    if not fromItem or fromItem == "" then return end
    if slotType == "inventory" then return end

    local oldItem = playerInventoryData[toSlot] or ""
    
    -- Update local data
    playerInventoryData[fromSlot] = ""
    playerInventoryData[toSlot] = fromItem
    
    -- Update UI
    updateSlot(fromSlot)                    -- Clear source slot
    updateEquipmentSlot(toSlot, fromItem)   -- Show item in equipment slot
    
    -- Send to server
    InventoryService.EquipItem(player, fromSlot, toSlot, fromItem, slotType):andThen(function(success, message)
        if not success then
            -- Revert on failure
            playerInventoryData[fromSlot] = fromItem
            playerInventoryData[toSlot] = oldItem
            updateSlot(fromSlot)
            updateEquipmentSlot(toSlot, oldItem)
            warn("Equip failed:", message)
        else
            print("Equipped", fromItem, "to", toSlot)
        end
    end):catch(function(err)
        warn("Equip error:", err)
        playerInventoryData[fromSlot] = fromItem
        playerInventoryData[toSlot] = oldItem
        updateSlot(fromSlot)
        updateEquipmentSlot(toSlot, oldItem)
    end)
end
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and dragging.active then
        if not dragging.fromSlot then
            dragging.active = false
            isMoving = false
            return
        end

        local toSlot, slotFrame, slotType = getSlotUnderMouse()
        equipItem(dragging.fromSlot, toSlot, slotFrame, slotType)

        if dragging.clone then
            dragging.clone:Destroy()
            dragging.clone = nil
        end

        local fromSlot = dragging.fromSlot

        local originalSlot = slots.Inventory[fromSlot]
        if originalSlot then
            local originalIcon = originalSlot:FindFirstChild("ItemIcon")
            if originalIcon then
                originalIcon.Visible = true
            end
        end

        isMoving = false
        dragging.active = false
        dragging.fromSlot = nil

        if toSlot and toSlot ~= fromSlot then
            local fromItem = playerInventoryData[fromSlot]
            local toItem = playerInventoryData[toSlot]

            playerInventoryData[toSlot] = fromItem
            playerInventoryData[fromSlot] = toItem or ""
            updateSlot(fromSlot)
            updateSlot(toSlot)

            isMoveInProgress = true

            InventoryService:MoveItem(fromSlot, toSlot):andThen(function(success)
                if not success then
                    playerInventoryData[fromSlot] = fromItem
                    playerInventoryData[toSlot] = toItem
                    updateSlot(fromSlot)
                    updateSlot(toSlot)
                end
                isMoveInProgress = false
            end):catch(function(err)
                warn("Move error:", err)
                playerInventoryData[fromSlot] = fromItem
                playerInventoryData[toSlot] = toItem
                updateSlot(fromSlot)
                updateSlot(toSlot)
                isMoveInProgress = false
            end)
        end
    end

    if input.KeyCode == Enum.KeyCode.X then
        if not dragging.active then
            local slot = getSlotUnderMouse()
            if slot and playerInventoryData[slot] ~= "" then
                local oldItem = playerInventoryData[slot]
                playerInventoryData[slot] = ""
                updateSlot(slot)

                InventoryService:DropItem(slot):andThen(function(success)
                    if not success then
                        playerInventoryData[slot] = oldItem
                        updateSlot(slot)
                    end
                end):catch(function(err)
                    warn("Failed to drop item:", err)
                    playerInventoryData[slot] = oldItem
                    updateSlot(slot)
                end)
            end
        end
    end

    if input.KeyCode == Enum.KeyCode.E then
        InventoryFunctions.PickupItem()
    end
end)

RunService.RenderStepped:Connect(function()
    if dragging.active and dragging.clone then
        local mousePos = getMousePos()
        local parentPos = InventoryParent.AbsolutePosition
        local localPos = mousePos - parentPos
        dragging.clone.Position = UDim2.new(0, localPos.X, 0, localPos.Y)
    end
end)

function InventoryController:KnitStart()
    print("InventoryController KnitStart")

    InventoryService = Knit.GetService("InventoryService")
    if not InventoryService then
        warn("InventoryService is nil!")
        return
    end

    setupInventoryListener()

    InventoryService:GetInventory():andThen(function(inventory)
        print("Initial inventory received, SlotCount:", inventory)
        applyInventory(inventory)
        SlotHandler()
    end):catch(function(err)
        warn("Failed to get inventory:", err)
    end)
end

function InventoryController:KnitInit() end

return InventoryController