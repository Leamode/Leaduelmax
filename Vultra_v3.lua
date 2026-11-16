-- ============================================================
-- Vultra - ULTIMATE EDITION
-- bypass++ | INSTANT aimbot | AC-proof ESP | unkillable car fly
-- ============================================================

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local Workspace        = game:GetService("Workspace")
local Lighting         = game:GetService("Lighting")
local TweenService     = game:GetService("TweenService")
local StarterGui       = game:GetService("StarterGui")
local LocalPlayer      = Players.LocalPlayer
local Mouse            = LocalPlayer:GetMouse()

-- ===================== CONFIG =====================
local CFG = {
    flySpeed      = 120,
    walkBoost     = 80,
    jumpBoost     = 120,
    carFlySpeed   = 280,
    carFlyBoost   = 450,
    carFlyKey     = Enum.KeyCode.F6,

    aimKey        = Enum.KeyCode.Q,
    aimFovPx      = 400,
    aimMaxDist    = 1e9,
    aimBone       = "Head",
    aimPredict    = 0.15,
    aimStepPx     = 35,

    mapSize       = 240,
    mapRange      = 600,
    mapShowNames  = true,
    ownerHz       = 0.1,
    carSnap       = 0.05,

    lootEnabled   = true,
    lootRange     = 500,
    lootMaxItems  = 80,
    lootBodyGlow  = true,
}

-- ===================== STATE =====================
local ON = {
    Speed=false, Fly=false, Noclip=false, InfJump=false,
    HighJump=false, NoFall=false, MobPush=false,
    ESP=false, Tracers=false, Fullbright=false, Minimap=true, ShowFov=true,
    Aimbot=false, SilentAim=false,
    AntiTP=true, Ownership=true, God=false, CarFly=false, Bypass=false,
    LootTracker=true,
}

local WHITELIST = {}

local S = {
    flyBV=nil, flyBG=nil, flyAtt=nil, flyConn=nil,
    carConn=nil, carBV=nil, carBG=nil, carAtt=nil, carModel=nil, carCF=nil,
    noclipConn=nil, ownerConn=nil, antiConn=nil, godConn=nil,
    espHL={}, tracerBeams={}, espFolder=nil, tracerFolder=nil, originAtt=nil,
    aimTarget=nil, lastCF=nil, lit={},
    gui=nil, fov=nil, map=nil, mapDots=nil, mapArrow=nil, status=nil,
    ownerT=0,
    lootLog={}, lootBodyHL={}, lootPanel=nil, lootConn=nil,
    resetConn=nil,
}

local COL_E  = Color3.fromRGB(255, 60,  60)
local COL_F  = Color3.fromRGB(70,  255, 110)
local COL_ME = Color3.fromRGB(90,  170, 255)
local ACCENT = Color3.fromRGB(255, 145, 45)
local ACCENT2= Color3.fromRGB(255, 80, 200)

local function char()  return LocalPlayer.Character end
local function hrp()   local c=char() return c and c:FindFirstChild("HumanoidRootPart") end
local function hum()   local c=char() return c and c:FindFirstChildOfClass("Humanoid") end
local function wl(p)   return WHITELIST[p.UserId] == true end
local function low(s)  return string.lower(tostring(s or "")) end

-- ===================== BYPASS =====================
local BLOCK = {
    "kick","ban","detect","anticheat","watchdog","antitamper","antiteleport",
    "teleportback","positioncheck","velocitycheck","speedcheck","flycheck",
    "noclipcheck","cheatdetect","securitycheck","clientcheck","integrity",
    "violation","punish","report","monitor","exploit","sandbox","cheatlog",
    "hacklog","hackcheck","hackdetect","abusereport","playerlog","movement_log",
    "abusecheck","speedlog","flagged","admincheck","adminlog","bancheck",
}
local ALLOW = {
    "move","stance","walk","jump","input","character","humanoid","replicate",
    "physics","network","cframe","position","velocity","vehicle","seat","drive",
    "car","chassis","engine","wheel","animation","emote","tool","equip",
}

local function blockRemote(name)
    local n = low(name)
    for _, a in ipairs(ALLOW) do if string.find(n, a, 1, true) then return false end end
    for _, b in ipairs(BLOCK) do if string.find(n, b, 1, true) then return true end end
    return false
end

local getBestTarget
local _hook = false
local function installHook()
    if _hook then return end
    _hook = true
    pcall(function()
        local mt = getrawmetatable and getrawmetatable(game)
        if not mt then return end
        local old = mt.__namecall
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            if checkcaller and checkcaller() then return old(self, ...) end
            local method = getnamecallmethod and getnamecallmethod() or ""
            if method == "Kick" and self == LocalPlayer then return end
            if method == "BreakJoints" and self:IsA("Humanoid") then return end
            if method == "FireServer" or method == "InvokeServer"
            or method == "Fire"       or method == "FireAllClients"
            or method == "FireClient" then
                local n = (self and rawget(self,"Name")) or (pcall(function() return self.Name end) and self.Name) or ""
                if blockRemote(n) then
                    if method == "InvokeServer" then return nil end
                    return
                end
                if ON.SilentAim and getBestTarget then
                    local ln = low(n)
                    if string.find(ln,"gun")    or string.find(ln,"fire")
                    or string.find(ln,"shoot")  or string.find(ln,"hit")
                    or string.find(ln,"damage") or string.find(ln,"ray")
                    or string.find(ln,"bullet") or string.find(ln,"weapon")
                    or string.find(ln,"cast")   or string.find(ln,"proj")
                    or string.find(ln,"attack") or string.find(ln,"shot") then
                        local t = getBestTarget()
                        if t then
                            local aimPoint = t.Position
                            if t.Name == "Head" then
                                aimPoint = aimPoint + Vector3.new(0, 0.1, 0)
                            end
                            if CFG.aimPredict > 0 and t.Parent then
                                local tRoot = t.Parent:FindFirstChild("HumanoidRootPart") or t
                                local ok, vel = pcall(function() return tRoot.AssemblyLinearVelocity end)
                                if ok and vel then
                                    aimPoint = aimPoint + vel * CFG.aimPredict
                                end
                            end
                            local args = {...}
                            local r = hrp()
                            local origin = r and r.Position or aimPoint
                            for i,v in ipairs(args) do
                                if typeof(v)=="Vector3" then
                                    local mag = v.Magnitude>0.1 and v.Magnitude or 120
                                    args[i] = (aimPoint-origin).Unit * mag
                                elseif typeof(v)=="CFrame" then
                                    args[i] = CFrame.new(v.Position, aimPoint)
                                end
                            end
                            return old(self, table.unpack(args))
                        end
                    end
                end
            end
            if method == "InvokeServer" then
                local n = (self and rawget(self,"Name")) or ""
                if blockRemote(n) then return nil end
            end
            return old(self, ...)
        end)
        setreadonly(mt, true)
    end)
end

local function stripConns()
    if not getconnections then return end
    pcall(function()
        local h = hum()
        if not h then return end
        for _, sig in ipairs({
            h.HealthChanged, h.Died, h.StateChanged,
            h:GetPropertyChangedSignal("WalkSpeed"),
            h:GetPropertyChangedSignal("JumpPower"),
        }) do
            for _, c in ipairs(getconnections(sig)) do
                pcall(function()
                    if c.Disable then c:Disable() elseif c.Disconnect then c:Disconnect() end
                end)
            end
        end
    end)
end

local function claim(root)
    if not root then return end
    for _, p in ipairs(root:GetDescendants()) do
        if p:IsA("BasePart") then pcall(function() p:SetNetworkOwner(LocalPlayer) end) end
    end
    if root:IsA("BasePart") then pcall(function() root:SetNetworkOwner(LocalPlayer) end) end
end

local function startBypass()
    installHook()
    stripConns()
    claim(char())
    ON.Bypass = true
    ON.Ownership = true
    ON.AntiTP = true
    if not S.ownerConn then
        S.ownerConn = RunService.Heartbeat:Connect(function()
            if not ON.Ownership then return end
            local now = os.clock()
            if now - S.ownerT < CFG.ownerHz then return end
            S.ownerT = now
            claim(char())
            if S.carModel then claim(S.carModel) end
        end)
    end
    if not S.antiConn then
        S.antiConn = RunService.Heartbeat:Connect(function(dt)
            if not ON.AntiTP then return end
            local r = hrp()
            if not r then return end
            if ON.Fly or ON.CarFly then
                S.lastCF = r.CFrame
            elseif S.lastCF then
                -- Lag spikes and higher WalkSpeed can cause large legitimate
                -- per-frame movement; scale the check to elapsed time/speed.
                local h = hum()
                local walkSpeed = h and h.WalkSpeed or 16
                local allowedDistance = math.max(16, walkSpeed * math.max(dt or 0, 1/60) * 3 + 8)
                if (r.Position - S.lastCF.Position).Magnitude > allowedDistance then
                    r.CFrame = S.lastCF
                    r.AssemblyLinearVelocity = Vector3.zero
                else
                    S.lastCF = r.CFrame
                end
            else
                S.lastCF = r.CFrame
            end
        end)
    end
end

local function startGod()
    if S.godConn then S.godConn:Disconnect() end
    local h = hum()
    if not h then return end
    pcall(function()
        h.BreakJointsOnDeath = false
        h:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
    end)
    S.godConn = h.HealthChanged:Connect(function(hp)
        if ON.God and hp < h.MaxHealth then
            pcall(function()
                h.Health = h.MaxHealth
                h:ChangeState(Enum.HumanoidStateType.Running)
            end)
        end
    end)
