
-- Installed by @chrrxs/robloxstudio-mcp to power the eval_server_runtime MCP
-- tool (shared-require-cache eval on the server during playtests). Inert
-- outside Studio (no-ops in live games); safe to leave in place.

local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

if not RunService:IsStudio() then
	return
end

local prevBf = ServerScriptService:FindFirstChild("__MCP_ServerEvalLocal")
if prevBf then prevBf:Destroy() end

local bf = Instance.new("BindableFunction")
bf.Name = "__MCP_ServerEvalLocal"
bf.Archivable = false
bf.Parent = ServerScriptService
bf.OnInvoke = function(payload)
	if typeof(payload) ~= "Instance" or not payload:IsA("ModuleScript") then
		return { ok = false, value = "payload must be a ModuleScript instance" }
	end
	local ok, value = pcall(require, payload)
	return { ok = ok, value = value }
end
