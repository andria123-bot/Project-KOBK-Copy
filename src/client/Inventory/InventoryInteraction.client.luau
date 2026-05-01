local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RunService = game:GetService("RunService")

local MoveItem = ReplicatedStorage.Shared.Remotes.Requests:WaitForChild("MoveItem")
local SendInventory = ReplicatedStorage.Shared.Remotes.InventoryEvents:WaitForChild("SendInventory")
local RequestInventory = ReplicatedStorage.Shared.Remotes.InventoryEvents:WaitForChild("RequestInventory")
local RequestModule = ReplicatedStorage.Shared.Remotes.Requests:WaitForChild("RequestModule")
local PlayerSlotData = ReplicatedStorage.Shared.Remotes.InventoryEvents:WaitForChild("PlayerSlotData")

local InventoryUIController = require(script.Parent.InventoryUIController)
local InventoryFunctions = require(ReplicatedStorage.Shared.Modules.Inventory.InventoryFunctions)
InventoryUIController:InitSys()

local slots = InventoryUIController.slots

repeat task.wait() until #slots.Inventory > 0

local Menu = playerGui:WaitForChild("Menu")
local MainParent = Menu.MainParent
local InventoryParent = MainParent:WaitForChild("InventoryParent")

local GuiService = game:GetService("GuiService")

local playerInventoryData = {}
local itemImageCache = {}
local isMoving = false
local dragging = {
	active = false,
	fromSlot = nil,
	clone = nil,
}

RequestInventory:FireServer()

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
	
	-- Position clone at the exact same screen position as the original slot
	local slotPos = slotFrame.AbsolutePosition
	local slotSize = slotFrame.AbsoluteSize
	
	-- Convert to MainParent local coordinates
	local mainParentPos = MainParent.AbsolutePosition
	local localX = slotPos.X + slotSize.X/2 - mainParentPos.X
	local localY = slotPos.Y + slotSize.Y/2 - mainParentPos.Y
	
	clone.Position = UDim2.new(0, localX, 0, localY)
	
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
	for index, itemName in pairs(playerInventoryData) do
		updateSlot(index)
	end
end

local function sendPlayerSlotData()
	local slotData = {}
	for i = 1, #slots.Inventory do
		slotData["Slot" .. i] = playerInventoryData[i] or ""
	end
	PlayerSlotData:FireServer(slotData)
end

local function SlotHandler()
	for index, slotFrame in pairs(slots.Inventory) do
		local itemIcon = slotFrame:FindFirstChild("ItemIcon")
		if itemIcon and not itemIcon:GetAttribute("DragHandlerAttached") then
			itemIcon:SetAttribute("DragHandlerAttached", true)
			itemIcon.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					if isMoving then return end
					if InventoryFunctions.HasItem(playerInventoryData, index) then
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
        
        if toSlot and toSlot ~= fromSlot then
            local fromItem = playerInventoryData[fromSlot]
            local toItem = playerInventoryData[toSlot]
            
            playerInventoryData[toSlot] = fromItem
            playerInventoryData[fromSlot] = toItem
            
            updateSlot(fromSlot)
            updateSlot(toSlot)
            
            task.spawn(function()
                local success = MoveItem:InvokeServer(fromSlot, toSlot)
                if not success then
                    playerInventoryData[fromSlot] = fromItem
                    playerInventoryData[toSlot] = toItem
                    updateSlot(fromSlot)
                    updateSlot(toSlot)
                end
                sendPlayerSlotData()
            end)
        end
        
        isMoving = false
        dragging.active = false
        dragging.fromSlot = nil
    end
end)

SendInventory.OnClientEvent:Connect(function(inventoryData)
	print("Received inventory type:", type(inventoryData))
    print("Has PlayerInventory?", inventoryData.PlayerInventory ~= nil)
    print("Has Equipment?", inventoryData.Equipment ~= nil)
    
	if not inventoryData then return end
	
	playerInventoryData = {}
	
	local inventoryTable = {}
	if type(inventoryData) == "table" and inventoryData.PlayerInventory then
		inventoryTable = inventoryData.PlayerInventory
	else
		inventoryTable = inventoryData
	end
	
	for i = 1, #slots.Inventory do
		playerInventoryData[i] = inventoryTable[i] or ""
	end
	
	RenderItems()
	SlotHandler()
	sendPlayerSlotData()
end)

RunService.RenderStepped:Connect(function(deltaTime)
	if dragging.active and dragging.clone then
		local mousePos = getMousePos()
		local mainParentPos = MainParent.AbsolutePosition
		local localPos = mousePos - mainParentPos
		dragging.clone.Position = UDim2.new(0, localPos.X, 0, localPos.Y)
	end
end)