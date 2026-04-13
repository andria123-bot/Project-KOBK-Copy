local remoteManager = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemotesFolder = ReplicatedStorage.Shared.Remotes
local InventoryFolder = RemotesFolder.InventoryEvents
local RequestsFolder = RemotesFolder.Requests

local remoteEvents = {
	"UpdateWeaponState",
	"UpdateClientState",
	"PlayerRespawned",
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
	"RequestReload",
	"RequestModule",
	"RequestShoot",
	"RequestGear",
	"MoveItem",
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

return remoteManager