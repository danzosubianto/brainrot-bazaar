-- WorldBuilder: raises the Brainrot Bazaar itself in Workspace.
--
-- The Rojo project file lays the ground, the Main Street and the spawn; this
-- module builds everything with a job: the six player bases around the
-- street (plot floor, pedestals, vault pad, name sign), the Summoning
-- Sidewalk and its portal at the north end, the Upgrade Obelisk, and the
-- dressing (lampposts, awnings, bunting) that makes the place read as a
-- bazaar instead of a car park.
--
-- Every base is a Model named Base1..Base6 with named children the other
-- services look up: Plot (the floor), VaultPad, LockGate, Sign, and a
-- Pedestals folder of pads named Pedestal1..Pedestal10 (the last six start
-- hidden and are switched on by the pedestal upgrade).

local GameConfig = require(game.ReplicatedStorage.Shared.GameConfig)

local WorldBuilder = {}

local Workspace = game:GetService("Workspace")

local function part(parent: Instance, name: string, size: Vector3, position: Vector3, color: Color3, material: Enum.Material): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Position = position
	p.Color = color
	p.Material = material
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function label(parent: Instance, name: string, text: string, size: Vector2, offset: Vector3, color: Color3): BillboardGui
	local gui = Instance.new("BillboardGui")
	gui.Name = name
	gui.Size = UDim2.fromOffset(size.X, size.Y)
	gui.StudsOffset = offset
	gui.AlwaysOnTop = true
	gui.MaxDistance = 220
	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "Text"
	textLabel.Size = UDim2.fromScale(1, 1)
	textLabel.BackgroundTransparency = 1
	textLabel.Font = Enum.Font.FredokaOne
	textLabel.TextScaled = true
	textLabel.TextColor3 = color
	textLabel.TextStrokeTransparency = 0.35
	textLabel.Text = text
	textLabel.Parent = gui
	gui.Parent = parent
	return gui
end

-- The six plots: three down each side of the Main Street, facing it.
function WorldBuilder.plotOrigin(index: number): Vector3
	local side = index <= 3 and -1 or 1
	local row = (index - 1) % 3
	return Vector3.new(side * 52, 0, -60 + row * 55)
end

local function buildBase(index: number): Model
	local origin = WorldBuilder.plotOrigin(index)
	local base = Instance.new("Model")
	base.Name = "Base" .. index

	local plot = part(base, "Plot", Vector3.new(40, 1, 40), origin + Vector3.new(0, 0.5, 0),
		Color3.fromRGB(232, 205, 160), Enum.Material.Sand)
	plot:SetAttribute("BaseIndex", index)

	-- A low fence the LockGate rises out of when the base is locked.
	part(base, "FenceBack", Vector3.new(40, 3, 1), origin + Vector3.new(0, 1.5, -20),
		Color3.fromRGB(150, 105, 60), Enum.Material.Wood)
	part(base, "FenceLeft", Vector3.new(1, 3, 40), origin + Vector3.new((origin.X > 0 and 20 or -20), 1.5, 0),
		Color3.fromRGB(150, 105, 60), Enum.Material.Wood)

	local gate = part(base, "LockGate", Vector3.new(1, 9, 40), origin + Vector3.new((origin.X > 0 and -20 or 20), -6, 0),
		Color3.fromRGB(255, 90, 90), Enum.Material.Neon)
	gate.Transparency = 0.45
	gate.CanCollide = false
	gate:SetAttribute("HomeY", 4.5)
	gate:SetAttribute("AwayY", -6)

	-- The vault pad: stand on it to sweep the vault into your pockets.
	local vault = part(base, "VaultPad", Vector3.new(8, 0.6, 8), origin + Vector3.new(0, 1.3, 15),
		Color3.fromRGB(255, 205, 50), Enum.Material.Neon)
	vault:SetAttribute("BaseIndex", index)
	label(vault, "VaultLabel", "VAULT\n$0", Vector2.new(180, 90), Vector3.new(0, 4, 0), Color3.fromRGB(255, 230, 130))

	-- The owner's sign over the gate side of the plot.
	local signPost = part(base, "Sign", Vector3.new(10, 7, 0.6), origin + Vector3.new(0, 6, -19),
		Color3.fromRGB(120, 80, 45), Enum.Material.Wood)
	label(signPost, "SignLabel", "Nobody's Bazaar", Vector2.new(340, 80), Vector3.new(0, 1.5, 0), Color3.fromRGB(255, 255, 255))

	-- Pedestals in two rows of five; only the first StartPedestals show.
	local pedestals = Instance.new("Folder")
	pedestals.Name = "Pedestals"
	pedestals.Parent = base
	for slot = 1, GameConfig.MaxPedestals do
		local column = (slot - 1) % 5
		local row = math.floor((slot - 1) / 5)
		local pad = part(pedestals, "Pedestal" .. slot, Vector3.new(5, 1.6, 5),
			origin + Vector3.new(-14 + column * 7, 1.8, -8 + row * 11),
			Color3.fromRGB(245, 240, 230), Enum.Material.Marble)
		pad:SetAttribute("BaseIndex", index)
		pad:SetAttribute("Slot", slot)
		if slot > GameConfig.StartPedestals then
			pad.Transparency = 0.75
			pad.CanCollide = false
			pad:SetAttribute("Dormant", true)
		end
	end

	base.Parent = Workspace
	return base
