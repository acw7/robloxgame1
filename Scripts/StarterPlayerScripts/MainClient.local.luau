local Players    = game:GetService("Players")
local RS         = game:GetService("ReplicatedStorage")
local Tween      = game:GetService("TweenService")
local player     = Players.LocalPlayer
local gui        = player:WaitForChild("PlayerGui")
local upgEv      = RS:WaitForChild("PurchaseUpgrade")
local metaEv     = RS:WaitForChild("PurchaseMeta")
local rebirthEv  = RS:WaitForChild("RebirthRequested")
local openShopEv = RS:WaitForChild("OpenShop")
local plotEv     = RS:WaitForChild("PlotAssigned")
local sellNotifEv= RS:WaitForChild("SellNotif")
local critEv     = RS:WaitForChild("CritNotif")
local bpsStormEv = RS:WaitForChild("BpsStorm")
local GD         = require(RS:WaitForChild("GameData"))
local ls         = player:WaitForChild("leaderstats")
local pd         = player:WaitForChild("PlayerData")
local brainV     = ls:WaitForChild("Brain")
local rpV        = ls:WaitForChild("RP")
local bpcV       = pd:WaitForChild("BPC")
local bpsV       = pd:WaitForChild("BPS")
local totalV     = pd:WaitForChild("TotalBrains")
local rawV       = pd:WaitForChild("RawBrains")
local upgF       = pd:WaitForChild("Upgrades")
local metaF      = pd:WaitForChild("MetaUpgrades")
local genF       = pd:WaitForChild("Generators")
local clickCntV  = pd:WaitForChild("ClickCount")

local fmt = GD.FormatNumber

local DARK=Color3.fromRGB(8,8,16); local PANEL=Color3.fromRGB(20,20,36)
local ACC=Color3.fromRGB(100,78,220); local GOLD=Color3.fromRGB(255,198,50)
local GRN=Color3.fromRGB(68,190,108); local TXT=Color3.fromRGB(240,240,255)
local SUB=Color3.fromRGB(148,148,178); local DIM=Color3.fromRGB(48,48,68)
local ORN=Color3.fromRGB(255,140,30); local PURP=Color3.fromRGB(160,80,255)
local RED=Color3.fromRGB(255,60,60)

local function corner(r,p) local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,r);c.Parent=p end
local function frm(p,bg,sz,pos,tr)
    local f=Instance.new("Frame");f.BorderSizePixel=0;f.BackgroundColor3=bg;f.Size=sz
    if pos then f.Position=pos end;if tr then f.BackgroundTransparency=tr end;f.Parent=p;return f
end
local function lbl(p,txt,sz,pos,tc,ts,xa,font)
    local l=Instance.new("TextLabel");l.BackgroundTransparency=1;l.Text=txt;l.Size=sz
    l.TextColor3=tc or TXT;l.TextSize=ts or 14;l.Font=font or Enum.Font.GothamBold
    l.TextXAlignment=xa or Enum.TextXAlignment.Center
    if pos then l.Position=pos end;l.Parent=p;return l
end
local function tbtn(p,txt,bg,sz,pos,tc,ts)
    local b=Instance.new("TextButton");b.BorderSizePixel=0;b.Font=Enum.Font.GothamBold
    b.Text=txt;b.BackgroundColor3=bg;b.Size=sz;b.TextColor3=tc or TXT;b.TextSize=ts or 14
    if pos then b.Position=pos end;b.Parent=p;return b
end
local function scroll(p)
    local s=Instance.new("ScrollingFrame")
    s.Size=UDim2.new(1,0,1,-40);s.Position=UDim2.new(0,0,0,40)
    s.BackgroundTransparency=1;s.BorderSizePixel=0
    s.ScrollBarThickness=4;s.ScrollBarImageColor3=ACC
    s.CanvasSize=UDim2.new(0,0,0,0);s.AutomaticCanvasSize=Enum.AutomaticSize.Y
    s.Visible=false;s.Parent=p
    local ul=Instance.new("UIListLayout");ul.Padding=UDim.new(0,4);ul.Parent=s
    local up=Instance.new("UIPadding")
    up.PaddingLeft=UDim.new(0,5);up.PaddingRight=UDim.new(0,5);up.PaddingTop=UDim.new(0,5);up.Parent=s
    return s
end

-- Check upgrade requirement (client-side)
local function checkReq(req)
    if not req then return true end
    if req.type=="upgOwned" then
        local v=upgF:FindFirstChild(req.id); return v and v.Value
    elseif req.type=="clicks" then return clickCntV.Value>=req.count
    elseif req.type=="genOwned" then
        local v=genF:FindFirstChild(req.id); return v and v.Value>=req.count
    elseif req.type=="anyTotal" then
        local t=0; for _,v in genF:GetChildren() do t+=v.Value end; return t>=req.count
    elseif req.type=="anyGen" then
        for _,v in genF:GetChildren() do if v.Value>=req.count then return true end end
        return false
    end
    return true
