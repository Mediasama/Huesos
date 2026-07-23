local v2 = Vector2.new
local v3 = Vector3.new
local cf = CFrame.new
local rad = math.rad
local cos = math.cos
local sin = math.sin
local abs = math.abs
local pi = math.pi
local clamp = math.clamp
local floor = math.floor
local max = math.max
local min = math.min
local sqrt = math.sqrt
local huge = math.huge
local insert = table.insert
local remove = table.remove
local rgb = Color3.fromRGB

local runservice = game:GetService("RunService")
local players = game:GetService("Players")
local localplayer = players.LocalPlayer
local camera = workspace.CurrentCamera

local lastlanding = nil
local isairborne = false
local smoothedpositions = {}
local lastcamerapos = camera.CFrame.Position
local lastcameracf = camera.CFrame
local cameraturnspeed = 0
local prejumpenabled = false
local lastmoveinput = v3(0, 0, 1)
local smoothedprejumplines = {}
local smoothedprejumpdot = v2(0, 0)
local time = 0

local draw = Drawing

local preddot = draw.new("Circle")
preddot.Radius = 6
preddot.Filled = true
preddot.Color = rgb(0, 255, 255)
preddot.Visible = false
preddot.Transparency = 1
preddot.NumSides = 32

local landdot = draw.new("Circle")
landdot.Radius = 12
landdot.Filled = true
landdot.Color = rgb(255, 100, 100)
landdot.Visible = false
landdot.Transparency = 1
landdot.NumSides = 32

local landoutline = draw.new("Circle")
landoutline.Radius = 18
landoutline.Filled = false
landoutline.Color = rgb(255, 150, 150)
landoutline.Visible = false
landoutline.Transparency = 1
landoutline.Thickness = 2
landoutline.NumSides = 32

local velline = draw.new("Line")
velline.Color = rgb(0, 255, 0)
velline.Thickness = 3
velline.Visible = false
velline.Transparency = 1

local velcurve = {}
for i = 1, 8 do
    local line = draw.new("Line")
    line.Color = rgb(0, 255, 0)
    line.Thickness = 3
    line.Visible = false
    line.Transparency = 1
    velcurve[i] = line
end

local arclines = {}
for i = 1, 29 do
    local line = draw.new("Line")
    line.Color = rgb(255, 240, 140)
    line.Thickness = 2
    line.Visible = false
    line.Transparency = 1
    arclines[i] = line
end

local prejumplines = {}
for i = 1, 29 do
    local line = draw.new("Line")
    line.Color = rgb(100, 200, 255)
    line.Thickness = 2
    line.Visible = false
    line.Transparency = 0.7
    prejumplines[i] = line
    smoothedprejumplines[i] = {from = v2(0, 0), to = v2(0, 0)}
end

local prejumplanddot = draw.new("Circle")
prejumplanddot.Radius = 10
prejumplanddot.Filled = true
prejumplanddot.Color = rgb(100, 200, 255)
prejumplanddot.Visible = false
prejumplanddot.Transparency = 0.7
prejumplanddot.NumSides = 32

local function lerp2(a, b, t)
    return a + (b - a) * t
end

local function predictpos(p0, v0, t)
    local grav = workspace.Gravity
    return p0 + v0 * t + v3(0, -grav, 0) * 0.5 * t * t
end

local function toscreen(pos)
    local screenpos, onscreen = camera:WorldToViewportPoint(pos)
    return v2(screenpos.X, screenpos.Y), onscreen
end

local function isvisible(pos)
    local rayparams = RaycastParams.new()
    rayparams.FilterDescendantsInstances = {localplayer.Character}
    rayparams.FilterType = Enum.RaycastFilterType.Exclude
    
    local campos = camera.CFrame.Position
    local dir = pos - campos
    local distance = dir.Magnitude
    
    if distance < 2 then return true end
    
    local ray = workspace:Raycast(campos, dir, rayparams)
    
    if ray and (ray.Position - campos).Magnitude < distance - 2 then
        return false
    end
    return true
end

