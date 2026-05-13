local ItemList = {
	Weapons = {
		"AK74";
		"AR15";
		"HK416";
		"Khrissy10R";
		"M4A1";
		"MG42";
		"RAM7";
		"SCARH";
	};

	Melees = {
		"Tomahawk";
	};

	Grenades = {
		"MK2";
	};

	Scopes = {
		"IronSights";
		"Holo";
		"ACOG"; --4x
		"PulsarThermion2";
		"ReapIR";
	};

	Helmets = {
		"6B47";
		"Altyn";
		"FastMT";
		"M100";
		"M88";
	};

	Visors = {
		-- Altyn
		"Altyn Face Visor";
		"Altyn Full Visor";

		-- FastMT
		"Ballistic Visor";
		"Fast Visor";
	};

	BodyArmors = {
		"6B45";
		"AVS";
		"IdZ Vest";
		"JPC";
		"LBT6094";
	};

	Backpacks = {
		"Fieldpack 45"
	},
	
	Ammos = {
		"9x39 AP",
		"9x39 T",

		"5.56x45 AP",
		"5.56x4 T",

		"7.62.39 AP",
		"7.62.39 T",
	}
}

ItemList.Stackables = {
	["9x39"] = true,
	["5.56x45"] = true,
	["7.62x39"] = true,

	["Bloxy Cola"] = true,
	["Bandage"] = true,
	["Medkit"] = true,
}

function ItemList.isStackable(category)
	if ItemList.Stackables[category] then
		return true
	else
		return false
	end
end

return ItemList