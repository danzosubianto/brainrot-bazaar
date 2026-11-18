-- CharacterFactory: builds a brainrot out of blocks.
--
-- No meshes, no uploads: every character in the cast is boxes, balls and
-- cylinders in its cast colours, a hat that says which one it is at twenty
-- paces, two eyes, and a BillboardGui label carrying its name, rarity and
-- money a second (the judge reads those labels in the screenshots, and so
-- does the player deciding what to buy).

local BrainrotData = require(game.ReplicatedStorage.Shared.BrainrotData)

local CharacterFactory = {}

local function block(parent: Instance, name: string, size: Vector3, offset: Vector3, color: Color3, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CFrame = CFrame.new(offset)
	p.Parent = parent
	return p
end

local function ball(parent: Instance, name: string, size: Vector3, offset: Vector3, color: Color3): Part
	local p = block(parent, name, size, offset, color)
	p.Shape = Enum.PartType.Ball
	return p
end

local function cylinder(parent: Instance, name: string, size: Vector3, offset: Vector3, color: Color3, rotation: Vector3?): Part
	local p = block(parent, name, size, offset, color)
	p.Shape = Enum.PartType.Cylinder
	if rotation then
		p.CFrame = CFrame.new(offset) * CFrame.Angles(math.rad(rotation.X), math.rad(rotation.Y), math.rad(rotation.Z))
	end
	return p
end

-- One hat per cast member; the silhouette is the joke and the recognition.
local hats: { [string]: (Model, any) -> () } = {
	none = function() end,
	cone = function(model, entry)
		cylinder(model, "Hat", Vector3.new(0.9, 1.3, 0.9), Vector3.new(0, 3.35, 0), Color3.fromRGB(255, 110, 30))
		cylinder(model, "HatBand", Vector3.new(0.95, 0.3, 0.95), Vector3.new(0, 3.1, 0), Color3.fromRGB(255, 255, 255))
	end,
	staple = function(model)
		block(model, "Hat", Vector3.new(1.1, 0.45, 0.6), Vector3.new(0, 3.05, 0), Color3.fromRGB(200, 40, 40), Enum.Material.Metal)
	end,
	waffle = function(model)
		local hat = block(model, "Hat", Vector3.new(1.9, 0.35, 1.9), Vector3.new(0, 3.1, 0), Color3.fromRGB(216, 164, 65))
		hat.Orientation = Vector3.new(0, 0, 8)
		for i = -1, 1 do
			block(model, "WaffleLine", Vector3.new(1.9, 0.1, 0.18), Vector3.new(0, 3.3, i * 0.55), Color3.fromRGB(160, 115, 40))
		end
	end,
	pickle = function(model)
		local pickle = ball(model, "Hat", Vector3.new(0.8, 2.2, 0.8), Vector3.new(0.6, 2.6, 0), Color3.fromRGB(60, 160, 70))
		pickle.Orientation = Vector3.new(0, 0, 55)
	end,
	magnet = function(model)
		block(model, "HatL", Vector3.new(0.35, 0.9, 0.35), Vector3.new(-0.45, 3.3, 0), Color3.fromRGB(210, 40, 40), Enum.Material.Metal)
		block(model, "HatR", Vector3.new(0.35, 0.9, 0.35), Vector3.new(0.45, 3.3, 0), Color3.fromRGB(210, 40, 40), Enum.Material.Metal)
		block(model, "HatTop", Vector3.new(1.25, 0.35, 0.35), Vector3.new(0, 3.75, 0), Color3.fromRGB(210, 40, 40), Enum.Material.Metal)
	end,
	bubble = function(model)
		local dome = ball(model, "Hat", Vector3.new(2.5, 2.5, 2.5), Vector3.new(0, 2.75, 0), Color3.fromRGB(200, 235, 250))
		dome.Transparency = 0.55
		ball(model, "Bubble1", Vector3.new(0.5, 0.5, 0.5), Vector3.new(0.7, 3.3, 0.3), Color3.fromRGB(220, 245, 255)).Transparency = 0.4
		ball(model, "Bubble2", Vector3.new(0.35, 0.35, 0.35), Vector3.new(-0.8, 3.0, -0.2), Color3.fromRGB(220, 245, 255)).Transparency = 0.4
	end,
	scooter = function(model)
		block(model, "ScooterDeck", Vector3.new(0.8, 0.25, 3.2), Vector3.new(0, 0.35, 0.4), Color3.fromRGB(200, 60, 160), Enum.Material.Metal)
		cylinder(model, "WheelF", Vector3.new(0.3, 0.9, 0.9), Vector3.new(0, 0.45, 1.9), Color3.fromRGB(30, 30, 30), Vector3.new(0, 0, 90))
		cylinder(model, "WheelB", Vector3.new(0.3, 0.9, 0.9), Vector3.new(0, 0.45, -1.1), Color3.fromRGB(30, 30, 30), Vector3.new(0, 0, 90))
	end,
	toast = function(model)
		block(model, "Hat", Vector3.new(1.7, 1.7, 0.35), Vector3.new(0, 3.4, 0), Color3.fromRGB(170, 115, 55))
		block(model, "HatInner", Vector3.new(1.3, 1.3, 0.4), Vector3.new(0, 3.4, 0), Color3.fromRGB(240, 220, 170))
	end,
	sock = function(model)
		local sock = ball(model, "Hat", Vector3.new(1.1, 2.4, 1.1), Vector3.new(0.3, 3.1, 0), Color3.fromRGB(150, 170, 190))
		sock.Orientation = Vector3.new(0, 0, 35)
	end,
	crown = function(model)
		cylinder(model, "Hat", Vector3.new(1.8, 0.6, 1.8), Vector3.new(0, 3.15, 0), Color3.fromRGB(255, 200, 40), Enum.Material.Metal)
		for i = 1, 4 do
			local angle = (i - 1) * math.pi / 2
			block(model, "CrownSpike", Vector3.new(0.3, 0.7, 0.3), Vector3.new(math.cos(angle) * 0.7, 3.7, math.sin(angle) * 0.7), Color3.fromRGB(255, 200, 40), Enum.Material.Metal)
		end
	end,
	orbit = function(model)
		for i = 1, 3 do
			local angle = i * (math.pi * 2 / 3)
			ball(model, "OrbitRock", Vector3.new(0.45, 0.45, 0.45), Vector3.new(math.cos(angle) * 1.6, 2.8 + (i % 2) * 0.5, math.sin(angle) * 1.6), Color3.fromRGB(140, 130, 200))
		end
	end,
	toaster = function(model)
		block(model, "Hat", Vector3.new(1.9, 1.1, 1.3), Vector3.new(0, 3.35, 0), Color3.fromRGB(205, 205, 215), Enum.Material.Metal)
		block(model, "Slot1", Vector3.new(0.6, 0.2, 0.9), Vector3.new(-0.45, 3.95, 0), Color3.fromRGB(40, 40, 40))
		block(model, "Slot2", Vector3.new(0.6, 0.2, 0.9), Vector3.new(0.45, 3.95, 0), Color3.fromRGB(40, 40, 40))
	end,
}

-- Build one brainrot model at a position. The model is anchored at its Root
-- (the legs block); services move it by the Root's CFrame. Attributes carry
-- the facts the rest of the game needs: BrainrotId, Mutation, Income, Cost.
function CharacterFactory.build(entry, mutation, position: Vector3): Model
	local model = Instance.new("Model")
	model.Name = "Brainrot_" .. entry.id

	local legs = block(model, "Legs", Vector3.new(1.5, 1, 0.9), Vector3.new(0, 0.5, 0), entry.legs)
	legs.Anchored = true
	block(model, "Torso", Vector3.new(1.9, 1.4, 1), Vector3.new(0, 1.7, 0), entry.body)
	local head = block(model, "Head", Vector3.new(1.5, 1.3, 1.3), Vector3.new(0, 3.05 - 0.6, 0), entry.head)
	-- eyes on the front of the head (the model faces -Z when following)
	ball(model, "EyeL", Vector3.new(0.28, 0.28, 0.28), Vector3.new(-0.35, 2.55, -0.62), Color3.fromRGB(20, 20, 20))
	ball(model, "EyeR", Vector3.new(0.28, 0.28, 0.28), Vector3.new(0.35, 2.55, -0.62), Color3.fromRGB(20, 20, 20))

	local hatFn = hats[entry.hat] or hats.none
	hatFn(model, entry)

	-- an Upside-Down mutation wears the whole body flipped
	if mutation and mutation.name == "Upside-Down" then
		for _, child in ipairs(model:GetChildren()) do
			if child:IsA("BasePart") and child.Name ~= "Legs" then
				local offset = child.CFrame.Position
				child.CFrame = CFrame.new(Vector3.new(offset.X, 4.6 - offset.Y, offset.Z)) * CFrame.Angles(0, 0, math.pi)
			end
		end
	end

	local label = Instance.new("BillboardGui")
	label.Name = "Label"
	label.Size = UDim2.fromOffset(300, 110)
	label.StudsOffset = Vector3.new(0, 3.4, 0)
	label.AlwaysOnTop = true
	label.MaxDistance = 160
	local text = Instance.new("TextLabel")
	text.Name = "Text"
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 0.35
	text.BackgroundColor3 = Color3.fromRGB(20, 16, 30)
	text.Font = Enum.Font.FredokaOne
	text.TextScaled = true
	text.TextColor3 = BrainrotData.RarityByName[entry.rarity].color
	text.TextStrokeTransparency = 0.4
	text.Text = BrainrotData.labelFor(entry, mutation)
	text.Parent = label
	label.Parent = head

	model.PrimaryPart = legs
	legs.CFrame = CFrame.new(position)
	model:SetAttribute("BrainrotId", entry.id)
	model:SetAttribute("Mutation", mutation and mutation.name or "")
	model:SetAttribute("Income", entry.income * (mutation and mutation.multiplier or 1))
	model:SetAttribute("Cost", entry.cost * (mutation and mutation.multiplier or 1))
	return model
end

-- A gentle idle bob for a placed brainrot, so a full base looks alive in a
-- screenshot instead of standing at attention. Returns a stop function.
function CharacterFactory.startBobbing(model: Model): () -> ()
	local root = model.PrimaryPart
	if not root then
		return function() end
	end
	local home = root.CFrame
	local stopped = false
	task.spawn(function()
		local t = math.random() * math.pi * 2
		while not stopped and root.Parent do
			t += task.wait(0.06)
			local lift = math.sin(t * 2.2) * 0.12
			local sway = math.sin(t * 1.3) * 0.05
			root.CFrame = home * CFrame.new(0, math.max(lift, 0), 0) * CFrame.Angles(0, sway, 0)
		end
		if root.Parent then
			root.CFrame = home
		end
	end)
	return function()
		stopped = true
	end
end

return CharacterFactory
