--[[
    Cloud Script's | FINAL
    LocalScript > StarterPlayerScripts
    ═══════════════════════════════════════════════════════
    ultrabypass v1 (15 katman) + Cloud Script v2 özellikleri
    + Aimbot tam yeniden yazma (titremesiz, anlık snap)
    + Speed menüsüz modda DOKUNULMAZ fix
    + Tüm özellikler bypass arkasında çalışır
    ═══════════════════════════════════════════════════════
]]

-- ══════════════════════════════════════════════════════
-- ██████████  ULTRABYPASS v1  ██████████
-- ══════════════════════════════════════════════════════
if not getgenv()._ultrabypass_v1 then
    getgenv()._ultrabypass_v1 = true

    local SAFE = {
        "score","points","coins","cash","money","currency","gem","gold",
        "reward","purchase","buy","sell","shop","inventory","item","weapon",
        "damage","health","hit","kill","death","respawn","spawn","match",
        "round","game","player","stats","leaderboard","xp","level","rank",
        "quest","mission","trade","drop","loot","ammo","reload","fire","shoot",
        "skin","cosmetic","emote","chat","team","party","friend","clan",
        "move","animate","animation","sound","music","effect","particle",
        "ui","gui","hud","menu","lobby","map","zone","region","trigger",
        "vehicle","mount","pet","npc","mob","boss","door","chest",
    }
    local HARD_AC = {
        "anticheat","anti_cheat","anti-cheat",
        "antiexploit","anti_exploit","anti-exploit",
        "ac_detect","ac_report","ac_flag","ac_log",
        "ac_kick","ac_ban","ac_punish","ac_warn",
        "acguard","acguardian","acmodule","acservice",
        "accheck","acmonitor","achandler","accore",
        "watchdog","sentinel","guardian","enforcer","protector",
        "integritycheck","integrity_check","integrityguard",
        "exploitdetect","exploit_detect","exploitcheck",
        "cheatdetect","cheat_detect","cheatguard","cheatblock",
        "violationreport","violation_report","violation_log",
        "suspiciousactivity","suspicious_activity","suspectlog",
        "securitykick","security_kick","securityban","security_ban",
        "securitycheck","security_check","securitycore",
        "antitamper","anti_tamper","tamperdetect",
        "honeypot","canary","tripwire","baitremote","trapremote",
        "patchguard","kernelguard","memoryguard","memcheck",
        "speedhack","flyhack","nocliphack","teleportdetect",
        "remotelogger","remotespy","remotemonitor","remotecheck",
        "scriptdetect","scriptguard","scriptcheck","corecheck",
        "playercheck","playerguard","clientcheck","clientguard",
        "detectionservice","banservice","kickservice","reportservice",
        "executordetect","exploitcheck","synapse","celery","krnl",
        "scriptware","fluxus","hydrogen","delta","arceus",
    }

    local dbg = getfenv().debug or getgenv().debug or debug

    local function _has(s, list)
        if type(s) ~= "string" then return false end
        s = s:lower()
        for i = 1, #list do if s:find(list[i], 1, true) then return true end end
        return false
    end
    local function _isSafe(n, pn)  return _has(n, SAFE) or _has(pn or "", SAFE) end
    local function _isAC(n, pn)    if _isSafe(n, pn) then return false end return _has(n, HARD_AC) or _has(pn or "", HARD_AC) end
    local function _srcIsAC(fn)
        if not fn or not dbg or not dbg.getinfo then return false end
        local ok, info = pcall(dbg.getinfo, fn)
        if not ok or not info then return false end
        local src = info.source or ""
        return _has(src, HARD_AC) and not _has(src, SAFE)
    end
    local function _hasACConn(sig)
        if not getconnections then return false end
        local ok, conns = pcall(getconnections, sig)
        if not ok or not conns then return false end
        for _, c in ipairs(conns) do if _srcIsAC(c.Function) then return true end end
        return false
    end
    local function _silence(obj)
        for _, sn in ipairs({"OnClientEvent","OnServerEvent","Event","Invoke"}) do
            pcall(function()
                local s = obj[sn]
                if s and getconnections then
                    for _, c in ipairs(getconnections(s)) do
                        pcall(function() c:Disable() end)
                        pcall(function() c:Disconnect() end)
                    end
                end
            end)
        end
    end
    local function _proxyRemote(r)
        pcall(function()
            if r:IsA("RemoteEvent") then
                local orig = r.FireServer
                r.FireServer = newcclosure(function(self, ...)
                    local a = {...}
                    for i = 1, #a do if type(a[i])=="string" and _has(a[i], HARD_AC) then return nil end end
                    return orig(self, ...)
                end)
            elseif r:IsA("RemoteFunction") then
                local orig = r.InvokeServer
                r.InvokeServer = newcclosure(function(self, ...)
                    local a = {...}
                    for i = 1, #a do if type(a[i])=="string" and _has(a[i], HARD_AC) then return nil end end
                    return orig(self, ...)
                end)
            end
        end)
        _silence(r)
    end
    local function _proxyBindable(b)
        pcall(function()
            if b:IsA("BindableEvent") then
                local orig = b.Fire
                b.Fire = newcclosure(function(self, ...)
                    local a = {...}
                    for i = 1, #a do if type(a[i])=="string" and _has(a[i], HARD_AC) then return nil end end
                    return orig(self, ...)
                end)
            elseif b:IsA("BindableFunction") then
                local orig = b.Invoke
                b.Invoke = newcclosure(function(self, ...)
                    local a = {...}
                    for i = 1, #a do if type(a[i])=="string" and _has(a[i], HARD_AC) then return nil end end
                    return orig(self, ...)
                end)
            end
        end)
        _silence(b)
    end
    local function _killScript(s)
        pcall(function() s.Disabled = true end)
        pcall(function() s.Enabled  = false end)
        if dbg and dbg.getconstants and dbg.setconstant then
            pcall(function()
                local cs = dbg.getconstants(s)
                for i, v in ipairs(cs) do
                    if type(v)=="string" and _has(v, HARD_AC) then pcall(dbg.setconstant, s, i, "") end
                end
            end)
        end
        pcall(function() s:Destroy() end)
    end
    local function _collect()
        local seen, out = {}, {}
        local function add(o) if o and not seen[o] then seen[o]=true; out[#out+1]=o end end
        for _, o in ipairs(game:GetDescendants()) do
            local pn = (o.Parent and o.Parent.Name) or ""
            if o:IsA("RemoteEvent") or o:IsA("RemoteFunction") then
                if _isAC(o.Name, pn) or _hasACConn(o.OnClientEvent) then add(o) end
            elseif o:IsA("BindableEvent") or o:IsA("BindableFunction") then
                if _isAC(o.Name, pn) then add(o) end
            elseif o:IsA("LocalScript") or o:IsA("Script") or o:IsA("ModuleScript") then
                if _isAC(o.Name, pn) then add(o) end
            end
        end
        for _, sn in ipairs({"AntiCheat","AntiExploit","SecurityService","ACGuardian","ExploitDetector","CheatGuard","AntiTamper","Watchdog"}) do
            local ok, sv = pcall(function() return game:GetService(sn) end)
            if ok and sv then add(sv) end
        end
        return out
    end
    local function _applyMetaLock()
        if not getrawmetatable or not setreadonly then return end
        local mt = getrawmetatable(game)
        if not mt then return end
        local oNC = mt.__namecall
        local oI  = mt.__index
        local oNI = mt.__newindex
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            if not checkcaller() then
                local m = getnamecallmethod()
                if m == "Kick" then return nil end
                if m=="FireServer" or m=="InvokeServer" or m=="FireAllClients" or m=="FireClient" then
                    local ok2, n  = pcall(function() return self.Name end)
                    local ok3, pn = pcall(function() return self.Parent and self.Parent.Name end)
                    if ok2 and _isAC(n, ok3 and pn) then return nil end
                end
            end
            return oNC(self, ...)
        end)
        mt.__index = newcclosure(function(self, k)
            if not checkcaller() and type(k)=="string" then
                local ok2, sn = pcall(function() return self.Name end)
                if ok2 and _isAC(k, sn) then
                    local v = oI(self, k)
                    if type(v)=="function" then return newcclosure(function() return nil end) end
                end
            end
            return oI(self, k)
        end)
        mt.__newindex = newcclosure(function(self, k, v)
            if not checkcaller() and type(k)=="string" then
                local ok2, sn = pcall(function() return self.Name end)
                if ok2 and _isAC(sn, nil) and _has(k, {"enabled","active","running","started"}) then
                    return nil
                end
            end
            if oNI then return oNI(self, k, v) end
        end)
        setreadonly(mt, true)
    end
    local RS = game:GetService("RunService")
    local function _neutralizeRS()
        if not getconnections then return end
        for _, sig in ipairs({RS.Heartbeat, RS.Stepped, RS.RenderStepped}) do
            pcall(function()
                for _, conn in ipairs(getconnections(sig)) do
                    if _srcIsAC(conn.Function) then
                        pcall(function() conn:Disable() end)
                        pcall(function() conn:Disconnect() end)
                    end
                end
            end)
        end
    end
    local function _purgeGC()
        if not getgc or not dbg then return end
        pcall(function()
            for _, obj in ipairs(getgc(true)) do
                if type(obj)=="function" and islclosure and islclosure(obj) then
                    local ok, info = pcall(dbg.getinfo, obj)
                    local src = (ok and info and info.source) or ""
                    if _has(src, HARD_AC) and not _has(src, SAFE) then
                        if dbg.getupvalue and dbg.setupvalue then
                            for i = 1, 100 do
                                local nm = dbg.getupvalue(obj, i)
                                if not nm then break end
                                pcall(dbg.setupvalue, obj, i, nil)
                            end
                        end
                        if dbg.getconstants and dbg.setconstant then
                            local ok2, cs = pcall(dbg.getconstants, obj)
                            if ok2 and cs then
                                for i, v in ipairs(cs) do
                                    if type(v)=="string" and _has(v, HARD_AC) then pcall(dbg.setconstant, obj, i, "") end
                                end
                            end
                        end
                    end
                end
            end
        end)
    end
    local function _purgeCoroutines()
        if not getgc or not dbg or not dbg.getinfo then return end
        pcall(function()
            for _, obj in ipairs(getgc(true)) do
                if type(obj)=="thread" then
                    local ok, info = pcall(dbg.getinfo, obj, 1)
                    if ok and info then
                        local src = info.source or ""
                        if _has(src, HARD_AC) and not _has(src, SAFE) then pcall(coroutine.close, obj) end
                    end
                end
            end
        end)
    end
    local function _hookGetService()
        if not hookfunction then return end
        local orig = game.GetService
        hookfunction(orig, newcclosure(function(self, sn)
            if _isAC(sn, nil) then
                return setmetatable({}, {
                    __index    = function() return function() return nil end end,
                    __newindex = function() end,
                    __call     = function() return nil end,
                })
            end
            return orig(self, sn)
        end))
    end
    local function _hookInstanceNew()
        if not hookfunction then return end
        local orig = Instance.new
        hookfunction(orig, newcclosure(function(cn, parent)
            if (cn=="LocalScript" or cn=="Script" or cn=="ModuleScript") and parent then
                local pn = pcall(function() return parent.Name end) and parent.Name or ""
                if _isAC(pn, nil) then return nil end
            end
            return orig(cn, parent)
        end))
    end
    local function _watchNew()
        game.DescendantAdded:Connect(function(o)
            task.defer(function()
                pcall(function()
                    local pn = (o.Parent and o.Parent.Name) or ""
                    if o:IsA("RemoteEvent") or o:IsA("RemoteFunction") then
                        if _isAC(o.Name, pn) or _hasACConn(o.OnClientEvent) then _proxyRemote(o) end
                    elseif o:IsA("BindableEvent") or o:IsA("BindableFunction") then
                        if _isAC(o.Name, pn) then _proxyBindable(o) end
                    elseif o:IsA("LocalScript") or o:IsA("Script") or o:IsA("ModuleScript") then
                        if _isAC(o.Name, pn) then _killScript(o) end
                    end
                end)
            end)
        end)
    end

    local function _run()
        local targets = _collect()
        for _, o in ipairs(targets) do
            if o:IsA("LocalScript") or o:IsA("Script") or o:IsA("ModuleScript") then
                _killScript(o)
            elseif o:IsA("RemoteEvent") or o:IsA("RemoteFunction") then
                _proxyRemote(o)
            elseif o:IsA("BindableEvent") or o:IsA("BindableFunction") then
                _proxyBindable(o)
            else
                _silence(o)
            end
        end
        _applyMetaLock()
        _neutralizeRS()
        _purgeGC()
        _purgeCoroutines()
        _hookGetService()
        _hookInstanceNew()
        _watchNew()
    end

    -- Sadece bir kez çalıştır — respawn'da tekrar etme
    local _lp = game:GetService("Players").LocalPlayer
    if _lp.Character then
        task.spawn(_run)
    else
        _lp.CharacterAdded:Once(function()
            task.wait(0.4)
            task.spawn(_run)
        end)
    end
    -- respawn'da sadece RS+GC temizliği (hafif), tam _run değil
    -- kaldırıldı: _lp.CharacterAdded:Connect(...)
