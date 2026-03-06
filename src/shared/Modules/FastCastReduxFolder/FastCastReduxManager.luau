local fastCastReduxManager = {}

local ReplicatedStorage = game:GetService('ReplicatedStorage')

local FastCastRedux = ReplicatedStorage.Shared.Modules.FastCastReduxFolder.FastCastRedux
local ActiveCast = ReplicatedStorage.Shared.Modules.FastCastReduxFolder.ActiveCast
local Signal = ReplicatedStorage.Shared.Modules.FastCastReduxFolder.Signal
local Table = ReplicatedStorage.Shared.Modules.FastCastReduxFolder.Table
local TypeDefinitions = ReplicatedStorage.Shared.Modules.FastCastReduxFolder.TypeDefinitions
local TypeMarshaller = ReplicatedStorage.Shared.Modules.FastCastReduxFolder.TypeMarshaller

function fastCastReduxManager:changeParent()
    ActiveCast.Parent = FastCastRedux
    Signal.Parent = FastCastRedux
    Table.Parent = FastCastRedux
    TypeDefinitions.Parent = FastCastRedux
    TypeMarshaller.Parent = FastCastRedux
end

return fastCastReduxManager