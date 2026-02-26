local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remoteManagers = require(ReplicatedStorage.Shared.Remotes.RemoteManagers.RemoteManager)

game.ReplicatedStorage.Shared.Remotes.LoadSlot.OnServerEvent:Connect(function(player, SoundID, Volume)
    if player.character then
        for i, v in pairs(player.Character.UpperTorso:GetChildren()) do
            if v.Name == "FireSound" then
                v:Destroy()
            end
        end

        local fireSound = Instance.new("Sound")
        fireSound.Parent = player.character.UpperTorso
        fireSound.Name = "FireSound"
        fireSound.Volume = Volume
        fireSound.SoundId = SoundID
    end
end)

game.ReplicatedStorage.Shared.Remotes.Shoot.OnServerEvent:Connect(function(player)
    if player.Character then
        local sound = player.Character.UpperTorso:FindFirstChild("FireSound")

        if sound then
            sound:Play()
        end
    end
end)

game.Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		character:FindFirstChild("Humanoid").Died:Connect(function()
            ReplicatedStorage.Shared.Remotes:WaitForChild("PlayerDied"):FireClient(player)
            print("Fired from server.")
        end)
	end)
end)