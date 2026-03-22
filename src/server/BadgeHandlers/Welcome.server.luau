local badgeId = 3611308014952425
local BadgeService = game:GetService("BadgeService")

game.Players.PlayerAdded:Connect(function(player)
	local hasBadge = BadgeService:UserHasBadgeAsync(player.UserId, badgeId)
	
	if not(hasBadge) then
		BadgeService:AwardBadge(player.UserId, badgeId)
	end
end)