end

-- ══════════════════════════════════════════════════════
-- ██████████  CLOUD SCRIPT'S FINAL  ██████████
-- ══════════════════════════════════════════════════════

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local Camera           = workspace.CurrentCamera

local player    = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

-- ══════════════════════════════════════════════════════
-- AYARLAR
-- ══════════════════════════════════════════════════════
local S = {
    ESP = {
        Enabled = true,  Rainbow = true,
        Color = Color3.fromRGB(255,60,120),
        RainbowSpeed = 2, Box = true, Name = true,
        Distance = true, Health = true,
        MaxDist = 800,   Tracers = true,
        TracerFrom = "Bottom",
        TracerColor = Color3.fromRGB(255,255,255),
        TracerThick = 2,
    },
    Hitbox = {
        Enabled = false, Show = false,
        Size = 12, Trans = 0.6,
        Color = Color3.fromRGB(255,255,255),
    },
    Aim = {
        Enabled     = false,
        Silent      = false,
        ShowFov     = true,
        Fov         = 120,
        Smooth      = 8,
        Part        = "Head",
        TeamCheck   = true,
        WallCheck   = true,
        Holding     = false,
        MobileLock  = false,
        _target     = nil,
        _snapDone   = false,
    },
    Mods = {
        SpeedOn    = false,   -- SADECE bu true iken WalkSpeed değiştirilir
        SpeedVal   = 32,
        JumpVal    = 50,
        InfJump    = false,
        Fly        = false,
        FlySpeed   = 60,
        Noclip     = false,
        Fullbright = false,
    },
}

-- Oyunun varsayılan WalkSpeed'ini bir kez oku (menüsüz mod için)
local DEFAULT_WALKSPEED = 16
task.defer(function()
    if player.Character then
        local hum = player.Character:FindFirstChildOfClass("Humanoid")
        if hum then DEFAULT_WALKSPEED = hum.WalkSpeed end
    end
end)

-- ══════════════════════════════════════════════════════
-- GUI YARDIMCI
-- ══════════════════════════════════════════════════════
local function tw(o,i,p) return TweenService:Create(o,i,p) end
local function cnr(o,r)  local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,r) c.Parent=o return c end
local function str(o,c,t,tr) local s=Instance.new("UIStroke") s.Color=c s.Thickness=t s.Transparency=tr or 0 s.Parent=o return s end

-- ══════════════════════════════════════════════════════
-- GUI CONTAINER
-- ══════════════════════════════════════════════════════
local gui = Instance.new("ScreenGui")
gui.Name = "CloudScripts" gui.ResetOnSpawn=false
gui.IgnoreGuiInset=true gui.DisplayOrder=999 gui.Parent=PlayerGui

local overlay = Instance.new("ScreenGui")
overlay.Name="CloudOverlay" overlay.ResetOnSpawn=false
overlay.IgnoreGuiInset=true overlay.DisplayOrder=998 overlay.Parent=PlayerGui

