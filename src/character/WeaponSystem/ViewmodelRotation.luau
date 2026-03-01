local ViewmodelRotation = {}

local UIS = game:GetService("UserInputService")

ViewmodelRotation.weaponModule = nil
ViewmodelRotation.viewmodel = nil
ViewmodelRotation.aimPart = nil
ViewmodelRotation.targetRotation = 0
ViewmodelRotation.currentRotation = 0
ViewmodelRotation.targetAimRotation = 0
ViewmodelRotation.currentAimRotation = 0
ViewmodelRotation.isMoving = nil

function ViewmodelRotation:Init(weaponModule, viewmodel, aimPart)
    self.weaponModule = weaponModule
    self.viewmodel = viewmodel
    self.aimPart = aimPart
end

function ViewmodelRotation:getRotation(dt, moveDirection, isAiming)
    if self.weaponModule ~= nil and self.viewmodel then
        if moveDirection and moveDirection.X ~= 0 and self.isMoving == "A" or self.isMoving == "D" then
            if isAiming then
                self.targetRotation = math.rad(3.2) * moveDirection.X
            else
                self.targetRotation = math.rad(7.5) * moveDirection.X
            end
        else
            self.targetRotation = 0
        end

        self.currentRotation = self.currentRotation + (self.targetRotation - self.currentRotation) * math.min(.7, 5 * dt)

        return self.currentRotation
    else
        return
    end
end

UIS.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.A then
        ViewmodelRotation.isMoving = "A"
    elseif input.KeyCode == Enum.KeyCode.D then
        ViewmodelRotation.isMoving = "D"
    end
end)

return ViewmodelRotation