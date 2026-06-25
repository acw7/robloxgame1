# BrainrotClicker: AdCap Endless Loop Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform BrainrotClicker into an Adventure Capitalist–style endless idle game with infinite number scale, a deepened rebirth system granting permanent multipliers and content unlocks, and offline earnings as a core mechanic.

**Architecture:** All economy constants live in `GameData` (single source of truth). A new `DataManager` ModuleScript handles all DataStore I/O. `PlotSetup` drives tier unlocks via a `RebirthCount.Changed` listener. `StatsCalculator` folds the rebirth multiplier in on every recalculate.

**Tech Stack:** Roblox Luau, Roblox Studio MCP tools (`execute_luau`, `start_stop_play`, `get_console_output`), DataStoreService (built-in Roblox service), TweenService.

## Global Constraints

- All economy numbers (costs, BPS, thresholds, multipliers) live in `GameData` — never hardcoded elsewhere.
- After any purchase or state change that affects stats, call `StatsCalculator.Recalculate(player)`.
- Never use `.client.luau` suffix in StarterPlayerScripts — always `.local.luau`.
- Apply Studio changes via `execute_luau` with `datamodel_type="Edit"`. Studio must NOT be in Play mode — call `start_stop_play(is_start=false)` first if needed.
- Every disk file change must also be applied to Studio AND committed to git.
- No raw `tostring(number)` calls in UI code — all displayed numbers go through `GD.FormatNumber`.

---

## File Map

**Modified:**
- `Scripts/ReplicatedStorage/GameData.luau` — Tasks 1, 3, 5, 7
- `Scripts/ServerScriptService/PlotSetup.legacy.luau` — Tasks 2, 4, 5, 6
- `Scripts/ServerScriptService/StatsCalculator.luau` — Task 3
- `Scripts/ServerScriptService/RebirthHandler.legacy.luau` — Task 3
- `Scripts/StarterPlayerScripts/MainClient.local.luau` — Tasks 1, 4, 5, 6

**Created:**
- `Scripts/ServerScriptService/DataManager.luau` — Task 2 (new ModuleScript)

**Studio-only additions via `execute_luau` (no disk file):**
- `ReplicatedStorage.TierUnlocked` RemoteEvent — Task 4
- `ReplicatedStorage.OfflineEarnings` RemoteEvent — Task 6
- `Workspace.Plots.*` — Slot6–10 anchors + Tier 2 pads per plot — Task 5
- `Workspace.Plots.*` — Slot11–15 anchors + Tier 3 pads per plot — Task 7

---

## Task 1: FormatNumber Utility

**Files:**
- Modify: `Scripts/ReplicatedStorage/GameData.luau`
- Modify: `Scripts/ServerScriptService/PlotSetup.legacy.luau`
- Modify: `Scripts/StarterPlayerScripts/MainClient.local.luau`

**Interfaces:**
- Produces: `GD.FormatNumber(n: number) → string` — used by all display code throughout the codebase

**Format rules:** Suffix steps up at 100× the current unit (e.g. K range is 1–99.999K; 100K becomes 0.100M). Always 3 decimal places. Below 1000: plain integer. Above Dc (1e33): scientific notation.

Examples: 947→"947", 1234→"1.234K", 12345→"12.345K", 100000→"0.100M", 1234567→"1.234M"

- [ ] **Step 1: Add FormatNumber to GameData on disk**

In `Scripts/ReplicatedStorage/GameData.luau`, add these lines immediately before `return GD`:

```lua
local _SFX = {"K","M","B","T","Qa","Qi","Sx","Sp","Oc","No","Dc"}
local _DIV, _THR = {}, {}
for i = 1, #_SFX do
    _DIV[i] = 10^(i*3)
    _THR[i] = (i==1) and 1e3 or (100 * _DIV[i-1])
end
function GD.FormatNumber(n)
    if not n or n ~= n then return "0" end
    n = math.max(0, math.floor(n))
    if n < 1000 then return tostring(n) end
    local si = 0
    for i = 1, #_SFX do
        if n >= _THR[i] then si = i else break end
    end
    if si == 0 then return tostring(n) end
    if si == #_SFX and n >= 100 * _DIV[si] then
        local e = math.floor(math.log10(n))
        return string.format("%.3fe%d", n / (10^e), e)
    end
    return string.format("%.3f", n / _DIV[si]) .. _SFX[si]
end
```

- [ ] **Step 2: Apply GameData to Studio**

```lua
-- execute_luau (Edit datamodel) — set the full updated source:
game:GetService("ReplicatedStorage"):WaitForChild("GameData").Source = [[ FULL GameData.luau CONTENT ]]
```

- [ ] **Step 3: Replace local fmt in PlotSetup (disk + Studio)**

In `Scripts/ServerScriptService/PlotSetup.legacy.luau`, replace lines 17–21 (the local `fmt` function):

```lua
-- REMOVE this block:
local function fmt(n) n=math.floor(n)
    if n>=1e6 then return("%.1fM"):format(n/1e6)
    elseif n>=1e3 then return("%.1fK"):format(n/1e3)
    else return tostring(n) end
end

-- REPLACE WITH:
local function fmt(n) return GD.FormatNumber(n) end
```

Apply full PlotSetup source to Studio via execute_luau.

- [ ] **Step 4: Replace local fmt in MainClient (disk + Studio)**

In `Scripts/StarterPlayerScripts/MainClient.local.luau`, replace lines 28–35 (the local `fmt` function):

```lua
-- REMOVE this block:
local function fmt(n)
    n=math.floor(n)
    if n>=1e12 then return("%.2fT"):format(n/1e12)
    elseif n>=1e9 then return("%.2fB"):format(n/1e9)
    elseif n>=1e6 then return("%.2fM"):format(n/1e6)
    elseif n>=1e3 then return("%.1fK"):format(n/1e3)
    else return tostring(n) end
end

-- REPLACE WITH:
local fmt = GD.FormatNumber
```

Apply full MainClient source to Studio via execute_luau.

- [ ] **Step 5: Verify in Studio**

```
1. execute_luau: start_stop_play(is_start=true)
2. execute_luau: get_console_output — expect zero errors
3. Click Brain until you pass 1000. HUD should show "1.000K", "1.234K", etc.
4. execute_luau: start_stop_play(is_start=false)
```

