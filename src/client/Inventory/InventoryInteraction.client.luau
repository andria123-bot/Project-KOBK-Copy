local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local MoveItem = ReplicatedStorage.Shared.Remotes.InventoryEvents:WaitForChild("MoveItem")
local SendInventory = ReplicatedStorage.Shared.Remotes.InventoryEvents:WaitForChild("SendInventory")
local requestDADSYS = ReplicatedStorage.Shared.Remotes:WaitForChild("RequestDADSYS")

local SlotInitializer = require(script.Parent.SlotInitializer)
SlotInitializer:InitSys()

local inventory = {}

local slots = SlotInitializer.slots

local Menu = playerGui:WaitForChild("Menu")
local MainParent = Menu.MainParent
local RowsParent = MainParent.InventoryParent.InventoryGui.InventoryItemsFrame.SingleRowParent
local InventoryParent = MainParent:WaitForChild("InventoryParent")

local Toolbar = playerGui:WaitForChild("Toolbar")
local MainFrame = Toolbar.MainFrame

local GuiService = game:GetService('GuiService')

local mouse = player:GetMouse()

local playerInventory = {}

SendInventory.OnClientEvent:Connect(function(savedInventory)
    playerInventory = playerInventory or {}
    print(savedInventory)

    for i = 1, #savedInventory do
        playerInventory[i] = savedInventory[i] or ""
    end

    print("Inventory synced:", playerInventory)
end)

local dragging = {
	active = false,
	fromSlot = nil,
	toSlot = nil,
	clone = nil,
}

local function getMousePos()
	local mousePos = UserInputService:GetMouseLocation()
	local guiInset = GuiService:GetGuiInset()
	return Vector2.new(mousePos.X, mousePos.Y - guiInset.Y)
end

local function getSlotUnderMouse()
	local pos = getMousePos()
	for index, slot in pairs(slots) do
		local sPos, sSize = slot.AbsolutePosition, slot.AbsoluteSize
		if pos.X >= sPos.X and pos.X <= sPos.X + sSize.X and pos.Y >= sPos.Y and pos.Y <= sPos.Y + sSize.Y then
			return index
		end
	end
	return nil
end

local function createDragClone(original)
	local clone = original:Clone()
	clone.Parent = InventoryParent
	clone.ZIndex = 10
	clone.AnchorPoint = Vector2.new(0.5, 0.5)
	clone.Size = UDim2.new(0, original.AbsoluteSize.X, 0, original.AbsoluteSize.Y)

	local mousePos = getMousePos()
	local invGuiPos = InventoryParent.AbsolutePosition
	local localPos = mousePos - invGuiPos
	clone.Position = UDim2.new(0, localPos.X, 0, localPos.Y)

	return clone
end

for i, slot in pairs(slots) do
    for index, k in pairs(slot) do
        local itemIcon = k:FindFirstChild("ItemIcon")
        
        itemIcon.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1  then -- add check: and playerInventory.slotIndex ~= ""
                dragging.active = true
                dragging.fromSlot = index
                dragging.clone = createDragClone(itemIcon)
            end
        end)

        itemIcon.InputEnded:Connect(function(input)
            if dragging.active and input.UserInputType == Enum.UserInputType.MouseButton1 then
                local targetSlot = getSlotUnderMouse()
                -- local draggedItem = weaponSystem.inventoryy[dragging.fromSlot]
            end
        end)
    end
end

print(playerInventory)