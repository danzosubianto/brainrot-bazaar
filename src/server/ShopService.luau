-- ShopService: the Summoning Sidewalk, where the money is spent.
--
-- One brainrot at a time steps out of the portal, stands on the glowing
-- lane with its price on its label, and waits out its offer timer. Buy it
-- with the prompt and it follows you home on foot; walk onto your own plot
-- and it hops onto a free pedestal and starts earning. A placed brainrot
-- carries a sell prompt (half price back), so a base is never a dead end:
-- sell the early junk, climb the ladder.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BrainrotData = require(ReplicatedStorage.Shared.BrainrotData)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local CharacterFactory = require(script.Parent.CharacterFactory)
local PlayerService = require(script.Parent.PlayerService)

local ShopService = {}

local rng = Random.new()
local world = nil
local currentOffer: any = nil

-- Slide a model along the ground to a point, facing its travel. Yields.
local function walkTo(model: Model, target: Vector3, speed: number)
	local root = model.PrimaryPart
	if not root then
		return
	end
	while model.Parent do
		local here = root.Position
		local flat = Vector3.new(target.X, here.Y, target.Z)
		local delta = flat - here
		if delta.Magnitude < 0.6 then
			break
		end
		local step = math.min(delta.Magnitude, speed * 0.05)
		local nextPos = here + delta.Unit * step
		local facing = CFrame.lookAt(nextPos, nextPos - delta.Unit, Vector3.yAxis)
		root.CFrame = CFrame.new(nextPos) * (facing - facing.Position)
		task.wait(0.05)
	end
end

-- The followers: every carried brainrot trails its owner in a conga line.
local function followLoop()
	RunService.Heartbeat:Connect(function()
		for _, player in ipairs(Players:GetPlayers()) do
			local state = PlayerService.get(player)
			local character = player.Character
			if state and character then
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if hrp then
					for i, carried in ipairs(state.carried) do
						local root = carried.model and carried.model.PrimaryPart
						if root then
							local behind = hrp.Position - hrp.CFrame.LookVector * (4 + (i - 1) * 3.5)
							local target = Vector3.new(behind.X, root.Position.Y, behind.Z)
							local delta = target - root.Position
							if delta.Magnitude > 0.4 then
								local nextPos = root.Position + delta * 0.18
								local facing = CFrame.lookAt(nextPos, nextPos + delta.Unit, Vector3.yAxis)
								root.CFrame = CFrame.new(nextPos) * (facing - facing.Position)
							end
						end
					end
				end
			end
		end
	end)
end

local function attachSellPrompt(player: Player, model: Model, slot: number)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "SellPrompt"
	prompt.ActionText = "Sell (half price)"
	prompt.ObjectText = model:GetAttribute("BrainrotId")
	prompt.HoldDuration = 0.6
	prompt.MaxActivationDistance = 9
	prompt.RequiresLineOfSight = false
	prompt.Parent = model.PrimaryPart
	prompt.Triggered:Connect(function(who)
		if who ~= player then
			return
		end
		local placed = PlayerService.removeFromPedestal(player, slot)
		if placed then
			local back = math.floor((placed.model:GetAttribute("Cost") or 0) / 2)
			if placed.model then
				placed.model:Destroy()
			end
			local state = PlayerService.get(player)
			if state then
				state.cash += back
				PlayerService.refreshLeaderstats(player)
				PlayerService.notify(player, string.format("Sold for +$%d", back), "cash")
				PlayerService.sync(player)
			end
		end
	end)
end

local function clearOffer()
	if currentOffer then
		if currentOffer.prompt then
			currentOffer.prompt:Destroy()
		end
		if currentOffer.model then
			currentOffer.model:Destroy()
		end
		currentOffer = nil
	end
end

