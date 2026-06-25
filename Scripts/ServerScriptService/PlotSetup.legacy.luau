local Players    = game:GetService("Players")
local RS         = game:GetService("ReplicatedStorage")
local SSS        = game:GetService("ServerScriptService")
local GD         = require(RS:WaitForChild("GameData"))
local Stats      = require(SSS:WaitForChild("StatsCalculator"))
local PlotMgr    = require(SSS:WaitForChild("PlotManager"))
local DataMgr    = require(SSS:WaitForChild("DataManager"))
local plotEv     = RS:WaitForChild("PlotAssigned")
local openShopEv = RS:WaitForChild("OpenShop")
local sellNotifEv= RS:WaitForChild("SellNotif")
local critEv     = RS:WaitForChild("CritNotif")
local bpsStormEv = RS:WaitForChild("BpsStorm")
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

local clickThrottle={}
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
    -- Tier 2 (slots 6-10 on second floor)
    NeuralNetwork=6, MemeVault=7, DopamineDen=8, CortexCollider=9, QuantumQuirk=10,
}

local function fmt(n) return GD.FormatNumber(n) end

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

local function spawnMachine(gen,plot)
    local machines=plot:FindFirstChild("Machines")
    if not machines or machines:FindFirstChild(gen.id) then return end
    local slot=plot:FindFirstChild("Slot"..(GEN_SLOTS[gen.id] or 0)); if not slot then return end
    local m=Instance.new("Part");m.Name=gen.id;m.Size=Vector3.new(6,6,6)
    m.Position=slot.Position+Vector3.new(0,3.5,0);m.Anchored=true
    m.BrickColor=GEN_COLORS[gen.id] or BrickColor.new("Medium stone grey")
    m.Material=Enum.Material.SmoothPlastic;m.Parent=machines
    local bg=Instance.new("BillboardGui",m);bg.Size=UDim2.new(0,130,0,26);bg.StudsOffset=Vector3.new(0,4.5,0)
    local tl=Instance.new("TextLabel",bg);tl.Size=UDim2.new(1,0,1,0)
    tl.BackgroundTransparency=1;tl.Text=gen.name;tl.TextColor3=Color3.new(1,1,1)
    tl.TextStrokeTransparency=0;tl.Font=Enum.Font.GothamBold;tl.TextSize=13
end

local function updatePadLabel(pad,gen,owned)
    local cost=GD.GetGeneratorCost(gen,owned)
    local str=gen.name.."\n"..fmt(cost)
    local bbg=pad:FindFirstChild("Label")
    local bl=bbg and bbg:FindFirstChildOfClass("TextLabel"); if bl then bl.Text=str end
    local sg=pad:FindFirstChildOfClass("SurfaceGui")
    local sl=sg and sg:FindFirstChildOfClass("TextLabel"); if sl then sl.Text=gen.name end
end

local function spawnOrb(plot,pos,val,player)
    local orb=Instance.new("Part");orb.Name="BrainOrb"
    orb.Shape=Enum.PartType.Ball;orb.Size=Vector3.new(3,3,3)
    orb.Position=pos;orb.Anchored=true;orb.BrickColor=BrickColor.new("Hot pink")
    orb.Material=Enum.Material.Neon;orb.CastShadow=false;orb.Parent=plot
    local bg=Instance.new("BillboardGui",orb);bg.Size=UDim2.new(0,80,0,18);bg.StudsOffset=Vector3.new(0,2.5,0)
    local tl=Instance.new("TextLabel",bg);tl.Size=UDim2.new(1,0,1,0)
    tl.BackgroundTransparency=1;tl.TextColor3=Color3.new(1,1,1)
    tl.TextStrokeTransparency=0;tl.Font=Enum.Font.GothamBold;tl.TextSize=11;tl.Text="+"..fmt(val)
    local done=false
    orb.Touched:Connect(function(hit)
        if done then return end
        local p=Players:GetPlayerFromCharacter(hit.Parent)
        if not p or p~=player then return end
        done=true;orb:Destroy()
        local ls2=player:FindFirstChild("leaderstats")
        local bv=ls2 and ls2:FindFirstChild("Brain"); if bv then bv.Value+=val end
    end)
    task.delay(25,function() if not done and orb.Parent then orb:Destroy() end end)
end

local function startOrbSpawner(player,plot)
    local floor=plot:FindFirstChild("Floor"); if not floor then return end
    local cx=floor.Position.X; local cz=floor.Position.Z; local f=cz<0 and 1 or -1
    task.spawn(function()
        while plot:GetAttribute("Taken") do
            task.wait(12)
            if not plot:GetAttribute("Taken") then break end
            local pd2=player:FindFirstChild("PlayerData")
            local bpsV=pd2 and pd2:FindFirstChild("BPS")
            local val=math.max(10,math.floor((bpsV and bpsV.Value or 0)*2))
            for _=1,3 do
                spawnOrb(plot,Vector3.new(cx+math.random(-22,22),3,cz-f*math.random(5,20)),val,player)
            end
            local uF2=pd2 and pd2:FindFirstChild("Upgrades")
            local efV=uF2 and uF2:FindFirstChild("ExperimentalFluids")
            if efV and efV.Value then
                local jarM=plot:FindFirstChild("Machines") and plot.Machines:FindFirstChild("BrainJar")
                if jarM then
                    spawnOrb(plot,jarM.Position+Vector3.new(math.random(-4,4),3,math.random(-4,4)),val*2,player)
                end
            end
        end
    end)