- [ ] **Step 6: Commit**

```bash
git add Scripts/ReplicatedStorage/GameData.luau Scripts/ServerScriptService/PlotSetup.legacy.luau Scripts/StarterPlayerScripts/MainClient.local.luau
git commit -m "feat: add FormatNumber utility (##.### with 100x suffix step-up)"
```

---

## Task 2: DataStore Persistence

**Files:**
- Create: `Scripts/ServerScriptService/DataManager.luau`
- Modify: `Scripts/ServerScriptService/PlotSetup.legacy.luau`

**Interfaces:**
- Produces: `DataManager.Load(player) → savedData` — returns saved table or defaults on first play / error
- Produces: `DataManager.Save(player)` — serialises player state and writes to DataStore

- [ ] **Step 1: Create DataManager.luau on disk**

Create `Scripts/ServerScriptService/DataManager.luau` with this full content:

```lua
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
```

- [ ] **Step 2: Create DataManager in Studio**

```lua
-- execute_luau (Edit datamodel):
local m = Instance.new("ModuleScript")
m.Name = "DataManager"
m.Parent = game:GetService("ServerScriptService")
m.Source = [[ FULL DataManager.luau CONTENT ]]
```

- [ ] **Step 3: Rewrite setupData in PlotSetup to load from DataManager**

At the top of PlotSetup (after the existing `require` calls), add:

```lua
local DataMgr = require(SSS:WaitForChild("DataManager"))
```

Replace the entire `setupData` function (lines 23–39) with:

```lua
local function setupData(player)
    if player:FindFirstChild("leaderstats") then return nil end
    local saved = DataMgr.Load(player)

    local ls = Instance.new("Folder"); ls.Name="leaderstats"; ls.Parent=player
    local brainV = Instance.new("NumberValue",ls); brainV.Name="Brain"; brainV.Value=saved.Brain
    local rpV    = Instance.new("IntValue",ls);    rpV.Name="RP";       rpV.Value=saved.RP

    local pd = Instance.new("Folder"); pd.Name="PlayerData"; pd.Parent=player
    local tbV = Instance.new("NumberValue",pd); tbV.Name="TotalBrains"; tbV.Value=saved.TotalBrains
    local rbV = Instance.new("NumberValue",pd); rbV.Name="RawBrains";   rbV.Value=saved.RawBrains
    local bpcV2 = Instance.new("NumberValue",pd); bpcV2.Name="BPC"; bpcV2.Value=1
    Instance.new("NumberValue",pd).Name="BPS"
    local ccV = Instance.new("IntValue",pd); ccV.Name="ClickCount";   ccV.Value=saved.ClickCount
    local rcV = Instance.new("IntValue",pd); rcV.Name="RebirthCount"; rcV.Value=saved.RebirthCount

    local gF = Instance.new("Folder",pd); gF.Name="Generators"
    for _,g in GD.Generators do
        local v = Instance.new("IntValue",gF); v.Name=g.id
        v.Value = saved.Generators[g.id] or 0
    end
    local uF = Instance.new("Folder",pd); uF.Name="Upgrades"
    for _,u in GD.Upgrades do
        local v = Instance.new("BoolValue",uF); v.Name=u.id
        v.Value = saved.Upgrades[u.id] or false
    end
    local mF = Instance.new("Folder",pd); mF.Name="MetaUpgrades"
    for _,u in GD.MetaUpgrades do
        local v = Instance.new("BoolValue",mF); v.Name=u.id
        v.Value = saved.MetaUpgrades[u.id] or false
    end
    return saved  -- returned to onAdded for offline earnings (Task 6)
end
```

- [ ] **Step 4: Update PlayerRemoving and add auto-save in PlotSetup**

Replace the `Players.PlayerRemoving` line (currently line 274):

```lua
Players.PlayerRemoving:Connect(function(p)
    DataMgr.Save(p)
    clickThrottle[p]=nil
    PlotMgr.FreePlot(p)
end)
```

Add auto-save loop after the `PlayerRemoving` block:

```lua
task.spawn(function()
    while true do
        task.wait(60)
        for _, p in Players:GetPlayers() do
            DataMgr.Save(p)
        end
    end
end)
```

Apply full PlotSetup source to Studio via execute_luau.

- [ ] **Step 5: Verify persistence in Studio**

```
1. execute_luau: start_stop_play(is_start=true)
2. execute_luau: get_console_output — first load warns "using defaults" (expected for new save)
3. Buy a BrainJar (click Brain to get 10 Brains, walk the BrainJarPad)
4. execute_luau: start_stop_play(is_start=false)  ← triggers PlayerRemoving → Save
5. execute_luau: start_stop_play(is_start=true)   ← re-joins, loads saved data
6. execute_luau: get_console_output — no "load failed" message; BrainJar count should be 1
7. execute_luau: start_stop_play(is_start=false)
```

- [ ] **Step 6: Commit**

```bash
git add Scripts/ServerScriptService/DataManager.luau Scripts/ServerScriptService/PlotSetup.legacy.luau
git commit -m "feat: DataStore persistence via DataManager — save/load on join/leave + 60s auto-save"
```

---

## Task 3: RebirthCount + Permanent Multiplier

**Files:**
- Modify: `Scripts/ReplicatedStorage/GameData.luau` — add 3 new constants
- Modify: `Scripts/ServerScriptService/StatsCalculator.luau` — fold rebirthMult into BPS/BPC
- Modify: `Scripts/ServerScriptService/RebirthHandler.legacy.luau` — increment RC, updated Neuron formula

**Interfaces:**
- Consumes: `player.PlayerData.RebirthCount` IntValue (created by setupData in Task 2)
- Produces: `GD.NeuronFormulaDivisor`, `GD.RebirthMultPerLevel`, `GD.RebirthMilestones` used by Task 4+

- [ ] **Step 1: Add constants to GameData (disk + Studio)**

Add these lines immediately after `GD.RPProductionBonus = 0.1` in `Scripts/ReplicatedStorage/GameData.luau`:

