local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local UIS = game:GetService("UserInputService")
local camera = game.Workspace.Camera
local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")

RunService.RenderStepped:Connect(function(dt)
	if humanoid then
		if humanoid.MoveDirection.Magnitude > 0 then
			local headBobY = math.sin(tick() * 7) * 0.2

			if humanoid.WalkSpeed > 15 then
				headBobY = math.sin(tick() * 10) * 0.2
			elseif humanoid.WalkSpeed == 22 then
				headBobY = math.sin(tick() * 20) * 0.4
			end

			local bob = Vector3.new(0, headBobY, 0)
			
			humanoid.CameraOffset = humanoid.CameraOffset:Lerp(bob, 1-0.01^dt)
		else
			humanoid.CameraOffset = humanoid.CameraOffset:Lerp(Vector3.new(), 1-0.01^dt)
		end
	end
end)

UIS.InputBegan:Connect(function(input)
    if humanoid then
        if input.KeyCode == Enum.KeyCode.LeftShift then
            humanoid.WalkSpeed = 22
        end
    end
end)

UIS.InputEnded:Connect(function(input)
    if humanoid then
        if input.KeyCode == Enum.KeyCode.LeftShift then
            humanoid.WalkSpeed = 16
        end
    end
end)

-- game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
humanoid.BreakJointsOnDeath = false
UIS.MouseIconEnabled = false