end

-- The Summoning Sidewalk: a glowing lane at the north end of the street,
-- the portal brainrots arrive through, and the spot they stand on sale.
local function buildSidewalk(parent: Instance)
	local lane = part(parent, "SummoningSidewalk", Vector3.new(30, 0.5, 16), Vector3.new(0, 0.25, -88),
		Color3.fromRGB(120, 60, 200), Enum.Material.Neon)
	lane:SetAttribute("OfferSpot", true)
	label(lane, "LaneLabel", "THE SUMMONING SIDEWALK", Vector2.new(420, 70), Vector3.new(0, 9, 0), Color3.fromRGB(230, 200, 255))

	-- The portal: two posts and a swirling disc the offers step out of.
	part(parent, "PortalPostL", Vector3.new(2, 16, 2), Vector3.new(-9, 8, -97), Color3.fromRGB(70, 40, 120), Enum.Material.Slate)
	part(parent, "PortalPostR", Vector3.new(2, 16, 2), Vector3.new(9, 8, -97), Color3.fromRGB(70, 40, 120), Enum.Material.Slate)
	local disc = part(parent, "PortalDisc", Vector3.new(16, 14, 0.6), Vector3.new(0, 7.5, -97),
		Color3.fromRGB(200, 120, 255), Enum.Material.Neon)
	disc.Shape = Enum.PartType.Cylinder
	disc.Orientation = Vector3.new(0, 0, 90)
	disc.Transparency = 0.25
	disc.CanCollide = false
	label(disc, "PortalLabel", "THE PORTAL OF QUESTIONABLE DECISIONS", Vector2.new(460, 60), Vector3.new(0, 3, 0), Color3.fromRGB(255, 255, 255))
end

-- The Upgrade Obelisk by the spawn: a tall stone with the shop prompt on it.
local function buildObelisk(parent: Instance)
	local stone = part(parent, "UpgradeObelisk", Vector3.new(5, 18, 5), Vector3.new(14, 9, 46),
		Color3.fromRGB(80, 80, 95), Enum.Material.Slate)
	label(stone, "ObeliskLabel", "THE OBELISK OF UPGRADES", Vector2.new(380, 70), Vector3.new(0, 4, 0), Color3.fromRGB(170, 230, 255))
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "UpgradePrompt"
	prompt.ActionText = "Browse Upgrades"
	prompt.ObjectText = "Obelisk of Upgrades"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 14
	prompt.Parent = stone
	return stone
end

-- Dressing: lampposts down the street, striped awnings over the plots, and
-- the welcome arch over the spawn end. None of it thinks; all of it poses.
local function buildDressing(parent: Instance)
	for i = -3, 3 do
		local z = i * 26
		for _, x in ipairs({ -15, 15 }) do
			part(parent, "LampPost", Vector3.new(0.7, 9, 0.7), Vector3.new(x, 4.5, z), Color3.fromRGB(40, 40, 45), Enum.Material.Metal)
			local bulb = part(parent, "LampBulb", Vector3.new(1.6, 1.6, 1.6), Vector3.new(x, 9.4, z), Color3.fromRGB(255, 240, 180), Enum.Material.Neon)
			bulb.Shape = Enum.PartType.Ball
			bulb.CanCollide = false
		end
	end
	part(parent, "WelcomeArchL", Vector3.new(2, 14, 2), Vector3.new(-11, 7, 58), Color3.fromRGB(200, 90, 60), Enum.Material.Brick)
	part(parent, "WelcomeArchR", Vector3.new(2, 14, 2), Vector3.new(11, 7, 58), Color3.fromRGB(200, 90, 60), Enum.Material.Brick)
	local beam = part(parent, "WelcomeArchTop", Vector3.new(24, 2.5, 2), Vector3.new(0, 14.5, 58), Color3.fromRGB(200, 90, 60), Enum.Material.Brick)
	label(beam, "WelcomeLabel", "BRAINROT BAZAAR", Vector2.new(520, 90), Vector3.new(0, 2.5, 0), Color3.fromRGB(255, 235, 160))
end

-- Build the whole bazaar and hand back the pieces the services drive.
function WorldBuilder.build()
	local world = Instance.new("Folder")
	world.Name = "BazaarWorld"
	world.Parent = Workspace

	local bases = {}
	for index = 1, GameConfig.BaseCount do
		bases[index] = buildBase(index)
	end
	buildSidewalk(world)
	local obelisk = buildObelisk(world)
	buildDressing(world)

	return {
		bases = bases,
		obelisk = obelisk,
		offerSpot = Vector3.new(0, 1.2, -88),
		portalMouth = Vector3.new(0, 1.2, -95),
	}
end

return WorldBuilder