-- ══════════════════════════════════════════════════════
-- LOADER
-- ══════════════════════════════════════════════════════
local loader=Instance.new("Frame")
loader.Size=UDim2.new(1,0,1,0)
loader.BackgroundColor3=Color3.fromRGB(11,13,21)
loader.BorderSizePixel=0 loader.Parent=gui

local grad=Instance.new("UIGradient")
grad.Color=ColorSequence.new{
    ColorSequenceKeypoint.new(0,Color3.fromRGB(11,13,21)),
    ColorSequenceKeypoint.new(.5,Color3.fromRGB(19,24,42)),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(10,11,19))
}
grad.Rotation=35 grad.Parent=loader

local card=Instance.new("Frame")
card.AnchorPoint=Vector2.new(.5,.5) card.Position=UDim2.new(.5,0,.5,0)
card.Size=UDim2.new(0,0,0,0) card.BackgroundColor3=Color3.fromRGB(20,23,36)
card.BackgroundTransparency=.12 card.BorderSizePixel=0 card.Parent=loader
cnr(card,24) str(card,Color3.new(1,1,1),1,.85)

local cloudH=Instance.new("Frame")
cloudH.AnchorPoint=Vector2.new(.5,.5) cloudH.Position=UDim2.new(.5,0,.36,0)
cloudH.Size=UDim2.new(0,0,0,0) cloudH.BackgroundTransparency=1 cloudH.Parent=card

local function puff(x,y,sx,sy)
    local f=Instance.new("Frame")
    f.AnchorPoint=Vector2.new(.5,.5) f.Position=UDim2.new(.5,x,.5,y)
    f.Size=UDim2.new(0,sx,0,sy) f.BackgroundColor3=Color3.fromRGB(255,255,255)
    f.BorderSizePixel=0 f.Parent=cloudH cnr(f,100)
    local g=Instance.new("UIGradient")
    g.Color=ColorSequence.new{
        ColorSequenceKeypoint.new(0,Color3.fromRGB(255,255,255)),
        ColorSequenceKeypoint.new(1,Color3.fromRGB(205,220,255))
    }
    g.Rotation=90 g.Parent=f return f
end
puff(-45,15,90,70) puff(0,-5,110,90) puff(45,15,95,75) puff(0,28,160,45)

local glow=Instance.new("ImageLabel")
glow.AnchorPoint=Vector2.new(.5,.5) glow.Position=UDim2.new(.5,0,.5,10)
glow.Size=UDim2.new(0,240,0,150) glow.BackgroundTransparency=1
glow.Image="rbxassetid://6014261993"
glow.ImageColor3=Color3.fromRGB(130,170,255) glow.ImageTransparency=.75 glow.Parent=cloudH

local titleL=Instance.new("TextLabel")
titleL.AnchorPoint=Vector2.new(.5,0) titleL.Position=UDim2.new(.5,0,.62,0)
titleL.Size=UDim2.new(1,0,0,30) titleL.BackgroundTransparency=1
titleL.Text="Cloud Script's" titleL.Font=Enum.Font.GothamBold titleL.TextSize=22
titleL.TextColor3=Color3.new(1,1,1) titleL.TextTransparency=1 titleL.Parent=card

local subL=Instance.new("TextLabel")
subL.AnchorPoint=Vector2.new(.5,0) subL.Position=UDim2.new(.5,0,.62,30)
subL.Size=UDim2.new(1,0,0,16) subL.BackgroundTransparency=1
subL.Text="coolest softest best experience" subL.Font=Enum.Font.Gotham
subL.TextSize=11 subL.TextColor3=Color3.fromRGB(140,150,180) subL.TextTransparency=1 subL.Parent=card

local barBg=Instance.new("Frame")
barBg.AnchorPoint=Vector2.new(.5,0) barBg.Position=UDim2.new(.5,0,.83,0)
barBg.Size=UDim2.new(.8,0,0,6) barBg.BackgroundColor3=Color3.new(1,1,1)
barBg.BackgroundTransparency=.9 barBg.BorderSizePixel=0 barBg.Parent=card cnr(barBg,100)
local barF=Instance.new("Frame") barF.Size=UDim2.new(0,0,1,0)
barF.BackgroundColor3=Color3.new(1,1,1) barF.BorderSizePixel=0 barF.Parent=barBg cnr(barF,100)
local barGrad=Instance.new("UIGradient")
barGrad.Color=ColorSequence.new{
    ColorSequenceKeypoint.new(0,Color3.fromRGB(120,170,255)),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(210,225,255))
}
barGrad.Parent=barF
local percL=Instance.new("TextLabel")
percL.AnchorPoint=Vector2.new(.5,0) percL.Position=UDim2.new(.5,0,.83,12)
percL.Size=UDim2.new(1,0,0,16) percL.BackgroundTransparency=1 percL.Text="%0"
percL.Font=Enum.Font.GothamMedium percL.TextSize=11
percL.TextColor3=Color3.fromRGB(180,190,210) percL.Parent=card

tw(card,TweenInfo.new(.7,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.new(0,320,0,300)}):Play()
task.wait(.35)
tw(cloudH,TweenInfo.new(.8,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.new(0,180,0,110)}):Play()
tw(titleL,TweenInfo.new(.5),{TextTransparency=0}):Play()
tw(subL,TweenInfo.new(.5),{TextTransparency=0}):Play()

task.spawn(function()
    while loader.Parent do
        tw(cloudH,TweenInfo.new(1.3,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Position=UDim2.new(.5,0,.36,-6)}):Play()
        task.wait(1.3)
        if not loader.Parent then break end
        tw(cloudH,TweenInfo.new(1.3,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Position=UDim2.new(.5,0,.36,0)}):Play()
        task.wait(1.3)
    end
end)

for i=0,100 do
    barF.Size=UDim2.new(i/100,0,1,0) percL.Text="%"..i task.wait(.016)
end
task.wait(.25)

tw(titleL,TweenInfo.new(.3),{Position=UDim2.new(.5,0,.48,0)}):Play()
tw(subL,TweenInfo.new(.3),{TextTransparency=1}):Play()
tw(barBg,TweenInfo.new(.3),{BackgroundTransparency=1}):Play()
tw(barF,TweenInfo.new(.3),{BackgroundTransparency=1}):Play()
tw(percL,TweenInfo.new(.3),{TextTransparency=1}):Play()
task.wait(.3)
barBg.Visible=false percL.Visible=false subL.Visible=false

-- ══════════════════════════════════════════════════════
-- LOADER SEÇİM BUTONLARI
-- ══════════════════════════════════════════════════════
local function mkChoice(y,txt,white)
    local b=Instance.new("TextButton")
    b.AnchorPoint=Vector2.new(.5,0) b.Position=UDim2.new(.5,0,y,0)
    b.Size=UDim2.new(.8,0,0,0)
    b.BackgroundColor3=white and Color3.new(1,1,1) or Color3.fromRGB(30,34,52)
    b.Text=txt b.Font=Enum.Font.GothamBold b.TextSize=13
    b.TextColor3=white and Color3.fromRGB(15,18,28) or Color3.new(1,1,1)
    b.AutoButtonColor=false b.Parent=card cnr(b,14)
    if not white then str(b,Color3.new(1,1,1),1,.85) end
    tw(b,TweenInfo.new(.5,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.new(.8,0,0,42)}):Play()
    b.MouseEnter:Connect(function() tw(b,TweenInfo.new(.2),{Size=UDim2.new(.83,0,0,46)}):Play() end)
    b.MouseLeave:Connect(function() tw(b,TweenInfo.new(.2),{Size=UDim2.new(.8,0,0,42)}):Play() end)
    return b
end
local bMenu   = mkChoice(.62,"  ●  MENULU DEVAM ET",true)
local bNoMenu = mkChoice(.79,"  ○  MENUSUZ DEVAM ET",false)

-- ══════════════════════════════════════════════════════
-- FOV DAİRESİ
-- ══════════════════════════════════════════════════════
local fovFrame=Instance.new("Frame")
fovFrame.AnchorPoint=Vector2.new(.5,.5)
fovFrame.BackgroundTransparency=1 fovFrame.Visible=false fovFrame.Parent=gui cnr(fovFrame,1000)
local fovStroke=str(fovFrame,Color3.new(1,1,1),1.5,0)
local function updFov()
    fovFrame.Position=UDim2.new(.5,0,.5,0)
    fovFrame.Size=UDim2.new(0,S.Aim.Fov*2,0,S.Aim.Fov*2)
    fovFrame.Visible=S.Aim.ShowFov and S.Aim.Enabled