```lua
GD.NeuronFormulaDivisor = 100000   -- neurons = max(1, floor(TotalBrains / this))
GD.RebirthMultPerLevel  = 0.10     -- permanent +10% global BPS & BPC per rebirth (stacks)
GD.RebirthMilestones = {
    [1]  = { unlockTier = 2, upgradeCategory = "NeuralExpansion" },
    [5]  = { unlockTier = 3, upgradeCategory = "CortexOverdrive" },
    [10] = { extraMetaSlot = true },
    [25] = { reserved = true },
}
```

Apply GameData to Studio via execute_luau.

- [ ] **Step 2: Update StatsCalculator to fold rebirthMult (disk + Studio)**

In `Scripts/ServerScriptService/StatsCalculator.luau`, replace lines 41–59 (from `local bps=0` to end of function) with:

```lua
    local rcV = pd:FindFirstChild("RebirthCount")
    local rc  = rcV and rcV.Value or 0
    local rebirthMult = (1 + GD.RebirthMultPerLevel) ^ rc

    local bps = 0
    for _,g in GD.Generators do
        local cv = gF:FindFirstChild(g.id)
        if not cv or cv.Value <= 0 then continue end
        local mm = 1
        for _,ms in GD.Milestones do if cv.Value >= ms then mm *= GD.MilestoneMult end end
        bps += g.baseBPS * cv.Value * mm * (gM[g.id] or 1)
    end
    bps *= globalM
    local rpBonus = 1 + rp * GD.RPProductionBonus
    bps *= rpBonus * rebirthMult
    bpcV.Value = math.max(1, math.floor(bpc * bm * rpBonus * rebirthMult))
    bpsV.Value = bps
    player:SetAttribute("CritChance", math.min(critPct, 40))
    player:SetAttribute("SpeedBonus", speedAdd)
    local char = player.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = 16 + speedAdd end
end
return M
```

Apply StatsCalculator to Studio via execute_luau.

- [ ] **Step 3: Rewrite RebirthHandler (disk + Studio)**

Replace the entire `rebirthEv.OnServerEvent:Connect` handler body in `Scripts/ServerScriptService/RebirthHandler.legacy.luau`:

```lua
rebirthEv.OnServerEvent:Connect(function(player)
    local ls = player:FindFirstChild("leaderstats")
    local pd = player:FindFirstChild("PlayerData")
    if not ls or not pd then return end
    local brainV = ls:FindFirstChild("Brain")
    local rpV    = ls:FindFirstChild("RP")
    local totalV = pd:FindFirstChild("TotalBrains")
    local rcV    = pd:FindFirstChild("RebirthCount")
    if not brainV or not rpV or not totalV or not rcV then return end
    if totalV.Value < GD.RebirthThreshold then return end

    -- Scaling Neurons: max(1, floor(TotalBrains / NeuronFormulaDivisor))
    local rpGain = math.max(1, math.floor(totalV.Value / GD.NeuronFormulaDivisor))
    local mF = pd:FindFirstChild("MetaUpgrades")
    local iiV = mF and mF:FindFirstChild("InvestorInsight")
    if iiV and iiV.Value then rpGain += 1 end
    rpV.Value += rpGain

    -- Increment RebirthCount — PlotSetup listens to .Changed for tier unlocks (Task 4)
    rcV.Value += 1

    -- Reset run state
    brainV.Value = 0; totalV.Value = 0
    local rawV = pd:FindFirstChild("RawBrains"); if rawV then rawV.Value = 0 end
    local ccV  = pd:FindFirstChild("ClickCount"); if ccV  then ccV.Value  = 0 end
    local gF   = pd:FindFirstChild("Generators")
    if gF then for _, v in gF:GetChildren() do v.Value = 0 end end
    local uF   = pd:FindFirstChild("Upgrades")
    if uF then for _, v in uF:GetChildren() do v.Value = false end end

    -- Clear machines from plot
    local plot = PlotMgr.GetPlot(player)
    if plot then
        local machines = plot:FindFirstChild("Machines")
        if machines then for _, m in machines:GetChildren() do m:Destroy() end end
    end

    -- SafetyNet meta upgrade
    local snV = mF and mF:FindFirstChild("SafetyNet")
    if snV and snV.Value then
        brainV.Value = 500
        if gF then local jarV = gF:FindFirstChild("BrainJar"); if jarV then jarV.Value = 1 end end
    end

    Stats.Recalculate(player)

    -- Teleport to spawn anchor
    task.spawn(function()
        task.wait(0.5)
        if not plot then return end
        local anchor = plot:FindFirstChild("SpawnAnchor")
        local char   = player.Character
        local hrp    = char and char:FindFirstChild("HumanoidRootPart")
        if anchor and hrp then hrp.CFrame = CFrame.new(anchor.Position + Vector3.new(0,6,0)) end
    end)
end)
```

Apply RebirthHandler to Studio via execute_luau.

- [ ] **Step 4: Verify rebirth depth in Studio**

```
1. execute_luau: start_stop_play(is_start=true)
2. execute_luau: get_console_output — no errors
3. Earn 100,000 TotalBrains (buy generators, wait for BPS), then rebirth
4. Confirm: RP increases by floor(TotalBrains/100000), RebirthCount becomes 1
5. Confirm: BPS is ~10% higher than an identical generator loadout at RC=0
   (compare bpsV.Value before and after rebirth via Explorer)
6. execute_luau: start_stop_play(is_start=false)
```

- [ ] **Step 5: Commit**

```bash
git add Scripts/ReplicatedStorage/GameData.luau Scripts/ServerScriptService/StatsCalculator.luau Scripts/ServerScriptService/RebirthHandler.legacy.luau
git commit -m "feat: RebirthCount, scaling Neurons, permanent stacking BPS/BPC multiplier"
```

---

## Task 4: Milestone Tier-Gating + TierUnlocked Flow

**Files:**
- Modify: `Scripts/ServerScriptService/PlotSetup.legacy.luau` — tier-gated pad wiring, RC.Changed listener
- Modify: `Scripts/StarterPlayerScripts/MainClient.local.luau` — TierUnlocked banner

**Interfaces:**
- Consumes: `GD.RebirthMilestones` (Task 3), `gen.tier` field (added in Task 5 — gating is a no-op until then)
- Produces: `TierUnlocked` RemoteEvent; tier-aware `connectPlot`

