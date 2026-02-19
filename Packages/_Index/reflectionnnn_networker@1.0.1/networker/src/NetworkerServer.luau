--!strict

local ERROR_ATTEMPT_CLIENT_CONSTRUCT = "Attempt to construct server networker from client"
local ERROR_TAG_ALREADY_EXIST = "Attempt to construct server networker with already existing tag"

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Janitor = require(script.Parent.Parent.Janitor)
local NetworkerUtils = require(script.Parent.NetworkerUtils)
local GlobalRemoteContainer = NetworkerUtils.GetRemoteContainer()

type PlayerGroup = { Player }
type Janitor = typeof(Janitor.new())

local NetworkerServer = {}
NetworkerServer.__index = NetworkerServer

export type NetworkerServer = typeof(setmetatable(
	{} :: {
		_janitor: Janitor,
		_tag: string,
		_module: any,

		_clientAccess: { [string]: boolean },
		_container: Folder,

		_remoteEvent: RemoteEvent,
		_remoteFunction: RemoteFunction,
		_unreliableRemoteEvent: UnreliableRemoteEvent,
	},
	NetworkerServer
))

function NetworkerServer.new(tag: string, module: any): NetworkerServer
	assert(RunService:IsServer(), ERROR_ATTEMPT_CLIENT_CONSTRUCT)
	assert(GlobalRemoteContainer:FindFirstChild(tag) == nil, ERROR_TAG_ALREADY_EXIST)

	local self = setmetatable({}, NetworkerServer) :: NetworkerServer
	self._janitor = Janitor.new()

	self._tag = tag
	self._clientAccess = {}

	self._module = module

	self._container = self._janitor:Add(Instance.new("Folder"))
	self._container.Name = tag
	self._container.Parent = GlobalRemoteContainer

	self._remoteEvent = Instance.new("RemoteEvent")
	self._unreliableRemoteEvent = Instance.new("UnreliableRemoteEvent")
	self._remoteFunction = Instance.new("RemoteFunction")

	self._remoteEvent.Parent = self._container
	self._unreliableRemoteEvent.Parent = self._container
	self._remoteFunction.Parent = self._container

	self._remoteEvent.OnServerEvent:Connect(function(...: any)
		self:_callback(...)
	end)

	self._unreliableRemoteEvent.OnServerEvent:Connect(function(...: any)
		self:_callback(...)
	end)

	self._remoteFunction.OnServerInvoke = function(...: any)
		return self:_callback(...)
	end

	return self
end

function NetworkerServer._callback(self: NetworkerServer, player: Player, tag: string, ...: any): ...any?
	if tag == NetworkerUtils.TAGS.METHOD then
		return self:_methodCallback(player, ...)
	elseif tag == NetworkerUtils.TAGS.GET then
		return self:_getCallback(...)
	else
		warn(`Invalid tag: "{tag}"`)
	end
end

function NetworkerServer._methodCallback(self: NetworkerServer, player: Player, methodName: string, ...: any?): ...any?
	if self._clientAccess[methodName] and typeof(self._module[methodName]) == "function" then
		return self._module[methodName](self._module, player, ...)
	else
		warn(`Method "{methodName}" is restricted or isn't a function`)
		return
	end
end

function NetworkerServer._getCallback(self: NetworkerServer, key: any): any?
	if self._clientAccess[key] and typeof(self._module[key]) ~= "function" then
		return self._module[key]
	else
		warn(`Key "{key}" is restricted from client or is a method`)
		return
	end
end

function NetworkerServer.AddClientAccess(self: NetworkerServer, keys: { string }): ()
	for _, key in keys do
		if self._clientAccess[key] then
			warn(`Key {key} already added to client access`)
			continue
		end

		self._clientAccess[key] = true
	end
end

function NetworkerServer.FireMethod(self: NetworkerServer, player: Player, methodName: string, ...: any?): ()
	self._remoteEvent:FireClient(player, NetworkerUtils.TAGS.METHOD, methodName, ...)
end

function NetworkerServer.FireMethodUnreliable(self: NetworkerServer, player: Player, methodName: string, ...: any?): ()
	self._unreliableRemoteEvent:FireClient(player, NetworkerUtils.TAGS.METHOD, methodName, ...)
end

function NetworkerServer.FireMethodAll(self: NetworkerServer, methodName: string, ...: any?): ()
	self._remoteEvent:FireAllClients(NetworkerUtils.TAGS.METHOD, methodName, ...)
end

function NetworkerServer.FireMethodAllUnreliable(self: NetworkerServer, methodName: string, ...: any?): ()
	self._unreliableRemoteEvent:FireAllClients(NetworkerUtils.TAGS.METHOD, methodName, ...)
end

function NetworkerServer.FireMethodAllExcept(
	self: NetworkerServer,
	except: PlayerGroup,
	methodName: string,
	...: any?
): ()
	for _, player in Players:GetPlayers() do
		if not table.find(except, player) then
			self._remoteEvent:FireClient(player, NetworkerUtils.TAGS.METHOD, methodName, ...)
		end
	end
end

function NetworkerServer.FireMethodAllExceptUnreliable(
	self: NetworkerServer,
	except: PlayerGroup,
	methodName: string,
	...: any?
): ()
	for _, player in Players:GetPlayers() do
		if not table.find(except, player) then
			self._unreliableRemoteEvent:FireClient(player, NetworkerUtils.TAGS.METHOD, methodName, ...)
		end
	end
end

function NetworkerServer.InvokeMethod(self: NetworkerServer, player: Player, methodName: string, ...: any?): ...any?
	return self._remoteFunction:InvokeClient(player, NetworkerUtils.TAGS.METHOD, methodName, ...)
end

function NetworkerServer.Set(self: NetworkerServer, player: Player, key: any, value: any?): ()
	self._remoteEvent:FireClient(player, NetworkerUtils.TAGS.SET, key, value)
end

function NetworkerServer.Get(self: NetworkerServer, player: Player, key: any): any?
	return self._remoteFunction:InvokeClient(player, NetworkerUtils.TAGS.GET, key)
end

function NetworkerServer.Destroy(self: NetworkerServer): ()
	self._janitor:Destroy()
	setmetatable(self :: any, nil)
	table.clear(self :: any)
end

return NetworkerServer
