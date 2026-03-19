local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RequestModule = ReplicatedStorage.Shared.Remotes:WaitForChild("RequestModule")

RequestModule.OnServerEvent:Connect(function(player, backpackName)
    print(backpackName)
end)