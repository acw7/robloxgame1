local Players   = game:GetService("Players")
local RS        = game:GetService("ReplicatedStorage")
local SSS       = game:GetService("ServerScriptService")
local GD        = require(RS:WaitForChild("GameData"))
local Stats     = require(SSS:WaitForChild("StatsCalculator"))
local PlotMgr   = require(SSS:WaitForChild("PlotManager"))
local rebirthEv = RS:WaitForChild("RebirthRequested")

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