end

local function connectPlot(player,plot)
    local floor=plot:FindFirstChild("Floor")
    local cx=floor and floor.Position.X or 0
    local cz=floor and floor.Position.Z or 0
    local f=cz<0 and 1 or -1

    local brain=plot:FindFirstChild("Brain")
    local cd=brain and brain:FindFirstChild("ClickDetector")
    if cd then
        cd.MouseClick:Connect(function(clicker)
            if clicker~=player then return end
            local now=tick()
            if clickThrottle[player] and now-clickThrottle[player]<0.05 then return end
            clickThrottle[player]=now
            local ls=player:FindFirstChild("leaderstats")
            local pd2=player:FindFirstChild("PlayerData")
            if not ls or not pd2 then return end
            local brainV=ls:FindFirstChild("Brain")
            local totalV=pd2:FindFirstChild("TotalBrains")
            local bpcV=pd2:FindFirstChild("BPC")
            local ccV=pd2:FindFirstChild("ClickCount")
            if not brainV or not bpcV then return end
            if ccV then ccV.Value+=1 end
            local award=bpcV.Value
            local crit=player:GetAttribute("CritChance") or 0
            if crit>0 and math.random(100)<=crit then
                award*=5; critEv:FireClient(player)
            end
            brainV.Value+=award
            if totalV then totalV.Value+=award end
            local uF2=pd2:FindFirstChild("Upgrades")
            local vsV=uF2 and uF2:FindFirstChild("ViralSpread")
            if vsV and vsV.Value then
                local gF2=pd2:FindFirstChild("Generators")
                local mfV=gF2 and gF2:FindFirstChild("MemeFarm")
                if mfV and mfV.Value>0 then
                    local rawV2=pd2:FindFirstChild("RawBrains")
                    if rawV2 then rawV2.Value+=GD.Generators[2].baseBPS*mfV.Value end
                end
            end
        end)
    end

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

    for _,obj in plot:GetDescendants() do
        local pp=obj:FindFirstChildOfClass("ProximityPrompt"); if not pp then continue end
        local cat=pp:GetAttribute("Category"); if not cat then continue end
        pp.Triggered:Connect(function(trigPlayer)
            if trigPlayer~=player then return end
            local ls2=player:FindFirstChild("leaderstats")
            local pd2=player:FindFirstChild("PlayerData")
            if cat=="market" then
                if not ls2 or not pd2 then return end
                local rawV=pd2:FindFirstChild("RawBrains")
                local brainV2=ls2:FindFirstChild("Brain")
                local totalV=pd2:FindFirstChild("TotalBrains")
                if not rawV or not brainV2 then return end
                local amt=math.floor(rawV.Value); if amt<1 then return end
                rawV.Value=0; brainV2.Value+=amt
                if totalV then totalV.Value+=amt end
                sellNotifEv:FireClient(player,amt)
            elseif cat=="meta" then
                local rpV2=ls2 and ls2:FindFirstChild("RP")
                if not rpV2 or rpV2.Value<1 then return end
                openShopEv:FireClient(player,"meta")
            elseif cat=="generator" or cat=="upgrades" or cat=="rebirth" or cat=="NeuralExpansion" then
                openShopEv:FireClient(player,cat)
            end
        end)
    end

    task.spawn(function()
        while plot:GetAttribute("Taken") do
            task.wait(90)
            if not plot:GetAttribute("Taken") then break end
            local pd2=player:FindFirstChild("PlayerData")
            local uF2=pd2 and pd2:FindFirstChild("Upgrades")
            local elV=uF2 and uF2:FindFirstChild("ExperimentalLoop")
            if elV and elV.Value then
                player:SetAttribute("BpsStorm",true)
                bpsStormEv:FireClient(player,true)
                task.wait(8)
                if player:IsDescendantOf(game) then
                    player:SetAttribute("BpsStorm",false)
                    bpsStormEv:FireClient(player,false)
                end
            end
        end
    end)

    startOrbSpawner(player,plot)

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
end

local function applySpeed(player,char)
    local hum=char:FindFirstChildOfClass("Humanoid"); if not hum then return end
    local spd=player:GetAttribute("SpeedBonus") or 0
    hum.WalkSpeed=16+spd
end

local function onAdded(player)
    setupData(player)
    local plot=PlotMgr.AssignPlot(player)
    if not plot then warn("No free plot for",player.Name); return end
    Stats.Recalculate(player)
    connectPlot(player,plot)
    plotEv:FireClient(player,plot)
    local function teleport(char)
        task.wait(0.2)
        local anchor=plot:FindFirstChild("SpawnAnchor")
        local hrp=char:FindFirstChild("HumanoidRootPart")
        if anchor and hrp then hrp.CFrame=CFrame.new(anchor.Position+Vector3.new(0,6,0)) end
        applySpeed(player,char)
    end
    player.CharacterAdded:Connect(function(c) task.spawn(teleport,c) end)
    if player.Character then task.spawn(teleport,player.Character) end
end

Players.PlayerAdded:Connect(onAdded)
Players.PlayerRemoving:Connect(function(p)
    DataMgr.Save(p)
    clickThrottle[p]=nil
    PlotMgr.FreePlot(p)
end)

task.spawn(function()
    while true do
        task.wait(60)
        for _, p in Players:GetPlayers() do
            DataMgr.Save(p)
        end
    end
end)

for _,p in Players:GetPlayers() do task.spawn(onAdded,p) end
