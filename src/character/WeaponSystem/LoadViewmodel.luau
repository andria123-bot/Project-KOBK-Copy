local viewmodelFinder = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RequestWeaponCategory = ReplicatedStorage.Shared.Remotes.Requests:WaitForChild("RequestWeaponCategory")

local viewmodelsFolder = game.ReplicatedStorage:WaitForChild("Viewmodels")

local primaryViewmodelsFolder = viewmodelsFolder:FindFirstChild("Primary")
local secondaryViewmodelsFolder = viewmodelsFolder:FindFirstChild("Secondary")
local danebisViewmodelsFolder = viewmodelsFolder:FindFirstChild("Danebi")
local throwableViewmodelsFolder = viewmodelsFolder:FindFirstChild("Throwable")

local weaponCategories = RequestWeaponCategory:InvokeServer()

function viewmodelFinder.GetViewmodel(Item)
	if not Item then
		print("Item name is required")
		return nil
	end

    if Item ~= "Nil" then
        local viewmodelToClone

        if not viewmodelToClone then
            for _, category in ipairs(weaponCategories.primaryCategories) do
                local viewmodelCategory = primaryViewmodelsFolder:FindFirstChild(category)
                if viewmodelCategory then
                    viewmodelToClone = viewmodelCategory:FindFirstChild(Item)
                    if viewmodelToClone then break end
                end
            end
        end

        if not viewmodelToClone then
            for _, category in ipairs(weaponCategories.secondaryCategories) do
                local viewmodelCategory = secondaryViewmodelsFolder:FindFirstChild(category)
                if viewmodelCategory then
                    viewmodelToClone = viewmodelCategory:FindFirstChild(Item)
                    if viewmodelToClone then break end
                end
            end
        end

        if not viewmodelToClone then
            for _, category in ipairs(weaponCategories.danebisCategories) do
                local viewmodelCategory = danebisViewmodelsFolder:FindFirstChild(category)
                if viewmodelCategory then
                    viewmodelToClone = viewmodelCategory:FindFirstChild(Item)
                    if viewmodelToClone then break end
                end
            end
        end

        if not viewmodelToClone then
            for _, category in ipairs(weaponCategories.throwableCategories) do
                local viewmodelCategory = throwableViewmodelsFolder:FindFirstChild(category)
                if viewmodelCategory then
                    viewmodelToClone = viewmodelCategory:FindFirstChild(Item)
                    if viewmodelToClone then break end
                end
            end
        end

        if viewmodelToClone then
			return viewmodelToClone	
		else
			warn("No viewmodel found for item: " .. Item)
			return nil
		end
    end
end

return viewmodelFinder