end

local old=gui:FindFirstChild("BrainrotHUD"); if old then old:Destroy() end
local sg=Instance.new("ScreenGui")
sg.Name="BrainrotHUD";sg.ResetOnSpawn=false;sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling;sg.Parent=gui

-- Top HUD
local topBar=frm(sg,DARK,UDim2.new(1,0,0,52),UDim2.new(0,0,0,0))
local tLayout=Instance.new("UIListLayout")
tLayout.FillDirection=Enum.FillDirection.Horizontal
tLayout.VerticalAlignment=Enum.VerticalAlignment.Center
tLayout.HorizontalAlignment=Enum.HorizontalAlignment.Center
tLayout.Padding=UDim.new(0,4);tLayout.Parent=topBar
local statVals={}
for _,info in {{"Brain","BRAINS",TXT},{"BPC","PER CLICK",SUB},{"BPS","PER SEC",SUB},{"Raw","PENDING",ORN},{"RP","NEURONS",GOLD}} do
    local f=frm(topBar,Color3.fromRGB(14,14,26),UDim2.new(0,106,0,46),nil);corner(4,f)
    lbl(f,info[2],UDim2.new(1,0,0,16),UDim2.new(0,0,0,6),info[3],8)
    statVals[info[1]]=lbl(f,"0",UDim2.new(1,0,0,22),UDim2.new(0,0,0,22),info[3],16)
end

-- Hint strip
local sellHint=lbl(sg,"",UDim2.new(1,0,0,14),UDim2.new(0,0,0,52),ORN,10,nil,Enum.Font.Gotham)
sellHint.BackgroundColor3=Color3.fromRGB(12,8,0);sellHint.BackgroundTransparency=0

-- Rebirth strip
local progBg=frm(sg,Color3.fromRGB(12,8,0),UDim2.new(1,0,0,4),UDim2.new(0,0,0,66))
local progFill=frm(progBg,GOLD,UDim2.new(0,0,1,0))

-- Sell pop
local sellPop=frm(sg,Color3.fromRGB(30,22,0),UDim2.new(0,280,0,52),UDim2.new(0.5,-140,1,-120))
corner(10,sellPop);sellPop.BackgroundTransparency=1
local sellPopTxt=lbl(sellPop,"",UDim2.new(1,0,1,0),nil,GOLD,20)
sellPopTxt.TextStrokeTransparency=0.4
sellNotifEv.OnClientEvent:Connect(function(amt)
    sellPop.BackgroundTransparency=0
    sellPopTxt.Text="+"..fmt(amt).." Brains sold!"
    Tween:Create(sellPop,TweenInfo.new(0.15),{Position=UDim2.new(0.5,-140,1,-140)}):Play()
    task.delay(1.8,function()
        Tween:Create(sellPop,TweenInfo.new(0.3),{Position=UDim2.new(0.5,-140,1,-80)}):Play()
        task.delay(0.3,function() sellPop.BackgroundTransparency=1 end)
    end)
end)

-- Crit flash
local critPop=lbl(sg,"CRIT! ×5",UDim2.new(0,120,0,40),UDim2.new(0.5,-60,0.35,0),RED,28)
critPop.BackgroundTransparency=1;critPop.TextStrokeTransparency=0;critPop.Visible=false
critEv.OnClientEvent:Connect(function()
    critPop.Visible=true;critPop.TextTransparency=0
    Tween:Create(critPop,TweenInfo.new(0.6,Enum.EasingStyle.Quart),{TextTransparency=1}):Play()
    task.delay(0.7,function() critPop.Visible=false end)
end)

-- BPS Storm overlay
local stormBar=frm(sg,Color3.fromRGB(255,80,0),UDim2.new(1,0,0,22),UDim2.new(0,0,0,70))
stormBar.BackgroundTransparency=1
local stormLbl=lbl(stormBar,"⚡ BPS STORM ×2 ⚡",UDim2.new(1,0,1,0),nil,Color3.new(1,1,0.2),14)
bpsStormEv.OnClientEvent:Connect(function(active)
    stormBar.BackgroundTransparency=active and 0 or 1
    stormLbl.Visible=active
end)

-- Shop panel
local shopPanel=frm(sg,PANEL,UDim2.new(0,320,1,-70),UDim2.new(1,0,0,70))
corner(8,shopPanel)
local shopHdr=frm(shopPanel,DARK,UDim2.new(1,0,0,40))
local shopTitle=lbl(shopHdr,"",UDim2.new(1,-44,1,0),UDim2.new(0,12,0,0),TXT,16,Enum.TextXAlignment.Left)
local closeBtn=tbtn(shopHdr,"X",Color3.fromRGB(160,50,50),UDim2.new(0,36,0,36),UDim2.new(1,-38,0,2),TXT,16)
corner(4,closeBtn)

