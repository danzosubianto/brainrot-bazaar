-- PlayerService: who owns what.
--
-- One state table per player lives here and nowhere else: cash, the vault,
-- lifetime earnings, rebirths, upgrade levels, the base they were dealt and
-- the brainrots standing on its pedestals. Every other service reads and
-- writes through this module, so the rules of ownership sit in one file.
-- It also owns the leaderstats, the base signs, and saving to DataStore
-- (with a session-only fallback when the store cannot be reached).

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local BrainrotData = require(ReplicatedStorage.Shared.BrainrotData)
local CharacterFactory = require(script.Parent.CharacterFactory)

local PlayerService = {}

local store = nil
pcall(function()
	store = DataStoreService:GetDataStore("BrainrotBazaar_v1")
end)

local bases: { Model } = {}
local states: { [Player]: any } = {}
local baseTaken: { [number]: Player? } = {}
local bobStops: { [Model]: () -> () } = {}

function PlayerService.setup(world)
	bases = world.bases
end

local function remotes(): Folder
	return ReplicatedStorage:WaitForChild("Remotes")
end

-- The numbers the client HUD shows, in one snapshot.
function PlayerService.snapshot(player: Player)
	local state = states[player]
	if not state then
		return nil
	end
	local lockLeft = math.max(0, (state.lockedUntil or 0) - os.clock())
	local cooldownLeft = math.max(0, (state.lockReadyAt or 0) - os.clock())
	return {
		cash = math.floor(state.cash),
		vault = math.floor(state.vault),
		perSecond = PlayerService.incomePerSecond(player),
		rebirths = state.rebirths,
		lifetime = math.floor(state.lifetime),
		rebirthCost = GameConfig.rebirthCost(state.rebirths),
		locked = lockLeft > 0,
		lockLeft = math.ceil(lockLeft),
		lockCooldown = math.ceil(cooldownLeft),
		lockSeconds = GameConfig.LockSeconds + 30 * state.upgrades.longlock,
		carried = #state.carried,
		carryMax = GameConfig.StartCarry + state.upgrades.backpack,
		pedestals = PlayerService.pedestalCount(player),
		upgrades = state.upgrades,
	}
end

function PlayerService.sync(player: Player)
	local snap = PlayerService.snapshot(player)
	if snap then
		remotes():WaitForChild("StateSync"):FireClient(player, snap)
	end
end

function PlayerService.notify(player: Player, text: string, kind: string?)
	remotes():WaitForChild("Notify"):FireClient(player, text, kind or "info")
end

function PlayerService.get(player: Player)
	return states[player]
end

function PlayerService.incomePerSecond(player: Player): number
	local state = states[player]
	if not state then
		return 0
	end
	local total = 0
	for _, placed in pairs(state.placed) do
		total += placed.income
	end
	return total * GameConfig.incomeMultiplier(state.rebirths)
end

function PlayerService.pedestalCount(player: Player): number
	local state = states[player]
	if not state then
		return GameConfig.StartPedestals
	end
	return math.min(GameConfig.MaxPedestals, GameConfig.StartPedestals + 2 * state.upgrades.pedestals)
end

-- Leaderstats: the numbers on the player list, and the client's quick read.
local function makeLeaderstats(player: Player, state)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Value = math.floor(state.cash)
	cash.Parent = stats
	local perSec = Instance.new("IntValue")
	perSec.Name = "$/s"
	perSec.Value = 0
	perSec.Parent = stats
	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Value = state.rebirths
	rebirths.Parent = stats
	stats.Parent = player
	state.leaderstats = { cash = cash, perSec = perSec, rebirths = rebirths }
end

function PlayerService.refreshLeaderstats(player: Player)
	local state = states[player]
	if state and state.leaderstats then
		state.leaderstats.cash.Value = math.floor(state.cash)
		state.leaderstats.perSec.Value = math.floor(PlayerService.incomePerSecond(player))
		state.leaderstats.rebirths.Value = state.rebirths
	end
end

-- The base sign and gate speak for the base's state: who owns it, and
-- whether its lock is up (gate raised, glowing) or down.
function PlayerService.refreshBase(player: Player)
	local state = states[player]
	if not state then
		return
	end
	local base = bases[state.baseIndex]
	if not base then
		return
	end
	local sign = base:FindFirstChild("Sign")
	if sign then
		local gui = sign:FindFirstChild("SignLabel")
		if gui then
			gui.Text.Text = player.DisplayName .. "'s Bazaar"
		end
	end
	local locked = (state.lockedUntil or 0) > os.clock()
	local gate = base:FindFirstChild("LockGate")
	if gate then
		gate.Position = Vector3.new(gate.Position.X, locked and gate:GetAttribute("HomeY") or gate:GetAttribute("AwayY"), gate.Position.Z)
		gate.CanCollide = locked
	end
	-- pedestals beyond the player's count stay dormant and ghostly
	local count = PlayerService.pedestalCount(player)
	local pedestals = base:FindFirstChild("Pedestals")
	if pedestals then
		for slot = 1, GameConfig.MaxPedestals do
			local pad = pedestals:FindFirstChild("Pedestal" .. slot)
			if pad then
				local active = slot <= count
				pad.Transparency = active and 0 or 0.75
				pad.CanCollide = active
				pad:SetAttribute("Dormant", not active)
			end
		end
	end
end