- [ ] **Step 1: Add TierUnlocked RemoteEvent to Studio**

```lua
-- execute_luau (Edit datamodel):
local re = Instance.new("RemoteEvent")
re.Name = "TierUnlocked"
re.Parent = game:GetService("ReplicatedStorage")
print("TierUnlocked event created")
```

- [ ] **Step 2: Add tier helpers and gating to PlotSetup (disk + Studio)**

At the top of PlotSetup, add after the existing RemoteEvent requires:

```lua
local tierUnlockedEv = RS:WaitForChild("TierUnlocked")

local function getMaxTier(rebirthCount)
    local maxT = 1
    for rb, ms in GD.RebirthMilestones do
        if rebirthCount >= rb and ms.unlockTier then
            maxT = math.max(maxT, ms.unlockTier)
        end
    end
    return maxT
end
```

In `connectPlot`, replace the `local touchDebounce={}` block and the generator-pad Touched loop with:

```lua
    local pd2     = player:FindFirstChild("PlayerData")
    local rcV2    = pd2 and pd2:FindFirstChild("RebirthCount")
    local maxTier = getMaxTier(rcV2 and rcV2.Value or 0)

    local touchDebounce = {}

    local function wirePadForGen(gen)
        local pad = plot:FindFirstChild(gen.id.."Pad"); if not pad then return end
        pad.Touched:Connect(function(hit)
            local char = hit.Parent
            local p = Players:GetPlayerFromCharacter(char)
            if not p or p ~= player then return end
            local now = tick()
            if touchDebounce[gen.id] and now - touchDebounce[gen.id] < 0.4 then return end
            touchDebounce[gen.id] = now
            local ls3  = player:FindFirstChild("leaderstats")
            local pd3  = player:FindFirstChild("PlayerData")
            if not ls3 or not pd3 then return end
            local brainV3 = ls3:FindFirstChild("Brain")
            local genF3   = pd3:FindFirstChild("Generators")
            local uF3     = pd3:FindFirstChild("Upgrades")
            local mF3     = pd3:FindFirstChild("MetaUpgrades")
            if not brainV3 or not genF3 then return end
            local cv = genF3:FindFirstChild(gen.id); if not cv then return end
            local earlyAccess = (mF3 and mF3:FindFirstChild("EarlyAccess") and mF3.EarlyAccess.Value)
                and (gen.id=="BrainJar" or gen.id=="MemeFarm")
            local function getCost(owned)
                local c = GD.GetGeneratorCost(gen, owned)
                return earlyAccess and math.floor(c*0.5) or c
            end
            local qty = 1
            local bulkV = uF3 and uF3:FindFirstChild("BulkBuyI")
            if bulkV and bulkV.Value then
                qty = 0; local tb = brainV3.Value; local to = cv.Value
                for _ = 1, 5 do
                    local c2 = getCost(to)
                    if tb >= c2 then tb -= c2; to += 1; qty += 1 else break end
                end
                if qty == 0 then return end
            else
                if brainV3.Value < getCost(cv.Value) then return end
            end
            local totalCost = 0
            for i = 0, qty-1 do totalCost += getCost(cv.Value+i) end
            if brainV3.Value < totalCost then return end
            brainV3.Value -= totalCost; cv.Value += qty
            Stats.Recalculate(player)
            spawnMachine(gen, plot)
            updatePadLabel(pad, gen, cv.Value)
        end)
    end

    for _, gen in GD.Generators do
        if (gen.tier or 1) <= maxTier then wirePadForGen(gen) end
    end
```

At the end of `connectPlot` (after `startOrbSpawner(player, plot)`), add the RC.Changed listener:

```lua
    -- Watch RebirthCount for milestone tier unlocks
    if rcV2 then
        rcV2.Changed:Connect(function(newCount)
            local ms = GD.RebirthMilestones[newCount]
            if ms and ms.unlockTier then
                -- Wire pads for the newly unlocked tier
                for _, gen in GD.Generators do
                    if (gen.tier or 1) == ms.unlockTier then
                        wirePadForGen(gen)
                    end
                end
                tierUnlockedEv:FireClient(player, ms.unlockTier)
            end
        end)
    end
```

Apply full PlotSetup source to Studio via execute_luau.

- [ ] **Step 3: Add TierUnlocked banner to MainClient (disk + Studio)**

In `Scripts/StarterPlayerScripts/MainClient.local.luau`, add after the BPS Storm overlay block (after the `bpsStormEv.OnClientEvent:Connect` block):

```lua
local tierUnlockedEv2 = RS:WaitForChild("TierUnlocked")
local tierBanner = frm(sg, Color3.fromRGB(0,180,80), UDim2.new(1,0,0,32), UDim2.new(0,0,0,70))
tierBanner.BackgroundTransparency = 1
local tierBannerLbl = lbl(tierBanner, "", UDim2.new(1,0,1,0), nil, Color3.new(1,1,1), 15)
tierBannerLbl.TextStrokeTransparency = 0
tierUnlockedEv2.OnClientEvent:Connect(function(tier)
    local msgs = {
        [2] = "TIER 2 UNLOCKED!  New generators on the 2nd floor!",
        [3] = "TIER 3 UNLOCKED!  Even more power awaits!",
    }
    tierBannerLbl.Text = msgs[tier] or ("TIER "..tier.." UNLOCKED!")
    tierBanner.BackgroundTransparency = 0
    task.delay(4, function()
        Tween:Create(tierBanner, TweenInfo.new(0.5), {BackgroundTransparency=1}):Play()
        task.delay(0.5, function() tierBannerLbl.Text = "" end)
    end)
end)
```

Apply full MainClient source to Studio via execute_luau.

- [ ] **Step 4: Verify tier-gating and banner in Studio**

```
1. execute_luau: start_stop_play(is_start=true)
2. execute_luau: get_console_output — no errors
3. Via Studio Explorer, set player.PlayerData.RebirthCount to 1
   (This fires .Changed → triggers the RC.Changed listener)
4. Observe: "TIER 2 UNLOCKED!" green banner appears at top of screen
5. execute_luau: start_stop_play(is_start=false)
```

- [ ] **Step 5: Commit**

