local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local menu = playerGui:WaitForChild("Menu")

local serverSelectorGuiTemplate = ReplicatedStorage:WaitForChild("GUIS"):WaitForChild("ServerSelectorGui")
local serverSelectorGui = serverSelectorGuiTemplate:Clone()
serverSelectorGui.Parent = playerGui
serverSelectorGui.Enabled = false

local camera = Workspace.CurrentCamera
local maxDistance = 10
local currentBot = nil

local function getDistanceToBot(bot)
	if bot and player.Character and player.Character.PrimaryPart and bot.PrimaryPart then
		return (player.Character.PrimaryPart.Position - bot.PrimaryPart.Position).Magnitude
	end
	return math.huge
end

local function findBotInFront()
	local origin = camera.CFrame.Position
	local direction = camera.CFrame.LookVector

	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {player.Character}
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

	local result = Workspace:Raycast(origin, direction * maxDistance, raycastParams)
	if result then
		local model = result.Instance:FindFirstAncestor("ServerBot")
		if model then
			return model
		end
	end
	return nil
end

RunService.RenderStepped:Connect(function()
	if serverSelectorGui.Enabled and currentBot then
		if getDistanceToBot(currentBot) > maxDistance then
			serverSelectorGui.Enabled = false
			currentBot = nil
		end
	end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.F then
		if serverSelectorGui.Enabled then
			serverSelectorGui.Enabled = false
			currentBot = nil
		else
			local bot = findBotInFront()
			if bot then
				menu.Enabled = false
				serverSelectorGui.Enabled = true
				currentBot = bot
			end
		end
	end

	if input.KeyCode == Enum.KeyCode.Tab then
		menu.Enabled = not menu.Enabled

		if menu.Enabled then
			local mainParent = menu.MainParent
			mainParent.VicinityParent.VicinityGUI.Visible = true
			mainParent.VicinityParent.SmallMilCrateScrollingFrame.Visible = false

			serverSelectorGui.Enabled = false
			currentBot = nil
		end
	end
end)

