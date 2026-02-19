local owner = "andria_noobpro"
local admins = {"stickman132456", "LeoLintula"}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

local ownerPopupTemplate = ReplicatedStorage:WaitForChild("GUIS"):WaitForChild("OwnerPopup")

local function showPopupForAll(message)
	for _, player in ipairs(Players:GetPlayers()) do
		local ownerPopupGui = ownerPopupTemplate:Clone()
		local ownerPopupText = ownerPopupGui:WaitForChild("TextPopup")
		ownerPopupText.Text = message
		ownerPopupText.TextTransparency = 0
		ownerPopupGui.Parent = player:WaitForChild("PlayerGui")

		local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
		local fadeTween = TweenService:Create(ownerPopupText, tweenInfo, { TextTransparency = 1 })

		task.delay(5, function()
			fadeTween:Play()
		end)

		Debris:AddItem(ownerPopupGui, 5.5)
	end
end

Players.PlayerAdded:Connect(function(player)
	if player.Name == owner then
		showPopupForAll("Owner " .. player.Name .. " has joined the experience")
	elseif table.find(admins, player.Name) then
		showPopupForAll("Admin " .. player.Name .. " has joined the experience")
	end
end)
