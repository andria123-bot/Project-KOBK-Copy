-- DraggableModule.lua (Simplified for your inventory)
local Draggable = {}
Draggable.__index = Draggable

function Draggable.new(frame)
    local self = setmetatable({}, Draggable)
    self.frame = frame
    self.dragging = false
    self.dragStart = nil
    self.startPos = nil
    return self
end

function Draggable:Enable()
    local inputBegan = self.frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self.dragging = true
            self.dragStart = input.Position
            self.startPos = self.frame.Position
        end
    end)
    
    local inputChanged = game:GetService("UserInputService").InputChanged:Connect(function(input)
        if self.dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - self.dragStart
            self.frame.Position = UDim2.new(
                self.startPos.X.Scale, self.startPos.X.Offset + delta.X,
                self.startPos.Y.Scale, self.startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    local inputEnded = game:GetService("UserInputService").InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self.dragging = false
        end
    end)
end

return Draggable