end

-- ===================== ANTI-RESET =====================
local function enableAntiReset()
    local h = hum()
    if not h then return end
    pcall(function()
        h.BreakJointsOnDeath = false
        h:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
    end)
    if S.resetConn then S.resetConn:Disconnect() end
    S.resetConn = h.HealthChanged:Connect(function(hp)
        if hp <= 0 then
            pcall(function()
                h.Health = h.MaxHealth
                h:ChangeState(Enum.HumanoidStateType.Running)
            end)
        end
    end)
end

LocalPlayer.CharacterAdded:Connect(function(c)
    task.wait(0.3)
    enableAntiReset()
    if ON.God then startGod() end
end)

-- ===================== MOVEMENT =====================
local function applySpeed()
    local h = hum()
    if not h then return end
    h.WalkSpeed = ON.Speed and CFG.walkBoost or 16
    if ON.HighJump then
        h.JumpPower = CFG.jumpBoost
        pcall(function() h.JumpHeight = 24 end)
    else
        h.JumpPower = 50
    end
end

RunService.Stepped:Connect(function()
    if ON.Speed then
        local h = hum()
        if h then h.WalkSpeed = CFG.walkBoost end
    end
end)

local function flyStop()
    if S.flyConn then S.flyConn:Disconnect() S.flyConn=nil end
    pcall(function() if S.flyBV then S.flyBV:Destroy() end end)
    pcall(function() if S.flyBG then S.flyBG:Destroy() end end)
    pcall(function() if S.flyAtt then S.flyAtt:Destroy() end end)
    S.flyBV,S.flyBG,S.flyAtt=nil,nil,nil
    local h=hum(); if h and not ON.Fly then pcall(function() h.PlatformStand=false end) end
end

local function flyStart()
    if ON.CarFly or not ON.Fly then flyStop() return end
    local r,h = hrp(),hum()
    if not r or not h then return end
    pcall(function() h.PlatformStand=true end)
    if not S.flyAtt or S.flyAtt.Parent~=r then
        flyStop()
        local att=Instance.new("Attachment"); att.Name="LeaFlyAtt"; att.Parent=r; S.flyAtt=att
        local lv=Instance.new("LinearVelocity"); lv.Name="LeaFlyLV"; lv.Attachment0=att
        lv.MaxForce=1e9; lv.RelativeTo=Enum.ActuatorRelativeTo.World; lv.Parent=r; S.flyBV=lv
        local ao=Instance.new("AlignOrientation"); ao.Name="LeaFlyAO"; ao.Attachment0=att
        ao.Mode=Enum.OrientationAlignmentMode.OneAttachment; ao.MaxTorque=1e9; ao.Responsiveness=80; ao.Parent=r; S.flyBG=ao
    end
    if S.flyConn then return end
    S.flyConn = RunService.Heartbeat:Connect(function()
        if not ON.Fly or ON.CarFly then flyStop() return end
        local rr=hrp(); if not rr or not S.flyBV then return end
        local cam=Workspace.CurrentCamera; if not cam then return end
        local uis=UserInputService
        local v=Vector3.zero
        local f,rt=cam.CFrame.LookVector,cam.CFrame.RightVector
        if uis:IsKeyDown(Enum.KeyCode.W) then v+=f end
        if uis:IsKeyDown(Enum.KeyCode.S) then v-=f end
        if uis:IsKeyDown(Enum.KeyCode.A) then v-=rt end
        if uis:IsKeyDown(Enum.KeyCode.D) then v+=rt end
        if uis:IsKeyDown(Enum.KeyCode.Space) then v+=Vector3.yAxis end
        if uis:IsKeyDown(Enum.KeyCode.LeftShift) then v-=Vector3.yAxis end
        S.flyBV.VectorVelocity = v.Magnitude>0 and v.Unit*CFG.flySpeed or Vector3.zero
        if S.flyBG then S.flyBG.CFrame=cam.CFrame end
        S.lastCF = rr.CFrame
    end)
end

local function setNoclip(on)
    if S.noclipConn then S.noclipConn:Disconnect() S.noclipConn=nil end
    if not on then return end
    S.noclipConn = RunService.Stepped:Connect(function()
        local c=char(); if not c then return end
        for _,p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide=false end
        end
    end)
end

UserInputService.JumpRequest:Connect(function()
    if ON.InfJump then local h=hum(); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end end
end)

-- ===================== CAR FLY v3 - NEVER SNAP BACK =====================
local function getVehicle()
    local h=hum(); if not h then return nil end
    local seat=h.SeatPart
    if seat and (seat:IsA("VehicleSeat") or seat:IsA("Seat")) then
        local m=seat:FindFirstAncestorOfClass("Model")
        return seat,m,(m and m.PrimaryPart) or seat
    end
    for _,o in ipairs(Workspace:GetDescendants()) do
        if (o:IsA("VehicleSeat") or o:IsA("Seat")) and o.Occupant==h then
            local m=o:FindFirstAncestorOfClass("Model")
            return o,m,(m and m.PrimaryPart) or o
        end
    end
end

local function carClean()
    pcall(function() if S.carBV then S.carBV:Destroy() end end)
    pcall(function() if S.carBG then S.carBG:Destroy() end end)
    pcall(function() if S.carAtt then S.carAtt:Destroy() end end)
    S.carBV,S.carBG,S.carAtt=nil,nil,nil
end

local function carNoclip(model, primary)
    local function strip(p)
        if p:IsA("BasePart") then
            p.CanCollide=false; p.CanTouch=false
            pcall(function() p.CanQuery=false end)
        end
    end
    if model then for _,p in ipairs(model:GetDescendants()) do strip(p) end
    elseif primary then strip(primary) end
    local c=char(); if c then for _,p in ipairs(c:GetDescendants()) do strip(p) end end
end

local function carAttach(primary)
    if not primary then return end
    if S.carAtt and S.carAtt.Parent~=primary then carClean() end
    if S.carAtt and S.carAtt.Parent==primary then return end
    local att=Instance.new("Attachment"); att.Name="LeaCarAtt"; att.Parent=primary; S.carAtt=att
    local lv=Instance.new("LinearVelocity"); lv.Name="LeaCarLV"; lv.Attachment0=att
    lv.MaxForce=math.huge; lv.RelativeTo=Enum.ActuatorRelativeTo.World; lv.Parent=primary; S.carBV=lv
    local ao=Instance.new("AlignOrientation"); ao.Name="LeaCarAO"; ao.Attachment0=att
    ao.Mode=Enum.OrientationAlignmentMode.OneAttachment; ao.MaxTorque=math.huge; ao.Responsiveness=200; ao.Parent=primary; S.carBG=ao
end

local function carStop()
    if S.carConn then S.carConn:Disconnect() S.carConn=nil end
    carClean(); S.carModel=nil; S.carCF=nil; ON.CarFly=false
end

local function carStart()
    if not ON.Bypass then startBypass() end
    ON.CarFly=true
    enableAntiReset()
    if S.carConn then return end
    S.carConn = RunService.Heartbeat:Connect(function()
        if not ON.CarFly then carStop() return end
        local seat,model,primary = getVehicle()
        if not seat or not primary then
            if S.carBV then carClean(); S.carModel=nil; S.carCF=nil end
            return
        end
        local h=hum()
        if not h then return end

        pcall(function()
            h.BreakJointsOnDeath = false
            if h.Health <= 0 then
                h.Health = h.MaxHealth
                h:ChangeState(Enum.HumanoidStateType.Running)
            end
        end)

        if seat:IsA("VehicleSeat") and seat.Occupant~=h then pcall(function() seat:Sit(h) end) end
        if S.carModel~=model then
            S.carModel=model; S.carCF=nil; carClean()
            claim(model or primary); carNoclip(model,primary); carAttach(primary)
        end
        carNoclip(model,primary)
        claim(model or primary)
        if seat:IsA("VehicleSeat") then
            pcall(function() seat.Torque=0; seat.TurnSpeed=0; seat.MaxSpeed=0; seat.Throttle=0; seat.Steer=0 end)
        end
        if not S.carBV or S.carBV.Parent~=primary then carAttach(primary) end
        if not S.carBV then return end
        pcall(function() primary.AssemblyAngularVelocity=Vector3.zero end)

        local cam=Workspace.CurrentCamera
        local uis=UserInputService

        local look, rght
        if cam then
            look = cam.CFrame.LookVector
            rght = cam.CFrame.RightVector
        else
            look = primary.CFrame.LookVector
            rght = primary.CFrame.RightVector
        end

        local fwd=Vector3.new(look.X,0,look.Z)
        fwd=fwd.Magnitude>0.05 and fwd.Unit or Vector3.new(0,0,-1)
        local lat=Vector3.new(rght.X,0,rght.Z)
        lat=lat.Magnitude>0.05 and lat.Unit or Vector3.new(1,0,0)

        local v=Vector3.zero
        if uis:IsKeyDown(Enum.KeyCode.W) then v=v+fwd end
        if uis:IsKeyDown(Enum.KeyCode.S) then v=v-fwd end
        if uis:IsKeyDown(Enum.KeyCode.A) then v=v-lat end
        if uis:IsKeyDown(Enum.KeyCode.D) then v=v+lat end
        if uis:IsKeyDown(Enum.KeyCode.Space) then v=v+Vector3.yAxis end
        if uis:IsKeyDown(Enum.KeyCode.LeftControl) then v=v-Vector3.yAxis end

        local spd=uis:IsKeyDown(Enum.KeyCode.LeftShift) and CFG.carFlyBoost or CFG.carFlySpeed

        if v.Magnitude>0.05 then
            S.carBV.VectorVelocity=v.Unit*spd
            if S.carBG then S.carBG.CFrame=CFrame.lookAt(primary.Position, primary.Position+v.Unit) end
        else
            S.carBV.VectorVelocity=Vector3.zero
            if S.carBG then S.carBG.CFrame=CFrame.lookAt(primary.Position, primary.Position+fwd) end
        end

        -- NEVER SNAP BACK
        if not S.carCF then
            S.carCF = primary.CFrame
        else
            local currentPos = primary.Position
            local savedPos = S.carCF.Position
            local dist = (currentPos - savedPos).Magnitude
            local vel = primary.AssemblyLinearVelocity
            local expectedMove = vel.Magnitude * 0.016

            if dist > math.max(expectedMove * 3, 2) and vel.Magnitude < 20 then
                primary.CFrame = S.carCF
                primary.AssemblyLinearVelocity = Vector3.zero
                primary.AssemblyAngularVelocity = Vector3.zero
                claim(model or primary)
            else
                S.carCF = primary.CFrame
            end
        end

        local r=hrp()
        if r then
            local charDist = (r.Position-primary.Position).Magnitude
            if charDist > 6 then
                pcall(function()
                    r.CFrame=primary.CFrame*CFrame.new(0,2.5,0)
                    r.AssemblyLinearVelocity=Vector3.zero
                end)
            end
        end
    end)
