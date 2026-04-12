local remoteManager = {}

local ReplicatedStorage = game:GetService('ReplicatedStorage')

remoteManager.ShootRemote = Instance.new("RemoteEvent")
remoteManager.ShootRemote.Parent = ReplicatedStorage.Shared.Remotes
remoteManager.ShootRemote.Name = "Shoot"

remoteManager.UpdateWeaponStatsRemote = Instance.new("RemoteEvent")
remoteManager.UpdateWeaponStatsRemote.Parent = ReplicatedStorage.Shared.Remotes
remoteManager.UpdateWeaponStatsRemote.Name = "UpdateWeaponStats"

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

remoteManager.PlayerRespawnedRemote = Instance.new("RemoteEvent")
remoteManager.PlayerRespawnedRemote.Parent = ReplicatedStorage.Shared.Remotes
remoteManager.PlayerRespawnedRemote.Name = "PlayerRespawned"

remoteManager.GrenadeRemote = Instance.new("RemoteEvent")
remoteManager.GrenadeRemote.Parent = ReplicatedStorage.Shared.Remotes
remoteManager.GrenadeRemote.Name = "Grenade"

remoteManager.MeleeRemote = Instance.new("RemoteEvent")
remoteManager.MeleeRemote.Parent = ReplicatedStorage.Shared.Remotes
remoteManager.MeleeRemote.Name = "Melee"

remoteManager.KilledRemote = Instance.new("RemoteEvent")
remoteManager.KilledRemote.Parent = ReplicatedStorage.Shared.Remotes
remoteManager.KilledRemote.Name = "Killed"

remoteManager.RequestInventoryRemote = Instance.new("RemoteEvent")
remoteManager.RequestInventoryRemote.Parent = ReplicatedStorage.Shared.Remotes.InventoryEvents
remoteManager.RequestInventoryRemote.Name = "RequestInventory"

remoteManager.SendInventoryRemote = Instance.new("RemoteEvent")
remoteManager.SendInventoryRemote.Parent = ReplicatedStorage.Shared.Remotes.InventoryEvents
remoteManager.SendInventoryRemote.Name = "SendInventory"

remoteManager.InventoryUpdateRemote = Instance.new("RemoteEvent")
remoteManager.InventoryUpdateRemote.Parent = ReplicatedStorage.Shared.Remotes.InventoryEvents
remoteManager.InventoryUpdateRemote.Name = "InventoryUpdate"

remoteManager.MoveItemRemote = Instance.new("RemoteEvent")
remoteManager.MoveItemRemote.Parent = ReplicatedStorage.Shared.Remotes.InventoryEvents
remoteManager.MoveItemRemote.Name = "MoveItem"

remoteManager.PlayerSlotDataRemote = Instance.new("RemoteEvent")
remoteManager.PlayerSlotDataRemote.Parent = ReplicatedStorage.Shared.Remotes.InventoryEvents
remoteManager.PlayerSlotDataRemote.Name = "PlayerSlotData"

remoteManager.RequestGearRemote = Instance.new("RemoteFunction")
remoteManager.RequestGearRemote.Parent = ReplicatedStorage.Shared.Remotes.Requests
remoteManager.RequestGearRemote.Name = "RequestGear"

remoteManager.RequestModuleRemote = Instance.new("RemoteFunction")
remoteManager.RequestModuleRemote.Parent = ReplicatedStorage.Shared.Remotes.Requests
remoteManager.RequestModuleRemote.Name = "RequestModule"

remoteManager.RequestWeaponCategoryRemote = Instance.new("RemoteFunction")
remoteManager.RequestWeaponCategoryRemote.Parent = ReplicatedStorage.Shared.Remotes.Requests
remoteManager.RequestWeaponCategoryRemote.Name = "RequestWeaponCategory"

remoteManager.RequestWeaponDataRemote = Instance.new("RemoteFunction")
remoteManager.RequestWeaponDataRemote.Parent = ReplicatedStorage.Shared.Remotes.Requests
remoteManager.RequestWeaponDataRemote.Name = "RequestWeaponData"

remoteManager.RequestWeaponSystemDataRemote = Instance.new("RemoteFunction")
remoteManager.RequestWeaponSystemDataRemote.Parent = ReplicatedStorage.Shared.Remotes.Requests
remoteManager.RequestWeaponSystemDataRemote.Name = "RequestWeaponSystemData"

remoteManager.UpdateWeaponStateRemote = Instance.new("RemoteEvent")
remoteManager.UpdateWeaponStateRemote.Parent = ReplicatedStorage.Shared.Remotes
remoteManager.UpdateWeaponStateRemote.Name = "UpdateWeaponState"

remoteManager.RequestShootRemote = Instance.new("RemoteFunction")
remoteManager.RequestShootRemote.Parent = ReplicatedStorage.Shared.Remotes.Requests
remoteManager.RequestShootRemote.Name = "RequestShoot"

remoteManager.RequestReloadRemote = Instance.new("RemoteFunction")
remoteManager.RequestReloadRemote.Parent = ReplicatedStorage.Shared.Remotes.Requests
remoteManager.RequestReloadRemote.Name = "RequestReload"

remoteManager.UpdateClientStateRemote = Instance.new("RemoteEvent")
remoteManager.UpdateClientStateRemote.Parent = ReplicatedStorage.Shared.Remotes
remoteManager.UpdateClientStateRemote.Name = "UpdateClientState"

return remoteManager