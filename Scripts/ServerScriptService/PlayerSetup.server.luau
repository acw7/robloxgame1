local Players = game:GetService("Players")

local function setupPlayer(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local brain = Instance.new("IntValue")
	brain.Name = "Brain"
	brain.Value = 0
	brain.Parent = leaderstats

	local clickMultiplier = Instance.new("IntValue")
	clickMultiplier.Name = "ClickMultiplier"
	clickMultiplier.Value = 1
	clickMultiplier.Parent = leaderstats
end

Players.PlayerAdded:Connect(setupPlayer)

-- Cover players who joined before this script ran (e.g. in Studio Play Solo)
for _, player in Players:GetPlayers() do
	if not player:FindFirstChild("leaderstats") then
		setupPlayer(player)
	end
end
