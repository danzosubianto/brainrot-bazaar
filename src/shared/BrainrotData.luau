-- BrainrotData: the cast of Brainrot Bazaar and the rarity ladder they climb.
--
-- Every character here is an original invention of this game: a name, a body
-- built from coloured blocks by CharacterFactory, a hat, a price and the cash
-- it earns each second once it stands on a pedestal. Rarer brainrots cost
-- more, earn more, and walk the Summoning Sidewalk less often.

local BrainrotData = {}

-- Rarities, cheapest first. `weight` is the sidewalk's pull toward the low
-- end; `color` paints the name label and the pedestal glow.
BrainrotData.Rarities = {
	{ name = "Common", color = Color3.fromRGB(178, 178, 178), weight = 100 },
	{ name = "Rare", color = Color3.fromRGB(64, 140, 255), weight = 55 },
	{ name = "Epic", color = Color3.fromRGB(170, 85, 255), weight = 26 },
	{ name = "Legendary", color = Color3.fromRGB(255, 190, 40), weight = 11 },
	{ name = "Mythic", color = Color3.fromRGB(255, 80, 200), weight = 4 },
	{ name = "BRAINROT GOD", color = Color3.fromRGB(120, 255, 230), weight = 1 },
}

BrainrotData.RarityByName = {}
for index, rarity in ipairs(BrainrotData.Rarities) do
	rarity.index = index
	BrainrotData.RarityByName[rarity.name] = rarity
end

-- Mutations a sidewalk brainrot can roll. A mutation multiplies both its
-- price and its income, and says so on its label.
BrainrotData.Mutations = {
	{ name = "", multiplier = 1, weight = 78 },
	{ name = "Shiny", multiplier = 2, weight = 14 },
	{ name = "Upside-Down", multiplier = 3, weight = 6 },
	{ name = "Made of Beans", multiplier = 5, weight = 2 },
}

-- The cast. `hat` names the accessory CharacterFactory builds; `body`,
-- `head` and `legs` are the block colours; `line` is the nonsense the
-- brainrot says on its label when it is placed.
BrainrotData.Cast = {
	{
		id = "damp_potato", name = "Kevin the Damp Potato", rarity = "Common",
		cost = 25, income = 1, hat = "none",
		body = Color3.fromRGB(168, 128, 74), head = Color3.fromRGB(188, 148, 90), legs = Color3.fromRGB(90, 70, 50),
		line = "He is damp. Nobody knows why.",
	},
	{
		id = "cone_knight", name = "Sir Bopsalot", rarity = "Common",
		cost = 60, income = 2, hat = "cone",
		body = Color3.fromRGB(200, 200, 205), head = Color3.fromRGB(230, 200, 170), legs = Color3.fromRGB(120, 120, 130),
		line = "A knight. His sword is a traffic cone.",
	},
	{
		id = "haunted_stapler", name = "A Slightly Haunted Stapler", rarity = "Common",
		cost = 120, income = 3, hat = "staple",
		body = Color3.fromRGB(150, 40, 40), head = Color3.fromRGB(170, 170, 175), legs = Color3.fromRGB(60, 60, 65),
		line = "It staples things at night. Nobody sees it move.",
	},
	{
		id = "waffleiron", name = "Madame Waffleiron", rarity = "Rare",
		cost = 300, income = 6, hat = "waffle",
		body = Color3.fromRGB(216, 164, 65), head = Color3.fromRGB(235, 190, 110), legs = Color3.fromRGB(140, 100, 40),
		line = "Presses every problem until it is breakfast.",
	},
	{
		id = "picklebeard", name = "Captain Picklebeard", rarity = "Rare",
		cost = 550, income = 9, hat = "pickle",
		body = Color3.fromRGB(46, 120, 60), head = Color3.fromRGB(230, 205, 170), legs = Color3.fromRGB(70, 50, 30),
		line = "His beard is one (1) enormous pickle.",
	},
	{
		id = "fridge_magnet", name = "DJ Fridge Magnet", rarity = "Rare",
		cost = 900, income = 13, hat = "magnet",
		body = Color3.fromRGB(90, 90, 200), head = Color3.fromRGB(200, 200, 215), legs = Color3.fromRGB(50, 50, 90),
		line = "Sticks to the beat. Also to fridges.",
	},
	{
		id = "bubblewrap", name = "Baron von Bubblewrap", rarity = "Epic",
		cost = 1800, income = 22, hat = "bubble",
		body = Color3.fromRGB(190, 225, 240), head = Color3.fromRGB(225, 245, 250), legs = Color3.fromRGB(130, 170, 190),
		line = "Pop him and he simply becomes two Barons.",
	},
	{
		id = "turbo_granny", name = "Granny Turbo-Scooter", rarity = "Epic",
		cost = 3200, income = 32, hat = "scooter",
		body = Color3.fromRGB(150, 60, 160), head = Color3.fromRGB(240, 215, 200), legs = Color3.fromRGB(90, 40, 100),
		line = "0 to 60 in four seconds. Knits at 70.",
	},
	{
		id = "professor_beans", name = "Professor Beans-on-Toast", rarity = "Epic",
		cost = 5000, income = 45, hat = "toast",
		body = Color3.fromRGB(120, 80, 40), head = Color3.fromRGB(240, 220, 180), legs = Color3.fromRGB(80, 55, 25),
		line = "Tenured at the University of Breakfast.",
	},
	{
		id = "wet_sock", name = "The Sentient Wet Sock", rarity = "Legendary",
		cost = 12000, income = 80, hat = "sock",
		body = Color3.fromRGB(100, 130, 160), head = Color3.fromRGB(130, 160, 190), legs = Color3.fromRGB(70, 95, 120),
		line = "It knows what you did. It is also wet.",
	},
	{
		id = "crumbington", name = "Lord Crumbington III", rarity = "Legendary",
		cost = 20000, income = 120, hat = "crown",
		body = Color3.fromRGB(110, 30, 40), head = Color3.fromRGB(238, 210, 175), legs = Color3.fromRGB(60, 20, 25),
		line = "Heir to a biscuit empire. Crumbs everywhere.",
	},
	{
		id = "auntie_gravity", name = "Auntie Gravity", rarity = "Mythic",
		cost = 45000, income = 220, hat = "orbit",
		body = Color3.fromRGB(60, 40, 120), head = Color3.fromRGB(200, 190, 255), legs = Color3.fromRGB(35, 25, 80),
		line = "She does not fall. The floor rises to meet her.",
	},
	{
		id = "almighty_toaster", name = "The Almighty Toaster", rarity = "Mythic",
		cost = 80000, income = 350, hat = "toaster",
		body = Color3.fromRGB(210, 210, 220), head = Color3.fromRGB(190, 190, 200), legs = Color3.fromRGB(120, 120, 130),
		line = "It knows when the toast is done. It knows everything.",
	},
	{
		id = "greg", name = "GREG", rarity = "BRAINROT GOD",
		cost = 250000, income = 1000, hat = "none",
		body = Color3.fromRGB(90, 110, 160), head = Color3.fromRGB(232, 205, 172), legs = Color3.fromRGB(60, 60, 70),
		line = "Just Greg. A completely normal man. Terrifying.",
	},
}