end

-- ===================== AIMBOT - INSTANT LOCK =====================
getBestTarget = function()
    local cam = Workspace.CurrentCamera
    if not cam then return nil end
    local vp = cam.ViewportSize
    local cx, cy = vp.X*0.5, vp.Y*0.5
    local best, bestPx = nil, CFG.aimFovPx
    local myPos = (hrp() and hrp().Position) or cam.CFrame.Position

    if S.aimTarget and S.aimTarget.Parent then
        local plr = Players:GetPlayerFromCharacter(S.aimTarget.Parent)
        if plr and not wl(plr) then
            local h = S.aimTarget.Parent:FindFirstChildOfClass("Humanoid")
            if h and h.Health>0 then
                local sp, on = cam:WorldToViewportPoint(S.aimTarget.Position)
                if on and sp.Z>0 then
                    local px = (Vector2.new(sp.X,sp.Y)-Vector2.new(cx,cy)).Magnitude
                    if px < CFG.aimFovPx*2 then return S.aimTarget end
                end
            end
        end
        S.aimTarget = nil
    end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr~=LocalPlayer and plr.Character and not wl(plr) then
            local h = plr.Character:FindFirstChildOfClass("Humanoid")
            local bone = plr.Character:FindFirstChild(CFG.aimBone)
                      or plr.Character:FindFirstChild("HumanoidRootPart")
            if h and bone and h.Health>0 then
                if (bone.Position-myPos).Magnitude <= CFG.aimMaxDist then
                    local sp, on = cam:WorldToViewportPoint(bone.Position)
                    if on and sp.Z>0 then
                        local px = (Vector2.new(sp.X,sp.Y)-Vector2.new(cx,cy)).Magnitude
                        if px < bestPx then
                            bestPx = px
                            best = bone
                        end
                    end
                end
            end
        end
    end
    S.aimTarget = best
    return best
end

RunService.RenderStepped:Connect(function()
    if not ON.Aimbot then S.aimTarget=nil return end
    if not UserInputService:IsKeyDown(CFG.aimKey) then return end
    local cam = Workspace.CurrentCamera
    if not cam then return end
    local target = getBestTarget()
    if not target then return end

    local aim = target.Position
    if target.Name=="Head" then aim = aim + Vector3.new(0,0.1,0) end
    if CFG.aimPredict>0 and target.Parent then
        local root = target.Parent:FindFirstChild("HumanoidRootPart") or target
        local ok, vel = pcall(function() return root.AssemblyLinearVelocity end)
        if ok and vel then
            aim = aim + vel * CFG.aimPredict
        end
    end

    -- INSTANT SNAP
    cam.CFrame = CFrame.new(cam.CFrame.Position, aim)
end)

-- ===================== ESP - AC PROOF =====================
local function makeInfoBB(plr)
    if not plr.Character then return end
    local root = plr.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local friend = wl(plr)
    local col = friend and COL_F or COL_E

    local old = root:FindFirstChild("LeaBB")
    if old then old:Destroy() end

    local bb = Instance.new("BillboardGui")
    bb.Name = "LeaBB"
    bb.Size = UDim2.fromOffset(90, 40)
    bb.StudsOffset = Vector3.new(0, 3.5, 0)
    bb.AlwaysOnTop = true
    bb.ResetOnSpawn = false
    bb.Parent = root

    local nameLbl = Instance.new("TextLabel", bb)
    nameLbl.Size = UDim2.new(1,0,0.5,0)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = plr.Name
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 12
    nameLbl.TextColor3 = col
    nameLbl.TextStrokeTransparency = 0.2
    nameLbl.TextXAlignment = Enum.TextXAlignment.Center

    local distLbl = Instance.new("TextLabel", bb)
    distLbl.Name = "Dist"
    distLbl.Size = UDim2.new(1,0,0.28,0)
    distLbl.Position = UDim2.fromScale(0,0.5)
    distLbl.BackgroundTransparency = 1
    distLbl.Text = "? m"
    distLbl.Font = Enum.Font.Gotham
    distLbl.TextSize = 10
    distLbl.TextColor3 = Color3.fromRGB(220,220,220)
    distLbl.TextStrokeTransparency = 0.2
    distLbl.TextXAlignment = Enum.TextXAlignment.Center

    local hpLbl = Instance.new("TextLabel", bb)
    hpLbl.Name = "HP"
    hpLbl.Size = UDim2.new(1,0,0.22,0)
    hpLbl.Position = UDim2.fromScale(0,0.78)
    hpLbl.BackgroundTransparency = 1
    hpLbl.Text = "100 HP"
    hpLbl.Font = Enum.Font.GothamBold
    hpLbl.TextSize = 9
    hpLbl.TextColor3 = Color3.fromRGB(100,255,100)
    hpLbl.TextStrokeTransparency = 0.2
    hpLbl.TextXAlignment = Enum.TextXAlignment.Center
end

local function makeHL(plr)
    if not plr.Character then return end
    local old = S.espHL[plr]
    if old and old.Parent then old:Destroy() end
    S.espHL[plr] = nil
    local friend = wl(plr)
    local col = friend and COL_F or COL_E
    local hl = Instance.new("Highlight")
    hl.Name = "LeaHL"
    hl.FillColor = col
    hl.OutlineColor = col
    hl.FillTransparency = 0.45
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    local ok = pcall(function()
        hl.Adornee = plr.Character
        hl.Parent = game:GetService("CoreGui")
    end)
    if not ok or not hl.Parent then
        hl.Adornee = nil
        hl.Parent = plr.Character
    end
    S.espHL[plr] = hl
    if ON.ESP then makeInfoBB(plr) end
end

local function makeTracer(plr)
    local my = hrp()
    if not my or not plr.Character then return end
    if not S.tracerFolder or not S.tracerFolder.Parent then
        local tf = Instance.new("Folder"); tf.Name="LeaTr"; tf.Parent=Workspace; S.tracerFolder=tf
    end
    if not S.originAtt or S.originAtt.Parent~=my then
        if S.originAtt then pcall(function() S.originAtt:Destroy() end) end
        local oa = Instance.new("Attachment"); oa.Name="LeaTO"; oa.Parent=my; S.originAtt=oa
    end
    local old = S.tracerBeams[plr]
    if old and old.Parent then old:Destroy() end
    S.tracerBeams[plr] = nil
    local bone = plr.Character:FindFirstChild("Head") or plr.Character:FindFirstChild("HumanoidRootPart")
    if not bone then return end
    local a1 = bone:FindFirstChild("LeaTE") or Instance.new("Attachment")
    a1.Name="LeaTE"; a1.Parent=bone
    local friend = wl(plr)
    local col = friend and COL_F or COL_E
    local beam = Instance.new("Beam")
    beam.Attachment0 = S.originAtt; beam.Attachment1 = a1
    beam.Width0=0.12; beam.Width1=0.12; beam.FaceCamera=true
    beam.Color=ColorSequence.new(col)
    beam.Transparency=NumberSequence.new(0.15)
    beam.LightEmission=1; beam.Parent=S.tracerFolder
    S.tracerBeams[plr] = beam
end

local function clearESP()
    for plr, hl in pairs(S.espHL) do
        pcall(function() if hl and hl.Parent then hl:Destroy() end end)
    end
    S.espHL = {}
    for plr, beam in pairs(S.tracerBeams) do
        pcall(function() if beam and beam.Parent then beam:Destroy() end end)
    end
    S.tracerBeams = {}
    if S.tracerFolder then pcall(function() S.tracerFolder:Destroy() end) end
    S.tracerFolder = nil
    if S.originAtt then pcall(function() S.originAtt:Destroy() end) end
    S.originAtt = nil
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character then
            local root = plr.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local bb = root:FindFirstChild("LeaBB")
                if bb then pcall(function() bb:Destroy() end) end
            end
        end
    end