-- Three scrolling frames (early, generator, meta)
local upgScroll=scroll(shopPanel)
local genScroll=scroll(shopPanel)
local metaScroll=scroll(shopPanel)

-- Rebirth panel
local rebirthPanel=frm(shopPanel,DARK,UDim2.new(1,0,1,-40),UDim2.new(0,0,0,40))
rebirthPanel.BackgroundTransparency=1;rebirthPanel.Visible=false
lbl(rebirthPanel,"Rebirth Shrine",UDim2.new(1,-16,0,44),UDim2.new(0,8,0,16),GOLD,22)
local rebirthInfo=lbl(rebirthPanel,"...",UDim2.new(1,-24,0,80),UDim2.new(0,12,0,68),SUB,13,nil,Enum.Font.Gotham)
rebirthInfo.TextWrapped=true
local doRebirthBtn=tbtn(rebirthPanel,"REBIRTH NOW",DIM,UDim2.new(0,200,0,46),UDim2.new(0.5,-100,0,160),Color3.fromRGB(28,14,0),15)
corner(8,doRebirthBtn)
doRebirthBtn.MouseButton1Click:Connect(function()
    if totalV.Value>=GD.RebirthThreshold then rebirthEv:FireServer() end
end)

-- Build upgrade cards (early + generator tiers)
local upgCards={}
local function makeUpgradeCard(parent,u,isUpg)
    local card=frm(parent,Color3.fromRGB(8,8,16),UDim2.new(1,0,0,70));corner(6,card)
    lbl(card,u.name,UDim2.new(0.55,0,0,22),UDim2.new(0,8,0,6),TXT,13,Enum.TextXAlignment.Left)
    lbl(card,u.desc,UDim2.new(0.55,0,0,18),UDim2.new(0,8,0,28),SUB,10,Enum.TextXAlignment.Left,Enum.Font.Gotham)
    local reqLbl=lbl(card,"",UDim2.new(0.55,0,0,14),UDim2.new(0,8,0,48),SUB,9,Enum.TextXAlignment.Left,Enum.Font.Gotham)
    local costLbl=lbl(card,fmt(u.baseCost),UDim2.new(0,76,0,14),UDim2.new(1,-80,1,-18),GOLD,10,nil,Enum.Font.Gotham)
    local buyB=tbtn(card,"Buy",ACC,UDim2.new(0,76,0,30),UDim2.new(1,-80,0.5,-15),TXT,12);corner(5,buyB)
    buyB.MouseButton1Click:Connect(function()
        if isUpg then upgEv:FireServer(u.id) else upgEv:FireServer(u.id) end
    end)
    upgCards[u.id]={card=card,buyB=buyB,reqLbl=reqLbl}
end

for _,u in GD.Upgrades do
    local parent = u.tier=="generator" and genScroll or upgScroll
    makeUpgradeCard(parent,u,true)
end

-- Meta upgrade cards
local metaCards={}
for _,u in GD.MetaUpgrades do
    local card=frm(metaScroll,Color3.fromRGB(14,6,22),UDim2.new(1,0,0,70));corner(6,card)
    lbl(card,u.name,UDim2.new(0.55,0,0,22),UDim2.new(0,8,0,6),Color3.fromRGB(200,150,255),13,Enum.TextXAlignment.Left)
    lbl(card,u.desc,UDim2.new(0.55,0,0,32),UDim2.new(0,8,0,26),SUB,10,Enum.TextXAlignment.Left,Enum.Font.Gotham)
    lbl(card,u.neuronCost.." Neuron"..(u.neuronCost>1 and "s" or ""),UDim2.new(0,76,0,14),UDim2.new(1,-80,1,-18),GOLD,10,nil,Enum.Font.Gotham)
    local buyB=tbtn(card,"Buy",Color3.fromRGB(60,20,100),UDim2.new(0,76,0,30),UDim2.new(1,-80,0.5,-15),TXT,12);corner(5,buyB)
    buyB.MouseButton1Click:Connect(function() metaEv:FireServer(u.id) end)
    metaCards[u.id]={card=card,buyB=buyB}
end

local TI_OPEN=TweenInfo.new(0.3,Enum.EasingStyle.Quint,Enum.EasingDirection.Out)
local TI_CLOSE=TweenInfo.new(0.22,Enum.EasingStyle.Quint,Enum.EasingDirection.In)
local currentCat=""
local function openShop(cat)
    currentCat=cat
    Tween:Create(shopPanel,TI_OPEN,{Position=UDim2.new(1,-324,0,70)}):Play()
    upgScroll.Visible=cat=="upgrades"
    genScroll.Visible=cat=="generator"
    metaScroll.Visible=cat=="meta"
    rebirthPanel.Visible=cat=="rebirth"
    local titles={upgrades="Upgrade Lab",generator="Generator Console",meta="Meta Lab",rebirth="Rebirth Shrine"}
    shopTitle.Text=titles[cat] or cat
