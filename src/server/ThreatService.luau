-- ThreatService: everything that can take a brainrot away.
--
-- Three dangers keep the dash home honest:
--  * The Janitor, an NPC who does his rounds and sweeps the richest
--    UNLOCKED base's best brainrot into the portal. The lock stops him.
--  * The Boulder of Responsibility, which rolls down the Main Street and
--    bonks carried (not yet placed) brainrots clean off your shoulder.
--  * Other players, who can lift a brainrot off an unlocked foreign base
--    by standing at its pedestal — the genre's namesake crime.
-- The base lock (the LockGate in WorldBuilder) answers all three, and this
-- module owns the ToggleLock remote that raises it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local BrainrotData = require(ReplicatedStorage.Shared.BrainrotData)
local PlayerService = require(script.Parent.PlayerService)
local ShopService = require(script.Parent.ShopService)

local ThreatService = {}

local rng = Random.new()
local world = nil

local function broadcast(text: string, kind: string)
	for _, player in ipairs(Players:GetPlayers()) do
		PlayerService.notify(player, text, kind)
	end
end

local function walkTo(model: Model, target: Vector3, speed: number)
	local root = model.PrimaryPart
	if not root then
		return
	end
	while model.Parent do
		local here = root.Position
		local delta = Vector3.new(target.X, here.Y, target.Z) - here
		if delta.Magnitude < 0.7 then
			break
		end
		local step = math.min(delta.Magnitude, speed * 0.05)
		local nextPos = here + delta.Unit * step
		local facing = CFrame.lookAt(nextPos, nextPos + delta.Unit, Vector3.yAxis)
		root.CFrame = CFrame.new(nextPos) * (facing - facing.Position)
		task.wait(0.05)
	end
end

local function isLocked(player: Player): boolean
	local state = PlayerService.get(player)
	return state ~= nil and (state.lockedUntil or 0) > os.clock()
end

-- The lock remote: raise your gate for LockSeconds, then it cools down.
local function watchLockRemote()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	remotes:WaitForChild("ToggleLock").OnServerEvent:Connect(function(player)
		local state = PlayerService.get(player)
		if not state then
			return
		end
		local now = os.clock()
		if (state.lockedUntil or 0) > now then
			PlayerService.notify(player, "Your base is already locked.", "info")
			return
		end
		if (state.lockReadyAt or 0) > now then
			PlayerService.notify(player, string.format("Lock recharging: %ds.", math.ceil(state.lockReadyAt - now)), "warn")
			return
		end
		local seconds = GameConfig.LockSeconds + 30 * state.upgrades.longlock
		state.lockedUntil = now + seconds
		state.lockReadyAt = state.lockedUntil + GameConfig.LockCooldownSeconds
		PlayerService.refreshBase(player)
		PlayerService.notify(player, string.format("Base LOCKED for %ds. The Janitor can whistle.", seconds), "good")
		PlayerService.sync(player)
		task.delay(seconds, function()
			if PlayerService.get(player) then
				PlayerService.refreshBase(player)
				PlayerService.notify(player, "Your lock has dropped.", "warn")
				PlayerService.sync(player)
			end
		end)
	end)
end

-- The Janitor himself: grey, tireless, armed with a broom.
local function buildJanitor(): Model
	local model = Instance.new("Model")
	model.Name = "TheJanitor"
	local function block(name, size, offset, color)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Color = color
		p.Material = Enum.Material.SmoothPlastic
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CFrame = CFrame.new(offset)
		p.Parent = model
		return p
	end
	local legs = block("Legs", Vector3.new(1.5, 1, 0.9), Vector3.new(0, 0.5, 0), Color3.fromRGB(60, 60, 70))
	legs.Anchored = true
	block("Torso", Vector3.new(1.9, 1.4, 1), Vector3.new(0, 1.7, 0), Color3.fromRGB(105, 105, 115))
	block("Head", Vector3.new(1.5, 1.3, 1.3), Vector3.new(0, 2.45, 0), Color3.fromRGB(232, 205, 172))
	block("Cap", Vector3.new(1.7, 0.35, 1.5), Vector3.new(0, 3.2, 0), Color3.fromRGB(50, 50, 60))
	local broom = block("Broom", Vector3.new(0.25, 4.4, 0.25), Vector3.new(1.6, 1.6, -0.6), Color3.fromRGB(150, 110, 60))
	broom.Orientation = Vector3.new(35, 0, 0)
	block("BroomHead", Vector3.new(1.6, 0.7, 0.5), Vector3.new(1.6, 0.35, -1.9), Color3.fromRGB(230, 200, 90))
	local label = Instance.new("BillboardGui")
	label.Name = "Label"
	label.Size = UDim2.fromOffset(260, 60)
	label.StudsOffset = Vector3.new(0, 3.2, 0)
	label.AlwaysOnTop = true
	local text = Instance.new("TextLabel")
	text.Name = "Text"
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Font = Enum.Font.FredokaOne
	text.TextScaled = true
	text.TextColor3 = Color3.fromRGB(200, 200, 210)
	text.TextStrokeTransparency = 0.4
	text.Text = "THE JANITOR"
	text.Parent = label
	label.Parent = model:FindFirstChild("Head")
	model.PrimaryPart = legs
	return model
