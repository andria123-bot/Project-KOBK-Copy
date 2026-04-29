local remoteManager = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemotesFolder = ReplicatedStorage.Shared.Remotes
local InventoryFolder = RemotesFolder.InventoryEvents
local RequestsFolder = RemotesFolder.Requests
local BindablesFolder = RemotesFolder.Bindables

local remoteEvents = {
	"SendKillFeedMessage",
	"UpdateWeaponState",
	"UpdateClientState",
	"PlayerRespawned",
	"MuzzlePos",
	"SyncProjectile",
	"PlayerAdded",
	"PlayerDied",
	"ItemFoley",
	"LoadSlot",
	"Grenade",
	"Killed",
	"Melee",
}

local inventoryRemotes = {
	"RequestInventory",
	"InventoryUpdate",
	"PlayerSlotData",
	"SendInventory",
}

local remoteFunctions = {
	"RequestWeaponSystemData",
	"RequestWeaponCategory",
	"RequestWeaponData",
	"ShootValidation",
	"RequestReload",
	"RequestModule",
	"RequestShoot",
	"RequestGear",
	"MoveItem",
}

local bindableEvents = {
}

local bindableFunctions = {
	"RequestPlayerData",
}

for _, name in ipairs(remoteEvents) do
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = RemotesFolder
	remoteManager[name .. "Remote"] = remote
end

for _, name in ipairs(inventoryRemotes) do
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = InventoryFolder
	remoteManager[name .. "Remote"] = remote
end

for _, name in ipairs(remoteFunctions) do
	local remote = Instance.new("RemoteFunction")
	remote.Name = name
	remote.Parent = RequestsFolder
	remoteManager[name .. "Remote"] = remote
end

for _, name in ipairs(bindableEvents) do
	local remote = Instance.new("BindableEvent")
	remote.Name = name
	remote.Parent = BindablesFolder
	remoteManager[name .. "Bindable"] = remote
end

for _, name in ipairs(bindableFunctions) do
	local remote = Instance.new("BindableFunction")
	remote.Name = name
	remote.Parent = BindablesFolder
	remoteManager[name .. "Bindable"] = remote
end

return remoteManager