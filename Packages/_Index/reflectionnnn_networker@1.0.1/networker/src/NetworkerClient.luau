--!strict

local ERROR_ATTEMPT_SERVER_CONSTRUCT = "Attempt to construct client networker from server"
local ERROR_MISSING_CONTAINER = "Missing networker container, make sure server networker by that tag exist"
local CONTAINER_WAIT_TIMEOUT = 5

local RunService = game:GetService("RunService")

local Janitor = require(script.Parent.Parent.Janitor)
local NetworkerUtils = require(script.Parent.NetworkerUtils)
local GlobalRemoteContainer = NetworkerUtils.GetRemoteContainer()

type Janitor = typeof(Janitor.new())

local NetworkerClient = {}
NetworkerClient.__index = NetworkerClient

export type NetworkerClient = typeof(setmetatable(
	{} :: {
		_janitor: Janitor,
		_tag: string,
		_module: any,

		_container: Folder,

		_remoteEvent: RemoteEvent,
		_unreliableRemoteEvent: UnreliableRemoteEvent,
		_remoteFunction: RemoteFunction,
	},
	NetworkerClient
))

function NetworkerClient.new(tag: string, module: any): NetworkerClient
	assert(RunService:IsClient(), ERROR_ATTEMPT_SERVER_CONSTRUCT)

	local self = setmetatable({}, NetworkerClient) :: NetworkerClient
	self._janitor = Janitor.new()

	self._tag = tag
	self._module = module

	self._container =
		assert(GlobalRemoteContainer:WaitForChild(tag, CONTAINER_WAIT_TIMEOUT) :: Folder, ERROR_MISSING_CONTAINER)

	self._remoteEvent = self._container:WaitForChild("RemoteEvent") :: RemoteEvent
	self._unreliableRemoteEvent = self._container:WaitForChild("UnreliableRemoteEvent") :: UnreliableRemoteEvent
	self._remoteFunction = self._container:WaitForChild("RemoteFunction") :: RemoteFunction

	self._janitor:Add(self._remoteEvent.OnClientEvent:Connect(function(...: any)
		self:_callback(...)
	end))

	self._janitor:Add(self._unreliableRemoteEvent.OnClientEvent:Connect(function(...: any)
		self:_callback(...)
	end))

	self._remoteFunction.OnClientInvoke = function(...: any)
		return self:_callback(...)
	end

	self._janitor:Add(function()
		self._remoteFunction.OnClientInvoke = function()
			return
		end
	end)

	return self
end

function NetworkerClient._callback(self: NetworkerClient, tag: string, ...: any): ...any?
	if tag == NetworkerUtils.TAGS.METHOD then
		return self:_methodCallback(...)
	elseif tag == NetworkerUtils.TAGS.SET then
		self:_setCallback(...)
	elseif tag == NetworkerUtils.TAGS.GET then
		return self:_getCallback(...)
	else
		error(`Invalid tag: "{tag}"`)
	end
end

function NetworkerClient._methodCallback(self: NetworkerClient, methodName: string, ...: any?): ...any?
	if typeof(self._module[methodName]) == "function" then
		return self._module[methodName](self._module, ...)
	end
end

function NetworkerClient._setCallback(self: NetworkerClient, key: any, value: any?): ()
	self._module[key] = value
end

function NetworkerClient._getCallback(self: NetworkerClient, key: any): any?
	return self._module[key]
end

function NetworkerClient.FireMethod(self: NetworkerClient, methodName: string, ...: any?): ()
	self._remoteEvent:FireServer(NetworkerUtils.TAGS.METHOD, methodName, ...)
end

function NetworkerClient.FireMethodUnreliable(self: NetworkerClient, methodName: string, ...: any?): ()
	self._unreliableRemoteEvent:FireServer(NetworkerUtils.TAGS.METHOD, methodName, ...)
end

function NetworkerClient.InvokeMethod(self: NetworkerClient, methodName: string, ...: any?): any?
	return self._remoteFunction:InvokeServer(NetworkerUtils.TAGS.METHOD, methodName, ...)
end

function NetworkerClient.Get(self: NetworkerClient, key: any): any?
	return self._remoteFunction:InvokeServer(NetworkerUtils.TAGS.GET, key)
end

function NetworkerClient.Destroy(self: NetworkerClient): ()
	self._janitor:Destroy()
	setmetatable(self :: any, nil)
	table.clear(self :: any)
end

return NetworkerClient
