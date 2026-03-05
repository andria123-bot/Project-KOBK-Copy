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

ViewmodelRotation.targetRotation = 0
ViewmodelRotation.currentRotation = 0

ViewmodelRotation.isMovingLeft = false
ViewmodelRotation.isMovingRight = false

ViewmodelRotation.isStrafingLeft = false
ViewmodelRotation.isStrafingRight = false

function ViewmodelRotation:Init(weaponModule, viewmodel)
    self.weaponModule = weaponModule
    self.viewmodel = viewmodel
end

print("GGG", ViewmodelRotation.weaponModule)
local state = ViewmodelRotation.weaponModule.state

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

function ViewmodelRotation:getRotation(dt)
    if not self.weaponModule or not self.viewmodel then
        return 0
    end

    if self.isStrafingLeft then
        if state == "Aiming" then
            print(1)
            self.targetRotation = -math.rad(-3.2) -- Negative for left
        else
            self.targetRotation = -math.rad(-7.5)
        end
    elseif self.isStrafingRight then
        if state == "Aiming" then
            print(12)
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
        ViewmodelRotation.isStrafingLeft = true
        ViewmodelRotation.isMovingLeft = true
        ViewmodelRotation.KeyEvents.LeftPressed:Fire()
    elseif input.KeyCode == Enum.KeyCode.D then
        ViewmodelRotation.isStrafingRight = true
        ViewmodelRotation.isMovingRight = true
        ViewmodelRotation.KeyEvents.RightPressed:Fire()
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

    if input.KeyCode == Enum.KeyCode.A then
        ViewmodelRotation.isStrafingLeft = false
        ViewmodelRotation.isMovingLeft = false
        ViewmodelRotation.KeyEvents.LeftReleased:Fire()
    elseif input.KeyCode == Enum.KeyCode.D then
        ViewmodelRotation.isStrafingRight = false
        ViewmodelRotation.isMovingRight = false
        ViewmodelRotation.KeyEvents.RightReleased:Fire()
    end
end)

return ViewmodelRotation