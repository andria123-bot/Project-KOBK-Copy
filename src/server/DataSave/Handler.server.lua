local Players = game:GetService("Players")
local ProfileManager = require(script.Parent.ProfileManager)

Players.PlayerAdded:Connect(function(player)
    ProfileManager.LoadProfile(player)
end)

Players.PlayerRemoving:Connect(function(player)
    ProfileManager.ReleaseProfile(player)
end)