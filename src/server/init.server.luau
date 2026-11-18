-- Brainrot Bazaar, server bootstrap.
--
-- Order matters: the remotes exist before any service listens on them, the
-- world stands before PlayerService deals out its bases, and the welcome
-- tips below are the game's tutorial — a new player is told the whole loop
-- in their first twenty seconds, in the world, not in a manual.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Server = script.Parent
local WorldBuilder = require(Server.WorldBuilder)
local PlayerService = require(Server.PlayerService)
local EconomyService = require(Server.EconomyService)
local ShopService = require(Server.ShopService)
local ThreatService = require(Server.ThreatService)
local RebirthService = require(Server.RebirthService)

local function makeRemotes()
	local remotes = Instance.new("Folder")
	remotes.Name = "Remotes"
	for _, name in ipairs({ "StateSync", "Notify", "ToggleLock", "BuyUpgrade", "DoRebirth", "OpenUpgrades" }) do
		local event = Instance.new("RemoteEvent")
		event.Name = name
		event.Parent = remotes
	end
	remotes.Parent = ReplicatedStorage
	return remotes
end

makeRemotes()

local world = WorldBuilder.build()
PlayerService.setup(world)
PlayerService.start()
EconomyService.start(world)
ShopService.start(world)
ThreatService.start(world)
RebirthService.start(world)

-- The tutorial, drip-fed so it lands one idea at a time.
local welcomeTips = {
	{ 1, "Welcome to BRAINROT BAZAAR! A brainrot is about to step out of the portal, north end of the street." },
	{ 7, "Buy it at the Summoning Sidewalk, then carry it home: step on YOUR plot to place it on a pedestal." },
	{ 14, "Placed brainrots earn into your VAULT. Step on the gold pad to collect. Rarer brainrots earn far more." },
	{ 21, "Beware: the Janitor sweeps UNLOCKED bases, rivals can steal, and the Boulder bonks whatever you carry. The LOCK button is your friend." },
}

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		for _, tip in ipairs(welcomeTips) do
			task.delay(tip[1], function()
				if player.Parent then
					PlayerService.notify(player, tip[2], "info")
				end
			end)
		end
		task.delay(2, function()
			if player.Parent then
				PlayerService.sync(player)
			end
		end)
	end)
end)
