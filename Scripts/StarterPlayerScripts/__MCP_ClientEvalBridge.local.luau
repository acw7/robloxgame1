
-- Installed by @chrrxs/robloxstudio-mcp to power the eval_client_runtime MCP
-- tool (shared-require-cache eval on the client during playtests). Inert
-- outside Studio (no-ops in live games); safe to leave in place.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

if not RunService:IsStudio() then
	return
end

local prevBf = ReplicatedStorage:FindFirstChild("__MCP_ClientEvalBridge")
if prevBf then prevBf:Destroy() end

local bf = Instance.new("BindableFunction")
bf.Name = "__MCP_ClientEvalBridge"
bf.Archivable = false
bf.Parent = ReplicatedStorage
bf.OnInvoke = function(payload)
	if typeof(payload) ~= "Instance" or not payload:IsA("ModuleScript") then
		return { ok = false, value = "payload must be a ModuleScript instance" }
	end
	local ok, value = pcall(require, payload)
	return { ok = ok, value = value }
end