end

local function doESP()
    if not (ON.ESP or ON.Tracers) then clearESP() return end
    local myPos = hrp() and hrp().Position
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local h = plr.Character:FindFirstChildOfClass("Humanoid")
            local root = plr.Character:FindFirstChild("HumanoidRootPart")
            -- Show if root exists - catches hidden/invisible players too
            if root then
                if ON.ESP then
                    local hl = S.espHL[plr]
                    if not hl or not hl.Parent then makeHL(plr) end
                    if root and myPos then
                        local bb = root:FindFirstChild("LeaBB")
                        if not bb then makeInfoBB(plr) bb = root:FindFirstChild("LeaBB") end
                        if bb then
                            local dl = bb:FindFirstChild("Dist")
                            if dl then
                                local dist = math.floor((root.Position - myPos).Magnitude)
                                dl.Text = dist .. " m"
                                if dist < 50 then dl.TextColor3 = COL_E
                                elseif dist < 150 then dl.TextColor3 = Color3.fromRGB(255,200,60)
                                else dl.TextColor3 = Color3.fromRGB(180,180,180) end
                            end
                            local hpL = bb:FindFirstChild("HP")
                            if hpL and h then
                                local hp = math.floor(h.Health)
                                hpL.Text = hp .. " HP"
                                if hp > 70 then hpL.TextColor3 = Color3.fromRGB(100,255,100)
                                elseif hp > 30 then hpL.TextColor3 = Color3.fromRGB(255,200,60)
                                else hpL.TextColor3 = COL_E end
                            end
                        end
                    end
                end
                if ON.Tracers then
                    local beam = S.tracerBeams[plr]
                    if not beam or not beam.Parent then makeTracer(plr) end
                end
            else
                local hl = S.espHL[plr]
                if hl and hl.Parent then hl:Destroy() end
                S.espHL[plr] = nil
                local beam = S.tracerBeams[plr]
                if beam and beam.Parent then beam:Destroy() end
                S.tracerBeams[plr] = nil
                if plr.Character then
                    local r = plr.Character:FindFirstChild("HumanoidRootPart")
                    if r then local bb=r:FindFirstChild("LeaBB") if bb then pcall(function()bb:Destroy()end) end end
                end
            end
        end
    end
    for plr, hl in pairs(S.espHL) do
        if not plr.Parent then
            pcall(function() if hl and hl.Parent then hl:Destroy() end end)
            S.espHL[plr] = nil
        end
    end
    for plr, beam in pairs(S.tracerBeams) do
        if not plr.Parent then
            pcall(function() if beam and beam.Parent then beam:Destroy() end end)
            S.tracerBeams[plr] = nil
        end
    end
end

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function()
        task.wait(0.3)
        if ON.ESP or ON.Tracers then doESP() end
    end)
end)
for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= LocalPlayer then
        plr.CharacterAdded:Connect(function()
            task.wait(0.3)
            if ON.ESP or ON.Tracers then doESP() end
        end)
    end
end

local function fullbright(on)
    if on then
        S.lit.b,S.lit.c,S.lit.f=Lighting.Brightness,Lighting.ClockTime,Lighting.FogEnd
        Lighting.Brightness=3.5; Lighting.ClockTime=14; Lighting.FogEnd=1e6; Lighting.GlobalShadows=false
    else
        if S.lit.b then Lighting.Brightness=S.lit.b end
        if S.lit.c then Lighting.ClockTime=S.lit.c end
        if S.lit.f then Lighting.FogEnd=S.lit.f end
        Lighting.GlobalShadows=true; S.lit={}
    end
end

-- ===================== MINIMAP =====================
local function buildMap(parent)
    if S.map then S.map:Destroy() end
    local size=CFG.mapSize
    local frame=Instance.new("Frame")
    frame.Name="Radar"
    frame.Size=UDim2.fromOffset(size,size)
    frame.Position=UDim2.new(1,-size-12,0,12)
    frame.BackgroundColor3=Color3.fromRGB(5,5,8)
    frame.BackgroundTransparency=0.1
    frame.BorderSizePixel=0
    frame.ZIndex=90
    frame.Parent=parent
    Instance.new("UICorner",frame).CornerRadius=UDim.new(0,size/2)
    local stroke=Instance.new("UIStroke",frame)
    stroke.Color=ACCENT; stroke.Thickness=2; stroke.Transparency=0.1

    local hline=Instance.new("Frame")
    hline.Size=UDim2.new(1,0,0,1); hline.Position=UDim2.new(0,0,0.5,0)
    hline.BackgroundColor3=Color3.fromRGB(60,60,75); hline.BackgroundTransparency=0.3
    hline.BorderSizePixel=0; hline.ZIndex=91; hline.Parent=frame
    local vline=Instance.new("Frame")
    vline.Size=UDim2.new(0,1,1,0); vline.Position=UDim2.new(0.5,0,0,0)
    vline.BackgroundColor3=Color3.fromRGB(60,60,75); vline.BackgroundTransparency=0.3
    vline.BorderSizePixel=0; vline.ZIndex=91; vline.Parent=frame

    for _, frac in ipairs({0.33, 0.66, 1.0}) do
        local ring=Instance.new("Frame")
        local rs = size * frac
        ring.Size=UDim2.fromOffset(rs, rs)
        ring.AnchorPoint=Vector2.new(0.5,0.5)
        ring.Position=UDim2.fromScale(0.5,0.5)
        ring.BackgroundTransparency=1
        ring.BorderSizePixel=0
        ring.ZIndex=91
        ring.Parent=frame
        Instance.new("UICorner",ring).CornerRadius=UDim.new(1,0)
        local rs2=Instance.new("UIStroke",ring)
        rs2.Color=Color3.fromRGB(50,50,65); rs2.Thickness=0.8; rs2.Transparency=0.5
    end

    local me=Instance.new("Frame")
    me.Size=UDim2.fromOffset(10,10); me.AnchorPoint=Vector2.new(0.5,0.5)
    me.Position=UDim2.fromScale(0.5,0.5); me.BackgroundColor3=COL_ME
    me.BorderSizePixel=0; me.ZIndex=94; me.Parent=frame
    Instance.new("UICorner",me).CornerRadius=UDim.new(1,0)
    local meStroke=Instance.new("UIStroke",me)
    meStroke.Color=Color3.new(1,1,1); meStroke.Thickness=1.5; meStroke.Transparency=0.3

    local arrow=Instance.new("Frame")
    arrow.Size=UDim2.fromOffset(5,12); arrow.AnchorPoint=Vector2.new(0.5,1)
    arrow.Position=UDim2.new(0.5,0,0.5,-6)
    arrow.BackgroundColor3=ACCENT; arrow.BorderSizePixel=0; arrow.ZIndex=95; arrow.Parent=frame
    Instance.new("UICorner",arrow).CornerRadius=UDim.new(0,2)
    S.mapArrow=arrow

    local dots=Instance.new("Folder"); dots.Name="Dots"; dots.Parent=frame

    local label=Instance.new("TextLabel")
    label.Size=UDim2.new(1,0,0,14); label.Position=UDim2.new(0,0,1,-16)
    label.BackgroundTransparency=1
    label.Text="RADAR  "..tostring(math.floor(CFG.mapRange)).."m"
    label.Font=Enum.Font.GothamBold; label.TextSize=9
    label.TextColor3=ACCENT; label.ZIndex=92; label.Parent=frame

    S.map=frame; S.mapDots=dots
end

local function updateMap()
    if not ON.Minimap or not S.map or not S.mapDots then
        if S.map then S.map.Visible=false end
        return
    end
    S.map.Visible=true
    local my=hrp()
    local myPos
    if my then
        myPos = my.Position
        S.lastMapPos = myPos
    elseif S.lastMapPos then
        myPos = S.lastMapPos
    else
        return
    end
    local range=CFG.mapRange
    local half=CFG.mapSize*0.5

    local cam = Workspace.CurrentCamera
    if not cam then
        cam = Workspace:FindFirstChildOfClass("Camera")
    end
    local camYaw
    if cam then
        camYaw = math.atan2(-cam.CFrame.LookVector.X, -cam.CFrame.LookVector.Z)
    else
        camYaw = 0
    end
    local cosY, sinY = math.cos(camYaw), math.sin(camYaw)
    if S.mapArrow then
        S.mapArrow.Visible = cam ~= nil
    end

    for _,d in ipairs(S.mapDots:GetChildren()) do d:Destroy() end

    for _,plr in ipairs(Players:GetPlayers()) do
        if plr~=LocalPlayer and plr.Character then
            local root=plr.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local dlt=root.Position-myPos
                local rx =  dlt.X*cosY + dlt.Z*sinY
                local rz = -dlt.X*sinY + dlt.Z*cosY
                local inRange = (dlt.X^2+dlt.Z^2) <= (range*range)
                local dx=math.clamp(rx/range*half, -half+8, half-8)
                local dz=math.clamp(rz/range*half, -half+8, half-8)
                local col = wl(plr) and COL_F or COL_E
                local dist2d = math.sqrt(dlt.X^2+dlt.Z^2)
                local dotSz  = dist2d < 50 and 12 or (dist2d < 150 and 9 or 7)

                local dot=Instance.new("Frame")
                dot.Size=UDim2.fromOffset(dotSz,dotSz)
                dot.AnchorPoint=Vector2.new(0.5,0.5)
                dot.Position=UDim2.new(0.5,dx,0.5,dz)
                dot.BackgroundColor3=col
                if not inRange then dot.BackgroundColor3=Color3.fromRGB(220,80,80) end
                dot.BorderSizePixel=0; dot.ZIndex=93; dot.Parent=S.mapDots
                Instance.new("UICorner",dot).CornerRadius=UDim.new(1,0)
                local dotStroke=Instance.new("UIStroke",dot)
                dotStroke.Color=Color3.new(1,1,1); dotStroke.Thickness=1; dotStroke.Transparency=0.5

                if CFG.mapShowNames then
                    local nl=Instance.new("TextLabel")
                    nl.Size=UDim2.fromOffset(70,11)
                    nl.AnchorPoint=Vector2.new(0.5,1)
                    nl.Position=UDim2.new(0.5,dx,0.5,dz-dotSz/2-2)
                    nl.BackgroundTransparency=1
                    nl.Text=plr.Name
                    nl.Font=Enum.Font.GothamBold
                    nl.TextSize=9
                    nl.TextColor3=col
                    nl.TextStrokeTransparency=0
                    nl.ZIndex=94
                    nl.Parent=S.mapDots
                end
            end
        end
    end