```bash
git add Scripts/ServerScriptService/PlotSetup.legacy.luau Scripts/StarterPlayerScripts/MainClient.local.luau
git commit -m "feat: tier-gated pad wiring and TierUnlocked banner on milestone rebirth"
```

---

## Task 5: Tier 2 Generators

**Files:**
- Modify: `Scripts/ReplicatedStorage/GameData.luau` — add `tier` field + 5 Tier 2 generators + NeuralExpansion upgrades
- Modify: `Scripts/ServerScriptService/PlotSetup.legacy.luau` — GEN_COLORS and GEN_SLOTS
- Modify: `Scripts/StarterPlayerScripts/MainClient.local.luau` — NeuralExpansion shop scroll
- Studio: Slot6–10 anchors + Tier 2 pads on second floor of all 6 plots

**Interfaces:**
- Produces: `GD.Generators[i].tier` field on all generators (Tier 1 = 1, Tier 2 = 2)
- Produces: 5 new generators with `tier=2`; 5 `NeuralExpansion` upgrades

- [ ] **Step 1: Update GD.Generators in GameData (disk + Studio)**

Replace the `GD.Generators` table in `Scripts/ReplicatedStorage/GameData.luau`:

```lua
GD.Generators = {
    -- Tier 1 (start)
    {id="BrainJar",       name="Brain Jar",        desc="Leaks Brains slowly.",           baseCost=10,              baseBPS=0.1,         costMult=1.15, tier=1},
    {id="MemeFarm",       name="Meme Farm",         desc="Harvests viral memes.",           baseCost=100,             baseBPS=0.5,         costMult=1.15, tier=1},
    {id="DoomscrollRig",  name="Doomscroll Rig",    desc="Auto-scrolls for raw output.",    baseCost=1100,            baseBPS=4,           costMult=1.15, tier=1},
    {id="NeuralTap",      name="Neural Tap",         desc="Taps into the brain stem.",       baseCost=12000,           baseBPS=20,          costMult=1.15, tier=1},
    {id="SkibidiLab",     name="Skibidi Lab",        desc="Advanced skibidi science.",       baseCost=130000,          baseBPS=100,         costMult=1.15, tier=1},
    -- Tier 2 (unlock at 1st rebirth via GD.RebirthMilestones)
    {id="NeuralNetwork",  name="Neural Network",     desc="Self-improving brain cluster.",   baseCost=5000000,         baseBPS=5000,        costMult=1.15, tier=2},
    {id="MemeVault",      name="Meme Vault",         desc="Stores memes for passive yield.", baseCost=50000000,        baseBPS=25000,       costMult=1.15, tier=2},
    {id="DopamineDen",    name="Dopamine Den",       desc="Pure dopamine production.",       baseCost=500000000,       baseBPS=125000,      costMult=1.15, tier=2},
    {id="CortexCollider", name="Cortex Collider",    desc="Smashes cortex for big BPS.",     baseCost=5000000000,      baseBPS=600000,      costMult=1.15, tier=2},
    {id="QuantumQuirk",   name="Quantum Quirk",      desc="Quantum-entangled brain farms.",  baseCost=50000000000,     baseBPS=3000000,     costMult=1.15, tier=2},
}
```

Also append these NeuralExpansion upgrades to `GD.Upgrades` before the closing `}`:

```lua
    -- === Neural Expansion (Tier 2 upgrades, visible after 1st rebirth) ===
    {id="SynapticBoostI",  name="Synaptic Boost I",    desc="×2 Neural Network BPS",      tier="NeuralExpansion", type="genMult",   baseCost=50000000,      genId="NeuralNetwork",  genMult=2,   req={type="genOwned",id="NeuralNetwork",count=10}},
    {id="MemeCacheI",      name="Meme Cache I",         desc="×2 Meme Vault BPS",          tier="NeuralExpansion", type="genMult",   baseCost=500000000,     genId="MemeVault",      genMult=2,   req={type="genOwned",id="MemeVault",count=10}},
    {id="DopamineRushI",   name="Dopamine Rush I",      desc="×1.5 global BPS",            tier="NeuralExpansion", type="globalBPS", baseCost=2000000000,    bpsMult=1.5,             req={type="genOwned",id="DopamineDen",count=5}},
    {id="ColliderMatrix",  name="Collider Matrix",      desc="×2 Cortex Collider BPS",     tier="NeuralExpansion", type="genMult",   baseCost=20000000000,   genId="CortexCollider", genMult=2,   req={type="genOwned",id="CortexCollider",count=5}},
    {id="QuantumEntangle", name="Quantum Entanglement", desc="×2 global BPS",              tier="NeuralExpansion", type="globalBPS", baseCost=200000000000,  bpsMult=2,               req={type="genOwned",id="QuantumQuirk",count=5}},
```

Apply GameData to Studio via execute_luau.

- [ ] **Step 2: Extend GEN_COLORS and GEN_SLOTS in PlotSetup (disk + Studio)**

Replace lines 14–15 of PlotSetup:

```lua
local GEN_COLORS = {
    BrainJar=BrickColor.new("Bright blue"),      MemeFarm=BrickColor.new("Bright green"),
    DoomscrollRig=BrickColor.new("Dark orange"),  NeuralTap=BrickColor.new("Electric blue"),
    SkibidiLab=BrickColor.new("Bright violet"),
    -- Tier 2
    NeuralNetwork=BrickColor.new("Cyan"),          MemeVault=BrickColor.new("Lime green"),
    DopamineDen=BrickColor.new("Hot pink"),        CortexCollider=BrickColor.new("Deep orange"),
    QuantumQuirk=BrickColor.new("Magenta"),
}
local GEN_SLOTS = {
    BrainJar=1, MemeFarm=2, DoomscrollRig=3, NeuralTap=4, SkibidiLab=5,
    -- Tier 2 (slots 6–10 on second floor)
    NeuralNetwork=6, MemeVault=7, DopamineDen=8, CortexCollider=9, QuantumQuirk=10,
}
```

Apply PlotSetup to Studio via execute_luau.

- [ ] **Step 3: Create Slot6–10 anchors and Tier 2 pads in Studio**

