local moduleFinder = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local moduleFolder = ReplicatedStorage.Shared:FindFirstChild("Modules")

local primaryModulesFolder = moduleFolder and moduleFolder:FindFirstChild("Primary")
local secondaryModulesFolder = moduleFolder and moduleFolder:FindFirstChild("Secondary")
local danebisModulesFolder = moduleFolder and moduleFolder:FindFirstChild("Danebi")
local throwableModulesFolder = moduleFolder and moduleFolder:FindFirstChild("Throwables")

local clothesModuleFolder = moduleFolder and moduleFolder:FindFirstChild("Clothes")

local weaponCategories = require(script.Parent.WeaponCategories)

function moduleFinder.FindModuleScript(Item)
	if not Item then
		print("Item name is required")
		return nil
	end
	
	if Item ~= "Nil" and weaponCategories then
        local moduleScript

        if not moduleScript and primaryModulesFolder then
            for _, category in ipairs(weaponCategories.primaryCategories) do
                local moduleCategory = primaryModulesFolder:FindFirstChild(category)
                if moduleCategory then
                    moduleScript = moduleCategory:FindFirstChild(Item)
                    if moduleScript then break end
                end
            end
        end

        if not moduleScript and secondaryModulesFolder then
            for _, category in ipairs(weaponCategories.secondaryCategories) do
                local moduleCategory = secondaryModulesFolder:FindFirstChild(category)
                if moduleCategory then
                    moduleScript = moduleCategory:FindFirstChild(Item)
                    if moduleScript then break end
                end
            end
        end

        if not moduleScript and danebisModulesFolder then
            for _, category in ipairs(weaponCategories.danebisCategories) do
                local moduleCategory = danebisModulesFolder:FindFirstChild(category)
                if moduleCategory then
                    moduleScript = moduleCategory:FindFirstChild(Item)
                    if moduleScript then break end
                end
            end
        end

        if not moduleScript and throwableModulesFolder then
            for _, category in ipairs(weaponCategories.throwableCategories) do
                local moduleCategory = throwableModulesFolder:FindFirstChild(category)
                if moduleCategory then
                    moduleScript = moduleCategory:FindFirstChild(Item)
                    if moduleScript then break end
                end
            end
        end

        if not moduleScript and clothesModuleFolder then
            for _, category in ipairs(weaponCategories.clothesCategories) do
                local moduleCategory = category
                if moduleCategory then
                    moduleScript = clothesModuleFolder:FindFirstChild(moduleCategory)
                end
            end
        end

        if moduleScript then
			return moduleScript
		else
			warn("No module script found for item: " .. Item)
			return nil
		end
    end
end

function moduleFinder.GetModule(Item)
    local moduleScript = moduleFinder.FindModuleScript(Item)
    if moduleScript then
        return moduleScript
    else
        return nil
    end
end

return moduleFinder