end

local function updateFov()
    if not S.fov then return end
    if ON.Aimbot and ON.ShowFov then
        S.fov.Visible=true
        local d=CFG.aimFovPx*2
        S.fov.Size=UDim2.fromOffset(d,d)
    else
        S.fov.Visible=false
    end
end

-- ===================== LOOT TRACKER =====================
local COL_LOOT = Color3.fromRGB(255, 215, 60)

local function guessLootItems(character)
    local items = {}
    local plr = Players:GetPlayerFromCharacter(character)
    if plr then
        local bp = plr:FindFirstChildOfClass("Backpack")
        if bp then
            for _, t in ipairs(bp:GetChildren()) do
                if t:IsA("Tool") then table.insert(items, "🔧 "..t.Name) end
            end
        end
        local char2 = plr.Character
        if char2 then
            for _, t in ipairs(char2:GetChildren()) do
                if t:IsA("Tool") then table.insert(items, "🔫 "..t.Name.." (equipped)") end
            end
        end
    end
    local lootKeywords = {"gun","weapon","rifle","pistol","smg","ammo","cash","money",
                          "medkit","heal","armor","vest","helmet","grenade","knife",
                          "sword","axe","shield","potion","key","item","loot","drop",
                          "backpack","bag","crate","chest"}
    for _, obj in ipairs(character:GetDescendants()) do
        local n = low(obj.Name)
        for _, kw in ipairs(lootKeywords) do
            if string.find(n, kw, 1, true) then
                table.insert(items, "📦 "..obj.Name)
                break
            end
        end
    end
    if #items == 0 then table.insert(items, "(no items detected)") end
    return items
end

local function highlightBody(character)
    if not CFG.lootBodyGlow then return end
    local hl = Instance.new("Highlight")
    hl.Name = "LeaLootHL"
    hl.FillColor = COL_LOOT
    hl.OutlineColor = COL_LOOT
    hl.FillTransparency = 0.6
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Adornee = character
    local ok = pcall(function()
        hl.Parent = game:GetService("CoreGui")
    end)
    if not ok or not hl.Parent then
        pcall(function() hl:Destroy() end)
        return
    end
    S.lootBodyHL[character] = hl
    task.delay(90, function()
        pcall(function() if hl and hl.Parent then hl:Destroy() end end)
        S.lootBodyHL[character] = nil
    end)
end

local function refreshLootPanel()
    if not S.lootPanel or not S.lootPanel.Parent then return end
    for _, c in ipairs(S.lootPanel:GetChildren()) do
        if c:IsA("Frame") or c:IsA("TextLabel") then c:Destroy() end
    end
    local my = hrp()
    local myPos = my and my.Position
    local shown = 0
    for i = #S.lootLog, 1, -1 do
        if shown >= CFG.lootMaxItems then break end
        local entry = S.lootLog[i]
        local dist = 9999
        if myPos and entry.bodyPos then
            dist = math.floor((entry.bodyPos - myPos).Magnitude)
        end
        if dist > CFG.lootRange then continue end
        shown += 1

        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, -4, 0, 0)
        card.AutomaticSize = Enum.AutomaticSize.Y
        card.BackgroundColor3 = Color3.fromRGB(20, 18, 10)
        card.BorderSizePixel = 0
        card.LayoutOrder = shown
        card.ZIndex = 52
        card.Parent = S.lootPanel
        Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)
        local cStroke = Instance.new("UIStroke", card)
        cStroke.Color = COL_LOOT; cStroke.Thickness = 1; cStroke.Transparency = 0.4
        local cLay = Instance.new("UIListLayout", card)
        cLay.Padding = UDim.new(0, 2)
        local cPad = Instance.new("UIPadding", card)
        cPad.PaddingLeft=UDim.new(0,8); cPad.PaddingRight=UDim.new(0,8)
        cPad.PaddingTop=UDim.new(0,6); cPad.PaddingBottom=UDim.new(0,6)

        local header = Instance.new("TextLabel", card)
        header.Size = UDim2.new(1,0,0,16)
        header.AutomaticSize = Enum.AutomaticSize.Y
        header.BackgroundTransparency = 1
        header.Text = "☠ "..entry.victimName.."  |  "..dist.."m  |  "..entry.killerName.." killed"
        header.Font = Enum.Font.GothamBold
        header.TextSize = 11
        header.TextColor3 = COL_LOOT
        header.TextXAlignment = Enum.TextXAlignment.Left
        header.TextWrapped = true
        header.ZIndex = 53

        for _, item in ipairs(entry.items) do
            local il = Instance.new("TextLabel", card)
            il.Size = UDim2.new(1,0,0,13)
            il.AutomaticSize = Enum.AutomaticSize.Y
            il.BackgroundTransparency = 1
            il.Text = "  "..item
            il.Font = Enum.Font.Gotham
            il.TextSize = 10
            il.TextColor3 = Color3.fromRGB(220,210,180)
            il.TextXAlignment = Enum.TextXAlignment.Left
            il.TextWrapped = true
            il.ZIndex = 53
        end
    end
    if shown == 0 then
        local empty = Instance.new("TextLabel", S.lootPanel)
        empty.Size = UDim2.new(1,0,0,30)
        empty.BackgroundTransparency = 1
        empty.Text = "no loot in range"
        empty.Font = Enum.Font.Gotham
        empty.TextSize = 10
        empty.TextColor3 = Color3.fromRGB(90,90,100)
        empty.TextXAlignment = Enum.TextXAlignment.Center
        empty.ZIndex = 52
    end
end

