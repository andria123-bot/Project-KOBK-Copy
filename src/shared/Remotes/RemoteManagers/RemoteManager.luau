local remoteManager = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemotesFolder = ReplicatedStorage.Shared.Remotes
local InventoryFolder = RemotesFolder.InventoryEvents
local RequestsFolder = RemotesFolder.Requests

local remoteEvents = {
	"LoadSlot",
	"ItemFoley",
	"PlayerRespawned",
	"PlayerAdded",
	"PlayerDied",
	"Grenade",
	"Melee",
	"Killed",
	"UpdateWeaponState",
	"UpdateClientState"
}

local inventoryRemotes = {
	"RequestInventory",
	"SendInventory",
	"InventoryUpdate",
	"MoveItem",
	"PlayerSlotData"
}

local remoteFunctions = {
	"RequestGear",
	"RequestModule",
	"RequestWeaponCategory",
	"RequestWeaponData",
	"RequestWeaponSystemData",
	"RequestShoot",
	"RequestReload"
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