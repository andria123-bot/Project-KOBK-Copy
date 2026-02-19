local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportRequest = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Teleports"):WaitForChild("TeleportRequest")

local placeIds = {
	[1] = 136672823254698,     -- Server 1
	--[2] = 108788006452709,    -- Server 2
	--[3] = 79122342257249,     -- Server 3
}

TeleportRequest.OnServerEvent:Connect(function(player, placeNum)
	local placeId = placeIds[placeNum]

	if placeId then
		TeleportService:TeleportAsync(placeId, {player})
	else
		warn("Invalid placeNum received:", placeNum)
	end
end)
