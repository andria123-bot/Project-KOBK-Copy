local badgeId = 744598781046478
local BadgeService = game:GetService("BadgeService")
local ownerName = "andria_noobpro"

local function AwardBadgeToAll()
    local owner = game.Players:FindFirstChild(ownerName)
    if not owner then return end
    
    for _, player in pairs(game.Players:GetPlayers()) do
        task.spawn(function()
            local success, hasBadge = pcall(function()
                return BadgeService:UserHasBadgeAsync(player.UserId, badgeId)
            end)
            
            if success and not hasBadge then
                BadgeService:AwardBadge(player.UserId, badgeId)
                print("Badge awarded to:", player.Name)
            end
        end)
    end
end

game.Players.PlayerAdded:Connect(function(player)
    AwardBadgeToAll()
end)

AwardBadgeToAll()