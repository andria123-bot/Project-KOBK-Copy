local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UIS = game:GetService("UserInputService")
local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RequestWeaponSystemData = ReplicatedStorage.Shared.Remotes.Requests:WaitForChild("RequestWeaponSystemData")
local UpdateWeaponStateRemote = ReplicatedStorage.Shared.Remotes:WaitForChild("UpdateWeaponState")

local PlayerWeaponSystemData = RequestWeaponSystemData:InvokeServer()

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
			if PlayerWeaponSystemData[1].state ~= PlayerWeaponSystemData[1].states[2] then
				UpdateWeaponStateRemote:FireServer(PlayerWeaponSystemData[1].states[6])
				humanoid.WalkSpeed = 22
			end
        end
    end
end)

UIS.InputEnded:Connect(function(input)
    if humanoid then
        if input.KeyCode == Enum.KeyCode.LeftShift then
			UpdateWeaponStateRemote:FireServer(PlayerWeaponSystemData[1].states[1])
            humanoid.WalkSpeed = 16
        end
    end
end)

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)

local success = false

repeat
	success = pcall(function()
		StarterGui:SetCore("ResetButtonCallback", false)
	end)
	task.wait()
until success

game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
humanoid.BreakJointsOnDeath = false
UIS.MouseIconEnabled = false