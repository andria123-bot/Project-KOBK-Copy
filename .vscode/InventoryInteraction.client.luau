local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Knit = require(game:GetService("ReplicatedStorage").Packages:WaitForChild("Knit"))

local InventoryUIController = require(script.Parent:WaitForChild("InventoryUIController"))
InventoryUIController:InitSys()


local slots = InventoryUIController.slots
repeat task.wait() until #slots.Inventory > 0

local SLOT_COUNT = #slots.Inventory
print("Detected slot count:", SLOT_COUNT)

local Menu = playerGui:WaitForChild("Menu")
local MainParent = Menu.MainParent
local InventoryParent = MainParent:WaitForChild("InventoryParent")

local playerInventoryData = {}
local itemImageCache = {}
local isMoving = false
local isMoveInProgress = false
local dragging = {
    active = false,
    fromSlot = nil,
    clone = nil,
}

for i = 1, SLOT_COUNT do
    playerInventoryData[i] = ""
end

local InventoryService

local function getMousePos()
    local mousePos = UserInputService:GetMouseLocation()
    local guiInset = GuiService:GetGuiInset()
    return Vector2.new(mousePos.X, mousePos.Y - guiInset.Y)
end

local function getSlotUnderMouse()
    local mousePos = UserInputService:GetMouseLocation()
    local guiInset = GuiService:GetGuiInset()
    local adjustedMousePos = Vector2.new(mousePos.X, mousePos.Y - guiInset.Y)
    for index, slot in pairs(slots.Inventory) do
        if slot then
            local slotPos = slot.AbsolutePosition
            local slotSize = slot.AbsoluteSize
            if adjustedMousePos.X >= slotPos.X
                and adjustedMousePos.X <= slotPos.X + slotSize.X
                and adjustedMousePos.Y >= slotPos.Y
                and adjustedMousePos.Y <= slotPos.Y + slotSize.Y
            then
                return index, slot
            end
        end
    end
    return nil, nil
end

local function createDragClone(original, slotFrame)
    local clone = original:Clone()
    clone.Parent = MainParent
    clone.ZIndex = 10
    clone.AnchorPoint = Vector2.new(0.5, 0.5)
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

local function updateSlot(index)
    if not index then return end
    local slot = slots.Inventory[index]
    if not slot then return end
    local itemIcon = slot:FindFirstChild("ItemIcon")
    if not itemIcon then return end

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

local function RenderItems()
    for i = 1, SLOT_COUNT do
        updateSlot(i)
    end
end

local function applyInventory(inventory)
    if not inventory or not inventory.PlayerInventory then return end
    for i = 1, SLOT_COUNT do
        playerInventoryData[i] = inventory.PlayerInventory[i] or ""
    end
    RenderItems()
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

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and dragging.active then
        if not dragging.fromSlot then
            dragging.active = false
            isMoving = false
            return
        end

        local toSlot = getSlotUnderMouse()

        if dragging.clone then
            dragging.clone:Destroy()
            dragging.clone = nil
        end

        local fromSlot = dragging.fromSlot

        local originalSlot = slots.Inventory[fromSlot]
        if originalSlot then
            local originalIcon = originalSlot:FindFirstChild("ItemIcon")
            if originalIcon then originalIcon.Visible = true end
        end

        isMoving = false
        dragging.active = false
        dragging.fromSlot = nil

        if toSlot and toSlot ~= fromSlot and InventoryService then
            local fromItem = playerInventoryData[fromSlot]
            local toItem = playerInventoryData[toSlot]

            playerInventoryData[toSlot] = fromItem
            playerInventoryData[fromSlot] = toItem or ""
            updateSlot(fromSlot)
            updateSlot(toSlot)

            isMoveInProgress = true

            InventoryService:MoveItem(fromSlot, toSlot):andThen(function(success)
                print("MoveItem result:", success)
                if not success then
                    playerInventoryData[fromSlot] = fromItem
                    playerInventoryData[toSlot] = toItem
                    updateSlot(fromSlot)
                    updateSlot(toSlot)
                end
                isMoveInProgress = false
            end):catch(function(err)
                warn("MoveItem error:", err)
                playerInventoryData[fromSlot] = fromItem
                playerInventoryData[toSlot] = toItem
                updateSlot(fromSlot)
                updateSlot(toSlot)
                isMoveInProgress = false
            end)
        end
    end

    if input.KeyCode == Enum.KeyCode.X then
        if not dragging.active and InventoryService then
            local slot = getSlotUnderMouse()
            if slot and playerInventoryData[slot] ~= "" then
                InventoryService:RemoveItem(slot):andThen(function(success)
                    if success then
                        playerInventoryData[slot] = ""
                        updateSlot(slot)
                    end
                end)
            end
        end
    end


end)

RunService.RenderStepped:Connect(function()
    if dragging.active and dragging.clone then
        local mousePos = getMousePos()
        local mainParentPos = MainParent.AbsolutePosition
        dragging.clone.Position = UDim2.new(0,
            mousePos.X - mainParentPos.X,
            0,
            mousePos.Y - mainParentPos.Y
        )
    end
end)

Knit.OnStart():andThen(function()
    InventoryService = Knit.GetService("InventoryService")
    print("Knit ready, InventoryService acquired")

    InventoryService.InventoryUpdated:Connect(function(inventoryData)
        if isMoveInProgress then return end  -- ignore during active move
        print("InventoryUpdated received from server")
        applyInventory(inventoryData)
    end)

    InventoryService:GetInventory():andThen(function(inventory)
        print("Initial inventory received:", inventory)
        applyInventory(inventory)
        SlotHandler()
    end):catch(function(err)
        warn("Failed to get inventory:", err)
    end)
end):catch(function(err)
    warn("Knit failed to start:", err)
end)