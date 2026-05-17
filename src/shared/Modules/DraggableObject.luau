local DraggableObject = {}
DraggableObject.__index = DraggableObject

function DraggableObject.new(frame, topParent)
    local self = setmetatable({
        Object = frame,
        TopParent = topParent or frame.Parent,
        OnDragStart = nil,
        OnDragEnd = nil,
        OnCanDrag = nil,
        Dragging = false,
        Clone = nil,
        SourceSlot = nil,
    }, DraggableObject)
    return self
end

function DraggableObject:GetTargetUnderMouse(mousePos)
    local GuiService = game:GetService("GuiService")
    local guiInset = GuiService:GetGuiInset()
    local adjustedPos = Vector2.new(mousePos.X, mousePos.Y - guiInset.Y)
    
    local targets = self.TopParent:GetDescendants()
    for _, target in pairs(targets) do
        if target:IsA("Frame") and target:FindFirstChild("ItemIcon") and target ~= self.Object.Parent then
            local pos = target.AbsolutePosition
            local size = target.AbsoluteSize
            if adjustedPos.X >= pos.X and adjustedPos.X <= pos.X + size.X
                and adjustedPos.Y >= pos.Y and adjustedPos.Y <= pos.Y + size.Y then
                print("[DraggableObject]: Target found:", target.Name)
                return target
            end
        end
    end
    return nil
end

function DraggableObject:Enable(sourceSlot)
    local UserInputService = game:GetService("UserInputService")
    local GuiService = game:GetService("GuiService")

    self.SourceSlot = sourceSlot

    self.InputBegan = self.Object.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if self.OnCanDrag and not self.OnCanDrag() then
                return
            end
            
            self.Dragging = true

            if self.OnDragStart then
                self.OnDragStart(self.SourceSlot)
            end

            self.Clone = self.Object:Clone()
            self.Clone.Parent = self.TopParent
            self.Clone.ZIndex = 999
            self.Clone.AnchorPoint = Vector2.new(0.5, 0.5)
            self.Clone.Size = UDim2.fromOffset(
                self.Object.AbsoluteSize.X,
                self.Object.AbsoluteSize.Y
            )

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

            local mousePos = UserInputService:GetMouseLocation()
            local targetFrame = self:GetTargetUnderMouse(mousePos)
            
            if self.OnDragEnd then
                self.OnDragEnd(self.SourceSlot, targetFrame)
            end

            self.Object.Visible = true
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