BrainrotData.ById = {}
for _, entry in ipairs(BrainrotData.Cast) do
	BrainrotData.ById[entry.id] = entry
end

-- Roll a rarity on the sidewalk. Higher lifetime earnings bend the weights
-- toward the rare end, so the ladder keeps offering a next step.
function BrainrotData.rollRarity(rng: Random, luck: number)
	local total = 0
	local weights = {}
	for index, rarity in ipairs(BrainrotData.Rarities) do
		local w = rarity.weight * (luck ^ (index - 1))
		weights[index] = w
		total += w
	end
	local roll = rng:NextNumber(0, total)
	for index, rarity in ipairs(BrainrotData.Rarities) do
		roll -= weights[index]
		if roll <= 0 then
			return rarity
		end
	end
	return BrainrotData.Rarities[1]
end

-- Pick a random cast member of a rarity.
function BrainrotData.randomOfRarity(rarityName: string, rng: Random)
	local pool = {}
	for _, entry in ipairs(BrainrotData.Cast) do
		if entry.rarity == rarityName then
			table.insert(pool, entry)
		end
	end
	return pool[rng:NextInteger(1, #pool)]
end

-- Roll a mutation for a fresh sidewalk brainrot.
function BrainrotData.rollMutation(rng: Random)
	local total = 0
	for _, mutation in ipairs(BrainrotData.Mutations) do
		total += mutation.weight
	end
	local roll = rng:NextNumber(0, total)
	for _, mutation in ipairs(BrainrotData.Mutations) do
		roll -= mutation.weight
		if roll <= 0 then
			return mutation
		end
	end
	return BrainrotData.Mutations[1]
end

-- The label a brainrot wears: its mutation, its name, its rarity and rate.
function BrainrotData.labelFor(entry, mutation)
	local prefix = ""
	if mutation and mutation.name ~= "" then
		prefix = mutation.name .. " "
	end
	local income = entry.income * (mutation and mutation.multiplier or 1)
	return string.format("%s%s\n%s · $%d/s", prefix, entry.name, entry.rarity, income)
end

return BrainrotData
