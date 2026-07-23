--[[
	Настроено: Мятный графит, минимализм
]]
getgenv().ghost_rgb = false -- Выключили вырвиглазную радугу
getgenv().ghost_strength = 1
getgenv().ghost_max_limb = 6

local custom_color = Color3.fromRGB(150, 255, 200) -- Тот самый мягкий мятный

local game=game
local osclock=os.clock
local e=Enum
local i=Instance.new
local min=math.min
local cf=CFrame.new
local v3=vector.create
local c3=Color3.new

local players=game:GetService("Players")
local rs=game:GetService("RunService")
local stats=game:GetService("Stats")
local plr=players.LocalPlayer
plr.Archivable=true

local part_names={
	"HumanoidRootPart","Head","Left Arm","Right Arm","Left Leg","Right Leg",
	"LeftUpperArm","RightUpperArm","LeftLowerArm","RightLowerArm",
	"LeftHand","RightHand","LeftUpperLeg","RightUpperLeg",
	"LeftLowerLeg","RightLowerLeg","LeftFoot","RightFoot"
}

local function rgb(t)
	return Color3.fromHSV((t%5)/5,1,1)
end

local function make_ghost(real)
	local g=i("Part")
	g.Name=real.Name.."_ghost"
	g.Size=real.Size
	g.Anchored=true
	g.CanCollide=false
	g.Transparency=1
	g.CFrame=real.CFrame
	g.Parent=workspace
	local b=i("SelectionBox")
	b.Adornee=g
	b.LineThickness=0.02 -- Сделал линии чуть тоньше для эстетики
	b.Parent=g
	return{real=real,ghost=g,box=b}
end

local function is_replicate(p)
	return p and not p.Anchored
end

local function is_owner(p)
	return p and p.ReceiveAge==0
end

local function setup()
	local char=plr.Character
	if not char then return end
	for _,o in ipairs(workspace:GetChildren()) do
		if o:IsA("Part") and o.Name:find("_ghost$") then o:Destroy() end
	end
	local hum=char:FindFirstChildWhichIsA("Humanoid")
	local hrp=char:FindFirstChild("HumanoidRootPart")
	if not hum or not hrp then return end

	local ghosts={}
	for _,n in ipairs(part_names) do
		local p=char:FindFirstChild(n)
		if p and p:IsA("BasePart") then
			ghosts[n]=make_ghost(p)
		end
	end

	local server_cf=hrp.CFrame
	local lin_vel=v3(0,0,0)
	local last=osclock()
	local acc=0
	local frames={}
	local hb

	hb=rs.Heartbeat:Connect(function(dt)
		if not hrp or not hrp.Parent then
			for _,g in pairs(ghosts) do if g.ghost then g.ghost:Destroy() end end
			hb:Disconnect()
			return
		end

		local now=osclock()
		local delta=now-last
		last=now

		local ping=plr.GetNetworkPing and plr:GetNetworkPing() or 0.08

		if is_replicate(hrp) then
			if is_owner(hrp) then
				lin_vel=hrp.AssemblyLinearVelocity
			else
				lin_vel=-hrp.AssemblyLinearVelocity
			end
			if acc>=ping then
				server_cf=hrp.CFrame
				acc=0
			else
				acc=acc+delta
			end
		end

		local hrp_cf=server_cf
		local hrp_pos=hrp_cf.Position
		local rel={}
		for n,g in pairs(ghosts) do
			if g.real and g.real.Parent then
				rel[n]=hrp_cf:ToObjectSpace(g.real.CFrame)
			end
		end

		table.insert(frames,{t=now,cf=hrp_cf,pos=hrp_pos,vel=lin_vel,rel=rel})
		if #frames>240 then for i=1,60 do table.remove(frames,1) end end

		local target_t=now-ping
		local f
		for i=#frames,1,-1 do if frames[i].t<=target_t then f=frames[i] break end end
		if not f then f=frames[1] end
		if not f then return end

		local td=min(target_t-f.t,0.06)
		local pred_pos=f.pos+f.vel*td*getgenv().ghost_strength
		local pred_cf=cf(pred_pos)*(f.cf-f.cf.Position)

		for n,g in pairs(ghosts) do
			local ghost=g.ghost
			local box=g.box
			local r=f.rel[n]
			local tgt=r and pred_cf*r or (g.real and g.real.CFrame or ghost.CFrame)
			local d=(tgt.Position-pred_cf.Position).Magnitude
			if d>getgenv().ghost_max_limb then
				local dir=(tgt.Position-pred_cf.Position).Unit
				local p=pred_cf.Position+dir*getgenv().ghost_max_limb
				local rx,ry,rz=tgt:ToEulerAnglesXYZ()
				tgt=cf(p)*CFrame.Angles(rx,ry,rz)
			end
			ghost.CFrame=ghost.CFrame:Lerp(tgt,min(delta*18,1))
            
			-- Применяем наш мягкий цвет
			if getgenv().ghost_rgb then
				box.Color3=rgb(now)
			else
				box.Color3=custom_color
			end
		end
	end)
end

if plr.Character then setup() end
plr.CharacterAdded:Connect(function()
	plr.Character:WaitForChild("HumanoidRootPart",3)
	task.wait(0.2)
	setup()
end)
