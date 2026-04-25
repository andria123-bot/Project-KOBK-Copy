local badgeId = 3611308014952425
local BadgeService = game:GetService("BadgeService")

game.Players.PlayerAdded:Connect(function(player)
	task.spawn(function()
		local success, hasBadge = pcall(function()
			return BadgeService:UserHasBadgeAsync(player.UserId, badgeId)
		end)

		if success and not hasBadge then
			BadgeService:AwardBadge(player.UserId, badgeId)
		end
	end)
end)