local NetworkerServer = require(script.NetworkerServer)
local NetworkerClient = require(script.NetworkerClient)

export type Server = NetworkerServer.NetworkerServer
export type Client = NetworkerClient.NetworkerClient

return {
	Server = NetworkerServer,
	Client = NetworkerClient
}