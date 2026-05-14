local DraggableObject = {}
DraggableObject.__index = DraggableObject

function DraggableObject.new(frame, topParent)
    local self = setmetatable({
        Object = frame,
        TopParent = topParent or frame.Parent, -- parent clone here for proper ZIndex
        DragStarted = nil,
        DragEnded = nil,
        Dragging = false,
        Clone = nil,
    }, DraggableObject)
    return self
end

function DraggableObject:Enable()
    local UserInputService = game:GetService("UserInputService")
    local GuiService = game:GetService("GuiService")

    self.InputBegan = self.Object.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self.Dragging = true

            if self.DragStarted then
                self.DragStarted()
            end

            -- Clone parented to TopParent so ZIndex is global
            self.Clone = self.Object:Clone()
            self.Clone.Parent = self.TopParent
            self.Clone.ZIndex = 999
            self.Clone.AnchorPoint = Vector2.new(0.5, 0.5)
            self.Clone.Size = UDim2.fromOffset(
                self.Object.AbsoluteSize.X,
                self.Object.AbsoluteSize.Y
            )

            -- Position clone at object's current screen position converted to TopParent space
            local objPos = self.Object.AbsolutePosition
            local objSize = self.Object.AbsoluteSize
            local parentPos = self.TopParent.AbsolutePosition
            self.Clone.Position = UDim2.fromOffset(
                objPos.X + objSize.X / 2 - parentPos.X,
                objPos.Y + objSize.Y / 2 - parentPos.Y
            )

            self.Object.Visible = false
        end
    end)

    self.InputChanged = UserInputService.InputChanged:Connect(function(input)
        if self.Dragging and self.Clone and input.UserInputType == Enum.UserInputType.MouseMovement then
            local guiInset = GuiService:GetGuiInset()
            local mousePos = UserInputService:GetMouseLocation()
            local parentPos = self.TopParent.AbsolutePosition

            self.Clone.Position = UDim2.fromOffset(
                mousePos.X - parentPos.X,
                mousePos.Y - guiInset.Y - parentPos.Y
            )
        end
    end)

    self.InputEnded = UserInputService.InputEnded:Connect(function(input)
        if self.Dragging and input.UserInputType == Enum.UserInputType.MouseButton1 then
            self.Dragging = false

            if self.Clone then
                self.Clone:Destroy()
                self.Clone = nil
            end

            self.Object.Visible = true

            if self.DragEnded then
                self.DragEnded()
            end
        end
    end)
end

function DraggableObject:Disable()
    if self.InputBegan then self.InputBegan:Disconnect() end
    if self.InputChanged then self.InputChanged:Disconnect() end
    if self.InputEnded then self.InputEnded:Disconnect() end
    if self.Clone then
        self.Clone:Destroy()
        self.Clone = nil
    end
    self.Dragging = false
    self.Object.Visible = true
end

return DraggableObject