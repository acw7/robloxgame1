local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
local brainClickRequested = ReplicatedStorage:WaitForChild("BrainClickRequested")

local VALID_INPUT_TYPES = {
	[Enum.UserInputType.MouseButton1] = true,
	[Enum.UserInputType.Touch] = true,
}

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if not VALID_INPUT_TYPES[input.UserInputType] then return end

	local objectsAtPosition = playerGui:GetGuiObjectsAtPosition(input.Position.X, input.Position.Y)
	if #objectsAtPosition > 0 then return end

	brainClickRequested:FireServer()
end)