end

local function janitorRounds()
	task.wait(GameConfig.JanitorFirstSweep)
	while true do
		-- pick the richest unlocked base that has anything worth sweeping
		local victim, victimSlot, victimIncome = nil, nil, -1
		for _, player in ipairs(Players:GetPlayers()) do
			local state = PlayerService.get(player)
			if state and not isLocked(player) then
				local slot = PlayerService.richestSlot(player)
				if slot then
					local placed = state.placed[slot]
					if placed and placed.income > victimIncome then
						victim, victimSlot, victimIncome = player, slot, placed.income
					end
				end
			end
		end

		local janitor = buildJanitor()
		janitor.PrimaryPart.CFrame = CFrame.new(world.portalMouth + Vector3.new(6, 0, 0))
		janitor.Parent = workspace

		if victim then
			broadcast("DING DING. The Janitor is doing his rounds — lock your base!", "warn")
			task.wait(GameConfig.JanitorWarnSeconds)
			-- he may have been locked out while the bell rang
			if PlayerService.get(victim) and not isLocked(victim) and PlayerService.richestSlot(victim) == victimSlot then
				local state = PlayerService.get(victim)
				local base = world.bases[state.baseIndex]
				local pedestals = base:FindFirstChild("Pedestals")
				local pad = pedestals and pedestals:FindFirstChild("Pedestal" .. victimSlot)
				if pad then
					walkTo(janitor, pad.Position + Vector3.new(0, 0, 4), 11)
					local placed = PlayerService.removeFromPedestal(victim, victimSlot)
					if placed and placed.model then
						PlayerService.notify(victim, "The Janitor swept your " .. (placed.model:GetAttribute("BrainrotId") or "brainrot") .. "! Lock your base next time.", "bad")
						-- he carries it back to the portal over his shoulder
						placed.model.PrimaryPart.CFrame = janitor.PrimaryPart.CFrame * CFrame.new(0, 4.6, 0)
						local loot = placed.model
						task.spawn(function()
							while loot.Parent and janitor.Parent do
								loot.PrimaryPart.CFrame = janitor.PrimaryPart.CFrame * CFrame.new(0, 4.6, 0)
								task.wait(0.05)
							end
						end)
						walkTo(janitor, world.portalMouth, 11)
						loot:Destroy()
					end
					PlayerService.sync(victim)
				end
			else
				broadcast("The Janitor found every base locked. He respects it. This time.", "info")
				walkTo(janitor, Vector3.new(0, 1.2, 40), 8)
			end
		else
			-- nobody worth sweeping: he just does a slow, ominous pass
			walkTo(janitor, Vector3.new(0, 1.2, 40), 7)
		end
		janitor:Destroy()
		task.wait(rng:NextNumber(GameConfig.JanitorSweepGapMin, GameConfig.JanitorSweepGapMax))
	end
end

