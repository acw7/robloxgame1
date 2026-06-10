local ReplicatedStorage = game:GetService("ReplicatedStorage")

local brainClickRequested = ReplicatedStorage:WaitForChild("BrainClickRequested")

brainClickRequested.OnServerEvent:Connect(function(player: Player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		warn("[BrainClickHandler] leaderstats missing for", player.Name)
		return
	end

	local brain = leaderstats:FindFirstChild("Brain")
	if not brain then
		warn("[BrainClickHandler] Brain IntValue missing for", player.Name)
		return
	end

	local clickMultiplier = leaderstats:FindFirstChild("ClickMultiplier")
	local multiplier = if clickMultiplier then clickMultiplier.Value else 1

	brain.Value += multiplier
end)
