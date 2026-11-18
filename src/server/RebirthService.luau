-- RebirthService: the long game.
--
-- Cash buys brainrots; brainrots buy upgrades; and when a player's
-- lifetime earnings pass the rebirth cost, they can burn the whole bazaar
-- down — every placed brainrot and every coin — for a permanent +50%
-- income multiplier and a crown on the player list. That loop (earn, grow,
-- reset stronger) is what keeps a player climbing after the first Mythic,
-- and the Obelisk of Upgrades by the spawn is where the mid-game is spent.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local PlayerService = require(script.Parent.PlayerService)

local RebirthService = {}

local function applyWalkspeed(player: Player)
	local state = PlayerService.get(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if state and humanoid then
		humanoid.WalkSpeed = 16 + 2 * state.upgrades.slippers
	end
end

local function watchRebirth()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	remotes:WaitForChild("DoRebirth").OnServerEvent:Connect(function(player)
		local state = PlayerService.get(player)
		if not state then
			return
		end
		local cost = GameConfig.rebirthCost(state.rebirths)
		if state.lifetime < cost then
			PlayerService.notify(player, string.format("Rebirth needs $%d lifetime earnings. You are at $%d.", cost, math.floor(state.lifetime)), "warn")
			return
		end
		-- burn it all down
		for slot in pairs(state.placed) do
			local placed = PlayerService.removeFromPedestal(player, slot)
			if placed and placed.model then
				placed.model:Destroy()
			end
		end
		for _, carried in ipairs(state.carried) do
			if carried.model then
				carried.model:Destroy()
			end
		end
		state.carried = {}
		state.cash = GameConfig.StartCash
		state.vault = 0
		state.rebirths += 1
		PlayerService.refreshLeaderstats(player)
		PlayerService.refreshBase(player)
		PlayerService.notify(player, string.format("REBIRTH %d! Everything burns, but every brainrot now earns +%d%% forever.", state.rebirths, math.floor(GameConfig.RebirthIncomeBonus * 100 * state.rebirths)), "good")
		PlayerService.sync(player)
	end)
end

local function watchUpgrades()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	remotes:WaitForChild("BuyUpgrade").OnServerEvent:Connect(function(player, upgradeId)
		local state = PlayerService.get(player)
		local upgrade = type(upgradeId) == "string" and GameConfig.UpgradeById[upgradeId] or nil
		if not (state and upgrade) then
			return
		end
		local level = state.upgrades[upgrade.id]
		local price = upgrade.prices[level + 1]
		if not price then
			PlayerService.notify(player, upgrade.name .. " is fully upgraded.", "info")
			return
		end
		if state.cash < price then
			PlayerService.notify(player, string.format("%s needs $%d. You hold $%d.", upgrade.name, price, math.floor(state.cash)), "warn")
			return
		end
		state.cash -= price
		state.upgrades[upgrade.id] = level + 1
		if upgrade.id == "slippers" then
			applyWalkspeed(player)
		elseif upgrade.id == "pedestals" then
			PlayerService.refreshBase(player)
		end
		PlayerService.refreshLeaderstats(player)
		PlayerService.notify(player, string.format("%s level %d! %s", upgrade.name, level + 1, upgrade.blurb), "good")
		PlayerService.sync(player)
	end)
end

local function watchObelisk(world)
	local prompt = world.obelisk and world.obelisk:FindFirstChild("UpgradePrompt")
	if prompt then
		prompt.Triggered:Connect(function(player)
			ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("OpenUpgrades"):FireClient(player)
		end)
	end
end

function RebirthService.start(world)
	watchRebirth()
	watchUpgrades()
	watchObelisk(world)
end

return RebirthService
