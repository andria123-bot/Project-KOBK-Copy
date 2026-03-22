local GearsSetup = {}

function GearsSetup.new()
    return {
        Helmet   = { equipped = false, name = "" },
        Armor    = { equipped = true, name = "6B45" },
        Leggings = { equipped = false, name = "" },
        Backpack = { equipped = false, name = "Fieldpack45" },

        Mask     = { equipped = false,  name = "" },
        TShirt   = { equipped = true,  name = "Default" },
        Pants    = { equipped = true,  name = "Default" },
    }
end

return GearsSetup