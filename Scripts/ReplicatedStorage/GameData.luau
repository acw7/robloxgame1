local GD = {}
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
    -- Tier 3 (unlock at 5th rebirth via GD.RebirthMilestones)
    {id="SynapseFlood",   name="Synapse Flood",    desc="Floods every synapse.",           baseCost=500000000000,     baseBPS=200000000,    costMult=1.15, tier=3},
    {id="VaporBrain",     name="Vapor Brain",       desc="Vaporizes neurons for gain.",     baseCost=5000000000000,    baseBPS=1000000000,   costMult=1.15, tier=3},
    {id="QuantumSkibidi", name="Quantum Skibidi",   desc="Skibidi at the quantum level.",   baseCost=50000000000000,   baseBPS=5000000000,   costMult=1.15, tier=3},
    {id="HiveMindHub",    name="Hive Mind Hub",     desc="Connects all brains in a hive.",  baseCost=500000000000000,  baseBPS=25000000000,  costMult=1.15, tier=3},
    {id="CosmicCortex",   name="Cosmic Cortex",     desc="Cortex the size of a galaxy.",    baseCost=5000000000000000, baseBPS=125000000000, costMult=1.15, tier=3},
}
GD.Milestones    = {10,25,50,100,200}
GD.MilestoneMult = 2
GD.RebirthThreshold  = 100000
GD.RPProductionBonus = 0.1
GD.NeuronFormulaDivisor = 100000   -- neurons = max(1, floor(TotalBrains / this))
GD.RebirthMultPerLevel  = 0.10     -- permanent +10% global BPS & BPC per rebirth (stacks)
GD.RebirthMilestones = {
    [1]  = { unlockTier = 2, upgradeCategory = "NeuralExpansion" },
    [5]  = { unlockTier = 3, upgradeCategory = "CortexOverdrive" },
    [10] = { extraMetaSlot = true },
    [25] = { reserved = true },
}
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
    -- === Neural Expansion (Tier 2 upgrades, visible after 1st rebirth) ===
    {id="SynapticBoostI",  name="Synaptic Boost I",    desc="×2 Neural Network BPS",      tier="NeuralExpansion", type="genMult",   baseCost=50000000,      genId="NeuralNetwork",  genMult=2,   req={type="genOwned",id="NeuralNetwork",count=10}},
    {id="MemeCacheI",      name="Meme Cache I",         desc="×2 Meme Vault BPS",          tier="NeuralExpansion", type="genMult",   baseCost=500000000,     genId="MemeVault",      genMult=2,   req={type="genOwned",id="MemeVault",count=10}},
    {id="DopamineRushI",   name="Dopamine Rush I",      desc="×1.5 global BPS",            tier="NeuralExpansion", type="globalBPS", baseCost=2000000000,    bpsMult=1.5,             req={type="genOwned",id="DopamineDen",count=5}},
    {id="ColliderMatrix",  name="Collider Matrix",      desc="×2 Cortex Collider BPS",     tier="NeuralExpansion", type="genMult",   baseCost=20000000000,   genId="CortexCollider", genMult=2,   req={type="genOwned",id="CortexCollider",count=5}},
    {id="QuantumEntangle", name="Quantum Entanglement", desc="×2 global BPS",              tier="NeuralExpansion", type="globalBPS", baseCost=200000000000,  bpsMult=2,               req={type="genOwned",id="QuantumQuirk",count=5}},
    -- === Cortex Overdrive (Tier 3 upgrades, visible after 5th rebirth) ===
    {id="FloodGates",     name="Flood Gates",        desc="×2 Synapse Flood BPS",           tier="CortexOverdrive", type="genMult",   baseCost=5000000000000,     genId="SynapseFlood",   genMult=2,  req={type="genOwned",id="SynapseFlood",count=10}},
    {id="VaporLock",      name="Vapor Lock",          desc="×2 Vapor Brain BPS",             tier="CortexOverdrive", type="genMult",   baseCost=50000000000000,    genId="VaporBrain",     genMult=2,  req={type="genOwned",id="VaporBrain",count=10}},
    {id="SkibidiQuantum", name="Skibidi Quantum",     desc="×1.5 global BPS",               tier="CortexOverdrive", type="globalBPS", baseCost=200000000000000,   bpsMult=1.5,             req={type="genOwned",id="QuantumSkibidi",count=5}},
    {id="HiveSync",       name="Hive Synchrony",      desc="×2 Hive Mind Hub BPS",           tier="CortexOverdrive", type="genMult",   baseCost=2000000000000000,  genId="HiveMindHub",    genMult=2,  req={type="genOwned",id="HiveMindHub",count=5}},
    {id="CortexEvent",    name="Cortex Event",        desc="×3 global BPS",                 tier="CortexOverdrive", type="globalBPS", baseCost=20000000000000000, bpsMult=3,               req={type="genOwned",id="CosmicCortex",count=5}},
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
