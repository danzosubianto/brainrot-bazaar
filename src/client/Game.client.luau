-- Brainrot Bazaar client: the ScreenGui over the 3D world.
--
-- Everything a player must read is big, because it has to survive being
-- screenshotted and shrunk: cash, income a second and the vault in a bar
-- across the top centre (clear of Roblox's own menu in the top-left), the
-- LOCK and REBIRTH buttons down the right side, an upgrade panel that
-- opens at the Obelisk, and a banner that carries every warning the server
-- sends — the Janitor's bell, the boulder's rumble, the yoinks.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local gui = Instance.new("ScreenGui")
gui.Name = "BazaarHud"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local function makeLabel(parent: Instance, name: string, position: UDim2, size: UDim2, text: string, color: Color3, textSize: number): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Position = position
	label.Size = size
	label.BackgroundTransparency = 0.25
	label.BackgroundColor3 = Color3.fromRGB(18, 14, 28)
	label.Font = Enum.Font.FredokaOne
	label.TextSize = textSize
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.5
	label.Text = text
	label.Parent = parent
	return label
end

local function makeButton(parent: Instance, name: string, position: UDim2, size: UDim2, text: string, color: Color3): TextButton
	local button = Instance.new("TextButton")
	button.Name = name
	button.Position = position
	button.Size = size
	button.BackgroundColor3 = color
	button.BackgroundTransparency = 0.1
	button.Font = Enum.Font.FredokaOne
	button.TextSize = 22
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextStrokeTransparency = 0.5
	button.Text = text
	button.AutoButtonColor = true
	button.Parent = parent
	return button
end

-- The top bar: what you hold, what you earn, what waits in the vault.
local cashLabel = makeLabel(gui, "Cash", UDim2.new(0.5, -320, 0, 12), UDim2.fromOffset(200, 54), "Cash $100", Color3.fromRGB(140, 255, 150), 26)
local rateLabel = makeLabel(gui, "Rate", UDim2.new(0.5, -105, 0, 12), UDim2.fromOffset(210, 54), "$0/s", Color3.fromRGB(255, 230, 130), 26)
local vaultLabel = makeLabel(gui, "Vault", UDim2.new(0.5, 120, 0, 12), UDim2.fromOffset(200, 54), "Vault $0", Color3.fromRGB(255, 190, 80), 26)

-- The carried counter, under the bar: hands full is a fact worth shouting.
local carryLabel = makeLabel(gui, "Carried", UDim2.new(0.5, -110, 0, 74), UDim2.fromOffset(220, 34), "", Color3.fromRGB(220, 200, 255), 19)
carryLabel.BackgroundTransparency = 1

-- The banner: one message at a time, coloured by how much it matters.
local banner = makeLabel(gui, "Banner", UDim2.new(0.5, -360, 0, 118), UDim2.fromOffset(720, 52), "", Color3.fromRGB(255, 255, 255), 24)
banner.BackgroundTransparency = 0.15
banner.TextWrapped = true
banner.Visible = false

local kindColors = {
	info = Color3.fromRGB(255, 255, 255),
	cash = Color3.fromRGB(140, 255, 150),
	good = Color3.fromRGB(120, 255, 190),
	warn = Color3.fromRGB(255, 205, 80),
	bad = Color3.fromRGB(255, 110, 110),
}

local bannerToken = 0
local function showBanner(text: string, kind: string?)
	bannerToken += 1
	local token = bannerToken
	banner.Text = text
	banner.TextColor3 = kindColors[kind or "info"] or kindColors.info
	banner.Visible = true
	task.delay(5, function()
		if bannerToken == token then
			banner.Visible = false
		end
	end)
end

-- Right-side buttons: lock, rebirth, upgrades.
local lockButton = makeButton(gui, "LockButton", UDim2.new(1, -190, 0, 120), UDim2.fromOffset(180, 56), "LOCK BASE", Color3.fromRGB(60, 130, 220))
local rebirthButton = makeButton(gui, "RebirthButton", UDim2.new(1, -190, 0, 186), UDim2.fromOffset(180, 56), "REBIRTH", Color3.fromRGB(150, 60, 200))
local upgradeButton = makeButton(gui, "UpgradeButton", UDim2.new(1, -190, 0, 252), UDim2.fromOffset(180, 56), "UPGRADES", Color3.fromRGB(70, 160, 120))

lockButton.Activated:Connect(function()
	remotes:WaitForChild("ToggleLock"):FireServer()
end)

-- Rebirth burns everything, so it asks twice: first click arms it.
local rebirthArmedUntil = 0
rebirthButton.Activated:Connect(function()
	local now = os.clock()
	if now < rebirthArmedUntil then
		rebirthArmedUntil = 0
		remotes:WaitForChild("DoRebirth"):FireServer()
	else
		rebirthArmedUntil = now + 4
		showBanner("Rebirth burns ALL brainrots and cash for a permanent income bonus. Click REBIRTH again to do it!", "warn")
	end
end)

-- The upgrade panel: one row per upgrade, its level, its next price, and a
-- buy button that stays honest about what you cannot yet afford.
local panel = Instance.new("Frame")
panel.Name = "UpgradePanel"
panel.Position = UDim2.new(0.5, -260, 0.5, -210)
panel.Size = UDim2.fromOffset(520, 420)
panel.BackgroundColor3 = Color3.fromRGB(22, 18, 34)
panel.BackgroundTransparency = 0.08
panel.Visible = false
panel.Parent = gui

local panelTitle = makeLabel(panel, "Title", UDim2.new(0, 0, 0, 0), UDim2.fromOffset(520, 52), "THE OBELISK OF UPGRADES", Color3.fromRGB(170, 230, 255), 26)
panelTitle.BackgroundTransparency = 1

local closeButton = makeButton(panel, "Close", UDim2.new(1, -52, 0, 6), UDim2.fromOffset(44, 40), "X", Color3.fromRGB(160, 60, 60))
closeButton.Activated:Connect(function()
	panel.Visible = false
end)

local rows: { [string]: { button: TextButton, info: TextLabel } } = {}
for i, upgrade in ipairs(GameConfig.Upgrades) do
	local y = 62 + (i - 1) * 86
	local info = makeLabel(panel, upgrade.id .. "Info", UDim2.new(0, 16, 0, y), UDim2.fromOffset(330, 76), "", Color3.fromRGB(255, 255, 255), 17)
	info.TextWrapped = true
	info.TextXAlignment = Enum.TextXAlignment.Left
	info.BackgroundTransparency = 1
	local button = makeButton(panel, upgrade.id .. "Buy", UDim2.new(1, -140, 0, y + 8), UDim2.fromOffset(124, 56), "BUY", Color3.fromRGB(70, 160, 120))
	button.Activated:Connect(function()
		remotes:WaitForChild("BuyUpgrade"):FireServer(upgrade.id)
	end)
	rows[upgrade.id] = { button = button, info = info }
end

upgradeButton.Activated:Connect(function()
	panel.Visible = not panel.Visible
end)
remotes:WaitForChild("OpenUpgrades").OnClientEvent:Connect(function()
	panel.Visible = true
end)

-- State snapshots keep every label honest.
local lastCash = nil
remotes:WaitForChild("StateSync").OnClientEvent:Connect(function(snap)
	cashLabel.Text = string.format("Cash $%d", snap.cash)
	rateLabel.Text = string.format("$%d/s · x%.1f", snap.perSecond, 1 + 0.5 * snap.rebirths)
	vaultLabel.Text = string.format("Vault $%d", snap.vault)
	if lastCash and snap.cash > lastCash then
		-- a little pulse when money lands: juice you can screenshot
		cashLabel.TextSize = 32
		task.delay(0.15, function()
			cashLabel.TextSize = 26
		end)
	end
	lastCash = snap.cash
	if snap.carried > 0 then
		carryLabel.Text = string.format("Carrying %d/%d — get it home!", snap.carried, snap.carryMax)
	else
		carryLabel.Text = ""
	end
	if snap.locked then
		lockButton.Text = string.format("LOCKED %ds", snap.lockLeft)
		lockButton.BackgroundColor3 = Color3.fromRGB(40, 170, 90)
	elseif snap.lockCooldown > 0 then
		lockButton.Text = string.format("LOCK (%ds)", snap.lockCooldown)
		lockButton.BackgroundColor3 = Color3.fromRGB(90, 90, 110)
	else
		lockButton.Text = "LOCK BASE"
		lockButton.BackgroundColor3 = Color3.fromRGB(60, 130, 220)
	end
	if snap.lifetime >= snap.rebirthCost then
		rebirthButton.Text = string.format("REBIRTH %d READY!", snap.rebirths + 1)
	else
		rebirthButton.Text = string.format("REBIRTH ($%d)", snap.rebirthCost)
	end
	for _, upgrade in ipairs(GameConfig.Upgrades) do
		local row = rows[upgrade.id]
		local level = snap.upgrades[upgrade.id] or 0
		local price = upgrade.prices[level + 1]
		row.info.Text = string.format("%s  ·  Lv %d\n%s", upgrade.name, level, upgrade.blurb)
		if price then
			row.button.Text = string.format("$%d", price)
			row.button.BackgroundColor3 = snap.cash >= price and Color3.fromRGB(70, 160, 120) or Color3.fromRGB(90, 90, 110)
		else
			row.button.Text = "MAX"
			row.button.BackgroundColor3 = Color3.fromRGB(90, 90, 110)
		end
	end
end)

remotes:WaitForChild("Notify").OnClientEvent:Connect(function(text, kind)
	showBanner(text, kind)
end)

showBanner("Welcome to BRAINROT BAZAAR! Head north to the glowing sidewalk — your first brainrot awaits.", "info")