local function isgrounded(hrp)
    local rayparams = RaycastParams.new()
    rayparams.FilterDescendantsInstances = {localplayer.Character}
    rayparams.FilterType = Enum.RaycastFilterType.Exclude
    
    local ray = workspace:Raycast(hrp.Position, v3(0, -3, 0), rayparams)
    return ray ~= nil
end

local function simulate(p0, v0)
    local positions = {}
    local prev = p0
    local landed = nil
    
    local rayparams = RaycastParams.new()
    rayparams.FilterDescendantsInstances = {localplayer.Character}
    rayparams.FilterType = Enum.RaycastFilterType.Exclude
    
    for t = 0, 2.5, 0.03 do
        local pos = predictpos(p0, v0, t)
        insert(positions, pos)
        
        local dir = pos - prev
        if dir.Magnitude > 0.01 then
            local ray = workspace:Raycast(prev, dir, rayparams)
            if ray then
                landed = ray.Position
                break
            end
        end
        
        prev = pos
    end
    
    if not landed and #positions > 0 then
        local last = positions[#positions]
        local down = workspace:Raycast(last + v3(0, 1, 0), v3(0, -5000, 0), rayparams)
        if down then
            landed = down.Position
        end
    end
    
    return positions, landed
end

local userinputservice = game:GetService("UserInputService")
userinputservice.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.H then
        prejumpenabled = not prejumpenabled
        print(prejumpenabled and "on" or "off")
    end
end)

