-- EconomyService: money moves here.
--
-- Once a tick, every placed brainrot pays its rate into its owner's vault;
-- the vault pad turns vault into cash when the owner steps on it. Keeping
-- the money in a vault (instead of paying cash directly) is the loop's
-- heartbeat: it gives the player a reason to keep dashing home, which is
-- exactly where the Janitor and the boulder want to catch them.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local PlayerService = require(script.Parent.PlayerService)

local EconomyService = {}

local function playerFromHit(hit: BasePart): Player?
	local character = hit:FindFirstAncestorOfClass("Model")
	if character then
		return Players:GetPlayerFromCharacter(character)
	end
	return nil
end

local function refreshVaultLabel(player: Player)
	local state = PlayerService.get(player)
	if not state then
		return
	end
	local bases = workspace:FindFirstChild("BazaarWorld")
	-- bases live in Workspace as Base1..Base6 models
	local base = workspace:FindFirstChild("Base" .. state.baseIndex)
	if base then
		local vault = base:FindFirstChild("VaultPad")
		if vault then
			local gui = vault:FindFirstChild("VaultLabel")
			if gui then
				gui.Text.Text = string.format("VAULT\n$%d", math.floor(state.vault))
			end
		end
	end
end

function EconomyService.start(world)
	-- the tick: pedestals pay the vault, the label shows the take
	task.spawn(function()
		while true do
			task.wait(GameConfig.TickSeconds)
			for _, player in ipairs(Players:GetPlayers()) do
				local state = PlayerService.get(player)
				if state then
					local pay = PlayerService.incomePerSecond(player) * GameConfig.TickSeconds
					if pay > 0 then
						state.vault += pay
						refreshVaultLabel(player)
					end
				end
			end
		end
	end)

	-- the pads: step on yours, sweep the vault into cash
	for _, base in ipairs(world.bases) do
		local vault = base:FindFirstChild("VaultPad")
		if vault then
			local debounce = false
			vault.Touched:Connect(function(hit)
				if debounce then
					return
				end
				local player = playerFromHit(hit)
				if not player then
					return
				end
				local state = PlayerService.get(player)
				if not state or state.baseIndex ~= vault:GetAttribute("BaseIndex") then
					return
				end
				if state.vault < 1 then
					return
				end
				debounce = true
				local taken = math.floor(state.vault)
				state.vault = 0
				state.cash += taken
				state.lifetime += taken
				refreshVaultLabel(player)
				PlayerService.refreshLeaderstats(player)
				PlayerService.notify(player, string.format("Vault collected: +$%d", taken), "cash")
				PlayerService.sync(player)
				task.wait(0.4)
				debounce = false
			end)
		end
	end
end

return EconomyService