end
local function closeShop()
    currentCat=""
    Tween:Create(shopPanel,TI_CLOSE,{Position=UDim2.new(1,0,0,70)}):Play()
end
closeBtn.MouseButton1Click:Connect(closeShop)
openShopEv.OnClientEvent:Connect(openShop)

-- Brain bounce
plotEv.OnClientEvent:Connect(function(plot)
    local brain=plot:FindFirstChild("Brain")
    local cd=brain and brain:FindFirstChild("ClickDetector"); if not cd then return end
    cd.MouseClick:Connect(function()
        Tween:Create(brain,TweenInfo.new(0.06),{Size=Vector3.new(6.5,6.5,6.5)}):Play()
        task.delay(0.07,function()
            Tween:Create(brain,TweenInfo.new(0.14,Enum.EasingStyle.Bounce),{Size=Vector3.new(8,8,8)}):Play()
        end)
    end)
end)

-- 0.1s update loop
task.spawn(function()
    while true do
        local brain=brainV.Value; local total=totalV.Value; local raw=rawV.Value
        statVals.Brain.Text=fmt(brain); statVals.BPC.Text=fmt(bpcV.Value)
        statVals.BPS.Text=("%.1f/s"):format(bpsV.Value)
        statVals.Raw.Text=fmt(raw); statVals.RP.Text=tostring(rpV.Value)
        sellHint.Text=raw>=1 and("  %s pending — press E at Brain Market"):format(fmt(raw))
            or "  Click Brain for direct Brains  |  Walk gen pads to buy  |  Sell pending at Market"
        local prog=math.clamp(total/GD.RebirthThreshold,0,1)
        progFill.Size=UDim2.new(prog,0,1,0)
        if currentCat=="rebirth" then
            local elig=total>=GD.RebirthThreshold
            rebirthInfo.Text=elig and("Ready! Earn %d Neurons."):format(math.max(1,math.floor(total/GD.RebirthThreshold)))
                or("Need %s total  (%d%%)"):format(fmt(GD.RebirthThreshold),math.floor(prog*100))
            doRebirthBtn.BackgroundColor3=elig and GOLD or DIM
            doRebirthBtn.TextColor3=elig and Color3.fromRGB(28,14,0) or SUB
        end
        -- Upgrade cards
        for _,u in GD.Upgrades do
            local ov=upgF:FindFirstChild(u.id); local c=upgCards[u.id]; if not c then continue end
            local reqMet=checkReq(u.req)
            if ov and ov.Value then
                c.card.BackgroundColor3=Color3.fromRGB(18,32,18)
                c.buyB.Text="Owned";c.buyB.BackgroundColor3=Color3.fromRGB(28,56,28);c.buyB.TextColor3=GRN
                c.reqLbl.Text=""
            elseif not reqMet then
                c.card.BackgroundColor3=Color3.fromRGB(8,8,16)
                c.buyB.Text="Locked";c.buyB.BackgroundColor3=DIM;c.buyB.TextColor3=SUB
                -- Show req hint
                local r=u.req
                if r.type=="clicks" then c.reqLbl.Text="Need "..r.count.." clicks"
                elseif r.type=="genOwned" then c.reqLbl.Text="Need "..r.count.." "..r.id
                elseif r.type=="anyTotal" then c.reqLbl.Text="Need "..r.count.." total gens"
                elseif r.type=="anyGen" then c.reqLbl.Text="Need "..r.count.." of one gen"
                elseif r.type=="upgOwned" then c.reqLbl.Text="Need "..r.id end
            else
                c.card.BackgroundColor3=Color3.fromRGB(8,8,16)
                local can=brain>=u.baseCost
                c.buyB.Text="Buy";c.buyB.BackgroundColor3=can and ACC or DIM;c.buyB.TextColor3=can and TXT or SUB
                c.reqLbl.Text=""
            end
        end
        -- Meta cards
        for _,u in GD.MetaUpgrades do
            local mv=metaF:FindFirstChild(u.id); local c=metaCards[u.id]; if not c then continue end
            if mv and mv.Value then
                c.card.BackgroundColor3=Color3.fromRGB(14,6,28)
                c.buyB.Text="Owned";c.buyB.BackgroundColor3=Color3.fromRGB(30,10,50);c.buyB.TextColor3=PURP
            else
                local can=rpV.Value>=u.neuronCost
                c.buyB.BackgroundColor3=can and Color3.fromRGB(80,20,120) or DIM
                c.buyB.TextColor3=can and TXT or SUB
            end
        end
        task.wait(0.1)
    end
end)