end

-- ══════════════════════════════════════════════════════
-- ANA MENÜ
-- ══════════════════════════════════════════════════════
local menu=Instance.new("Frame")
menu.AnchorPoint=Vector2.new(.5,.5) menu.Position=UDim2.new(.5,0,.5,0)
menu.Size=UDim2.new(0,360,0,480) menu.BackgroundColor3=Color3.fromRGB(18,20,32)
menu.BackgroundTransparency=.06 menu.BorderSizePixel=0 menu.Visible=false menu.Parent=gui
cnr(menu,20) str(menu,Color3.new(1,1,1),1,.8)
local sizeC=Instance.new("UISizeConstraint")
sizeC.MaxSize=Vector2.new(380,520) sizeC.MinSize=Vector2.new(300,380) sizeC.Parent=menu

local topBar=Instance.new("Frame")
topBar.Size=UDim2.new(1,0,0,56)
topBar.BackgroundColor3=Color3.new(1,1,1) topBar.BackgroundTransparency=.94
topBar.BorderSizePixel=0 topBar.Parent=menu cnr(topBar,20)
local topFix=Instance.new("Frame")
topFix.AnchorPoint=Vector2.new(.5,1) topFix.Position=UDim2.new(.5,0,1,0)
topFix.Size=UDim2.new(1,0,0,20)
topFix.BackgroundColor3=topBar.BackgroundColor3
topFix.BackgroundTransparency=topBar.BackgroundTransparency
topFix.BorderSizePixel=0 topFix.Parent=topBar
local topTitle=Instance.new("TextLabel")
topTitle.Position=UDim2.new(0,14,0,8) topTitle.Size=UDim2.new(1,-100,0,20)
topTitle.BackgroundTransparency=1 topTitle.Text="☁  Cloud Script's"
topTitle.Font=Enum.Font.GothamBold topTitle.TextSize=15
topTitle.TextXAlignment=0 topTitle.TextColor3=Color3.new(1,1,1) topTitle.Parent=topBar
local topSub=Instance.new("TextLabel")
topSub.Position=UDim2.new(0,14,0,28) topSub.Size=UDim2.new(1,-100,0,16)
topSub.BackgroundTransparency=1 topSub.Text="esp • hitbox • aim • mods"
topSub.Font=Enum.Font.Gotham topSub.TextSize=11
topSub.TextXAlignment=0 topSub.TextColor3=Color3.fromRGB(130,200,255) topSub.Parent=topBar

local function mkTopBtn(x,t,c)
    local b=Instance.new("TextButton")
    b.AnchorPoint=Vector2.new(1,.5) b.Position=UDim2.new(1,x,.5,0)
    b.Size=UDim2.new(0,30,0,30) b.BackgroundColor3=c b.Text=t
    b.Font=Enum.Font.GothamBold b.TextSize=14
    b.TextColor3=Color3.new(1,1,1) b.AutoButtonColor=false b.Parent=topBar cnr(b,10)
    return b
end
local closeBtn=mkTopBtn(-10,"—",Color3.fromRGB(55,60,85))
local xBtn    =mkTopBtn(-46,"×",Color3.fromRGB(255,95,95))

local tabBar=Instance.new("Frame")
tabBar.Position=UDim2.new(0,10,0,66) tabBar.Size=UDim2.new(1,-20,0,34)
tabBar.BackgroundTransparency=1 tabBar.Parent=menu
local tabLayout=Instance.new("UIListLayout")
tabLayout.FillDirection=Enum.FillDirection.Horizontal tabLayout.Padding=UDim.new(0,6) tabLayout.Parent=tabBar

local pages=Instance.new("Frame")
pages.Position=UDim2.new(0,10,0,106) pages.Size=UDim2.new(1,-20,1,-116)
pages.BackgroundTransparency=1 pages.Parent=menu

local function mkPage()
    local s=Instance.new("ScrollingFrame")
    s.Size=UDim2.new(1,0,1,0) s.BackgroundTransparency=1
    s.ScrollBarThickness=3 s.ScrollBarImageColor3=Color3.fromRGB(120,170,255)
    s.AutomaticCanvasSize=Enum.AutomaticSize.Y
    s.CanvasSize=UDim2.new(0,0,0,0) s.Visible=false s.Parent=pages
    local l=Instance.new("UIListLayout")
    l.Padding=UDim.new(0,8) l.SortOrder=Enum.SortOrder.LayoutOrder l.Parent=s
    return s
end
local pESP=mkPage() local pHit=mkPage() local pAim=mkPage() local pMods=mkPage()
pESP.Visible=true

local function mkTab(txt,page)
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(.25,-5,1,0) b.BackgroundColor3=Color3.fromRGB(28,32,48)
    b.Text=txt b.Font=Enum.Font.GothamBold b.TextSize=11
    b.TextColor3=Color3.fromRGB(180,190,210) b.AutoButtonColor=false b.Parent=tabBar cnr(b,11)
    b.MouseButton1Click:Connect(function()
        for _,v in pairs(tabBar:GetChildren()) do
            if v:IsA("TextButton") then
                tw(v,TweenInfo.new(.2),{BackgroundColor3=Color3.fromRGB(28,32,48),TextColor3=Color3.fromRGB(180,190,210)}):Play()
            end
        end
        tw(b,TweenInfo.new(.2),{BackgroundColor3=Color3.new(1,1,1),TextColor3=Color3.fromRGB(15,18,28)}):Play()
        for _,p in pairs(pages:GetChildren()) do p.Visible=false end
        page.Visible=true
    end)
    return b
end
local tab1=mkTab("ESP",pESP) mkTab("HITBOX",pHit) mkTab("AIM",pAim) mkTab("MODS",pMods)
tab1.BackgroundColor3=Color3.new(1,1,1) tab1.TextColor3=Color3.fromRGB(15,18,28)

-- UI bileşenleri
local function sect(p,t)
    local l=Instance.new("TextLabel")
    l.Size=UDim2.new(1,0,0,18) l.BackgroundTransparency=1 l.Text=t
    l.Font=Enum.Font.GothamBold l.TextSize=11 l.TextXAlignment=0
    l.TextColor3=Color3.fromRGB(130,170,255) l.Parent=p return l
end
local function tog(p,txt,val,cb)
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(1,0,0,44) b.BackgroundColor3=Color3.fromRGB(28,32,48)
    b.Text="" b.AutoButtonColor=false b.Parent=p cnr(b,12) str(b,Color3.new(1,1,1),1,.88)
    local t=Instance.new("TextLabel")
    t.Position=UDim2.new(0,10,0,0) t.Size=UDim2.new(1,-60,1,0)
    t.BackgroundTransparency=1 t.Text=txt t.Font=Enum.Font.GothamBold
    t.TextSize=12 t.TextXAlignment=0 t.TextColor3=Color3.new(1,1,1) t.Parent=b
    local dot=Instance.new("Frame")
    dot.AnchorPoint=Vector2.new(1,.5) dot.Position=UDim2.new(1,-10,.5,0)
    dot.Size=UDim2.new(0,36,0,20)
    dot.BackgroundColor3=val and Color3.fromRGB(90,200,120) or Color3.fromRGB(55,60,80)
    dot.BorderSizePixel=0 dot.Parent=b cnr(dot,100)
    local dot2=Instance.new("Frame")
    dot2.AnchorPoint=Vector2.new(.5,.5)
    dot2.Position=UDim2.new(val and .75 or .25,.5,.5,0)
    dot2.Size=UDim2.new(0,14,0,14) dot2.BackgroundColor3=Color3.new(1,1,1)
    dot2.BorderSizePixel=0 dot2.Parent=dot cnr(dot2,100)
    local on=val
    b.MouseButton1Click:Connect(function()
        on=not on
        tw(dot,TweenInfo.new(.25),{BackgroundColor3=on and Color3.fromRGB(90,200,120) or Color3.fromRGB(55,60,80)}):Play()
        tw(dot2,TweenInfo.new(.25,Enum.EasingStyle.Back),{Position=UDim2.new(on and .75 or .25,.5,.5,0)}):Play()
        cb(on)
    end)
    return b
