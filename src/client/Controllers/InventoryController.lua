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

local slots = InventoryUIController.slots -- THIS IS NIL

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
    clone.Size = UDim2.new(0, 80, 0, 80)
    clone.BackgroundTransparency = 1
    clone.BorderSizePixel = 1

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

    local function isHit(frame)
        if not frame then return false end
        local pos = frame.AbsolutePosition
        local size = frame.AbsoluteSize
        return adjustedMousePos.X >= pos.X and adjustedMousePos.X <= pos.X + size.X
            and adjustedMousePos.Y >= pos.Y and adjustedMousePos.Y <= pos.Y + size.Y
    end

    -- Check all slots in order (inventory + equipment)
    for slotId, slotInfo in pairs(slots.All) do
        if slotInfo and slotInfo.frame and isHit(slotInfo.frame) then
            return slotId, slotInfo.type, slotInfo.frame
        end
    end

    return nil, nil, nil
end

local SLOT_MAPPINGS = {
    [16] = {"rbxassetid://116460202128729"},
    [17] = {"rbxassetid://116460202128729"},
    [18] = {"rbxassetid://116460202128729"},

    [19] = {"rbxassetid://131689103359132"},
    [20] = {"rbxassetid://138566981597980"},
    [21] = {"rbxassetid://76798103842404"},
    [22] = {"rbxassetid://116460202128729"},

    [23] = {"rbxassetid://140060749395813"},
    [24] = {"rbxassetid://106536134525419"},
    [25] = {"rbxassetid://127049093744923"},
    [26] = {"rbxassetid://72916872741117"},
}

local function updateSlot(slotId)
    local slotInfo = slots.All[slotId]
    if not slotInfo or not slotInfo.frame then return end

    local itemIcon = slotInfo.frame:FindFirstChild("ItemIcon")
    if not itemIcon then return end

    itemIcon.Visible = true
    local itemName = playerInventoryData[slotId]

    if itemName and itemName ~= "" then
        if itemImageCache[itemName] then
            itemIcon.Image = itemImageCache[itemName]
        else
            if not itemImageCache[itemName .. "_loading"] then
                itemImageCache[itemName .. "_loading"] = true
                task.spawn(function()
                    local RequestModule = ReplicatedStorage.Shared.Remotes.Requests:WaitForChild("RequestModule")
                    local success, mod = pcall(function()
                        return RequestModule:InvokeServer(itemName)
                    end)

                    print(slotId, success )
                    if success and mod and mod.imageIconId then
                        itemImageCache[itemName] = mod.imageIconId
                        local currentSlotInfo = slots.All[slotId]
                        if currentSlotInfo and currentSlotInfo.frame then
                            local currentIcon = currentSlotInfo.frame:FindFirstChild("ItemIcon")
                            if currentIcon and playerInventoryData[slotId] == itemName then
                                currentIcon.Image = mod.imageIconId
                            end
                        end
                    end
                    itemImageCache[itemName .. "_loading"] = nil
                end)
            end
        end
    else
        if slotId >= 16 then
            local mapping = SLOT_MAPPINGS[slotId]
            if mapping then
                itemIcon.Image = mapping[1]
            else
                itemIcon.Image = ""
            end
        else
            -- Empty inventory slot: clear the image
            itemIcon.Image = ""
        end
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

    for slotId, slotInfo in pairs(slots.All) do
        if slotInfo and slotInfo.type ~= "inventory" then
            local slotFrame = slotInfo.frame
            local itemIcon = slotFrame:FindFirstChild("ItemIcon")
            if itemIcon and not itemIcon:GetAttribute("DragHandlerAttached") then
                itemIcon:SetAttribute("DragHandlerAttached", true)
                itemIcon.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        if isMoving or isMoveInProgress then return end
                        if playerInventoryData[slotId] and playerInventoryData[slotId] ~= "" then
                            isMoving = true
                            dragging.fromSlot = slotId
                            dragging.active = true
                            dragging.clone = createDragClone(itemIcon, slotFrame)
                            itemIcon.Visible = false
                        end
                    end
                end)
            end
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

-- Helper: get the ItemIcon for any slot id, whether inventory or equipment
local function getIconForSlot(id)
    local invSlot = slots.Inventory[id]
    if invSlot then return invSlot:FindFirstChild("ItemIcon") end
    local allSlot = slots.All[id]
    if allSlot and allSlot.frame then return allSlot.frame:FindFirstChild("ItemIcon") end
    return nil
end

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and dragging.active then
        if not dragging.fromSlot then
            dragging.active = false
            isMoving = false
            return
        end

        local toSlot, slotType, slotFrame = getSlotUnderMouse()

        if dragging.clone then
            dragging.clone:Destroy()
            dragging.clone = nil
        end

        local fromSlot = dragging.fromSlot

        isMoving = false
        dragging.active = false
        dragging.fromSlot = nil

        if toSlot and toSlot ~= fromSlot then
            -- Valid drop target: swap data and let updateSlot handle icon visibility
            local fromItem = playerInventoryData[fromSlot]
            local toItem = playerInventoryData[toSlot]

            playerInventoryData[toSlot] = fromItem
            playerInventoryData[fromSlot] = toItem or ""
            updateSlot(fromSlot)
            updateSlot(toSlot)

            isMoveInProgress = true
            print(fromSlot, toSlot)

            InventoryService:MoveItem(fromSlot, toSlot):andThen(function(success)
                if not success then
                    print("Not success")
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
        else
            -- Dropped on nothing or same slot: just restore the icon at fromSlot
            local icon = getIconForSlot(fromSlot)
            if icon then icon.Visible = true end
        end
    end

    if input.KeyCode == Enum.KeyCode.X then
        if not dragging.active then
            local slot = getSlotUnderMouse()
            if slot and playerInventoryData[slot] ~= "" then
                local oldItem = playerInventoryData[slot]
                playerInventoryData[slot] = ""
                updateSlot(slot)
                print(oldItem, slot)

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
