local badgeId = 744598781046478
local BadgeService = game:GetService("BadgeService")
local owner = "andria_noobpro"

game.Players.PlayerAdded:Connect(function(player)
	if player.Name == owner then
		for i, v in pairs(game.Players:GetPlayers()) do
			BadgeService:AwardBadge(player.UserId, badgeId)
		end
	elseif game.Players:FindFirstChild(owner) then
		BadgeService:AwardBadge(player.UserId, badgeId)	
	end
end)