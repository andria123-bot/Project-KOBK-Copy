local Knit = require(game:GetService("ReplicatedStorage").Packages:WaitForChild("Knit"))
local InventoryController = Knit.CreateController({
	Name = "InventoryController",
})

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local InventoryService

local InventoryUIController = require(script.Parent.Parent.Inventory:WaitForChild("InventoryUIController"))
InventoryUIController:InitSys()

local slots = InventoryUIController.slots
local SLOT_COUNT = #slots.Inventory

repeat task.wait() until #slots.Inventory > 0
print("Detected slots: ", SLOT_COUNT)

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

for i = 1, SLOT_COUNT do
    playerInventoryData[i] = ""
end

local function getMousePos()
    local mousePos = UserInputService:GetMouseLocation()
    local guiInset = GuiService:GetGuiInset()
    return Vector2.new(mousePos.X, mousePos.Y - guiInset.Y)
end

local function createDragClone(original, slotFrame)
    local clone = original:Clone()
    clone.Parent = MainParent
    clone.ZIndex = 10
    clone.AnchorPoint = Vector2.new(.5, 0)
    clone.Size = UDim2.new(0, original.AbsoluteSize.X, 0, original.AbsoluteSize.Y)

    local slotPos = slotFrame.AbsolutePosition
    local slotSize = slotFrame.AbsoluteSize
    local mainParentPos = MainParent.AbsolutePosition
    local localX = slotPos.X + slotSize.X / 2 - mainParentPos.X
    local localY = slotPos.Y + slotSize.Y / 2 - mainParentPos.Y

    clone.Position = UDim2.new(0, localX, 0, localY)
    return clone
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
                local success, module = pcall(function()
                    return RequestModule:InvokeServer(itemName)
                end)

                if success and module and module.imageIconId then
                    itemImageCache[itemName] = module.imageIconId
                    local currentSlot = slots.Inventory[index]
                    if currentSlot then
                        local currentIcon = currentSlot:FindFirstChild("ItemIcon")
                        if currentIcon and playerInventoryData[index] == itemName then
                            currentIcon.Image = module.imageIconId
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

-- SINGLE InventoryUpdated listener (will be set in KnitStart)
local function setupInventoryListener()
	print(InventoryService)
	InventoryService.InventoryUpdated:Connect(function(data)  -- Just data
		local inventory = data.PlayerInventory

		if inventory then
			for i = 1, SLOT_COUNT do
				playerInventoryData[i] = inventory[i] or ""
			end
			RenderItems()
		end
	end)
end

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and dragging.active then
        if not dragging.fromSlot then
            dragging.active = false
            isMoving = false
            return
        end

        local toSlot, _ = getSlotUnderMouse()

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
            isMoveInProgress = true

            InventoryService:MoveItem(fromSlot, toSlot):andThen(function(success)
                if not success then
                    updateSlot(fromSlot)
                    updateSlot(toSlot)
                end
                isMoveInProgress = false
            end):catch(function(err)
                print("Move error:", err)
                isMoveInProgress = false
            end)
        end
    end

    if input.KeyCode == Enum.KeyCode.X then
        if not dragging.active then
            local slot, _ = getSlotUnderMouse()
            if slot and playerInventoryData[slot] ~= "" then
                InventoryService:RemoveItem(slot):andThen(function(success, item)
                    if success then
                        playerInventoryData[slot] = ""
                        updateSlot(slot)
                        print("Dropped", item)
                    end
                end)
            end
        end
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
	wait(1.5)
    print("InventoryController KnitStart")
    
    InventoryService = Knit.GetService("InventoryService")
    print("InventoryService obtained:", InventoryService)
    
    if not InventoryService then
        warn("InventoryService is nil!")
        return
    end
    
    setupInventoryListener()
    
    InventoryService:GetInventory():andThen(function(inventory)
        print("Initial inventory received:", inventory.PlayerInventory)
        if inventory and inventory.PlayerInventory then
			print(SLOT_COUNT)
            for i = 1, SLOT_COUNT do
                playerInventoryData[i] = inventory.PlayerInventory[i] or ""
            end
            RenderItems()
        end
    end):catch(function(err)
        warn("Failed to get inventory:", err)
    end)
    
    SlotHandler()
end

function InventoryController:KnitInit() end

return InventoryController