-- Put a brainrot on the player's first free pedestal. Returns the slot, or
-- nil when the base is full.
function PlayerService.placeOnPedestal(player: Player, model: Model): number?
	local state = states[player]
	if not state then
		return nil
	end
	local base = bases[state.baseIndex]
	local pedestals = base and base:FindFirstChild("Pedestals")
	if not pedestals then
		return nil
	end
	local count = PlayerService.pedestalCount(player)
	for slot = 1, count do
		if not state.placed[slot] then
			local pad = pedestals:FindFirstChild("Pedestal" .. slot)
			if pad then
				model.PrimaryPart.CFrame = CFrame.new(pad.Position + Vector3.new(0, pad.Size.Y / 2 + 0.05, 0))
				model.Parent = base
				state.placed[slot] = {
					id = model:GetAttribute("BrainrotId"),
					mutation = model:GetAttribute("Mutation"),
					income = model:GetAttribute("Income"),
					model = model,
				}
				bobStops[model] = CharacterFactory.startBobbing(model)
				PlayerService.refreshLeaderstats(player)
				return slot
			end
		end
	end
	return nil
end

-- Lift a brainrot off a pedestal (a steal, the Janitor, a rebirth). Returns
-- the placed record that was there, model and all.
function PlayerService.removeFromPedestal(player: Player, slot: number)
	local state = states[player]
	if not state then
		return nil
	end
	local placed = state.placed[slot]
	if placed then
		state.placed[slot] = nil
		if placed.model and bobStops[placed.model] then
			bobStops[placed.model]()
			bobStops[placed.model] = nil
		end
		PlayerService.refreshLeaderstats(player)
	end
	return placed
end

-- The fullest pedestal a thief would pick: the highest income on the base.
function PlayerService.richestSlot(player: Player): number?
	local state = states[player]
	if not state then
		return nil
	end
	local bestSlot, bestIncome = nil, -1
	for slot, placed in pairs(state.placed) do
		if placed.income > bestIncome then
			bestIncome = placed.income
			bestSlot = slot
		end
	end
	return bestSlot
end

function PlayerService.freeSlotCount(player: Player): number
	local state = states[player]
	if not state then
		return 0
	end
	local used = 0
	for _ in pairs(state.placed) do
		used += 1
	end
	return PlayerService.pedestalCount(player) - used
end

local function freshState(player: Player, baseIndex: number)
	return {
		cash = GameConfig.StartCash,
		vault = 0,
		lifetime = 0,
		rebirths = 0,
		upgrades = { slippers = 0, backpack = 0, pedestals = 0, longlock = 0 },
		baseIndex = baseIndex,
		placed = {} :: any,
		carried = {} :: any,
		lockedUntil = 0,
		lockReadyAt = 0,
	}
end

local function save(player: Player)
	local state = states[player]
	if not (store and state) then
		return
	end
	local placedList = {}
	for slot, placed in pairs(state.placed) do
		table.insert(placedList, { slot = slot, id = placed.id, mutation = placed.mutation })
	end
	local data = {
		cash = math.floor(state.cash),
		lifetime = math.floor(state.lifetime),
		rebirths = state.rebirths,
		upgrades = state.upgrades,
		placed = placedList,
	}
	pcall(function()
		store:SetAsync("player_" .. player.UserId, data)
	end)
end

local function load(player: Player, state)
	if not store then
		return
	end
	local ok, data = pcall(function()
		return store:GetAsync("player_" .. player.UserId)
	end)
	if not (ok and type(data) == "table") then
		return
	end
	state.cash = data.cash or state.cash
	state.lifetime = data.lifetime or 0
	state.rebirths = data.rebirths or 0
	if type(data.upgrades) == "table" then
		for id, level in pairs(data.upgrades) do
			if state.upgrades[id] ~= nil and type(level) == "number" then
				state.upgrades[id] = level
			end
		end
	end
	-- rebuild the saved pedestals as living models
	if type(data.placed) == "table" then
		for _, saved in ipairs(data.placed) do
			local entry = BrainrotData.ById[saved.id]
			if entry then
				local mutation = BrainrotData.Mutations[1]
				for _, m in ipairs(BrainrotData.Mutations) do
					if m.name == (saved.mutation or "") then
						mutation = m
					end
				end
				local model = CharacterFactory.build(entry, mutation, Vector3.new(0, 0, 0))
				local slot = PlayerService.placeOnPedestal(player, model)
				if not slot then
					model:Destroy()
				end
			end
		end
	end
end

function PlayerService.start()
	Players.PlayerAdded:Connect(function(player)
		local baseIndex = nil
		for index = 1, GameConfig.BaseCount do
			if not baseTaken[index] then
				baseIndex = index
				break
			end
		end
		if not baseIndex then
			-- a seventh player spectates from the street until a base frees up
			baseIndex = 1
		else
			baseTaken[baseIndex] = player
		end
		local state = freshState(player, baseIndex)
		states[player] = state
		load(player, state)
		makeLeaderstats(player, state)
		PlayerService.refreshBase(player)
		PlayerService.refreshLeaderstats(player)
		player.CharacterAdded:Connect(function(character)
			local humanoid = character:WaitForChild("Humanoid")
			humanoid.WalkSpeed = 16 + 2 * state.upgrades.slippers
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		save(player)
		local state = states[player]
		if state then
			if baseTaken[state.baseIndex] == player then
				baseTaken[state.baseIndex] = nil
				local base = bases[state.baseIndex]
				if base then
					local sign = base:FindFirstChild("Sign")
					if sign then
						local gui = sign:FindFirstChild("SignLabel")
						if gui then
							gui.Text.Text = "Nobody's Bazaar"
						end
					end
					for _, placed in pairs(state.placed) do
						if placed.model then
							placed.model:Destroy()
						end
					end
				end
			end
			for _, carried in ipairs(state.carried) do
				if carried.model then
					carried.model:Destroy()
				end
			end
		end
		states[player] = nil
	end)

	-- a gentle autosave, so a crash costs minutes, not the whole bazaar
	task.spawn(function()
		while true do
			task.wait(120)
			for player in pairs(states) do
				save(player)
			end
		end
	end)
end

return PlayerService