```lua
-- execute_luau (Edit datamodel):
local TIER2 = {
    {id="NeuralNetwork",  name="Neural Network"},
    {id="MemeVault",      name="Meme Vault"},
    {id="DopamineDen",    name="Dopamine Den"},
    {id="CortexCollider", name="Cortex Collider"},
    {id="QuantumQuirk",   name="Quantum Quirk"},
}
for _, plot in game.Workspace.Plots:GetChildren() do
    local floor = plot:FindFirstChild("Floor"); if not floor then continue end
    local cx = floor.Position.X; local cz = floor.Position.Z
    local sf  = plot:FindFirstChild("SecondFloor_R")
    local padY = sf and (sf.Position.Y + sf.Size.Y/2 + 1) or 22
    local f   = cz < 0 and 1 or -1
    for i, g in ipairs(TIER2) do
        local slotX = cx - 20 + (i-1)*10
        local padZ  = cz - f*22
        -- Invisible slot anchor
        if not plot:FindFirstChild("Slot"..(i+5)) then
            local slot = Instance.new("Part")
            slot.Name = "Slot"..(i+5); slot.Size = Vector3.new(1,1,1)
            slot.Position = Vector3.new(slotX, padY+3, padZ)
            slot.Anchored = true; slot.Transparency = 1; slot.CanCollide = false
            slot.Parent = plot
        end
        -- Generator pad
        if not plot:FindFirstChild(g.id.."Pad") then
            local pad = Instance.new("Part")
            pad.Name = g.id.."Pad"; pad.Size = Vector3.new(8,1,8)
            pad.Position = Vector3.new(slotX, padY, padZ)
            pad.Anchored = true; pad.BrickColor = BrickColor.new("Dark stone grey")
            pad.Material = Enum.Material.SmoothPlastic; pad.Parent = plot
            local bg = Instance.new("BillboardGui", pad)
            bg.Name = "Label"; bg.Size = UDim2.new(0,140,0,36)
            bg.StudsOffset = Vector3.new(0,3,0)
            local tl = Instance.new("TextLabel", bg)
            tl.Size = UDim2.new(1,0,1,0); tl.BackgroundTransparency = 1
            tl.Text = g.name; tl.TextColor3 = Color3.new(1,1,1)
            tl.TextStrokeTransparency = 0; tl.Font = Enum.Font.GothamBold
            tl.TextSize = 13; tl.Parent = bg
        end
    end
end
print("Tier 2 pads done — check second floor of each plot")
```

- [ ] **Step 4: Add NeuralExpansion scroll to MainClient shop (disk + Studio)**

In `Scripts/StarterPlayerScripts/MainClient.local.luau`:

1. Add alongside the other scroll declarations (after `local metaScroll=scroll(shopPanel)`):
```lua
local neuralScroll = scroll(shopPanel)
```

2. Update the upgrade card routing loop:
```lua
for _,u in GD.Upgrades do
    local parent = u.tier=="generator" and genScroll
        or u.tier=="NeuralExpansion" and neuralScroll
        or upgScroll
    makeUpgradeCard(parent,u,true)
end
```

3. Update `openShop` to show neuralScroll and add its title:
```lua
-- In openShop function, add:
neuralScroll.Visible = cat=="NeuralExpansion"

-- In titles table, add:
NeuralExpansion = "Neural Expansion Lab",
```

4. Also add `NeuralExpansion` to `openShopEv` handling in PlotSetup's ProximityPrompt section:
```lua
elseif cat=="generator" or cat=="upgrades" or cat=="rebirth" or cat=="NeuralExpansion" then
    openShopEv:FireClient(player,cat)
```

Apply MainClient and PlotSetup to Studio via execute_luau.

- [ ] **Step 5: Verify Tier 2 in Studio**

```
1. execute_luau: start_stop_play(is_start=true)
2. execute_luau: get_console_output — no errors
3. Via Explorer, set player.PlayerData.RebirthCount = 1
   — "TIER 2 UNLOCKED!" banner should appear
4. Navigate to the second floor. Confirm 5 new pads are visible.
5. Via Explorer, give player 5,000,000 Brain
6. Walk the NeuralNetworkPad — confirm purchase goes through and machine spawns
7. execute_luau: start_stop_play(is_start=false)
```

- [ ] **Step 6: Commit**

```bash
git add Scripts/ReplicatedStorage/GameData.luau Scripts/ServerScriptService/PlotSetup.legacy.luau Scripts/StarterPlayerScripts/MainClient.local.luau
git commit -m "feat: Tier 2 generators (NeuralNetwork–QuantumQuirk) and NeuralExpansion upgrades"
```

---

## Task 6: Offline Earnings

**Files:**
- Modify: `Scripts/ServerScriptService/PlotSetup.legacy.luau` — calculate and apply offline bonus
- Modify: `Scripts/StarterPlayerScripts/MainClient.local.luau` — welcome-back popup

**Interfaces:**
- Consumes: `savedData.LastLogout` (set by `DataManager.Save` — available from Task 2)
- Consumes: `player.PlayerData.BPS` after `Stats.Recalculate` — used to compute the bonus
- Produces: `OfflineEarnings` RemoteEvent fires `(bonusAmount: number)` to client

- [ ] **Step 1: Add OfflineEarnings RemoteEvent to Studio**

```lua
-- execute_luau (Edit datamodel):
local re = Instance.new("RemoteEvent")
re.Name = "OfflineEarnings"
re.Parent = game:GetService("ReplicatedStorage")
print("OfflineEarnings event created")
```

- [ ] **Step 2: Calculate offline bonus in PlotSetup.onAdded (disk + Studio)**

Add to PlotSetup top (with the other RemoteEvent variables):

```lua
local offlineEv = RS:WaitForChild("OfflineEarnings")
```

Update `onAdded` to capture `saved` from `setupData` and calculate the bonus. Replace the `onAdded` function:

