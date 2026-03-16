local moduleFinder = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local camera = game.workspace.CurrentCamera


local moduleFolder = game.ReplicatedStorage.Shared:FindFirstChild("Modules")

local primaryModulesFolder = moduleFolder:FindFirstChild("Primary")
local secondaryModulesFolder = moduleFolder:FindFirstChild("Secondary")
local danebisModulesFolder = moduleFolder:FindFirstChild("Danebi")
local throwableModulesFolder = moduleFolder:FindFirstChild("Throwables")

local weaponCategories = require(script.Parent.WeaponCategories)

function moduleFinder.GetModule(Item)
	if not Item then
		print("Item name is required")
		return nil
	end
	
	if Item ~= "Nil" and weaponCategories then
        local moduleToClone

        if not moduleToClone then
            for _, category in ipairs(weaponCategories.primaryCategories) do
                local moduleCategory = primaryModulesFolder:FindFirstChild(category)
                if moduleCategory then
                    moduleToClone = moduleCategory:FindFirstChild(Item)
                    if moduleToClone then break end
                end
            end
        end

        if not moduleToClone then
            for _, category in ipairs(weaponCategories.secondaryCategories) do
                local moduleCategory = secondaryModulesFolder:FindFirstChild(category)
                if moduleCategory then
                    moduleToClone = moduleCategory:FindFirstChild(Item)
                    if moduleToClone then break end
                end
            end
        end

        if not moduleToClone then
            for _, category in ipairs(weaponCategories.danebisCategories) do
                local moduleCategory = danebisModulesFolder:FindFirstChild(category)
                if moduleCategory then
                    moduleToClone = moduleCategory:FindFirstChild(Item)
                    if moduleToClone then break end
                end
            end
        end

        if not moduleToClone then
            for _, category in ipairs(weaponCategories.throwableCategories) do
                local moduleCategory = throwableModulesFolder:FindFirstChild(category)
                if moduleCategory then
                    moduleToClone = moduleCategory:FindFirstChild(Item)
                    if moduleToClone then break end
                end
            end
        end

        if not moduleToClone then
            for _, category in ipairs(weaponCategories.throwableCategories) do
                local moduleCategory = throwableModulesFolder:FindFirstChild(category)
                if moduleCategory then
                    moduleToClone = moduleCategory:FindFirstChild(Item)
                    if moduleToClone then break end
                end
            end
        end

        if moduleToClone then
			local clonedModule = moduleToClone

			return require(clonedModule)
		else
			warn("No module found for item: " .. Item)
			return nil
		end
    end
end

return moduleFinder;