local remoteManager = {}

local ReplicatedStorage = game:GetService('ReplicatedStorage')

remoteManager.ShootRemote = Instance.new("RemoteEvent")
remoteManager.ShootRemote.Parent = ReplicatedStorage:WaitForChild("Shared").Remotes
remoteManager.ShootRemote.Name = "Shoot"

remoteManager.LoadSlotRemote = Instance.new("RemoteEvent")
remoteManager.LoadSlotRemote.Parent = ReplicatedStorage.Shared.Remotes
remoteManager.LoadSlotRemote.Name = "LoadSlot"

remoteManager.ItemFoleyRemote = Instance.new("RemoteEvent")
remoteManager.ItemFoleyRemote.Parent = ReplicatedStorage.Shared.Remotes
remoteManager.ItemFoleyRemote.Name = "ItemFoley"

remoteManager.PlayerAddedRemote = Instance.new("RemoteEvent")
remoteManager.PlayerAddedRemote.Parent = ReplicatedStorage.Shared.Remotes
remoteManager.PlayerAddedRemote.Name = "PlayerAdded"

remoteManager.PlayerDiedRemote = Instance.new("RemoteEvent")
remoteManager.PlayerDiedRemote.Parent = ReplicatedStorage.Shared.Remotes
remoteManager.PlayerDiedRemote.Name = "PlayerDied"

remoteManager.GrenadeRemote = Instance.new("RemoteEvent")
remoteManager.GrenadeRemote.Parent = ReplicatedStorage.Shared.Remotes
remoteManager.GrenadeRemote.Name = "Grenade"

remoteManager.MeleeRemote = Instance.new("RemoteEvent")
remoteManager.MeleeRemote.Parent = ReplicatedStorage.Shared.Remotes
remoteManager.MeleeRemote.Name = "Melee"

remoteManager.KilledRemote = Instance.new("RemoteEvent")
remoteManager.KilledRemote.Parent = ReplicatedStorage.Shared.Remotes
remoteManager.KilledRemote.Name = "Killed"

return remoteManager