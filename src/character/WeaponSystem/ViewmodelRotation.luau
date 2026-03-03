local ViewmodelRotation = {}
local UIS = game:GetService("UserInputService")

ViewmodelRotation.KeyEvents = {
    LeftPressed = Instance.new("BindableEvent"),
    LeftReleased = Instance.new("BindableEvent"),
    RightPressed = Instance.new("BindableEvent"),
    RightReleased = Instance.new("BindableEvent")
}

ViewmodelRotation.weaponModule = nil
ViewmodelRotation.viewmodel = nil
ViewmodelRotation.aimPart = nil

ViewmodelRotation.targetRotation = 0
ViewmodelRotation.currentRotation = 0

ViewmodelRotation.isMovingLeft = false
ViewmodelRotation.isMovingRight = false

function ViewmodelRotation:Init(weaponModule, viewmodel, aimPart)
    self.weaponModule = weaponModule
    self.viewmodel = viewmodel
    self.aimPart = aimPart
end

function ViewmodelRotation:OnLeftPressed(callback)
    return self.KeyEvents.LeftPressed.Event:Connect(callback)
end

function ViewmodelRotation:OnLeftReleased(callback)
    return self.KeyEvents.LeftReleased.Event:Connect(callback)
end

function ViewmodelRotation:OnRightPressed(callback)
    return self.KeyEvents.RightPressed.Event:Connect(callback)
end

function ViewmodelRotation:OnRightReleased(callback)
    return self.KeyEvents.RightReleased.Event:Connect(callback)
end

function ViewmodelRotation:getRotation(dt, moveDirection, isAiming)
    if not self.weaponModule or not self.viewmodel then
        return 0
    end

    if moveDirection then
        self.isMovingLeft = moveDirection.X < 0
        self.isMovingRight = moveDirection.X > 0
    end

    if moveDirection and moveDirection.X ~= 0 then
        if isAiming then
            self.targetRotation = math.rad(3.2) * moveDirection.X
        else
            self.targetRotation = math.rad(7.5) * moveDirection.X
        end
    else
        self.targetRotation = 0
    end

    self.currentRotation = self.currentRotation 
        + (self.targetRotation - self.currentRotation) 
        * math.min(0.7, 5 * dt)

    return self.currentRotation
end

UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

    if input.KeyCode == Enum.KeyCode.A then
        ViewmodelRotation.isMovingLeft = true
        ViewmodelRotation.KeyEvents.LeftPressed:Fire()
    elseif input.KeyCode == Enum.KeyCode.D then
        ViewmodelRotation.isMovingRight = true
        ViewmodelRotation.KeyEvents.RightPressed:Fire()
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

    if input.KeyCode == Enum.KeyCode.A then
        ViewmodelRotation.isMovingLeft = false
        ViewmodelRotation.KeyEvents.LeftReleased:Fire()
    elseif input.KeyCode == Enum.KeyCode.D then
        ViewmodelRotation.isMovingRight = false
        ViewmodelRotation.KeyEvents.RightReleased:Fire()
    end
end)

return ViewmodelRotation