local GD = {}
GD.Generators = {
    {id="BrainJar",      name="Brain Jar",      desc="Leaks Brains slowly.",         baseCost=10,     baseBPS=0.1,  costMult=1.15},
    {id="MemeFarm",      name="Meme Farm",       desc="Harvests viral memes.",         baseCost=100,    baseBPS=0.5,  costMult=1.15},
    {id="DoomscrollRig", name="Doomscroll Rig",  desc="Auto-scrolls for raw output.", baseCost=1100,   baseBPS=4,    costMult=1.15},
    {id="NeuralTap",     name="Neural Tap",       desc="Taps into the brain stem.",    baseCost=12000,  baseBPS=20,   costMult=1.15},
    {id="SkibidiLab",    name="Skibidi Lab",      desc="Advanced skibidi science.",    baseCost=130000, baseBPS=100,  costMult=1.15},
}
GD.Milestones    = {10,25,50,100,200}
GD.MilestoneMult = 2
GD.RebirthThreshold  = 100000
GD.RPProductionBonus = 0.1
function GD.GetGeneratorCost(gen,owned) return math.floor(gen.baseCost*(gen.costMult^owned)) end

GD.Upgrades = {
    -- === Early ===
    {id="BetterFingers",  name="Better Fingers",   desc="+1 BPC",          tier="early",type="click",        baseCost=50,    bpcBonus=1},
    {id="DoubleClick",    name="Double Click",      desc="×2 BPC",          tier="early",type="clickMultiply",baseCost=500,   bpcMult=2},
    {id="PowerFingers",   name="Power Fingers",     desc="+5 BPC",          tier="early",type="click",        baseCost=2000,  bpcBonus=5},
    {id="TripleClick",    name="Triple Click",       desc="×3 BPC",          tier="early",type="clickMultiply",baseCost=20000, bpcMult=3},
    {id="JarLid",         name="Better Jar Lid",    desc="×2 Brain Jar BPS",tier="early",type="genMult",      baseCost=200,   genId="BrainJar",      genMult=2},
    {id="ViralBoost",     name="Viral Boost",       desc="×2 Meme Farm BPS",tier="early",type="genMult",      baseCost=2000,  genId="MemeFarm",      genMult=2},
    {id="InfiniteScroll", name="Infinite Scroll",   desc="×2 Doomscroll",   tier="early",type="genMult",      baseCost=22000, genId="DoomscrollRig", genMult=2},
    {id="NeuralEff",      name="Neural Efficiency", desc="×2 all BPS",      tier="early",type="globalBPS",    baseCost=50000, bpsMult=2},
    -- === New Early ===
    {id="BrainWorkoutII",  name="Brain Workout II",  desc="+2 BPC",            tier="early",type="click",      baseCost=5000,   bpcBonus=2},
    {id="BrainWorkoutIII", name="Brain Workout III", desc="+5 BPC",            tier="early",type="click",      baseCost=50000,  bpcBonus=5,  req={type="upgOwned",id="BrainWorkoutII"}},
    {id="HyperfocusI",     name="Hyperfocus I",      desc="+8% crit (×5 BPC)", tier="early",type="critAdd",    baseCost=3500,   critPct=8,   req={type="clicks",count=500}},
    {id="HyperfocusII",    name="Hyperfocus II",     desc="+12% crit",          tier="early",type="critAdd",   baseCost=35000,  critPct=12,  req={type="upgOwned",id="HyperfocusI"}},
    {id="NeuralUplinkI",   name="Neural Uplink I",   desc="×1.3 all BPS",      tier="early",type="globalBPS", baseCost=12000,  bpsMult=1.3, req={type="anyTotal",count=20}},
    {id="NeuralUplinkII",  name="Neural Uplink II",  desc="×1.6 all BPS",      tier="early",type="globalBPS", baseCost=120000, bpsMult=1.6, req={type="upgOwned",id="NeuralUplinkI"}},
    {id="JoggersMindset",  name="Jogger's Mindset",  desc="+12 WalkSpeed",      tier="early",type="speed",     baseCost=800,    speedAdd=12},
    -- === Generator Console ===
    {id="LeakproofLids",     name="Leakproof Lids",    desc="×2 Brain Jar BPS",           tier="generator",type="genMult",       baseCost=6000,   genId="BrainJar",      genMult=2,    req={type="genOwned",id="BrainJar",count=25}},
    {id="ExperimentalFluids",name="Experimental Fluids",desc="Jars occasionally spawn orbs",tier="generator",type="orbProc",     baseCost=25000,  genId="BrainJar",                    req={type="genOwned",id="BrainJar",count=50}},
    {id="ViralSpread",       name="Viral Spread",      desc="Clicks tick Meme Farms",      tier="generator",type="clickGenTick", baseCost=9000,   genId="MemeFarm",                    req={type="genOwned",id="MemeFarm",count=25}},
    {id="TrendForecasting",  name="Trend Forecasting", desc="×1.75 Meme Farm BPS",         tier="generator",type="genMult",       baseCost=45000,  genId="MemeFarm",      genMult=1.75, req={type="genOwned",id="MemeFarm",count=50}},
    {id="InfiniteFeed",      name="Infinite Feed",     desc="×1.5 Doomscroll BPS",         tier="generator",type="genMult",       baseCost=18000,  genId="DoomscrollRig", genMult=1.5,  req={type="genOwned",id="DoomscrollRig",count=10}},
    {id="DeepTap",           name="Deep Tap",          desc="Neural Tap ×(1+5%/Neuron)",   tier="generator",type="rebirthSynergy",baseCost=70000,  genId="NeuralTap",                   req={type="genOwned",id="NeuralTap",count=10}},
    {id="ExperimentalLoop",  name="Experimental Loop", desc="Every 90s: ×2 BPS for 8s",   tier="generator",type="bpsStorm",      baseCost=250000,                                       req={type="genOwned",id="SkibidiLab",count=5}},
    {id="BulkBuyI",          name="Bulk Purchase",     desc="Buy up to ×5 on gen pads",    tier="generator",type="bulkBuy",       baseCost=15000,                                        req={type="anyGen",count=25}},
}
GD.MetaUpgrades = {
    {id="NeuralMultiplier",  name="Neural Multiplier",  desc="×1.2 global BPS, permanent",       neuronCost=1, type="neuronMult",    neuronBpsMult=1.2},
    {id="InvestorInsight",   name="Investor Insight",   desc="+1 extra Neuron per Rebirth",       neuronCost=2, type="investorInsight"},
    {id="OfflineCognition",  name="Offline Cognition",  desc="25% BPS earned offline (up to 4h)", neuronCost=3, type="offlineGain"},
    {id="SafetyNet",         name="Safety Net",         desc="Start each run: 500 Brain + 1 Jar", neuronCost=1, type="safetyNet"},
    {id="BrainstormMastery", name="Brainstorm Mastery", desc="×1.5 BPC every run, permanent",    neuronCost=2, type="clickMultiply", bpcMult=1.5},
    {id="EarlyAccess",       name="Early Access",       desc="First 2 gen types 50% off each run",neuronCost=3, type="earlyAccess"},
}

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

return GD
