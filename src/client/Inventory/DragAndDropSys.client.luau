local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local MoveItem = ReplicatedStorage.Shared.Remotes.InventoryEvents:WaitForChild("MoveItem")


local Menu = playerGui:WaitForChild("Menu")
local MainParent = Menu.MainParent
local RowsParent = MainParent.InventoryParent.InventoryGui.InventoryItemsFrame.SingleRowParent

local Toolbar = playerGui:WaitForChild("Toolbar")
local MainFrame = Toolbar.MainFrame

local mouse = player:GetMouse()

local dragging = {
	active = false,
	fromSlot = nil,
	toSlot = nil,
	clone = nil,
}

local function getSlotUnderMouse()
    for _, slot in pairs(MainParent:GetDescendants()) do
        if slot:IsA("Frame") and slot.Name:match("^Slot%d+$") then
            local absPos = slot.AbsolutePosition
            local absSize = slot.AbsoluteSize
            local mousePos = Vector2.new(mouse.X, mouse.Y)

            if mousePos.X >= absPos.X and mousePos.X <= absPos.X + absSize.X
               and mousePos.Y >= absPos.Y and mousePos.Y <= absPos.Y + absSize.Y then
                return slot
            end
        end
    end

    return nil
end



UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end

    if input.KeyCode == Enum.UserInputType.MouseButton1 then
        local mousePos = getSlotUnderMouse()
        
    end
end)