```lua
local function onAdded(player)
    local saved = setupData(player)
    local plot = PlotMgr.AssignPlot(player)
    if not plot then warn("No free plot for", player.Name); return end
    Stats.Recalculate(player)

    -- Offline earnings: cap 8 hours (28800s), 50% BPS efficiency
    if saved and saved.LastLogout > 0 then
        local elapsed = math.min(os.time() - saved.LastLogout, 28800)
        local pd2   = player:FindFirstChild("PlayerData")
        local bpsV2 = pd2 and pd2:FindFirstChild("BPS")
        local bps   = bpsV2 and bpsV2.Value or 0
        local bonus = math.floor(bps * elapsed * 0.5)
        if bonus > 0 then
            local ls2     = player:FindFirstChild("leaderstats")
            local brainV2 = ls2 and ls2:FindFirstChild("Brain")
            if brainV2 then brainV2.Value += bonus end
            local totalV2 = pd2 and pd2:FindFirstChild("TotalBrains")
            if totalV2 then totalV2.Value += bonus end
            task.delay(2, function()  -- delay so client GUI is loaded
                if player:IsDescendantOf(game) then
                    offlineEv:FireClient(player, bonus)
                end
            end)
        end
    end

    connectPlot(player, plot)
    plotEv:FireClient(player, plot)
    local function teleport(char)
        task.wait(0.2)
        local anchor = plot:FindFirstChild("SpawnAnchor")
        local hrp    = char:FindFirstChild("HumanoidRootPart")
        if anchor and hrp then hrp.CFrame = CFrame.new(anchor.Position+Vector3.new(0,6,0)) end
        applySpeed(player, char)
    end
    player.CharacterAdded:Connect(function(c) task.spawn(teleport,c) end)
    if player.Character then task.spawn(teleport, player.Character) end
end
```

Apply PlotSetup to Studio via execute_luau.

- [ ] **Step 3: Add offline earnings popup to MainClient (disk + Studio)**

In `Scripts/StarterPlayerScripts/MainClient.local.luau`, add after the sell popup block:

```lua
local offlineEv = RS:WaitForChild("OfflineEarnings")
local offlinePop   = frm(sg, Color3.fromRGB(0,18,40), UDim2.new(0,320,0,64), UDim2.new(0.5,-160,1,-160))
corner(10, offlinePop); offlinePop.BackgroundTransparency = 1
lbl(offlinePop, "Welcome back!", UDim2.new(1,0,0,22), UDim2.new(0,0,0,4), GOLD, 14)
local offlineSub = lbl(offlinePop, "", UDim2.new(1,0,0,22), UDim2.new(0,0,0,28), TXT, 13)
offlineEv.OnClientEvent:Connect(function(bonus)
    offlinePop.BackgroundTransparency = 0
    offlineSub.Text = "You earned "..fmt(bonus).." Brains while away!"
    Tween:Create(offlinePop,TweenInfo.new(0.2),{Position=UDim2.new(0.5,-160,1,-180)}):Play()
    task.delay(4.5, function()
        Tween:Create(offlinePop,TweenInfo.new(0.4),{Position=UDim2.new(0.5,-160,1,-100)}):Play()
        task.delay(0.4, function() offlinePop.BackgroundTransparency = 1 end)
    end)
end)
```

Apply MainClient to Studio via execute_luau.

- [ ] **Step 4: Verify offline earnings in Studio**

```
1. execute_luau: start_stop_play(is_start=true)
2. Buy several BrainJars until BPS is ~10
3. execute_luau: start_stop_play(is_start=false)   ← saves LastLogout = now
4. Wait ~30 real seconds (or temporarily change the cap in DataManager.Load to 30s for testing)
5. execute_luau: start_stop_play(is_start=true)
6. After ~2 seconds the "Welcome back!" popup should appear:
   Expected bonus = floor(10 BPS * 30s * 0.5) = 150 Brains minimum
7. execute_luau: get_console_output — no errors
8. execute_luau: start_stop_play(is_start=false)
```

- [ ] **Step 5: Commit**

```bash
git add Scripts/ServerScriptService/PlotSetup.legacy.luau Scripts/StarterPlayerScripts/MainClient.local.luau
git commit -m "feat: offline earnings — 50% BPS for up to 8 hours, welcome-back popup"
```

---

## Task 7: Tier 3 Generators

**Files:**
- Modify: `Scripts/ReplicatedStorage/GameData.luau` — add 5 Tier 3 generators + CortexOverdrive upgrades
- Modify: `Scripts/ServerScriptService/PlotSetup.legacy.luau` — GEN_COLORS, GEN_SLOTS
- Modify: `Scripts/StarterPlayerScripts/MainClient.local.luau` — CortexOverdrive shop scroll
- Studio: Slot11–15 anchors + Tier 3 pads per plot (further back on second floor)

**Interfaces:**
- Produces: `gen.tier=3` entries; `CortexOverdrive` upgrades; Tier 3 pads in world

- [ ] **Step 1: Add Tier 3 generators and CortexOverdrive upgrades to GameData (disk + Studio)**

Append to `GD.Generators` after the Tier 2 block:

```lua
    -- Tier 3 (unlock at 5th rebirth via GD.RebirthMilestones)
    {id="SynapseFlood",   name="Synapse Flood",    desc="Floods every synapse.",           baseCost=500000000000,     baseBPS=200000000,    costMult=1.15, tier=3},
    {id="VaporBrain",     name="Vapor Brain",       desc="Vaporizes neurons for gain.",     baseCost=5000000000000,    baseBPS=1000000000,   costMult=1.15, tier=3},
    {id="QuantumSkibidi", name="Quantum Skibidi",   desc="Skibidi at the quantum level.",   baseCost=50000000000000,   baseBPS=5000000000,   costMult=1.15, tier=3},
    {id="HiveMindHub",    name="Hive Mind Hub",     desc="Connects all brains in a hive.",  baseCost=500000000000000,  baseBPS=25000000000,  costMult=1.15, tier=3},
    {id="CosmicCortex",   name="Cosmic Cortex",     desc="Cortex the size of a galaxy.",    baseCost=5000000000000000, baseBPS=125000000000, costMult=1.15, tier=3},
```

Append CortexOverdrive upgrades to `GD.Upgrades`:

