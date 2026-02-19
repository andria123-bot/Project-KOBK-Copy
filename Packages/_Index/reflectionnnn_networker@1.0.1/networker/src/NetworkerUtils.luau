--!strict

local CONTAINER_NAME = "NetworkerContainer"

local TAGS = {
	METHOD = "Method",
	SET = "Set",
	GET = "Get"
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local RemoteContainer: Folder? = nil

local function GetRemoteContainer(): Folder
		if RunService:IsClient() then
		return ReplicatedStorage:WaitForChild(CONTAINER_NAME) :: Folder
	end
	
	if not RemoteContainer then
		local remoteContainer = Instance.new("Folder")
		remoteContainer.Name = CONTAINER_NAME
		remoteContainer.Parent = ReplicatedStorage

		RemoteContainer = remoteContainer
		return remoteContainer
	else
		return RemoteContainer
	end
end

return {
	GetRemoteContainer = GetRemoteContainer,
	TAGS = TAGS
}