end
local function sld(p,txt,mn,mx,val,cb)
    local f=Instance.new("Frame")
    f.Size=UDim2.new(1,0,0,52) f.BackgroundColor3=Color3.fromRGB(28,32,48)
    f.BorderSizePixel=0 f.Parent=p cnr(f,12) str(f,Color3.new(1,1,1),1,.88)
    local t=Instance.new("TextLabel")
    t.Position=UDim2.new(0,10,0,6) t.Size=UDim2.new(1,-20,0,16)
    t.BackgroundTransparency=1 t.Text=txt.." : "..val
    t.Font=Enum.Font.GothamBold t.TextSize=11 t.TextXAlignment=0
    t.TextColor3=Color3.new(1,1,1) t.Parent=f
    local bg2=Instance.new("TextButton")
    bg2.AnchorPoint=Vector2.new(.5,0) bg2.Position=UDim2.new(.5,0,0,30)
    bg2.Size=UDim2.new(1,-20,0,12) bg2.BackgroundColor3=Color3.fromRGB(15,18,28)
    bg2.Text="" bg2.AutoButtonColor=false bg2.Parent=f cnr(bg2,100)
    local fill=Instance.new("Frame")
    fill.Size=UDim2.new((val-mn)/(mx-mn),0,1,0)
    fill.BackgroundColor3=Color3.fromRGB(130,170,255)
    fill.BorderSizePixel=0 fill.Parent=bg2 cnr(fill,100)
    local function setVal(v)
        v=math.clamp(math.floor(v),mn,mx)
        fill.Size=UDim2.new((v-mn)/(mx-mn),0,1,0)
        t.Text=txt.." : "..v cb(v)
    end
    bg2.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
            local function upd(pos)
                local rx=bg2.AbsolutePosition.X local sw=bg2.AbsoluteSize.X
                setVal(mn+(mx-mn)*math.clamp((pos.X-rx)/sw,0,1))
            end
            upd(inp.Position)
            local mc mc=UserInputService.InputChanged:Connect(function(ii)
                if ii.UserInputType==Enum.UserInputType.MouseMovement or ii.UserInputType==Enum.UserInputType.Touch then
                    upd(ii.Position)
                end
            end)
            UserInputService.InputEnded:Wait()
            if mc then mc:Disconnect() end
        end
    end)
    return f
end
local function cols(p,txt,list,cb)
    sect(p,txt)
    local h=Instance.new("Frame") h.Size=UDim2.new(1,0,0,36) h.BackgroundTransparency=1 h.Parent=p
    local l=Instance.new("UIListLayout") l.FillDirection=Enum.FillDirection.Horizontal l.Padding=UDim.new(0,6) l.Parent=h
    for _,c in pairs(list) do
        local b=Instance.new("TextButton") b.Size=UDim2.new(0,32,0,32)
        if c=="Rainbow" then b.BackgroundColor3=Color3.new(1,1,1) b.Text="🌈"
        else b.BackgroundColor3=c b.Text="" end
        b.Font=Enum.Font.GothamBold b.TextSize=14 b.AutoButtonColor=false b.Parent=h
        cnr(b,10) str(b,Color3.new(1,1,1),1,.7)
        b.MouseButton1Click:Connect(function()
            cb(c)
            tw(b,TweenInfo.new(.15,Enum.EasingStyle.Back),{Size=UDim2.new(0,37,0,37)}):Play()
            task.wait(.15)
            tw(b,TweenInfo.new(.15),{Size=UDim2.new(0,32,0,32)}):Play()
        end)
    end
end
local function cyc(p,txt,opts,cur,cb)
    local f=Instance.new("Frame")
    f.Size=UDim2.new(1,0,0,44) f.BackgroundColor3=Color3.fromRGB(28,32,48) f.Parent=p cnr(f,12) str(f,Color3.new(1,1,1),1,.88)
    local t=Instance.new("TextLabel")
    t.Position=UDim2.new(0,10,0,0) t.Size=UDim2.new(1,-20,0,20)
    t.BackgroundTransparency=1 t.Text=txt.." : "..cur
    t.Font=Enum.Font.GothamBold t.TextSize=11 t.TextXAlignment=0
    t.TextColor3=Color3.new(1,1,1) t.Parent=f
    local b2=Instance.new("TextButton")
    b2.Position=UDim2.new(0,10,0,22) b2.Size=UDim2.new(1,-20,0,16)
    b2.BackgroundTransparency=1 b2.Text="değiştir >"
    b2.Font=Enum.Font.Gotham b2.TextSize=11
    b2.TextColor3=Color3.fromRGB(130,200,255) b2.Parent=f
    local idx=table.find(opts,cur) or 1
    b2.MouseButton1Click:Connect(function()
        idx=idx%#opts+1 t.Text=txt.." : "..opts[idx] cb(opts[idx])
    end)
end

-- ══════════════════════════════════════════════════════
-- MENÜ İÇERİĞİ
-- ══════════════════════════════════════════════════════
-- ESP
sect(pESP,"ana")
tog(pESP,"esp açık",true,function(v) S.ESP.Enabled=v end)
tog(pESP,"rainbow",true,function(v) S.ESP.Rainbow=v end)
cols(pESP,"esp rengi",{"Rainbow",Color3.fromRGB(255,60,120),Color3.new(1,1,1),Color3.fromRGB(80,150,255),Color3.fromRGB(90,255,140),Color3.fromRGB(180,120,255),Color3.fromRGB(255,180,60)},
    function(c) if c=="Rainbow" then S.ESP.Rainbow=true else S.ESP.Rainbow=false S.ESP.Color=c end end)
sect(pESP,"parçalar")
tog(pESP,"box highlight",true,function(v) S.ESP.Box=v end)
tog(pESP,"isim",true,function(v) S.ESP.Name=v end)
tog(pESP,"mesafe",true,function(v) S.ESP.Distance=v end)
tog(pESP,"can barı",true,function(v) S.ESP.Health=v end)
sect(pESP,"tracer")
tog(pESP,"tracers açık",true,function(v) S.ESP.Tracers=v end)
cols(pESP,"tracer rengi",{Color3.new(1,1,1),Color3.fromRGB(255,60,120),Color3.fromRGB(80,150,255),Color3.fromRGB(90,255,140)},
    function(c) if c~="Rainbow" then S.ESP.TracerColor=c end end)
cyc(pESP,"çıkış",{"Bottom","Center","Top","Mouse"},"Bottom",function(v) S.ESP.TracerFrom=v end)
sld(pESP,"max mesafe",100,3000,800,function(v) S.ESP.MaxDist=v end)
sld(pESP,"rainbow hızı",1,10,2,function(v) S.ESP.RainbowSpeed=v end)
sld(pESP,"tracer kalınlık",1,5,2,function(v) S.ESP.TracerThick=v end)

-- HITBOX
sect(pHit,"hitbox")
tog(pHit,"hitbox açık",false,function(v) S.Hitbox.Enabled=v end)
tog(pHit,"hitbox göster",false,function(v) S.Hitbox.Show=v end)
cols(pHit,"hitbox rengi",{Color3.new(1,1,1),Color3.fromRGB(255,60,120),Color3.fromRGB(80,150,255),Color3.fromRGB(90,255,140)},
    function(c) if c~="Rainbow" then S.Hitbox.Color=c end end)
sld(pHit,"büyüklük",2,30,12,function(v) S.Hitbox.Size=v end)
sld(pHit,"şeffaflık x10",0,9,6,function(v) S.Hitbox.Trans=v/10 end)

-- AIM
sect(pAim,"aimbot")
tog(pAim,"aimbot açık",false,function(v) S.Aim.Enabled=v S.Aim._target=nil S.Aim._snapDone=false updFov() end)
tog(pAim,"silent aim",false,function(v) S.Aim.Silent=v end)
tog(pAim,"fov göster",true,function(v) S.Aim.ShowFov=v updFov() end)
tog(pAim,"takım kontrol",true,function(v) S.Aim.TeamCheck=v end)
tog(pAim,"duvar kontrol",true,function(v) S.Aim.WallCheck=v end)
sld(pAim,"fov",40,400,120,function(v) S.Aim.Fov=v updFov() end)
sld(pAim,"smooth (1=anlık)",1,30,8,function(v) S.Aim.Smooth=v end)
cyc(pAim,"hedef",{"Head","Torso","Random"},"Head",function(v) S.Aim.Part=v end)
sect(pAim,"mobil")
tog(pAim,"mobil lock",false,function(v) S.Aim.MobileLock=v end)