```lua
    -- === Cortex Overdrive (Tier 3 upgrades, visible after 5th rebirth) ===
    {id="FloodGates",     name="Flood Gates",        desc="×2 Synapse Flood BPS",           tier="CortexOverdrive", type="genMult",   baseCost=5000000000000,     genId="SynapseFlood",   genMult=2,  req={type="genOwned",id="SynapseFlood",count=10}},
    {id="VaporLock",      name="Vapor Lock",          desc="×2 Vapor Brain BPS",             tier="CortexOverdrive", type="genMult",   baseCost=50000000000000,    genId="VaporBrain",     genMult=2,  req={type="genOwned",id="VaporBrain",count=10}},
    {id="SkibidiQuantum", name="Skibidi Quantum",     desc="×1.5 global BPS",               tier="CortexOverdrive", type="globalBPS", baseCost=200000000000000,   bpsMult=1.5,             req={type="genOwned",id="QuantumSkibidi",count=5}},
    {id="HiveSync",       name="Hive Synchrony",      desc="×2 Hive Mind Hub BPS",           tier="CortexOverdrive", type="genMult",   baseCost=2000000000000000,  genId="HiveMindHub",    genMult=2,  req={type="genOwned",id="HiveMindHub",count=5}},
    {id="CortexEvent",    name="Cortex Event",        desc="×3 global BPS",                 tier="CortexOverdrive", type="globalBPS", baseCost=20000000000000000, bpsMult=3,               req={type="genOwned",id="CosmicCortex",count=5}},
```

Apply GameData to Studio via execute_luau.

- [ ] **Step 2: Extend GEN_COLORS and GEN_SLOTS in PlotSetup (disk + Studio)**

Append to `GEN_COLORS`:
```lua
    -- Tier 3
    SynapseFlood=BrickColor.new("Bright red"),      VaporBrain=BrickColor.new("Cyan"),
    QuantumSkibidi=BrickColor.new("Dark purple"),   HiveMindHub=BrickColor.new("Bright yellow"),
    CosmicCortex=BrickColor.new("White"),
```

Append to `GEN_SLOTS`:
```lua
    -- Tier 3 (slots 11–15)
    SynapseFlood=11, VaporBrain=12, QuantumSkibidi=13, HiveMindHub=14, CosmicCortex=15,
```

Apply PlotSetup to Studio via execute_luau.

- [ ] **Step 3: Create Slot11–15 anchors and Tier 3 pads in Studio**

```lua
-- execute_luau (Edit datamodel):
local TIER3 = {
    {id="SynapseFlood",   name="Synapse Flood"},
    {id="VaporBrain",     name="Vapor Brain"},
    {id="QuantumSkibidi", name="Quantum Skibidi"},
    {id="HiveMindHub",    name="Hive Mind Hub"},
    {id="CosmicCortex",   name="Cosmic Cortex"},
}
for _, plot in game.Workspace.Plots:GetChildren() do
    local floor = plot:FindFirstChild("Floor"); if not floor then continue end
    local cx = floor.Position.X; local cz = floor.Position.Z
    local sf  = plot:FindFirstChild("SecondFloor_R")
    local padY = sf and (sf.Position.Y + sf.Size.Y/2 + 1) or 22
    local f   = cz < 0 and 1 or -1
    for i, g in ipairs(TIER3) do
        local slotX = cx - 20 + (i-1)*10
        local padZ  = cz - f*30  -- further back than Tier 2 pads
        if not plot:FindFirstChild("Slot"..(i+10)) then
            local slot = Instance.new("Part")
            slot.Name = "Slot"..(i+10); slot.Size = Vector3.new(1,1,1)
            slot.Position = Vector3.new(slotX, padY+3, padZ)
            slot.Anchored = true; slot.Transparency = 1; slot.CanCollide = false
            slot.Parent = plot
        end
        if not plot:FindFirstChild(g.id.."Pad") then
            local pad = Instance.new("Part")
            pad.Name = g.id.."Pad"; pad.Size = Vector3.new(8,1,8)
            pad.Position = Vector3.new(slotX, padY, padZ)
            pad.Anchored = true; pad.BrickColor = BrickColor.new("Dark stone grey")
            pad.Material = Enum.Material.SmoothPlastic; pad.Parent = plot
            local bg = Instance.new("BillboardGui", pad)
            bg.Name = "Label"; bg.Size = UDim2.new(0,140,0,36)
            bg.StudsOffset = Vector3.new(0,3,0)
            local tl = Instance.new("TextLabel", bg)
            tl.Size = UDim2.new(1,0,1,0); tl.BackgroundTransparency = 1
            tl.Text = g.name; tl.TextColor3 = Color3.new(1,1,1)
            tl.TextStrokeTransparency = 0; tl.Font = Enum.Font.GothamBold
            tl.TextSize = 13; tl.Parent = bg
        end
    end
end
print("Tier 3 pads done")
```

- [ ] **Step 4: Add CortexOverdrive scroll to MainClient shop (disk + Studio)**

Mirror the NeuralExpansion changes from Task 5, Step 4, but for CortexOverdrive:

```lua
-- Add scroll:
local cortexScroll = scroll(shopPanel)

-- Add to routing:
or u.tier=="CortexOverdrive" and cortexScroll

-- Add to openShop:
cortexScroll.Visible = cat=="CortexOverdrive"

-- Add to titles:
CortexOverdrive = "Cortex Overdrive Lab",
```

Also add `"CortexOverdrive"` to the PlotSetup ProximityPrompt handler's `cat` check (same line as NeuralExpansion from Task 5).

Apply MainClient and PlotSetup to Studio via execute_luau.

- [ ] **Step 5: Verify Tier 3 in Studio**

```
1. execute_luau: start_stop_play(is_start=true)
2. execute_luau: get_console_output — no errors
3. Via Explorer, set player.PlayerData.RebirthCount = 5
   — "TIER 3 UNLOCKED!" banner should appear
4. Navigate to second floor rear — confirm 5 Tier 3 pads visible
5. Via Explorer give 500,000,000,000 Brain (5e11), walk SynapseFloodPad — confirm purchase
6. execute_luau: start_stop_play(is_start=false)
```

- [ ] **Step 6: Commit**

```bash
git add Scripts/ReplicatedStorage/GameData.luau Scripts/ServerScriptService/PlotSetup.legacy.luau Scripts/StarterPlayerScripts/MainClient.local.luau
git commit -m "feat: Tier 3 generators (SynapseFlood–CosmicCortex) and CortexOverdrive upgrades"
```