local pulsetime = 0
local conn
conn = runservice.RenderStepped:Connect(function(dt)
    pulsetime = pulsetime + dt
    
    local char = localplayer.Character
    if not char or not char.Parent then return end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not hrp or not hum then return end
    
    local p0 = hrp.Position
    local v0 = hrp.AssemblyLinearVelocity
    local grounded = isgrounded(hrp)
    
    local currentcf = camera.CFrame
    
    local relativecf = lastcameracf:Inverse() * currentcf
    local _, yaw, _ = relativecf:ToEulerAnglesXYZ()
    
    local turndir = yaw / max(dt, 0.001)
    
    cameraturnspeed = cameraturnspeed * 0.7 + turndir * 0.3
    
    lastcameracf = currentcf
    
    local wasairborne = isairborne
    isairborne = not grounded and v0.Y < -5
    
    if not wasairborne and isairborne then
        lastlanding = nil
    end
    
    if isairborne and grounded then
        lastlanding = nil
    end
    
    local pred3 = predictpos(p0, v0, 0.25)
    local pred2, predon = toscreen(pred3)
    preddot.Position = pred2
    preddot.Visible = predon and isvisible(pred3)
    
    if v0.Magnitude > 1 then
        local curvature = -cameraturnspeed * 0.8
        local vellength = min(v0.Magnitude * 0.5, 20)
        local segments = 8
        
        for i = 1, segments do
            local t0 = (i - 1) / segments
            local t1 = i / segments
            local offset0 = t0 * vellength
            local offset1 = t1 * vellength
            local curve0 = curvature * offset0 * offset0 * 0.06
            local curve1 = curvature * offset1 * offset1 * 0.06
            local dir = v0.Unit
            local up = v3(0, 1, 0)
            local right = dir:Cross(up).Unit
            local pos0 = p0 + dir * offset0 + right * curve0
            local pos1 = p0 + dir * offset1 + right * curve1
            local start2, starton = toscreen(pos0)
            local end2, endon = toscreen(pos1)
            local visible0 = isvisible(pos0)
            local visible1 = isvisible(pos1)
            velcurve[i].From = start2
            velcurve[i].To = end2
            velcurve[i].Visible = starton and endon and visible0 and visible1
        end
        
        velline.Visible = false
    else
        velline.Visible = false
        for i = 1, 8 do
            velcurve[i].Visible = false
        end
    end
    
    local positions, landing = simulate(p0, v0)
    if #positions > 1 then
        for i = 1, 29 do
            local idx1 = floor((i - 1) * (#positions - 1) / 29) + 1
            local idx2 = floor(i * (#positions - 1) / 29) + 1
            idx1 = clamp(idx1, 1, #positions)
            idx2 = clamp(idx2, 1, #positions)
            local pos1 = positions[idx1]
            local pos2 = positions[idx2]
            local s1, on1 = toscreen(pos1)
            local s2, on2 = toscreen(pos2)
            local midpoint = (pos1 + pos2) * 0.5
            local visible = isvisible(midpoint)
            
            arclines[i].From = s1
            arclines[i].To = s2
            arclines[i].Visible = on1 and on2 and visible
        end
    else
        for i = 1, 29 do
            arclines[i].Visible = false
        end
    end
    
    if isairborne and landing then
        lastlanding = landing
    end
    
    if lastlanding and isairborne then
        local land2, landon = toscreen(lastlanding)
        
        landdot.Position = land2
        landdot.Visible = landon and isvisible(lastlanding)
        
        local pulse = abs(sin(pulsetime * 3))
        landoutline.Position = land2
        landoutline.Radius = 18 + pulse * 8
        landoutline.Transparency = 0.3 + pulse * 0.7
        landoutline.Visible = landon and isvisible(lastlanding)
    else
        landdot.Visible = false
        landoutline.Visible = false
    end
    
    if prejumpenabled and not isairborne then
        local camlook = camera.CFrame.LookVector
        local camright = camera.CFrame.RightVector
        
        local inputservice = game:GetService("UserInputService")
        local movevec = v3(0, 0, 0)
        
        if inputservice:IsKeyDown(Enum.KeyCode.W) then
            movevec = movevec + v3(camlook.X, 0, camlook.Z).Unit
        end
        if inputservice:IsKeyDown(Enum.KeyCode.S) then
            movevec = movevec - v3(camlook.X, 0, camlook.Z).Unit
        end
        if inputservice:IsKeyDown(Enum.KeyCode.A) then
            movevec = movevec - v3(camright.X, 0, camright.Z).Unit
        end
        if inputservice:IsKeyDown(Enum.KeyCode.D) then
            movevec = movevec + v3(camright.X, 0, camright.Z).Unit
        end
        
        if movevec.Magnitude > 0.1 then
            lastmoveinput = movevec.Unit
        end
        
        local walkspeed = hum.WalkSpeed or 16
        local futurevel = lastmoveinput * walkspeed
        
        local jumpvel = futurevel + v3(0, 50, 0)
        local prejumppositions, prejumplanding = simulate(p0, jumpvel)
        
        if #prejumppositions > 1 then
            for i = 1, 29 do
                local idx1 = floor((i - 1) * (#prejumppositions - 1) / 29) + 1
                local idx2 = floor(i * (#prejumppositions - 1) / 29) + 1
                idx1 = clamp(idx1, 1, #prejumppositions)
                idx2 = clamp(idx2, 1, #prejumppositions)
                
                local pos1 = prejumppositions[idx1]
                local pos2 = prejumppositions[idx2]
                
                local s1, on1 = toscreen(pos1)
                local s2, on2 = toscreen(pos2)
                
                local midpoint = (pos1 + pos2) * 0.5
                local visible = isvisible(midpoint)
                
                prejumplines[i].From = s1
                prejumplines[i].To = s2
                prejumplines[i].Visible = on1 and on2 and visible
            end
        else
            for i = 1, 29 do
                prejumplines[i].Visible = false
            end
        end
        
        if prejumplanding then
            local preland2, prelandon = toscreen(prejumplanding)
            
            prejumplanddot.Position = preland2
            prejumplanddot.Visible = prelandon and isvisible(prejumplanding)
        else
            prejumplanddot.Visible = false
        end
    else
        for i = 1, 29 do
            prejumplines[i].Visible = false
        end
        prejumplanddot.Visible = false
    end
end)

local function cleanup()
    if conn then
        conn:Disconnect()
    end
    preddot:Remove()
    landdot:Remove()
    landoutline:Remove()
    velline:Remove()
    for _, line in ipairs(velcurve) do
        line:Remove()
    end
    for _, line in ipairs(arclines) do
        line:Remove()
    end
    for _, line in ipairs(prejumplines) do
        line:Remove()
    end
    prejumplanddot:Remove()
end

localplayer.CharacterAdded:Connect(function(char)
    char:WaitForChild("Humanoid").Died:Connect(cleanup)
end);print("\ncyan = predicted pos\nyellow = trajectory\ngreen = velocity\nred = landing spot");print("click H for pre jump arc")