-- GameConfig: every tuning number of Brainrot Bazaar in one place, so the
-- services below read like rules instead of arithmetic.

local GameConfig = {}

-- Money
GameConfig.StartCash = 100
GameConfig.TickSeconds = 1 -- placed brainrots pay into the vault once a tick

-- Bases and pedestals
GameConfig.BaseCount = 6
GameConfig.StartPedestals = 4
GameConfig.MaxPedestals = 10

-- The Summoning Sidewalk
GameConfig.OfferSeconds = 35 -- an unp bought offer wanders back into the portal
GameConfig.OfferGapSeconds = 2.5 -- pause between one offer leaving and the next arriving
GameConfig.StartCarry = 1

-- Locking and stealing
GameConfig.LockSeconds = 45
GameConfig.LockCooldownSeconds = 90
GameConfig.StealHoldSeconds = 1.2 -- standing on a foreign pedestal this long steals it

-- The Janitor, who sweeps unlocked bases
GameConfig.JanitorFirstSweep = 150 -- seconds into the server before his first round
GameConfig.JanitorSweepGapMin = 110
GameConfig.JanitorSweepGapMax = 170
GameConfig.JanitorWarnSeconds = 12 -- the bell rings this long before he moves

-- The Boulder of Responsibility, which bonks carried brainrots home
GameConfig.BoulderGapMin = 170
GameConfig.BoulderGapMax = 260
GameConfig.BoulderWarnSeconds = 8
GameConfig.BoulderSpeed = 55 -- studs a second down the Main Street

-- Rebirth
GameConfig.RebirthBaseCost = 100000 -- lifetime earnings needed for the first one
GameConfig.RebirthCostGrowth = 4 -- each rebirth costs this many times more
GameConfig.RebirthIncomeBonus = 0.5 -- +50% income per rebirth, forever

-- Upgrades sold at the Obelisk. Each entry: id, display name, what it does in
-- words, the price of the next level, and the most levels it can reach.
GameConfig.Upgrades = {
	{
		id = "slippers", name = "Swift Slippers",
		blurb = "+2 walk speed per level. Outrun the boulder. Outrun your problems.",
		prices = { 400, 1500, 5000, 16000 },
	},
	{
		id = "backpack", name = "Double Trouble Backpack",
		blurb = "Carry one more brainrot at a time per level.",
		prices = { 2500, 12000, 50000 },
	},
	{
		id = "pedestals", name = "Extra Pedestals",
		blurb = "+2 pedestals on your base per level.",
		prices = { 1000, 6000, 25000, 90000, 300000 },
	},
	{
		id = "longlock", name = "The Really Good Lock",
		blurb = "+30 seconds of base lock per level.",
		prices = { 3000, 14000, 60000 },
	},
}

GameConfig.UpgradeById = {}
for _, upgrade in ipairs(GameConfig.Upgrades) do
	GameConfig.UpgradeById[upgrade.id] = upgrade
end

-- The price of a player's next rebirth, from how many they already hold.
function GameConfig.rebirthCost(rebirths: number): number
	return GameConfig.RebirthBaseCost * (GameConfig.RebirthCostGrowth ^ rebirths)
end

-- The income multiplier a player's rebirths earn them.
function GameConfig.incomeMultiplier(rebirths: number): number
	return 1 + GameConfig.RebirthIncomeBonus * rebirths
end

return GameConfig