-- MODS
sect(pMods,"hareket")
tog(pMods,"speed açık",false,function(v) S.Mods.SpeedOn=v end)
sld(pMods,"speed",16,200,32,function(v) S.Mods.SpeedVal=v end)
sld(pMods,"jump power",50,200,50,function(v)
    S.Mods.JumpVal=v
    if player.Character then
        local hum=player.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.JumpPower=v end
    end
end)
tog(pMods,"inf jump",false,function(v) S.Mods.InfJump=v end)
tog(pMods,"fly",false,function(v) S.Mods.Fly=v end)
sld(pMods,"fly hızı",20,150,60,function(v) S.Mods.FlySpeed=v end)
sect(pMods,"dünya")
tog(pMods,"noclip",false,function(v) S.Mods.Noclip=v end)
tog(pMods,"fullbright",false,function(v)
    S.Mods.Fullbright=v
    if v then
        game.Lighting.Brightness=2
        game.Lighting.ClockTime=14
        game.Lighting.FogEnd=100000
    else
        game.Lighting.Brightness=1
        game.Lighting.FogEnd=1000
    end
end)

-- ══════════════════════════════════════════════════════
-- MENÜ SÜRÜKLEME
-- ══════════════════════════════════════════════════════
do
    local dragging, dragStart, startPos
    topBar.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
            dragging=true dragStart=inp.Position startPos=menu.Position
            inp.Changed:Connect(function()
                if inp.UserInputState==Enum.UserInputState.End then dragging=false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and (inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch) then
            local d=inp.Position-dragStart
            menu.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
        end
    end)
end

-- ══════════════════════════════════════════════════════
-- SIDE BAR (menüsüz mod) + MİNİ BUTON
-- ══════════════════════════════════════════════════════
-- ══════════════════════════════════════════════════════
-- SIDE PANEL — köşe frame (çarpı + ESP + HIT + ERDEM)
-- ══════════════════════════════════════════════════════
local sideWrap=Instance.new("Frame")
sideWrap.AnchorPoint=Vector2.new(1,0)
sideWrap.Position=UDim2.new(1,-10,0,72)   -- sağ üstten 72 px aşağı
sideWrap.Size=UDim2.new(0,66,0,10)          -- yükseklik UIListLayout ile büyür
sideWrap.BackgroundTransparency=1
sideWrap.Visible=false sideWrap.Parent=gui
local sideWrapList=Instance.new("UIListLayout")
sideWrapList.FillDirection=Enum.FillDirection.Vertical
sideWrapList.VerticalAlignment=Enum.VerticalAlignment.Top
sideWrapList.Padding=UDim.new(0,6)
sideWrapList.SortOrder=Enum.SortOrder.LayoutOrder
sideWrapList.Parent=sideWrap
sideWrapList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    sideWrap.Size=UDim2.new(0,66,0,sideWrapList.AbsoluteContentSize.Y)
end)

-- eski side değişkeni artık sideWrap içindeki bir alt frame
local side=Instance.new("Frame")
side.Size=UDim2.new(0,58,0,0)   -- yükseklik UIListLayout ile otomatik
side.BackgroundTransparency=1
side.LayoutOrder=2 side.Parent=sideWrap
local sideList=Instance.new("UIListLayout")
sideList.Padding=UDim.new(0,6)
sideList.SortOrder=Enum.SortOrder.LayoutOrder
sideList.Parent=side
sideList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    side.Size=UDim2.new(0,58,0,sideList.AbsoluteContentSize.Y)
end)

-- Çarpı butonu — butonların biraz üstünde (LayoutOrder=1 → en üstte)
local erdemOn=false
local mini
local menuOpen=false
local sideClose=Instance.new("TextButton")
sideClose.Size=UDim2.new(0,58,0,32)
sideClose.BackgroundColor3=Color3.fromRGB(255,70,70)
sideClose.BackgroundTransparency=.1
sideClose.Text="×" sideClose.Font=Enum.Font.GothamBold
sideClose.TextSize=18 sideClose.TextColor3=Color3.new(1,1,1)
sideClose.AutoButtonColor=false sideClose.LayoutOrder=1 sideClose.Parent=sideWrap
cnr(sideClose,14) str(sideClose,Color3.new(1,1,1),1,.8)
sideClose.MouseButton1Click:Connect(function()
    -- Tam kapatma: Erdem kombinasyonu dahil bütün özellikleri pasifleştir.
    espSideOn=false
    hbSideOn=false
    erdemOn=false
    S.ESP.Enabled=false
    S.Hitbox.Enabled=false
    S.Aim.Enabled=false
    S.Aim.Silent=false
    S.Aim.Holding=false
    S.Aim.MobileLock=false
    S.Aim._target=nil
    S.Aim._snapDone=false
    S.Mods.SpeedOn=false
    S.Mods.InfJump=false
    S.Mods.Fly=false
    S.Mods.Noclip=false
    S.Mods.Fullbright=false
    fovFrame.Visible=false

    tw(sideWrap,TweenInfo.new(.25),{Position=UDim2.new(1,80,0,72)}):Play()
    task.wait(.25)
    sideWrap.Visible=false
    menu.Visible=false
    menuOpen=false
    mini.Visible=false
end)

local function mkSideBtn(txt,on)
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(0,58,0,58)
    b.BackgroundColor3=on and Color3.fromRGB(90,200,120) or Color3.fromRGB(20,23,36)
    b.BackgroundTransparency=.08 b.Text=txt b.Font=Enum.Font.GothamBold
    b.TextSize=16 b.TextColor3=Color3.new(1,1,1) b.AutoButtonColor=false b.Parent=side
    cnr(b,18) str(b,Color3.new(1,1,1),1,.8)
    return b
end
local espSideBtn=mkSideBtn("ESP",true)
local hbSideBtn =mkSideBtn("HIT",false)
local espSideOn=true local hbSideOn=false
espSideBtn.MouseButton1Click:Connect(function()
    espSideOn=not espSideOn S.ESP.Enabled=espSideOn
    tw(espSideBtn,TweenInfo.new(.2),{BackgroundColor3=espSideOn and Color3.fromRGB(90,200,120) or Color3.fromRGB(20,23,36)}):Play()
end)
hbSideBtn.MouseButton1Click:Connect(function()
    hbSideOn=not hbSideOn S.Hitbox.Enabled=hbSideOn
    tw(hbSideBtn,TweenInfo.new(.2),{BackgroundColor3=hbSideOn and Color3.fromRGB(90,200,120) or Color3.fromRGB(20,23,36)}):Play()
end)

