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
InventoryUIController:InitSys()

local slots = InventoryUIController.slots

repeat
	task.wait()
until #slots.Inventory > 0

local Menu = playerGui:WaitForChild("Menu")
local MainParent = Menu.MainParent
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

	for index, slot in pairs(slots.Inventory) do
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
	clone.Parent = MainParent
	clone.ZIndex = 10
	clone.AnchorPoint = Vector2.new(0.5, 0.5)
	clone.Size = UDim2.fromOffset(original.AbsoluteSize.X, original.AbsoluteSize.Y)

	return clone
end

local function updateSlot(index)
	if not index then return end
	
	local slot = slots.Inventory[index]
	if not slot then return end
	
	local itemIcon = slot:FindFirstChild("ItemIcon")
	if not itemIcon then return end
	
	if not playerInventoryData then return end
	
	local itemName = playerInventoryData[index]
	
	if itemName and itemName ~= "" and itemName ~= "Empty" then
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
	if not playerInventoryData then return end
	
	for index, _itemName in pairs(playerInventoryData) do
		if index then
			updateSlot(index)
		end
	end
end

local function sendPlayerSlotData()
	if not slots or not slots.Inventory then return end
	
	local slotData = {
		slots = {};
		weaponSlots = {};
		utils = {};
	}
	
	for i = 1, #slots.Inventory do
		slotData.slots["Slot" .. i] = playerInventoryData[i] or ""
	end
	
	for i = 1, #slots.WeaponSlots do
		slotData.weaponSlots["WeaponSlot" .. i] = ""
	end
	
	for i = 1, #slots.Utils do
		slotData.utils["UtilSlot" .. i] = ""
	end
	
	PlayerSlotData:FireServer(slotData)
end

local function SlotHandler()
	if not slots or not slots.Inventory then return end
	
	for index, k in pairs(slots.Inventory) do
		local itemIcon = k:FindFirstChild("ItemIcon")
		if itemIcon and not itemIcon:GetAttribute("DragHandlerAttached") then
			itemIcon:SetAttribute("DragHandlerAttached", true)
			itemIcon.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					if playerInventoryData and playerInventoryData[index]
						and playerInventoryData[index] ~= ""
						and playerInventoryData[index] ~= "Empty"
						and playerInventoryData[index] ~= nil
					then
						dragging.fromSlot = index
						dragging.active = true
						dragging.clone = createDragClone(itemIcon)
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
            return 
        end
        
        local slotGroup, slotIndex, slotFrame = getSlotUnderMouse()
        
        if dragging.clone then
            dragging.clone:Destroy()
            dragging.clone = nil
        end
        
        if slotGroup and slotIndex and slotIndex ~= dragging.fromSlot then
		if not dragging.fromSlot or not slotIndex then return end
		
		-- Make sure playerInventoryData exists
		if not playerInventoryData then return end
		
		-- Get items with nil fallbacks
		local fromItem = playerInventoryData[dragging.fromSlot] or ""
		local toItem = playerInventoryData[slotIndex] or ""
		
		-- Swap items
		playerInventoryData[slotIndex] = fromItem
		playerInventoryData[dragging.fromSlot] = toItem
		
		-- Update slots if they exist
		if dragging.fromSlot then updateSlot(dragging.fromSlot) end
		if slotIndex then updateSlot(slotIndex) end

		if playerInventoryData and dragging.fromSlot then
			print("playerInventoryData exists, fromSlot:", dragging.fromSlot, "value:", playerInventoryData[dragging.fromSlot])
		else
			print("playerInventoryData is nil or fromSlot is nil")
		end
            
		task.spawn(function()
			if dragging.fromSlot and slotIndex then
				local success = MoveItem:InvokeServer(dragging.fromSlot, slotIndex)
				if not success then
					print(playerInventoryData, dragging.fromSlot, fromItem)
					playerInventoryData[dragging.fromSlot] = fromItem
					playerInventoryData[slotIndex] = toItem
					if dragging.fromSlot then updateSlot(dragging.fromSlot) end
					if slotIndex then updateSlot(slotIndex) end
				end
				sendPlayerSlotData()
                end
            end)
        end
        
        local originalSlot = slots.Inventory[dragging.fromSlot]
        if originalSlot then
            local originalIcon = originalSlot:FindFirstChild("ItemIcon")
            if originalIcon then
                originalIcon.Visible = true
            end
        end

        dragging.active = false
        dragging.fromSlot = nil
    end
end)

-- After receiving inventory, print the data
SendInventory.OnClientEvent:Connect(function(savedInventory)
    if not savedInventory then return end
    
    -- Clear existing
    playerInventoryData = {}
    
    -- Get inventory data
    local inventoryTable = {}
    if type(savedInventory) == "table" and savedInventory.PlayerInventory then
        inventoryTable = savedInventory.PlayerInventory
    else
        inventoryTable = savedInventory
    end
    
    -- Fill ALL slots based on actual slot count
    print("Total slots available:", #slots.Inventory)
    print("Inventory table length:", #inventoryTable)
    
    for i = 1, #slots.Inventory do
        playerInventoryData[i] = inventoryTable[i] or ""
        print("Slot", i, "=", playerInventoryData[i])
    end
    
    RenderItems()
    SlotHandler()
    sendPlayerSlotData()
end)

RunService.RenderStepped:Connect(function(deltaTime)
	if dragging.active and dragging.clone then
		local mousePos = getMousePos()
		local invGuiPos = InventoryParent.AbsolutePosition
		local localPos = mousePos - invGuiPos
		dragging.clone.Position = UDim2.new(0, localPos.X, 0, localPos.Y)
	end
end)