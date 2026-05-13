local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RequestModule = ReplicatedStorage.Shared.Remotes.Requests:WaitForChild("RequestModule")
local RequestWeaponCategory = ReplicatedStorage.Shared.Remotes.Requests:WaitForChild("RequestWeaponCategory")

local LoadModule = require(script.Parent.LoadModule)
local WeaponCategory = require(script.Parent.WeaponCategories)
local ItemList = require(ReplicatedStorage.Shared.Modules.ItemList)

local VALID_ITEMS = {}
for _, items in pairs(ItemList) do
    if type(items) == "table" then
        for _, itemName in ipairs(items) do
            VALID_ITEMS[itemName] = true
        end
    end
end

local requestCount = {}  -- Track requests per second instead

local function isValidItem(itemName)
    return VALID_ITEMS[itemName] == true
end

RequestWeaponCategory.OnServerInvoke = function(player)
    return WeaponCategory
end

RequestModule.OnServerInvoke = function(player, Item)
    if not player then return nil end
    if Item == "" then return nil end
    
    local now = tick()
    if not requestCount[player] then
        requestCount[player] = {count = 0, resetTime = now + 1}
    end
    
    if requestCount[player].resetTime <= now then
        requestCount[player].count = 0
        requestCount[player].resetTime = now + 1
    end
    
    requestCount[player].count = requestCount[player].count + 1
    
    if requestCount[player].count > 30 then
        warn(player.Name, "is spamming requests! Count:", requestCount[player].count)
        return nil
    end

    if type(Item) ~= "string" or #Item > 50 then
        warn(player.Name, "invalid item name:", Item)
        return nil
    end

    if not isValidItem(Item) then
        warn(player.Name, "tried to request invalid item:", Item)
        return nil
    end

    local module = LoadModule.GetModule(Item)
    if module then
        return require(module)
    end
    return nil
end