-- ERDEM butonu — pembe, en altta (LayoutOrder büyük)
local erdemBtn=Instance.new("TextButton")
erdemBtn.Size=UDim2.new(0,58,0,42)
erdemBtn.BackgroundColor3=Color3.fromRGB(255,20,147)   -- koyu pembe
erdemBtn.BackgroundTransparency=.05
erdemBtn.Text="ERDEM" erdemBtn.Font=Enum.Font.GothamBold
erdemBtn.TextSize=10 erdemBtn.TextColor3=Color3.new(1,1,1)
erdemBtn.AutoButtonColor=false erdemBtn.LayoutOrder=99 erdemBtn.Parent=side
cnr(erdemBtn,14) str(erdemBtn,Color3.fromRGB(255,100,180),1,.6)
-- basılıkta efekt
erdemBtn.MouseButton1Down:Connect(function()
    tw(erdemBtn,TweenInfo.new(.1),{BackgroundColor3=Color3.fromRGB(200,10,110)}):Play()
end)
erdemBtn.MouseButton1Up:Connect(function()
    tw(erdemBtn,TweenInfo.new(.15),{BackgroundColor3=Color3.fromRGB(255,20,147)}):Play()
end)
-- Erdem'e özel kısayol: yalnızca ESP + HITBOX; speed/aim/jump ayarlarına dokunmaz.
erdemBtn.MouseButton1Click:Connect(function()
    erdemOn=not erdemOn
    espSideOn=erdemOn  S.ESP.Enabled=erdemOn
    hbSideOn=erdemOn   S.Hitbox.Enabled=erdemOn
    tw(espSideBtn,TweenInfo.new(.2),{BackgroundColor3=erdemOn and Color3.fromRGB(255,20,147) or Color3.fromRGB(20,23,36)}):Play()
    tw(hbSideBtn, TweenInfo.new(.2),{BackgroundColor3=erdemOn and Color3.fromRGB(255,20,147) or Color3.fromRGB(20,23,36)}):Play()
    tw(erdemBtn,  TweenInfo.new(.2),{BackgroundColor3=erdemOn and Color3.fromRGB(255,20,147) or Color3.fromRGB(100,10,60)}):Play()
    local t=Instance.new("TextLabel")
    t.AnchorPoint=Vector2.new(.5,.5) t.Position=UDim2.new(.5,0,.5,0)
    t.Size=UDim2.new(1,0,1,0) t.BackgroundTransparency=1
    t.Text=erdemOn and "🎯 ON" or "OFF"
    t.Font=Enum.Font.GothamBold t.TextSize=11 t.TextColor3=Color3.new(1,1,1)
    t.ZIndex=10 t.Parent=erdemBtn
    tw(t,TweenInfo.new(.8),{TextTransparency=1}):Play()
    task.delay(.85,function() t:Destroy() end)
end)

-- mini buton — sağ altta, menülü modda görünür
mini=Instance.new("TextButton")
mini.AnchorPoint=Vector2.new(1,1) mini.Position=UDim2.new(1,-10,1,-10)
mini.Size=UDim2.new(0,52,0,52) mini.BackgroundColor3=Color3.fromRGB(20,23,36)
mini.BackgroundTransparency=.08 mini.Text="☁" mini.Font=Enum.Font.GothamBold
mini.TextSize=22 mini.TextColor3=Color3.new(1,1,1)
mini.Visible=false mini.AutoButtonColor=false mini.Parent=gui
cnr(mini,18) str(mini,Color3.new(1,1,1),1,.8)

-- ══════════════════════════════════════════════════════
-- MENÜ AÇ / KAPAT
-- ══════════════════════════════════════════════════════
local function openMenu()
    menu.Visible=true menuOpen=true mini.Visible=false
    menu.Position=UDim2.new(.5,0,.6,0) menu.Size=UDim2.new(0,0,0,0)
    tw(menu,TweenInfo.new(.55,Enum.EasingStyle.Back,Enum.EasingDirection.Out),
        {Size=UDim2.new(0,360,0,480),Position=UDim2.new(.5,0,.5,0)}):Play()
end
local function closeMenu()
    tw(menu,TweenInfo.new(.3,Enum.EasingStyle.Back,Enum.EasingDirection.In),
        {Size=UDim2.new(0,0,0,0),Position=UDim2.new(.5,0,.6,0)}):Play()
    task.wait(.3) menu.Visible=false menuOpen=false mini.Visible=true
end
closeBtn.MouseButton1Click:Connect(closeMenu)
xBtn.MouseButton1Click:Connect(closeMenu)
mini.MouseButton1Click:Connect(function()
    -- menülü mod için openMenu, menüsüz mod için sideWrap geri
    if sideWrap.Visible==false and not menuOpen then
        -- menüsüz panel kapalıysa aç
        sideWrap.Visible=true
        sideWrap.Position=UDim2.new(1,80,0,72)
        tw(sideWrap,TweenInfo.new(.4,Enum.EasingStyle.Back,Enum.EasingDirection.Out),
            {Position=UDim2.new(1,-10,0,72)}):Play()
        mini.Visible=false
    else
        openMenu()
    end
end)

local function killLoader()
    tw(loader,TweenInfo.new(.5),{BackgroundTransparency=1}):Play()
    tw(card,TweenInfo.new(.5,Enum.EasingStyle.Back,Enum.EasingDirection.In),{Size=UDim2.new(0,0,0,0)}):Play()
    task.wait(.5) loader:Destroy()
end

bMenu.MouseButton1Click:Connect(function()
    killLoader() openMenu()
end)

bNoMenu.MouseButton1Click:Connect(function()
    killLoader()
    -- Speed'e DOKUNMA — sadece köşe panel göster
    sideWrap.Visible=true
    sideWrap.Position=UDim2.new(1,80,0,72)
    tw(sideWrap,TweenInfo.new(.6,Enum.EasingStyle.Back,Enum.EasingDirection.Out),
        {Position=UDim2.new(1,-10,0,72)}):Play()
end)

