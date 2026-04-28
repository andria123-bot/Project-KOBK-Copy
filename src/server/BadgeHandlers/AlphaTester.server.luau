local playerIds = {
    [4567910353] = true,
    [3582529737] = true, 
    [1194305234] = true,
    [1210653126] = true,
    [7162629627] = true,
    [4381811563] = true,
    [3092110782] = true,
}
local badgeId = 4421489520473847
local BadgeService = game:GetService("BadgeService")

game.Players.PlayerAdded:Connect(function(player)
    task.spawn(function()
        if playerIds[player.UserId] then
            local success, hasBadge = pcall(function()
                return BadgeService:UserHasBadgeAsync(player.UserId, badgeId)
            end)
            
            if success and not hasBadge then
                BadgeService:AwardBadge(player.UserId, badgeId)
            end
        end
    end)
end)