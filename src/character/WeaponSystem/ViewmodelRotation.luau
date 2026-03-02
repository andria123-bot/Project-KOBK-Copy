local ViewmodelRotation = {}

local UIS = game:GetService("UserInputService")

ViewmodelRotation.weaponModule = nil
ViewmodelRotation.viewmodel = nil
ViewmodelRotation.aimPart = nil

ViewmodelRotation.targetRotation = 0
ViewmodelRotation.currentRotation = 0

ViewmodelRotation.targetAimRotation = 0
ViewmodelRotation.currentAimRotation = 0

ViewmodelRotation.isMovingLeft = false
ViewmodelRotation.isMovingRight = false

function ViewmodelRotation:Init(weaponModule, viewmodel, aimPart)
    self.weaponModule = weaponModule
    self.viewmodel = viewmodel
    self.aimPart = aimPart
end

function ViewmodelRotation:getRotation(dt, moveDirection, isAiming)
    if not self.weaponModule or not self.viewmodel then
        return 0
    end

    if moveDirection 
        and moveDirection.X ~= 0 
        and (self.isMovingLeft or self.isMovingRight) then
        
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
    elseif input.KeyCode == Enum.KeyCode.D then
        ViewmodelRotation.isMovingRight = true
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

    if input.KeyCode == Enum.KeyCode.A then
        ViewmodelRotation.isMovingLeft = false
    elseif input.KeyCode == Enum.KeyCode.D then
        ViewmodelRotation.isMovingRight = false
    end
end)

return ViewmodelRotation