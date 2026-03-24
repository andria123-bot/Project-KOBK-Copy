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

local Menu = playerGui:WaitForChild("Menu")
local MainParent = Menu.MainParent
local RowsParent = MainParent.InventoryParent.InventoryGui.InventoryItemsFrame.SingleRowParent
local InventoryParent = MainParent:WaitForChild("InventoryParent")

local Toolbar = playerGui:WaitForChild("Toolbar")
local MainFrame = Toolbar.MainFrame

local GuiService = game:GetService('GuiService')

local playerInventoryData = {}

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

local function initInventoryToSlots()
	local itemModule = RequestModule.InvokeServer()
	for i, slot in pairs(slots) do
		for index, k in pairs(slot) do
			print(index, k)
		end
	end
end

local function SlotHandler()
	-- initInventoryToSlots()
	for i, slot in pairs(slots) do
		print(slots.inventory)
		for index, k in pairs(slot) do
			local itemIcon = k:FindFirstChild("ItemIcon")
			if playerInventoryData[index] ~= "" and playerInventoryData[index] ~= nil then
				itemIcon.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						
						dragging.active = true
						dragging.fromSlot = index
						dragging.clone = createDragClone(itemIcon)
					end
				end)

				itemIcon.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then 
						dragging.active = false
						dragging.clone:Destroy()
					end
				end)
			end
		end
	end
end

SendInventory.OnClientEvent:Connect(function(savedInventory)
	local index = 1
	print(savedInventory)
	for i, v in pairs(savedInventory) do
		playerInventoryData[i] = v 
	end

	repeat wait() until playerInventoryData[index] ~= "" or playerInventoryData[index] ~= nil 

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