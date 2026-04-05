local ViewmodelRot = {}
local UIS = game:GetService("UserInputService")

ViewmodelRot.KeyEvents = {
    LeftPressed = Instance.new("BindableEvent"),
    LeftReleased = Instance.new("BindableEvent"),
    RightPressed = Instance.new("BindableEvent"),
    RightReleased = Instance.new("BindableEvent")
}

ViewmodelRot.weaponModule = nil
ViewmodelRot.viewmodel = nil

ViewmodelRot.targetRotation = 0
ViewmodelRot.currentRotation = 0

ViewmodelRot.isMovingLeft = false
ViewmodelRot.isMovingRight = false

ViewmodelRot.isStrafingLeft = false
ViewmodelRot.isStrafingRight = false

function ViewmodelRot:Init(weaponModule, viewmodel)
    self.weaponModule = weaponModule
    self.viewmodel = viewmodel
end

function ViewmodelRot:OnLeftPressed(callback)
    return self.KeyEvents.LeftPressed.Event:Connect(callback)
end

function ViewmodelRot:OnLeftReleased(callback)
    return self.KeyEvents.LeftReleased.Event:Connect(callback)
end

function ViewmodelRot:OnRightPressed(callback)
    return self.KeyEvents.RightPressed.Event:Connect(callback)
end

function ViewmodelRot:OnRightReleased(callback)
    return self.KeyEvents.RightReleased.Event:Connect(callback)
end

function ViewmodelRot:getRotation(dt, state)
    if not self.weaponModule or not self.viewmodel then
        return 0
    end

    if self.isStrafingLeft then
        if state == "Aiming" then
            self.targetRotation = -math.rad(-3.2) -- Negative for left
        else
            self.targetRotation = -math.rad(-7.5)
        end
    elseif self.isStrafingRight then
        if state == "Aiming" then
            self.targetRotation = -math.rad(3.2) -- Positive for right
        else
            self.targetRotation = -math.rad(7.5)
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
        ViewmodelRot.isStrafingLeft = true
        ViewmodelRot.isMovingLeft = true
        ViewmodelRot.KeyEvents.LeftPressed:Fire()
    elseif input.KeyCode == Enum.KeyCode.D then
        ViewmodelRot.isStrafingRight = true
        ViewmodelRot.isMovingRight = true
        ViewmodelRot.KeyEvents.RightPressed:Fire()
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    if input.KeyCode == Enum.KeyCode.A then
        ViewmodelRot.isStrafingLeft = false
        ViewmodelRot.isMovingLeft = false
        ViewmodelRot.KeyEvents.LeftReleased:Fire()
    elseif input.KeyCode == Enum.KeyCode.D then
        ViewmodelRot.isStrafingRight = false
        ViewmodelRot.isMovingRight = false
        ViewmodelRot.KeyEvents.RightReleased:Fire()
    end
end)

return ViewmodelRot