-- ══════════════════════════════════════════════════════
-- INPUT
-- ══════════════════════════════════════════════════════
UserInputService.InputBegan:Connect(function(inp,gpe)
    if gpe then return end
    if inp.KeyCode==Enum.KeyCode.RightShift and not loader.Parent then
        if menuOpen then closeMenu() elseif mini.Visible then openMenu() end
    end
    if inp.UserInputType==Enum.UserInputType.MouseButton2 then
        S.Aim.Holding=true
        S.Aim._target=nil
        S.Aim._snapDone=false
    end
end)
UserInputService.InputEnded:Connect(function(inp)
    if inp.UserInputType==Enum.UserInputType.MouseButton2 then
        S.Aim.Holding=false
        S.Aim._target=nil
        S.Aim._snapDone=false
    end
end)
UserInputService.JumpRequest:Connect(function()
    if S.Mods.InfJump and player.Character then
        local hum=player.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- ══════════════════════════════════════════════════════
-- ESP MOTORU
-- ══════════════════════════════════════════════════════
local espStore={}
local function espColor()
    if S.ESP.Rainbow then return Color3.fromHSV(tick()*S.ESP.RainbowSpeed/10%1,.7,1)
    else return S.ESP.Color end
end
local function mkESP(plr)
    if plr==player then return end
    local h=Instance.new("Highlight")
    h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
    h.FillTransparency=.6 h.OutlineTransparency=0 h.Parent=overlay
    local bb=Instance.new("BillboardGui")
    bb.Size=UDim2.new(0,120,0,60) bb.StudsOffset=Vector3.new(0,3,0)
    bb.AlwaysOnTop=true bb.Parent=overlay
    local nm=Instance.new("TextLabel")
    nm.Size=UDim2.new(1,0,0,16) nm.BackgroundTransparency=1
    nm.Font=Enum.Font.GothamBold nm.TextSize=12 nm.TextStrokeTransparency=.4
    nm.TextColor3=Color3.new(1,1,1) nm.Parent=bb
    local ds=Instance.new("TextLabel")
    ds.Position=UDim2.new(0,0,0,16) ds.Size=UDim2.new(1,0,0,14)
    ds.BackgroundTransparency=1 ds.Font=Enum.Font.Gotham ds.TextSize=11
    ds.TextStrokeTransparency=.4 ds.TextColor3=Color3.fromRGB(200,210,230) ds.Parent=bb
    local hbg=Instance.new("Frame")
    hbg.Position=UDim2.new(.1,0,0,34) hbg.Size=UDim2.new(.8,0,0,6)
    hbg.BackgroundColor3=Color3.fromRGB(0,0,0) hbg.BackgroundTransparency=.4
    hbg.BorderSizePixel=0 hbg.Parent=bb cnr(hbg,100)
    local hpf=Instance.new("Frame")
    hpf.Size=UDim2.new(1,0,1,0) hpf.BackgroundColor3=Color3.fromRGB(90,255,140)
    hpf.BorderSizePixel=0 hpf.Parent=hbg cnr(hpf,100)
    local tr=Instance.new("Frame")
    tr.AnchorPoint=Vector2.new(.5,.5) tr.BackgroundColor3=Color3.new(1,1,1)
    tr.BorderSizePixel=0 tr.Visible=false tr.Parent=overlay cnr(tr,100)
    espStore[plr]={h=h,bb=bb,nm=nm,ds=ds,hbg=hbg,hpf=hpf,tr=tr}
end
for _,p in pairs(Players:GetPlayers()) do mkESP(p) end
Players.PlayerAdded:Connect(mkESP)
Players.PlayerRemoving:Connect(function(p)
    if espStore[p] then
        espStore[p].h:Destroy() espStore[p].bb:Destroy() espStore[p].tr:Destroy()
        espStore[p]=nil
    end
end)

-- ══════════════════════════════════════════════════════
-- AİMBOT — HEDEF BULMA
-- ══════════════════════════════════════════════════════
local function getAimPart(char)
    local n
    if S.Aim.Part=="Random" then n=(math.random(2)==1) and "Head" or "HumanoidRootPart"
    elseif S.Aim.Part=="Head" then n="Head"
    else n="HumanoidRootPart" end
    return char:FindFirstChild(n)
end

local function passWall(pt)
    local pr=RaycastParams.new()
    pr.FilterType=Enum.RaycastFilterType.Exclude
    pr.FilterDescendantsInstances={player.Character,Camera}
    local r=workspace:Raycast(Camera.CFrame.Position, pt.Position-Camera.CFrame.Position, pr)
    if r and r.Instance and not r.Instance:IsDescendantOf(pt.Parent) then return false end
    return true
end

local function findTarget()
    local mp=UserInputService:GetMouseLocation()
    local best,bestD,bestPt=nil,S.Aim.Fov,nil
    for _,plr in pairs(Players:GetPlayers()) do
        if plr==player then continue end
        if not plr.Character then continue end
        local hum=plr.Character:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health<=0 then continue end
        if S.Aim.TeamCheck and plr.Team==player.Team and player.Team~=nil then continue end
        local pt=getAimPart(plr.Character)
        if not pt then continue end
        local vp,onScreen=Camera:WorldToViewportPoint(pt.Position)
        if not onScreen then continue end
        local dist=math.sqrt((vp.X-mp.X)^2+(vp.Y-mp.Y)^2)
        if dist>=bestD then continue end
        if S.Aim.WallCheck and not passWall(pt) then continue end
        bestD=dist best=plr bestPt=pt
    end
    return best, bestPt
end

-- ══════════════════════════════════════════════════════
-- RENDER LOOP
-- ══════════════════════════════════════════════════════
RunService.RenderStepped:Connect(function(dt)
    local ec=espColor()
    updFov()

    -- ── ESP ──────────────────────────────────────────
    for plr,d in pairs(espStore) do
        local ch  = plr.Character
        local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
        local hum = ch and ch:FindFirstChildOfClass("Humanoid")
        local show = S.ESP.Enabled and hrp and hum and hum.Health>0
        if show and (hrp.Position-Camera.CFrame.Position).Magnitude>S.ESP.MaxDist then
            show=false
        end
        if not show then
            d.h.Enabled=false d.bb.Enabled=false d.tr.Visible=false
        else
            d.h.Adornee=ch d.h.Enabled=S.ESP.Box d.h.FillColor=ec d.h.OutlineColor=ec
            d.bb.Adornee=hrp d.bb.Enabled=true
            d.nm.Visible=S.ESP.Name d.nm.Text=plr.Name d.nm.TextColor3=ec
            local dist=(hrp.Position-Camera.CFrame.Position).Magnitude
            d.ds.Visible=S.ESP.Distance d.ds.Text="["..math.floor(dist).."m]"
            d.hbg.Visible=S.ESP.Health
            if hum then
                local r=math.clamp(hum.Health/hum.MaxHealth,0,1)
                d.hpf.Size=UDim2.new(r,0,1,0)
                d.hpf.BackgroundColor3=Color3.fromHSV(r*.33,.8,1)
            end
            if S.ESP.Tracers then
                local vp2,on2=Camera:WorldToViewportPoint(hrp.Position)
                if on2 then
                    local vs=Camera.ViewportSize local ox,oy
                    if S.ESP.TracerFrom=="Bottom" then ox,oy=vs.X/2,vs.Y-40
                    elseif S.ESP.TracerFrom=="Top" then ox,oy=vs.X/2,40
                    elseif S.ESP.TracerFrom=="Center" then ox,oy=vs.X/2,vs.Y/2
                    else local mm=UserInputService:GetMouseLocation() ox,oy=mm.X,mm.Y end
                    local dx,dy=vp2.X-ox,vp2.Y-oy
                    local len=math.sqrt(dx*dx+dy*dy)
                    d.tr.Visible=true d.tr.BackgroundColor3=S.ESP.TracerColor
                    d.tr.Size=UDim2.new(0,len,0,S.ESP.TracerThick)
                    d.tr.Position=UDim2.new(0,(ox+vp2.X)/2,0,(oy+vp2.Y)/2)
                    d.tr.Rotation=math.deg(math.atan2(dy,dx))
                else d.tr.Visible=false end
            else d.tr.Visible=false end
        end

        -- Hitbox
        if hrp then
            if S.Hitbox.Enabled then
                local want=Vector3.new(S.Hitbox.Size,S.Hitbox.Size,S.Hitbox.Size)
                if hrp.Size~=want then
                    hrp.Size=hrp.Size:Lerp(want,.25)
                    if (hrp.Size-want).Magnitude<.5 then hrp.Size=want end
                end
                hrp.Transparency=S.Hitbox.Show and S.Hitbox.Trans or 1
                hrp.Color=S.Hitbox.Color
                hrp.Material=Enum.Material.SmoothPlastic
                hrp.CanCollide=false
            else
                if hrp.Size~=Vector3.new(2,2,1) then
                    hrp.Size=Vector3.new(2,2,1) hrp.Transparency=1
                end
            end
        end
    end

    -- ── MODS ─────────────────────────────────────────
    if player.Character then
        local hum=player.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            -- Speed kapalıyken WalkSpeed'e kesinlikle dokunma.
            -- Böylece script kendi kendine 16'ya zorlamaz.
            if S.Mods.SpeedOn and hum.WalkSpeed ~= S.Mods.SpeedVal then
                hum.WalkSpeed = S.Mods.SpeedVal
            end
            -- Noclip
            if S.Mods.Noclip then
                for _,v in pairs(player.Character:GetDescendants()) do
                    if v:IsA("BasePart") then v.CanCollide=false end
                end
            end
        end
        -- Fly
        if S.Mods.Fly then
            local hrp2=player.Character:FindFirstChild("HumanoidRootPart")
            local hum2=player.Character:FindFirstChildOfClass("Humanoid")
            if hrp2 and hum2 then
                local mv=hum2.MoveDirection
                hrp2.Velocity=Vector3.new(mv.X*S.Mods.FlySpeed,0,mv.Z*S.Mods.FlySpeed)
                hrp2.AssemblyLinearVelocity=Vector3.new(mv.X*S.Mods.FlySpeed,5,mv.Z*S.Mods.FlySpeed)
            end
        end
    end

    -- ── AİMBOT ───────────────────────────────────────
    if not S.Aim.Enabled then
        fovStroke.Color=Color3.new(1,1,1) return
    end
    if not (S.Aim.Holding or S.Aim.MobileLock) then
        S.Aim._target=nil S.Aim._snapDone=false
        fovStroke.Color=Color3.new(1,1,1) return
    end

    local _,bestPt=findTarget()
    if not bestPt then
        S.Aim._target=nil S.Aim._snapDone=false
        fovStroke.Color=Color3.new(1,1,1) return
    end

    if S.Aim._target~=bestPt then
        S.Aim._target=bestPt S.Aim._snapDone=false
    end

    fovStroke.Color=Color3.fromRGB(255,60,120)

    local goalCF=CFrame.new(Camera.CFrame.Position, bestPt.Position)

    local alpha
    if not S.Aim._snapDone then
        alpha=1 S.Aim._snapDone=true
    else
        local base=math.clamp(1/S.Aim.Smooth, 0.03, 1)
        alpha=1-(1-base)^(dt*60)
    end

    if S.Aim.Silent then
        -- Silent: minimal kamera hareketi (%12) → görünmez ama hit register
        Camera.CFrame=Camera.CFrame:Lerp(goalCF, alpha*0.12)
    else
        Camera.CFrame=Camera.CFrame:Lerp(goalCF, alpha)
    end
end)