-- One offer's whole life: arrive, wait to be bought, leave.
local function runOffer()
	local richest = 0
	for _, player in ipairs(Players:GetPlayers()) do
		local state = PlayerService.get(player)
		if state then
			richest = math.max(richest, state.lifetime)
		end
	end
	local luck = 1 + math.min(2, richest / 60000)
	local rarity = BrainrotData.rollRarity(rng, luck)
	local entry = BrainrotData.randomOfRarity(rarity.name, rng)
	local mutation = BrainrotData.rollMutation(rng)
	local cost = entry.cost * mutation.multiplier

	local model = CharacterFactory.build(entry, mutation, world.portalMouth)
	model.Parent = workspace
	local offer = { model = model, entry = entry, mutation = mutation, cost = cost, bought = false }
	currentOffer = offer

	-- the price joins the label while it stands on the lane
	local head = model:FindFirstChild("Head")
	if head then
		local gui = head:FindFirstChild("Label")
		if gui then
			gui.Text.Text = BrainrotData.labelFor(entry, mutation) .. string.format("\nFOR SALE: $%d", cost)
		end
	end

	task.spawn(function()
		walkTo(model, world.offerSpot, 9)
		if offer.bought or currentOffer ~= offer then
			return
		end
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "BuyPrompt"
		prompt.ActionText = string.format("Buy for $%d", cost)
		prompt.ObjectText = (mutation.name ~= "" and (mutation.name .. " ") or "") .. entry.name
		prompt.HoldDuration = 0.3
		prompt.MaxActivationDistance = 11
		prompt.RequiresLineOfSight = false
		prompt.Parent = model.PrimaryPart
		offer.prompt = prompt
		prompt.Triggered:Connect(function(player)
			local state = PlayerService.get(player)
			if not state or offer.bought then
				return
			end
			if #state.carried >= GameConfig.StartCarry + state.upgrades.backpack then
				PlayerService.notify(player, "Hands full! Place what you carry, or buy the Backpack upgrade.", "warn")
				return
			end
			if state.cash < cost then
				PlayerService.notify(player, string.format("Not enough cash — you need $%d.", cost), "warn")
				return
			end
			state.cash -= cost
			offer.bought = true
			prompt:Destroy()
			table.insert(state.carried, { model = model, entry = entry, mutation = mutation })
			-- the label goes back to name and rate once it is yours
			local h = model:FindFirstChild("Head")
			if h then
				local g = h:FindFirstChild("Label")
				if g then
					g.Text.Text = BrainrotData.labelFor(entry, mutation)
				end
			end
			PlayerService.refreshLeaderstats(player)
			PlayerService.notify(player, entry.name .. " is yours! Carry it home and step on your plot.", "good")
			PlayerService.sync(player)
			currentOffer = nil
			task.wait(GameConfig.OfferGapSeconds)
			runOffer()
		end)
		-- the offer timer: unp bought, it trudges back into the portal
		local waited = 0
		while waited < GameConfig.OfferSeconds and not offer.bought and currentOffer == offer do
			task.wait(0.5)
			waited += 0.5
		end
		if not offer.bought and currentOffer == offer then
			currentOffer = nil
			if prompt then
				prompt:Destroy()
			end
			walkTo(model, world.portalMouth, 9)
			model:Destroy()
			task.wait(GameConfig.OfferGapSeconds)
			runOffer()
		end
	end)
end

-- Stepping onto your own plot with full hands places the first carried
-- brainrot on a free pedestal. Stepping on with a full base explains why not.
local function watchPlots()
	for index, base in ipairs(world.bases) do
		local plot = base:FindFirstChild("Plot")
		if plot then
			plot.Touched:Connect(function(hit)
				local character = hit:FindFirstAncestorOfClass("Model")
				local player = character and Players:GetPlayerFromCharacter(character)
				if not player then
					return
				end
				local state = PlayerService.get(player)
				if not state or state.baseIndex ~= index or #state.carried == 0 then
					return
				end
				if PlayerService.freeSlotCount(player) <= 0 then
					PlayerService.notify(player, "Base full! Sell a brainrot or buy Extra Pedestals.", "warn")
					return
				end
				local carried = table.remove(state.carried, 1)
				local slot = PlayerService.placeOnPedestal(player, carried.model)
				if slot then
					attachSellPrompt(player, carried.model, slot)
					PlayerService.notify(player, carried.entry.name .. " placed! It earns into your vault.", "good")
					PlayerService.sync(player)
				else
					table.insert(state.carried, 1, carried)
				end
			end)
		end
	end
end

function ShopService.start(w)
	world = w
	followLoop()
	watchPlots()
	task.spawn(function()
		task.wait(3)
		runOffer()
	end)
end

-- What the boulder and the Janitor call when a carried brainrot is lost.
function ShopService.dropCarried(player: Player)
	local state = PlayerService.get(player)
	if state and #state.carried > 0 then
		local carried = table.remove(state.carried, 1)
		if carried.model then
			carried.model:Destroy()
		end
		PlayerService.sync(player)
		return carried
	end
	return nil
end

return ShopService
