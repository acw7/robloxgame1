local RS = game:GetService("ReplicatedStorage")
local GD = require(RS:WaitForChild("GameData"))
local M  = {}
function M.Recalculate(player)
    local ls=player:FindFirstChild("leaderstats")
    local pd=player:FindFirstChild("PlayerData")
    if not ls or not pd then return end
    local gF=pd:FindFirstChild("Generators")
    local uF=pd:FindFirstChild("Upgrades")
    local mF=pd:FindFirstChild("MetaUpgrades")
    local rpV=ls:FindFirstChild("RP")
    local bpcV=pd:FindFirstChild("BPC")
    local bpsV=pd:FindFirstChild("BPS")
    if not gF or not uF or not bpcV or not bpsV then return end
    local rp=rpV and rpV.Value or 0
    local bpc,bm,gM,globalM,critPct,speedAdd=1,1,{},1,0,0
    -- Normal upgrades
    for _,u in GD.Upgrades do
        local v=uF:FindFirstChild(u.id)
        if not v or not v.Value then continue end
        if     u.type=="click"          then bpc+=u.bpcBonus
        elseif u.type=="clickMultiply"  then bm*=u.bpcMult
        elseif u.type=="genMult"        then gM[u.genId]=(gM[u.genId] or 1)*u.genMult
        elseif u.type=="globalBPS"      then globalM*=u.bpsMult
        elseif u.type=="critAdd"        then critPct+=u.critPct
        elseif u.type=="speed"          then speedAdd+=u.speedAdd
        elseif u.type=="rebirthSynergy" then gM[u.genId]=(gM[u.genId] or 1)*(1+0.05*rp)
        end
    end
    -- Meta upgrades (persist across rebirths)
    if mF then
        for _,u in GD.MetaUpgrades do
            local v=mF:FindFirstChild(u.id)
            if not v or not v.Value then continue end
            if     u.type=="neuronMult"   then globalM*=u.neuronBpsMult
            elseif u.type=="clickMultiply"then bm*=u.bpcMult
            end
        end
    end
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