local function watchPlayer(plr)
    local function onChar(character)
        local hum = character:WaitForChild("Humanoid", 10)
        if not hum then return end
        hum.Died:Connect(function()
            task.wait(0.3)
            if not ON.LootTracker then return end
            local killerName = "unknown"
            pcall(function()
                local tag = hum:FindFirstChild("creator")
                if tag and tag:IsA("ObjectValue") and tag.Value then
                    killerName = tag.Value.Name
                end
            end)
            local items = guessLootItems(character)
            local bodyPos
            pcall(function()
                local root = character:FindFirstChild("HumanoidRootPart")
                bodyPos = root and root.Position
            end)
            local entry = {
                victimName = plr.Name,
                killerName = killerName,
                items      = items,
                bodyPos    = bodyPos,
                ts         = os.clock(),
                bodyModel  = character,
            }
            table.insert(S.lootLog, entry)
            while #S.lootLog > CFG.lootMaxItems do table.remove(S.lootLog, 1) end
            highlightBody(character)
            pcall(refreshLootPanel)
            pcall(function() S.say("☠ "..plr.Name.." died — "..#items.." items") end)
            pcall(function()
                StarterGui:SetCore("SendNotification", {
                    Title = "Loot",
                    Text  = plr.Name.." dropped "..#items.." item(s)",
                    Duration = 4,
                })
            end)
        end)
    end
    if plr.Character then task.spawn(onChar, plr.Character) end
    plr.CharacterAdded:Connect(onChar)
end

local function startLootTracker()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then watchPlayer(plr) end
    end
    Players.PlayerAdded:Connect(function(plr)
        if plr ~= LocalPlayer then watchPlayer(plr) end
    end)
end

-- ===================== LOOPS =====================
local _espT,_mapT,_lootT=0,0,0
RunService.Heartbeat:Connect(function(dt)
    _espT+=dt; _mapT+=dt; _lootT+=dt
    if _espT>=0.25  then _espT=0;  if ON.ESP or ON.Tracers then pcall(doESP) end end
    if _mapT>=0.07 then _mapT=0;  pcall(updateMap); pcall(updateFov) end
    if _lootT>=1.0 then _lootT=0; if ON.LootTracker then pcall(refreshLootPanel) end end
    if ON.NoFall then
        local h=hum()
        if h and h:GetState()==Enum.HumanoidStateType.Freefall then
            h:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end
    if ON.MobPush then
        local r=hrp(); if r then
            for _,m in ipairs(Workspace:GetChildren()) do
                if m:IsA("Model") and m~=char() and not Players:GetPlayerFromCharacter(m) then
                    local mh=m:FindFirstChildOfClass("Humanoid")
                    local mr=m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart
                    if mh and mr and mh.Health>0 then
                        local d=(mr.Position-r.Position).Magnitude
                        if d>0.4 and d<=16 then
                            local away=r.Position-mr.Position
                            if away.Magnitude>0 then
                                r.AssemblyLinearVelocity=away.Unit*90+Vector3.new(0,40,0)
                            end
                        end
                    end
                end
            end
        end
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.4)
    claim(char()); stripConns()
    flyStop(); carStop()
    if ON.Fly then flyStart() end
    if ON.CarFly then carStart() end
    if ON.Speed then applySpeed() end
    if ON.Noclip then setNoclip(true) end
    if ON.ESP or ON.Tracers then doESP() end
    if ON.God then startGod() end
    enableAntiReset()
    S.aimTarget=nil; S.lastCF=nil
end)

-- ===================== UI — NEON CYBERPUNK =====================
S.say = function(t)
    if S.status then
        S.status.Text = tostring(t)
        task.delay(2, function()
            if S.status then S.status.Text = "ready" end
        end)
    end
end

local PANEL_H = 560

local function buildGui()
    local pg = LocalPlayer:WaitForChild("PlayerGui")
    local old = pg:FindFirstChild("LeaHub")
    if old then old:Destroy() end

    local g = Instance.new("ScreenGui")
    g.Name = "LeaHub"
    g.ResetOnSpawn = false
    g.IgnoreGuiInset = true
    g.DisplayOrder = 999
    g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    g.Parent = pg
    S.gui = g
    if S.map then S.map:Destroy() S.map=nil end

    local fov = Instance.new("Frame")
    fov.Name = "FOV"
    fov.AnchorPoint = Vector2.new(0.5, 0.5)
    fov.Position = UDim2.fromScale(0.5, 0.5)
    fov.BackgroundTransparency = 1
    fov.ZIndex = 40
    fov.Parent = g
    local fs = Instance.new("UIStroke", fov)
    fs.Color = ACCENT; fs.Thickness = 2; fs.Transparency = 0.3
    Instance.new("UICorner", fov).CornerRadius = UDim.new(1, 0)
    S.fov = fov

    buildMap(g)

    local root = Instance.new("Frame")
    root.Name = "LeaRoot"
    root.Size = UDim2.fromOffset(320, 32)
    root.Position = UDim2.new(0.5, -160, 0, 10)
    root.BackgroundTransparency = 1
    root.ClipsDescendants = false
    root.ZIndex = 50
    root.Parent = g

    local glow = Instance.new("Frame")
    glow.Name = "Glow"
    glow.Size = UDim2.new(1, 20, 0, 40)
    glow.Position = UDim2.fromOffset(-10, -4)
    glow.BackgroundColor3 = ACCENT
    glow.BackgroundTransparency = 0.95
    glow.BorderSizePixel = 0
    glow.ZIndex = 49
    glow.Parent = root
    Instance.new("UICorner", glow).CornerRadius = UDim.new(0, 8)

    local bar = Instance.new("Frame")
    bar.Name = "TopBar"
    bar.Size = UDim2.new(1, 0, 0, 32)
    bar.Position = UDim2.fromOffset(0, 0)
    bar.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
    bar.BorderSizePixel = 0
    bar.ZIndex = 55
    bar.Parent = root
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 6)
    local barStroke = Instance.new("UIStroke", bar)
    barStroke.Color = ACCENT
    barStroke.Thickness = 1.5
    barStroke.Transparency = 0.2

    local stripe = Instance.new("Frame")
    stripe.Size = UDim2.fromOffset(4, 20)
    stripe.Position = UDim2.fromOffset(10, 6)
    stripe.BackgroundColor3 = ACCENT
    stripe.BorderSizePixel = 0
    stripe.ZIndex = 56
    stripe.Parent = bar
    Instance.new("UICorner", stripe).CornerRadius = UDim.new(0, 2)
    task.spawn(function()
        while stripe and stripe.Parent do
            TweenService:Create(stripe, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                BackgroundColor3 = ACCENT2
            }):Play()
            task.wait(0.8)
            if not stripe or not stripe.Parent then break end
            TweenService:Create(stripe, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                BackgroundColor3 = ACCENT
            }):Play()
            task.wait(0.8)
        end
    end)

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -140, 1, 0)
    titleLbl.Position = UDim2.fromOffset(22, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = "⚡ VULTRA"
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 13
    titleLbl.TextColor3 = Color3.fromRGB(255, 200, 100)
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.ZIndex = 56
    titleLbl.Parent = bar

    local statusPill = Instance.new("TextLabel")
    statusPill.Size = UDim2.fromOffset(90, 20)
    statusPill.Position = UDim2.new(1, -140, 0.5, -10)
    statusPill.BackgroundColor3 = Color3.fromRGB(15, 25, 15)
    statusPill.Text = "● ready"
    statusPill.Font = Enum.Font.GothamBold
    statusPill.TextSize = 10
    statusPill.TextColor3 = Color3.fromRGB(100, 255, 150)
    statusPill.TextXAlignment = Enum.TextXAlignment.Center
    statusPill.ZIndex = 56
    statusPill.Parent = bar
    Instance.new("UICorner", statusPill).CornerRadius = UDim.new(0, 10)
    local statusStroke = Instance.new("UIStroke", statusPill)
    statusStroke.Color = Color3.fromRGB(100, 255, 150)
    statusStroke.Thickness = 1
    statusStroke.Transparency = 0.5
    S.status = statusPill

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.fromOffset(50, 22)
    toggleBtn.Position = UDim2.new(1, -56, 0.5, -11)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(30, 20, 10)
    toggleBtn.Text = "OPEN ▼"
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextSize = 10
    toggleBtn.TextColor3 = ACCENT
    toggleBtn.ZIndex = 57
    toggleBtn.Parent = bar
    Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 4)
    local tStroke = Instance.new("UIStroke", toggleBtn)
    tStroke.Color = ACCENT; tStroke.Thickness = 1.5; tStroke.Transparency = 0.3

    local panel = Instance.new("Frame")
    panel.Name = "Panel"
    panel.Size = UDim2.fromOffset(320, 0)
    panel.Position = UDim2.fromOffset(0, 32)
    panel.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
    panel.ClipsDescendants = true
    panel.BorderSizePixel = 0
    panel.ZIndex = 50
    panel.Parent = root
    local pStroke = Instance.new("UIStroke", panel)
    pStroke.Color = Color3.fromRGB(60, 50, 40)
    pStroke.Thickness = 1
    pStroke.Transparency = 0.3
    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 6)

    local panelOpen = false
    local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

    local function setPanel(open)
        panelOpen = open
        toggleBtn.Text = open and "CLOSE ▲" or "OPEN ▼"
        local targetH = open and PANEL_H or 0
        local tween = TweenService:Create(panel, tweenInfo, {Size = UDim2.fromOffset(320, targetH)})
        tween:Play()
    end

    toggleBtn.MouseButton1Click:Connect(function()
        setPanel(not panelOpen)
    end)

    local dragging, d0, p0 = false, nil, nil
    bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true; d0 = i.Position; p0 = root.Position
        end
    end)
    bar.InputEnded:Connect(function() dragging = false end)
    UserInputService.InputChanged:Connect(function(i)
        if not dragging then return end
        if i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch then
            local d = i.Position - d0
            root.Position = UDim2.new(p0.X.Scale, p0.X.Offset + d.X, p0.Y.Scale, p0.Y.Offset + d.Y)
        end
    end)

    local tabBar = Instance.new("Frame")
    tabBar.Size = UDim2.new(1, -16, 0, 32)
    tabBar.Position = UDim2.fromOffset(8, 10)
    tabBar.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
    tabBar.ZIndex = 51
    tabBar.Parent = panel
    Instance.new("UICorner", tabBar).CornerRadius = UDim.new(0, 6)
    local tabStroke = Instance.new("UIStroke", tabBar)
    tabStroke.Color = Color3.fromRGB(40, 35, 30)
    tabStroke.Thickness = 1
    tabStroke.Transparency = 0.4
    local tabLay = Instance.new("UIListLayout", tabBar)
    tabLay.FillDirection = Enum.FillDirection.Horizontal
    tabLay.Padding = UDim.new(0, 3)
    tabLay.VerticalAlignment = Enum.VerticalAlignment.Center
    local tabPad = Instance.new("UIPadding", tabBar)
    tabPad.PaddingLeft = UDim.new(0, 4); tabPad.PaddingRight = UDim.new(0, 4)
    tabPad.PaddingTop = UDim.new(0, 4); tabPad.PaddingBottom = UDim.new(0, 4)

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -16, 1, -56)
    scroll.Position = UDim2.fromOffset(8, 50)
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness = 3
    scroll.ScrollBarImageColor3 = ACCENT
    scroll.CanvasSize = UDim2.fromOffset(0, 0)
    scroll.ZIndex = 51
    scroll.Parent = panel
    local sLay = Instance.new("UIListLayout", scroll)
    sLay.Padding = UDim.new(0, 5)
    sLay.SortOrder = Enum.SortOrder.LayoutOrder
    sLay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize = UDim2.fromOffset(0, sLay.AbsoluteContentSize.Y + 12)
    end)

    local TABS = {
        {id="main",   t="⚡ Main"},
        {id="combat", t="🎯 Aim"},
        {id="move",   t="🚀 Move"},
        {id="visual", t="👁 ESP"},
        {id="loot",   t="💰 Loot"},
        {id="list",   t="📋 List"},
    }
    local pages, tabs, active = {}, {}, nil

    for _, td in ipairs(TABS) do
        local page = Instance.new("Frame")
        page.Name = td.id
        page.Size = UDim2.new(1, 0, 0, 0)
        page.BackgroundTransparency = 1
        page.Visible = false
        page.AutomaticSize = Enum.AutomaticSize.Y
        page.ZIndex = 52
        page.Parent = scroll
        local pl = Instance.new("UIListLayout", page)
        pl.Padding = UDim.new(0, 5)
        pl.SortOrder = Enum.SortOrder.LayoutOrder
        pages[td.id] = {f = page, o = 0}
    end

    local function switch(id)
        if active == id then return end
        active = id
        for _, td in ipairs(TABS) do
            if pages[td.id] then pages[td.id].f.Visible = (td.id == id) end
        end
        for tid, b in pairs(tabs) do
            local isActive = (tid == id)
            b.BackgroundColor3 = isActive and Color3.fromRGB(40, 25, 10) or Color3.fromRGB(15, 15, 20)
            b.TextColor3 = isActive and ACCENT or Color3.fromRGB(100, 100, 110)
            local stroke = b:FindFirstChildOfClass("UIStroke")
            if stroke then
                stroke.Color = isActive and ACCENT or Color3.fromRGB(40, 40, 50)
                stroke.Transparency = isActive and 0.2 or 0.6
            end
        end
        scroll.CanvasPosition = Vector2.zero
    end

    local n = #TABS
    for _, td in ipairs(TABS) do
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1/n, -3, 1, 0)
        b.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
        b.Text = td.t
        b.Font = Enum.Font.GothamBold
        b.TextSize = 11
        b.TextColor3 = Color3.fromRGB(100, 100, 110)
        b.ZIndex = 52
        b.Parent = tabBar
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
        local bStroke = Instance.new("UIStroke", b)
        bStroke.Color = Color3.fromRGB(40, 40, 50)
        bStroke.Thickness = 1
        bStroke.Transparency = 0.6
        tabs[td.id] = b
        local id = td.id
        b.MouseButton1Click:Connect(function() switch(id) end)
    end

    -- Widget helpers with neon style
    local function tog(page, name, key, onE, onD)
        local p = pages[page]; if not p then return end
        p.o += 1
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -4, 0, 36)
        row.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
        row.LayoutOrder = p.o
        row.ZIndex = 52
        row.Parent = p.f
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
        local rowStroke = Instance.new("UIStroke", row)
        rowStroke.Color = Color3.fromRGB(30, 30, 40)
        rowStroke.Thickness = 1
        rowStroke.Transparency = 0.5

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -60, 1, 0)
        lbl.Position = UDim2.fromOffset(12, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = name
        lbl.Font = Enum.Font.GothamMedium
        lbl.TextSize = 12
        lbl.TextColor3 = Color3.fromRGB(140, 140, 150)
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.ZIndex = 53
        lbl.Parent = row

        local pill = Instance.new("Frame")
        pill.Size = UDim2.fromOffset(40, 20)
        pill.Position = UDim2.new(1, -48, 0.5, -10)
        pill.ZIndex = 53
        pill.Parent = row
        Instance.new("UICorner", pill).CornerRadius = UDim.new(0, 10)

        local dot = Instance.new("Frame")
        dot.Size = UDim2.fromOffset(14, 14)
        dot.ZIndex = 54
        dot.Parent = pill
        Instance.new("UICorner", dot).CornerRadius = UDim.new(0, 7)

        local function ref()
            local on = ON[key]
            pill.BackgroundColor3 = on and ACCENT or Color3.fromRGB(25, 25, 35)
            dot.BackgroundColor3 = on and Color3.new(1, 1, 1) or Color3.fromRGB(80, 80, 90)
            dot.Position = on and UDim2.fromOffset(24, 3) or UDim2.fromOffset(3, 3)
            lbl.TextColor3 = on and Color3.fromRGB(255, 200, 120) or Color3.fromRGB(140, 140, 150)
            row.BackgroundColor3 = on and Color3.fromRGB(25, 18, 10) or Color3.fromRGB(12, 12, 16)
            rowStroke.Color = on and ACCENT or Color3.fromRGB(30, 30, 40)
            rowStroke.Transparency = on and 0.3 or 0.5
        end

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 1, 0)
        btn.BackgroundTransparency = 1
        btn.Text = ""
        btn.ZIndex = 55
        btn.Parent = row
        btn.MouseButton1Click:Connect(function()
            ON[key] = not ON[key]; ref()
            if ON[key] and onE then pcall(onE) end
            if not ON[key] and onD then pcall(onD) end
            say(name .. (ON[key] and " on" or " off"))
        end)
        ref()
    end

    local function act(page, name, fn)
        local p = pages[page]; if not p then return end
        p.o += 1
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, -4, 0, 30)
        b.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
        b.LayoutOrder = p.o
        b.ZIndex = 52
        b.Parent = p.f
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
        local bStroke = Instance.new("UIStroke", b)
        bStroke.Color = Color3.fromRGB(40, 35, 30)
        bStroke.Thickness = 1
        bStroke.Transparency = 0.5
        b.Text = "  " .. name
        b.Font = Enum.Font.GothamMedium
        b.TextSize = 12
        b.TextColor3 = Color3.fromRGB(200, 200, 210)
        b.TextXAlignment = Enum.TextXAlignment.Left
        b.MouseButton1Click:Connect(function()
            pcall(fn)
            b.BackgroundColor3 = Color3.fromRGB(35, 25, 15)
            task.delay(0.15, function() 
                if b and b.Parent then
                    b.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
                end
            end)
        end)
    end

    local function sec(page, name)
        local p = pages[page]; if not p then return end
        p.o += 1
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, 0, 0, 18)
        l.BackgroundTransparency = 1
        l.Text = "◆ " .. string.upper(name)
        l.Font = Enum.Font.GothamBold
        l.TextSize = 10
        l.TextColor3 = ACCENT
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.LayoutOrder = p.o
        l.ZIndex = 52
        l.Parent = p.f
    end

    local function slider(page, name, cfgKey, minV, maxV, step, fmt)
        local p = pages[page]; if not p then return end
        p.o += 1
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -4, 0, 40)
        row.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
        row.LayoutOrder = p.o
        row.ZIndex = 52
        row.Parent = p.f
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
        local rowStroke = Instance.new("UIStroke", row)
        rowStroke.Color = Color3.fromRGB(30, 30, 40)
        rowStroke.Thickness = 1
        rowStroke.Transparency = 0.5

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0.55, 0, 0, 18)
        lbl.Position = UDim2.fromOffset(12, 3)
        lbl.BackgroundTransparency = 1
        lbl.Text = name
        lbl.Font = Enum.Font.GothamMedium
        lbl.TextSize = 11
        lbl.TextColor3 = Color3.fromRGB(140, 140, 150)
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.ZIndex = 53
        lbl.Parent = row

        local valLbl = Instance.new("TextLabel")
        valLbl.Size = UDim2.new(1, -20, 0, 16)
        valLbl.Position = UDim2.fromOffset(12, 22)
        valLbl.BackgroundTransparency = 1
        valLbl.Font = Enum.Font.GothamBold
        valLbl.TextSize = 11
        valLbl.TextColor3 = ACCENT
        valLbl.TextXAlignment = Enum.TextXAlignment.Left
        valLbl.ZIndex = 53
        valLbl.Parent = row

        local function refreshVal()
            valLbl.Text = (fmt or "%g"):format(CFG[cfgKey])
        end
        refreshVal()

        local minus = Instance.new("TextButton")
        minus.Size = UDim2.fromOffset(22, 22)
        minus.Position = UDim2.new(1, -50, 0.5, -11)
        minus.BackgroundColor3 = Color3.fromRGB(35, 22, 12)
        minus.Text = "−"
        minus.Font = Enum.Font.GothamBold
        minus.TextSize = 16
        minus.TextColor3 = ACCENT
        minus.ZIndex = 54
        minus.Parent = row
        Instance.new("UICorner", minus).CornerRadius = UDim.new(0, 4)
        local minusStroke = Instance.new("UIStroke", minus)
        minusStroke.Color = ACCENT; minusStroke.Thickness = 1; minusStroke.Transparency = 0.4

        local plus = Instance.new("TextButton")
        plus.Size = UDim2.fromOffset(22, 22)
        plus.Position = UDim2.new(1, -24, 0.5, -11)
        plus.BackgroundColor3 = Color3.fromRGB(35, 22, 12)
        plus.Text = "+"
        plus.Font = Enum.Font.GothamBold
        plus.TextSize = 16
        plus.TextColor3 = ACCENT
        plus.ZIndex = 54
        plus.Parent = row
        Instance.new("UICorner", plus).CornerRadius = UDim.new(0, 4)
        local plusStroke = Instance.new("UIStroke", plus)
        plusStroke.Color = ACCENT; plusStroke.Thickness = 1; plusStroke.Transparency = 0.4

        minus.MouseButton1Click:Connect(function()
            CFG[cfgKey] = math.clamp(CFG[cfgKey] - step, minV, maxV); refreshVal()
            say(name .. ": " .. (fmt or "%g"):format(CFG[cfgKey]))
        end)
        plus.MouseButton1Click:Connect(function()
            CFG[cfgKey] = math.clamp(CFG[cfgKey] + step, minV, maxV); refreshVal()
            say(name .. ": " .. (fmt or "%g"):format(CFG[cfgKey]))
        end)
    end

    -- MAIN tab
    sec("main","bypass")
    act("main","Enable Bypass", function() startBypass(); say("bypass live") end)
    tog("main","Ownership",    "Ownership")
    tog("main","Anti-Teleport","AntiTP")
    tog("main","God Mode",     "God", startGod, function() if S.godConn then S.godConn:Disconnect() end end)
    tog("main","Anti-Reset",   "God", enableAntiReset, function() end)

    -- COMBAT tab
    sec("combat","aimbot")
    tog("combat","Aimbot  [hold Q]","Aimbot")
    tog("combat","FOV Circle",      "ShowFov")
    tog("combat","Silent Aim",      "SilentAim")
    slider("combat","FOV radius",   "aimFovPx",  80, 900, 25, "%g px")
    slider("combat","Predict",      "aimPredict", 0, 0.5, 0.02, "%.2f")
    sec("combat","extra")
    tog("combat","Mob Push","MobPush")
    tog("combat","No Fall", "NoFall")

    -- MOVE tab
    sec("move","movement")
    tog("move","Speed",    "Speed",    applySpeed, applySpeed)
    tog("move","High Jump","HighJump", applySpeed, applySpeed)
    tog("move","Fly",      "Fly",      flyStart,   flyStop)
    tog("move","Noclip",   "Noclip",   function() setNoclip(true) end, function() setNoclip(false) end)
    tog("move","Inf Jump", "InfJump")
    slider("move","Fly speed",    "flySpeed",    20, 500, 10, "%g")
    slider("move","Walk boost",   "walkBoost",   16, 300, 5,  "%g")
    sec("move","vehicle  [F6]")
    tog("move","Car Fly","CarFly", carStart, carStop)
    slider("move","Car speed",  "carFlySpeed",  50, 600, 10, "%g")
    slider("move","Car boost",  "carFlyBoost",  50, 900, 20, "%g")

    -- ESP tab
    sec("visual","esp")
    tog("visual","ESP",        "ESP",        doESP, function() if not ON.Tracers then clearESP() else doESP() end end)
    tog("visual","Tracers",    "Tracers",    doESP, function() if not ON.ESP     then clearESP() else doESP() end end)
    tog("visual","Minimap",    "Minimap")
    tog("visual","Map Names",  "Minimap",
        function() CFG.mapShowNames=true  end,
        function() CFG.mapShowNames=false end)
    tog("visual","Fullbright", "Fullbright", function() fullbright(true) end, function() fullbright(false) end)
    slider("visual","Map range","mapRange", 100, 3000, 100, "%g m")
    slider("visual","Map size", "mapSize",  120, 320,  20, "%g px")

    -- LOOT tab
    sec("loot","loot tracker")
    tog("loot","Loot Tracker","LootTracker",
        function() startLootTracker(); say("loot tracker on") end,
        function() say("loot tracker off") end)
    tog("loot","Body Glow",  "LootTracker",
        function() CFG.lootBodyGlow=true  end,
        function() CFG.lootBodyGlow=false end)
    slider("loot","Show range","lootRange", 50, 2000, 50, "%g m")

    act("loot","Clear Log", function()
        S.lootLog={}
        for model, hl in pairs(S.lootBodyHL) do
            pcall(function() if hl and hl.Parent then hl:Destroy() end end)
        end
        S.lootBodyHL={}
        pcall(refreshLootPanel)
        say("loot log cleared")
    end)

    sec("loot","kills / drops")
    local lp2 = pages["loot"]; lp2.o += 1
    local lootScroll = Instance.new("ScrollingFrame")
    lootScroll.Size = UDim2.new(1, -4, 0, 300)
    lootScroll.BackgroundColor3 = Color3.fromRGB(10, 9, 5)
    lootScroll.LayoutOrder = lp2.o
    lootScroll.ZIndex = 52
    lootScroll.ScrollBarThickness = 3
    lootScroll.ScrollBarImageColor3 = COL_LOOT
    lootScroll.CanvasSize = UDim2.fromOffset(0, 0)
    lootScroll.Parent = lp2.f
    Instance.new("UICorner", lootScroll).CornerRadius = UDim.new(0, 6)
    local lootStroke = Instance.new("UIStroke", lootScroll)
    lootStroke.Color = Color3.fromRGB(60, 50, 20)
    lootStroke.Thickness = 1
    lootStroke.Transparency = 0.5
    local lLay = Instance.new("UIListLayout", lootScroll)
    lLay.Padding = UDim.new(0, 5)
    lLay.SortOrder = Enum.SortOrder.LayoutOrder
    lLay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        lootScroll.CanvasSize = UDim2.fromOffset(0, lLay.AbsoluteContentSize.Y + 10)
    end)
    S.lootPanel = lootScroll
    local emptyL = Instance.new("TextLabel", lootScroll)
    emptyL.Size = UDim2.new(1,0,0,30)
    emptyL.BackgroundTransparency = 1
    emptyL.Text = "no loot yet — kills will appear here"
    emptyL.Font = Enum.Font.Gotham
    emptyL.TextSize = 10
    emptyL.TextColor3 = Color3.fromRGB(90,90,100)
    emptyL.TextXAlignment = Enum.TextXAlignment.Center
    emptyL.ZIndex = 52

    -- LIST tab
    sec("list","whitelist")
    local lp = pages["list"]; lp.o += 1
    local box = Instance.new("ScrollingFrame")
    box.Size = UDim2.new(1, -4, 0, 240)
    box.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
    box.LayoutOrder = lp.o
    box.ZIndex = 52
    box.ScrollBarThickness = 3
    box.ScrollBarImageColor3 = ACCENT
    box.Parent = lp.f
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)
    local boxStroke = Instance.new("UIStroke", box)
    boxStroke.Color = Color3.fromRGB(30, 30, 40)
    boxStroke.Thickness = 1
    boxStroke.Transparency = 0.5
    local bl = Instance.new("UIListLayout", box)
    bl.Padding = UDim.new(0, 4)
    bl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        box.CanvasSize = UDim2.fromOffset(0, bl.AbsoluteContentSize.Y + 8)
    end)

    local function refreshList()
        for _, c in ipairs(box:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local friend = wl(plr)
                local b = Instance.new("TextButton")
                b.Size = UDim2.new(1, -8, 0, 28)
                b.BackgroundColor3 = friend and Color3.fromRGB(15, 35, 20) or Color3.fromRGB(35, 15, 15)
                b.Text = (friend and "✓ " or "✗ ") .. plr.Name
                b.Font = Enum.Font.GothamBold
                b.TextSize = 12
                b.TextColor3 = friend and COL_F or COL_E
                b.ZIndex = 53
                b.Parent = box
                Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
                local bStroke = Instance.new("UIStroke", b)
                bStroke.Color = friend and COL_F or COL_E
                bStroke.Thickness = 1
                bStroke.Transparency = 0.6
                local p = plr
                b.MouseButton1Click:Connect(function()
                    if WHITELIST[p.UserId] then WHITELIST[p.UserId] = nil
                    else WHITELIST[p.UserId] = true end
                    refreshList()
                    if ON.ESP or ON.Tracers then doESP() end
                    say(p.Name .. (wl(p) and " friend" or " enemy"))
                end)
            end
        end
    end

    act("list","Refresh", refreshList)
    Players.PlayerAdded:Connect(function() task.defer(refreshList) end)
    Players.PlayerRemoving:Connect(function(p) WHITELIST[p.UserId] = nil; task.defer(refreshList) end)
    task.defer(refreshList)

    -- keyboard shortcuts
    UserInputService.InputBegan:Connect(function(i, gp)
        if gp then return end
        if i.KeyCode == Enum.KeyCode.RightShift then
            setPanel(not panelOpen)
            if panelOpen then
                if not active then switch("main") end
                refreshList()
            end
        elseif i.KeyCode == Enum.KeyCode.F9 then
            ON.Aimbot = not ON.Aimbot
            say("aimbot " .. (ON.Aimbot and "on" or "off"))
            updateFov()
        elseif i.KeyCode == Enum.KeyCode.F8 then
            ON.ESP = not ON.ESP
            if ON.ESP or ON.Tracers then doESP() else clearESP() end
            say("esp " .. (ON.ESP and "on" or "off"))
        elseif i.KeyCode == CFG.carFlyKey then
            ON.CarFly = not ON.CarFly
            if ON.CarFly then carStart() else carStop() end
            say("car fly " .. (ON.CarFly and "on" or "off"))
        end
    end)

    switch("main")
end

-- ===================== INIT =====================
task.wait(0.25)
startBypass()
buildGui()
ON.Minimap = true
ON.ShowFov = true
ON.LootTracker = true
updateFov()
startLootTracker()
enableAntiReset()
if S.gui then buildMap(S.gui) end
