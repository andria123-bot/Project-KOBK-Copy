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

local Menu = playerGui:WaitForChild("Menu")
local MainParent = Menu.MainParent
local GearsGui = MainParent.GearParent.GearGUI
local InventoryParent = MainParent:WaitForChild("InventoryParent")

local GuiService = game:GetService("GuiService")

local playerInventoryData = {}
local itemImageCache = {}

RequestInventory:FireServer()

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
				return "inventory", index, slot
			end
		end
	end

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

local function updateSlot(index)
	local slot = slots.inventory[index]
	if not slot then return end
	
	local itemIcon = slot:FindFirstChild("ItemIcon")
	if not itemIcon then return end
	
	local itemName = playerInventoryData[index]
	
	if itemName and itemName ~= "" and itemName ~= "Empty" then
		local cachedImage = itemImageCache[itemName]
		if cachedImage then
			itemIcon.Image = cachedImage
		else
			task.spawn(function()
				local module = RequestModule:InvokeServer(itemName)
				if module and module.imageIconId then
					itemImageCache[itemName] = module.imageIconId
					itemIcon.Image = module.imageIconId
				end
			end)
		end
	else
		itemIcon.Image = ""
	end
end

local function RenderItems()
	for index, itemName in pairs(playerInventoryData) do
		updateSlot(index)
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
						itemIcon.Visible = false
					end
				end
			end)
		end
	end
end

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 and dragging.active and dragging.clone then
		local slotGroup, slotIndex, slotFrame = getSlotUnderMouse()

		if slotGroup and slotIndex and slotIndex ~= dragging.fromSlot then
			
			local fromItem = playerInventoryData[dragging.fromSlot]
			local toItem = playerInventoryData[slotIndex]
			
			playerInventoryData[slotIndex] = fromItem
			playerInventoryData[dragging.fromSlot] = toItem or ""
			
			updateSlot(dragging.fromSlot)
			updateSlot(slotIndex)
			
			MoveItem:FireServer(dragging.fromSlot, slotIndex)
		end
		
		local originalSlot = slots.inventory[dragging.fromSlot]
		if originalSlot then
			local originalIcon = originalSlot:FindFirstChild("ItemIcon")
			if originalIcon then
				originalIcon.Visible = true
			end
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