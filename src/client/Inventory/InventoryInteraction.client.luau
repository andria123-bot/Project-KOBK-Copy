local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RunService = game:GetService("RunService")

local MoveItem = ReplicatedStorage.Shared.Remotes.InventoryEvents:WaitForChild("MoveItem")
local SendInventory = ReplicatedStorage.Shared.Remotes.InventoryEvents:WaitForChild("SendInventory")
local RequestInventory = ReplicatedStorage.Shared.Remotes.InventoryEvents:WaitForChild("RequestInventory")
local RequestModule = ReplicatedStorage.Shared.Remotes:WaitForChild("RequestModule")

local SlotInitializer = require(script.Parent.SlotInitializer)
SlotInitializer:InitSys()

local slots = SlotInitializer.slots

repeat
	task.wait()
until #slots.inventory > 0

print("Total inventory slots initialized:", #slots.inventory)
for i = 1, #slots.inventory do
	if slots.inventory[i] then
		print("Slot " .. i .. " exists:", slots.inventory[i].Name)
	end
end

local Menu = playerGui:WaitForChild("Menu")
local MainParent = Menu.MainParent
local RowsParent = MainParent.InventoryParent.InventoryGui.InventoryItemsFrame.SingleRowParent
local InventoryParent = MainParent:WaitForChild("InventoryParent")

local Toolbar = playerGui:WaitForChild("Toolbar")
local MainFrame = Toolbar.MainFrame

local GuiService = game:GetService("GuiService")

local playerInventoryData = {}

RequestInventory:FireServer()


--[[        for i = #starterKit + 1, 8 do
            inventory[i] = "Empty"
        end]]

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
	local mousePos = UserInputService:GetMouseLocation()
	local guiInset = GuiService:GetGuiInset()
	local adjustedMousePos = Vector2.new(mousePos.X, mousePos.Y - guiInset.Y)

	for index, slot in pairs(slots.inventory) do
		if slot then
			local slotPos = slot.AbsolutePosition
			local slotSize = slot.AbsoluteSize

			if adjustedMousePos.X >= slotPos.X
			   and adjustedMousePos.X <= slotPos.X + slotSize.X
			   and adjustedMousePos.Y >= slotPos.Y
			   and adjustedMousePos.Y <= slotPos.Y + slotSize.Y
			then
				print("Found slot:", index, slot.Name, "at position", slotPos, "with size", slotSize)
				return "inventory", index, slot
			end
		end
	end

	print("No slot found under mouse at position:", adjustedMousePos)

	-- -- Check toolbar slots
	-- for index, slot in pairs(slots.toolbar) do
	--     if slot then
	--         local slotPos = slot.AbsolutePosition
	--         local slotSize = slot.AbsoluteSize

	--         if adjustedMousePos.X >= slotPos.X
	--             and adjustedMousePos.X <= slotPos.X + slotSize.X
	--             and adjustedMousePos.Y >= slotPos.Y
	--             and adjustedMousePos.Y <= slotPos.Y + slotSize.Y then
	--             return "toolbar", index, slot
	--         end
	--     end
	-- end

	-- -- Check utils slots
	-- for index, slot in pairs(slots.utils) do
	--     if slot then
	--         local slotPos = slot.AbsolutePosition
	--         local slotSize = slot.AbsoluteSize

	--         if adjustedMousePos.X >= slotPos.X
	--             and adjustedMousePos.X <= slotPos.X + slotSize.X
	--             and adjustedMousePos.Y >= slotPos.Y
	--             and adjustedMousePos.Y <= slotPos.Y + slotSize.Y then
	--             return "utils", index, slot
	--         end
	--     end
	-- end

	return nil, nil, nil
end

local function createDragClone(original)
	local clone = original:Clone()
	clone.Parent = InventoryParent
	clone.ZIndex = 10
	clone.AnchorPoint = Vector2.new(0.5, 0.5)
	clone.Size = UDim2.fromOffset(original.AbsoluteSize.X, original.AbsoluteSize.Y)

	return clone
end

local function RenderItems()
	for index, itemName in pairs(playerInventoryData) do
		local slot = slots.inventory[index]
		if slot then
			local itemIcon = slot:FindFirstChild("ItemIcon")
			if itemIcon then
				if itemName ~= "Empty" and itemName ~= "" then
					local module = RequestModule:InvokeServer(itemName)
					if module then
						itemIcon.Image = module.imageIconId or ""
					end
				else
					itemIcon.Image = ""
				end
			end
		end
	end
end

local function SlotHandler()
	for index, k in pairs(slots.inventory) do
		local itemIcon = k:FindFirstChild("ItemIcon")
		if itemIcon and not itemIcon:GetAttribute("DragHandlerAttached") then
			itemIcon:SetAttribute("DragHandlerAttached", true)
			itemIcon.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					if
						playerInventoryData[index]
						and playerInventoryData[index] ~= ""
						and playerInventoryData[index] ~= "Empty"
					then
						dragging.active = true
						dragging.fromSlot = index
						dragging.clone = createDragClone(itemIcon)
					end
				end
			end)
		end
	end
end

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 and dragging.active and dragging.clone then
		local slotGroup, slotIndex, slotFrame = getSlotUnderMouse()
		print("Mouse released. Slot under mouse:", slotGroup, slotIndex, slotFrame)

		if slotGroup and slotIndex then
			print("Dropped on slot:", slotGroup, slotIndex)
			MoveItem:FireServer(dragging.fromSlot, slotIndex)
		end

		dragging.active = false
		if dragging.clone then
			dragging.clone:Destroy()
		end
	end
end)

SendInventory.OnClientEvent:Connect(function(savedInventory)
	local index = 1
	for i, v in pairs(savedInventory) do
		playerInventoryData[i] = v
	end

	repeat
		task.wait()
	until playerInventoryData[index] ~= nil

	RenderItems()
	SlotHandler()
end)

RunService.RenderStepped:Connect(function(deltaTime)
	if dragging.active and dragging.clone then
		local mousePos = getMousePos()
		local invGuiPos = InventoryParent.AbsolutePosition
		local localPos = mousePos - invGuiPos
		dragging.clone.Position = UDim2.new(0, localPos.X, 0, localPos.Y)
	end
end)

print(slots)