local function boulderWatch()
	task.wait(rng:NextNumber(60, 100))
	while true do
		task.wait(rng:NextNumber(GameConfig.BoulderGapMin, GameConfig.BoulderGapMax))
		if #Players:GetPlayers() == 0 then
			continue
		end
		broadcast("RUMBLE... THE BOULDER OF RESPONSIBILITY IS COMING! Get carried brainrots HOME!", "bad")
		task.wait(GameConfig.BoulderWarnSeconds)
		local boulder = Instance.new("Part")
		boulder.Name = "BoulderOfResponsibility"
		boulder.Shape = Enum.PartType.Ball
		boulder.Size = Vector3.new(11, 11, 11)
		boulder.Color = Color3.fromRGB(90, 85, 80)
		boulder.Material = Enum.Material.Slate
		boulder.Anchored = true
		boulder.CanCollide = false
		boulder.Position = Vector3.new(0, 5.5, -100)
		boulder.Parent = workspace
		local label = Instance.new("BillboardGui")
		label.Size = UDim2.fromOffset(420, 60)
		label.StudsOffset = Vector3.new(0, 7, 0)
		label.AlwaysOnTop = true
		local text = Instance.new("TextLabel")
		text.Name = "Text"
		text.Size = UDim2.fromScale(1, 1)
		text.BackgroundTransparency = 1
		text.Font = Enum.Font.FredokaOne
		text.TextScaled = true
		text.TextColor3 = Color3.fromRGB(255, 120, 120)
		text.TextStrokeTransparency = 0.3
		text.Text = "THE BOULDER OF RESPONSIBILITY"
		text.Parent = label
		label.Parent = boulder
		local z = -100
		while z < 105 and boulder.Parent do
			z += GameConfig.BoulderSpeed * 0.05
			boulder.Position = Vector3.new(0, 5.5, z)
			boulder.Orientation = Vector3.new(-z * 6, 0, 0)
			-- bonk carried brainrots (placed ones are safe at home)
			for _, player in ipairs(Players:GetPlayers()) do
				local state = PlayerService.get(player)
				if state then
					for _, carried in ipairs(state.carried) do
						local root = carried.model and carried.model.PrimaryPart
						if root and (root.Position - boulder.Position).Magnitude < 8 then
							local lost = ShopService.dropCarried(player)
							if lost then
								PlayerService.notify(player, "BONK! The Boulder took your " .. lost.entry.name .. ". Placed brainrots are safe — carry them home faster!", "bad")
							end
							break
						end
					end
					-- and bowl the player themselves over, for comedy
					local character = player.Character
					local hrp = character and character:FindFirstChild("HumanoidRootPart")
					if hrp and (hrp.Position - boulder.Position).Magnitude < 7.5 then
						hrp.AssemblyLinearVelocity = Vector3.new(rng:NextNumber(-14, 14), 26, 30)
					end
				end
			end
			task.wait(0.05)
		end
		boulder:Destroy()
	end
end

-- Player stealing: stand at a foreign, unlocked pedestal and the brainrot
-- changes owners. The progress is per-thief and resets when they step away.
local stealProgress: { [Player]: { victim: Player, slot: number, t: number } } = {}

local function stealWatch()
	while true do
		task.wait(0.2)
		for _, thief in ipairs(Players:GetPlayers()) do
			local tState = PlayerService.get(thief)
			local character = thief.Character
			local hrp = character and character:FindFirstChild("HumanoidRootPart")
			local progress = stealProgress[thief]
			if tState and hrp and #tState.carried < GameConfig.StartCarry + tState.upgrades.backpack then
				local found = nil
				for _, victim in ipairs(Players:GetPlayers()) do
					if victim ~= thief and not isLocked(victim) then
						local vState = PlayerService.get(victim)
						if vState then
							for slot, placed in pairs(vState.placed) do
								local root = placed.model and placed.model.PrimaryPart
								if root and (root.Position - hrp.Position).Magnitude < 4.5 then
									found = { victim = victim, slot = slot }
									break
								end
							end
						end
					end
					if found then
						break
					end
				end
				if found then
					if progress and progress.victim == found.victim and progress.slot == found.slot then
						progress.t += 0.2
					else
						progress = { victim = found.victim, slot = found.slot, t = 0.2 }
						stealProgress[thief] = progress
					end
					if progress.t >= GameConfig.StealHoldSeconds then
						stealProgress[thief] = nil
						local placed = PlayerService.removeFromPedestal(found.victim, found.slot)
						if placed and placed.model then
							local prompt = placed.model.PrimaryPart:FindFirstChild("SellPrompt")
							if prompt then
								prompt:Destroy()
							end
							placed.model.Parent = workspace
							local realEntry = BrainrotData.ById[placed.id]
							local realMutation = nil
							for _, m in ipairs(BrainrotData.Mutations) do
								if m.name == (placed.mutation or "") then
									realMutation = m
								end
							end
							table.insert(tState.carried, { model = placed.model, entry = realEntry or { name = placed.id }, mutation = realMutation })
							PlayerService.notify(thief, "Yoink! Stolen fair and square. Get it home!", "good")
							PlayerService.notify(found.victim, "A rival lifted a brainrot off your base! Lock it next time.", "bad")
							PlayerService.sync(thief)
							PlayerService.sync(found.victim)
						end
					end
				else
					stealProgress[thief] = nil
				end
			else
				stealProgress[thief] = nil
			end
		end
	end
end

function ThreatService.start(w)
	world = w
	watchLockRemote()
	task.spawn(janitorRounds)
	task.spawn(boulderWatch)
	task.spawn(stealWatch)
end

return ThreatService
