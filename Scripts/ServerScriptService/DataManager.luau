local DSS   = game:GetService("DataStoreService")
local RS    = game:GetService("ReplicatedStorage")
local GD    = require(RS:WaitForChild("GameData"))
local store = DSS:GetDataStore("BrainrotClickerV1")

local DEFAULTS = {
    Brain=0, TotalBrains=0, RawBrains=0, RP=0,
    RebirthCount=0, ClickCount=0, LastLogout=0,
    Generators={}, Upgrades={}, MetaUpgrades={},
}

local M = {}

function M.Load(player)
    local ok, data = pcall(function()
        return store:GetAsync(tostring(player.UserId))
    end)
    if not ok or not data then
        warn("DataManager: load failed for", player.Name, "— using defaults")
        return table.clone(DEFAULTS)
    end
    for k, v in DEFAULTS do
        if data[k] == nil then data[k] = v end
    end
    return data
end

function M.Save(player)
    local ls = player:FindFirstChild("leaderstats")
    local pd = player:FindFirstChild("PlayerData")
    if not ls or not pd then return end
    local gF = pd:FindFirstChild("Generators")
    local uF = pd:FindFirstChild("Upgrades")
    local mF = pd:FindFirstChild("MetaUpgrades")
    local snap = {
        Brain        = ls.Brain         and ls.Brain.Value         or 0,
        TotalBrains  = pd.TotalBrains   and pd.TotalBrains.Value   or 0,
        RawBrains    = pd.RawBrains     and pd.RawBrains.Value     or 0,
        RP           = ls.RP            and ls.RP.Value            or 0,
        RebirthCount = pd.RebirthCount  and pd.RebirthCount.Value  or 0,
        ClickCount   = pd.ClickCount    and pd.ClickCount.Value    or 0,
        LastLogout   = os.time(),
        Generators={}, Upgrades={}, MetaUpgrades={},
    }
    if gF then for _, v in gF:GetChildren() do snap.Generators[v.Name] = v.Value end end
    if uF then for _, v in uF:GetChildren() do if v.Value then snap.Upgrades[v.Name] = true end end end
    if mF then for _, v in mF:GetChildren() do if v.Value then snap.MetaUpgrades[v.Name] = true end end end
    pcall(function() store:SetAsync(tostring(player.UserId), snap) end)
end

return M
