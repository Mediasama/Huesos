local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()
task.wait(0.5)
local Options = Library.Options
local Toggles = Library.Toggles
-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local LocalCharacter = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local LocalHumanoidRootPart = LocalCharacter:WaitForChild("HumanoidRootPart")
local mouse = LocalPlayer:GetMouse()
-- === PERFECT HUMAN-LIKE REACTION TIME & LOGIC ===
local PerceivedPos = nil
local PerceivedVel = Vector3.new()
local LastUpdateTimeX = 0
local LastUpdateTimeY = 0
local ReactionDelayX = 0.5
local ReactionDelayY = 0.5
local TargetReactionDelay = 0.5
local JustLocked = true
local CurrentLockedTarget = nil
local TargetSwitchTimer = 0
local PendingTarget = nil
local Window = Library:CreateWindow({
    Title = "v1",
    Footer = "v1",
    NotifySide = "Right",
    ShowCustomCursor = false,
})
local Tabs = {
    Combat = Window:AddTab("Combat", "crosshair"),
    Whitelist = Window:AddTab("Whitelist", "shield"),
    Misc = Window:AddTab("Miscellaneous", "cog"),
    User = Window:AddTab("User", "user"),
    ["UI Settings"] = Window:AddTab("UI Settings", "settings"),
}
-- ============================================================
-- UNIVERSAL SILENT AIM HELPERS
-- ============================================================
local ExpectedArguments = {
    FindPartOnRayWithIgnoreList = {
        ArgCountRequired = 3,
        Args = { "Instance", "Ray", "table", "boolean", "boolean" }
    },
    FindPartOnRayWithWhitelist = {
        ArgCountRequired = 3,
        Args = { "Instance", "Ray", "table", "boolean" }
    },
    FindPartOnRay = {
        ArgCountRequired = 2,
        Args = { "Instance", "Ray", "Instance", "boolean", "boolean" }
    },
    Raycast = {
        ArgCountRequired = 3,
        Args = { "Instance", "Vector3", "Vector3", "RaycastParams" }
    }
}
local function CalculateChance(Percentage)
    Percentage = math.floor(Percentage)
    local chance = math.floor(Random.new().NextNumber(Random.new(), 0, 1) * 100) / 100
    return chance <= Percentage / 100
end
local function ValidateArguments(Args, RayMethod)
    local Matches = 0
    if #Args < RayMethod.ArgCountRequired then
        return false
    end
    for Pos, Argument in next, Args do
        if typeof(Argument) == RayMethod.Args[Pos] then
            Matches = Matches + 1
        end
    end
    return Matches >= RayMethod.ArgCountRequired
end
local function getDirection(Origin, Position)
    return (Position - Origin).Unit * 1000
end
-- ============================================================
-- GUI SETUP
-- ============================================================
-- Aimbot Group
local AimbotGroup = Tabs.Combat:AddLeftGroupbox("Aim")
AimbotGroup:AddToggle("AimbotEnabled", {
    Text = "Aimbot",
    Default = false,
    Callback = function(value)
        if FOVCircle then
            FOVCircle.Visible = value and Toggles.FovVisible.Value
        end
    end,
})
AimbotGroup:AddToggle("TeamCheck", { Text = "Team Check", Default = true })
AimbotGroup:AddToggle("WallCheck", { Text = "Wall Check", Default = true })
AimbotGroup:AddToggle("HealthCheck", { Text = "Health Check", Default = true })
AimbotGroup:AddToggle("ForceFieldCheck", { Text = "ForceField Check", Default = true })
AimbotGroup:AddSlider("MinHealth", {
    Text = "Min Health to Aim",
    Default = 0,
    Min = 0,
    Max = 100,
    Rounding = 0,
})
AimbotGroup:AddLabel("Aimbot Key"):AddKeyPicker("AimbotKeybind", {
    Default = "Q",
    Mode = "Hold",
    Text = "Press to aim (hold)",
    DefaultModifiers = {},
})
AimbotGroup:AddDivider()
AimbotGroup:AddDropdown("AimMethod", {
    Values = { "Mouse", "Camera" },
    Default = 1,
    Text = "Aim Method",
})
-- START OF THIRD-PERSON LOCK INTEGRATION (GUI)
AimbotGroup:AddToggle("ThirdPersonLock", { Text = "Third Person Lock", Default = false })
AimbotGroup:AddSlider("LockDistance", { Text = "Lock Distance", Default = 10, Min = 5, Max = 50, Rounding = 1 })  -- Расстояние камеры от цели
AimbotGroup:AddSlider("LockHeight", { Text = "Lock Height Offset", Default = 2, Min = 0, Max = 10, Rounding = 1 })  -- Высота над целью
AimbotGroup:AddSlider("LockSmooth", { Text = "Lock Smoothness", Default = 0.1, Min = 0.01, Max = 0.5, Rounding = 3 })  -- Плавность (меньше = быстрее)
-- END OF THIRD-PERSON LOCK INTEGRATION (GUI)
AimbotGroup:AddSlider("Prediction", {
    Text = "Prediction",
    Default = 0.165,
    Min = 0,
    Max = 0.5,
    Rounding = 3,
})
AimbotGroup:AddSlider("ReactionTimeX", {
    Text = "X ms",
    Default = 500,
    Min = 0,
    Max = 1000,
    Rounding = 0,
    Callback = function(val)
        ReactionDelayX = val / 1000
        TargetReactionDelay = (ReactionDelayX + ReactionDelayY) / 2
    end
})
AimbotGroup:AddSlider("ReactionTimeY", {
    Text = "Y ms",
    Default = 500,
    Min = 0,
    Max = 1000,
    Rounding = 0,
    Callback = function(val)
        ReactionDelayY = val / 1000
        TargetReactionDelay = (ReactionDelayX + ReactionDelayY) / 2
    end
})
-- NEW SNAP BACK SLIDER
AimbotGroup:AddSlider("SnapBackSpeed", {
    Text = "Snap Back Speed",
    Default = 3,
    Min = 1,
    Max = 20,
    Rounding = 1,
    Tooltip = "Lower = Faster Snap. Used when catching up to target."
})
AimbotGroup:AddSlider("XSmoothness", {
    Text = "X Smoothness",
    Default = 5,
    Min = 1,
    Max = 20,
})
AimbotGroup:AddSlider("YSmoothness", {
    Text = "Y Smoothness",
    Default = 5,
    Min = 1,
    Max = 20,
})
AimbotGroup:AddSlider("MaxDistance", {
    Text = "Aim Distance",
    Default = 500,
    Min = 50,
    Max = 2000,
})
AimbotGroup:AddDivider()
AimbotGroup:AddDropdown("AimPart", {
    Values = { "Head", "UpperTorso", "HumanoidRootPart" },
    Default = 1,
    Text = "AimPart",
})
AimbotGroup:AddLabel("Fov Color"):AddColorPicker("FovColor", {
    Default = Color3.new(1,1,1),
})
AimbotGroup:AddDivider()
AimbotGroup:AddSlider("FOVRadius", {
    Text = "FOV Size",
    Default = 130,
    Min = 10,
    Max = 500,
})
AimbotGroup:AddToggle("FovVisible", {
    Text = "Show FOV Circle",
    Default = true,
    Callback = function(val)
        if FOVCircle then
            FOVCircle.Visible = Toggles.AimbotEnabled.Value and val
        end
    end,
})
AimbotGroup:AddToggle("RainbowFov", {
    Text = "Rainbow FOV",
    Default = false,
})
-- Prediction Foreshadow Settings
AimbotGroup:AddDivider()
AimbotGroup:AddToggle("PredictionForeshadow", {
    Text = "Prediction Foreshadow",
    Default = false,
})
AimbotGroup:AddLabel("Ghost Color"):AddColorPicker("GhostColor", {
    Default = Color3.fromRGB(120, 120, 120),
})
AimbotGroup:AddSlider("GhostTransparency", {
    Text = "Ghost Transparency",
    Default = 0.5,
    Min = 0,
    Max = 1,
    Rounding = 2,
})
local WhitelistGroup = Tabs.Whitelist:AddLeftGroupbox("Whitelists")
WhitelistGroup:AddDropdown("PlayerWhitelist", {
    SpecialType = "Player",
    ExcludeLocalPlayer = true,
    Multi = true,
    Text = "Player Whitelist",
    Tooltip = "Whitelisted players cannot be aimed at",
})
WhitelistGroup:AddDropdown("TeamWhitelist", {
    SpecialType = "Team",
    Multi = true,
    Text = "Team Whitelist",
    Tooltip = "Whitelisted teams cannot be aimed at",
})
WhitelistGroup:AddDivider()
WhitelistGroup:AddLabel("ESP Whitelists")
WhitelistGroup:AddDropdown("ESPPlayerWhitelist", {
    SpecialType = "Player",
    ExcludeLocalPlayer = true,
    Multi = true,
    Text = "ESP Player Whitelist",
    Tooltip = "Whitelisted players will not show on ESP",
})
WhitelistGroup:AddDropdown("ESPTeamWhitelist", {
    SpecialType = "Team",
    Multi = true,
    Text = "ESP Team Whitelist",
    Tooltip = "Whitelisted teams will not show on ESP",
})
-- Misc Group
local MiscGroup = Tabs.Misc:AddLeftGroupbox("Miscellaneous")
MiscGroup:AddToggle("AimNPCs", { Text = "Aim NPCs", Default = false })
MiscGroup:AddToggle("InfDistance", { Text = "Infinite Distance", Default = false })
MiscGroup:AddToggle("AimVisibleParts", { Text = "Aim Visible Parts", Default = false })
MiscGroup:AddToggle("OutwallAim", { Text = "Outwall Aim", Default = false })
-- Full Bright Implementation
local Lighting = game:GetService("Lighting")
local OriginalLighting = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    Ambient = Lighting.Ambient
}
MiscGroup:AddToggle("FullBright", {
    Text = "Full Bright",
    Default = false,
    Callback = function(Value)
        if Value then
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.FogEnd = 100000
            Lighting.Ambient = Color3.new(1,1,1)
        else
            Lighting.Brightness = OriginalLighting.Brightness
            Lighting.ClockTime = OriginalLighting.ClockTime
            Lighting.FogEnd = OriginalLighting.FogEnd
            Lighting.Ambient = OriginalLighting.Ambient
        end
    end
})
-- Visuals Group
local VisualsGroup = Tabs.Combat:AddRightGroupbox("Visuals")
VisualsGroup:AddToggle("ESPEnabled", {
    Text = "Enable ESP",
    Default = false,
    Callback = function(value)
        if not value then
            for _, comp in pairs(espInstance.espCache) do
                espInstance:hideComponents(comp)
            end
        end
    end,
})
VisualsGroup:AddToggle("ESPBox", { Text = "Box", Default = true })
VisualsGroup:AddLabel("Box Color"):AddColorPicker("ESPBoxColor", { Default = Color3.new(1,1,1) })
VisualsGroup:AddToggle("ESPBoxFilled", { Text = "Fill Box", Default = false })
VisualsGroup:AddLabel("Filled Box Color"):AddColorPicker("ESPBoxFillColor", { Default = Color3.new(1,0,0) })
VisualsGroup:AddSlider("ESPBoxFillTransparency", {
    Text = "Fill Box Transparency",
    Default = 0.5,
    Min = 0,
    Max = 1,
    Rounding = 2,
})
VisualsGroup:AddToggle("ESPTracer", { Text = "Tracer", Default = true })
VisualsGroup:AddToggle("ESPName", { Text = "Name", Default = true })
VisualsGroup:AddToggle("ESPDistance", { Text = "Distance", Default = true })
VisualsGroup:AddToggle("ESPHealth", { Text = "Health Bar", Default = true })
VisualsGroup:AddToggle("ESPTool", { Text = "Tool", Default = true })
VisualsGroup:AddToggle("ESPSkeleton", { Text = "Skeleton", Default = false })
VisualsGroup:AddToggle("ESPHideTeam", { Text = "Hide Teammates", Default = true })
VisualsGroup:AddDivider()
VisualsGroup:AddLabel("ESP Color"):AddColorPicker("ESPColor", { Default = Color3.new(1,1,1) })
VisualsGroup:AddToggle("RainbowESP", { Text = "Rainbow ESP", Default = false })
VisualsGroup:AddToggle("ChamsEnabled", {
    Text = "Chams",
    Default = false,
})
-- Legit / Blantant Tabs inside Combat
local TabBox = Tabs.Combat:AddRightTabbox("Legit / Blantant")
-- Legit Tab
local LegitTab = TabBox:AddTab("Legit")
LegitTab:AddToggle("StickyAim", { Text = "Sticky Aim", Default = false })
LegitTab:AddToggle("StickyWallCheck", { Text = "Sticky Wall Check", Default = false })
LegitTab:AddToggle("SwitchPart", { Text = "Switch Part", Default = false })
LegitTab:AddSlider("SwitchPartSpeed", {
    Text = "Switch Part Speed",
    Default = 0.1,
    Min = 0,
    Max = 1,
    Rounding = 2,
})
LegitTab:AddToggle("TriggerDistanceCheck", { Text = "Trigger Distance Check", Default = false })
LegitTab:AddSlider("TriggerMaxDistance", {
    Text = "Trigger Max Distance",
    Default = 500,
    Min = 50,
    Max = 2000,
})
LegitTab:AddToggle("TriggerbotEnabled", { Text = "Triggerbot", Default = false })
LegitTab:AddToggle("TriggerbotWallCheck", { Text = "Triggerbot Wall Check", Default = false })
LegitTab:AddLabel("Triggerbot Key"):AddKeyPicker("TriggerbotKeybind", {
    Default = "E",
    Mode = "Hold",
    Text = "Press to trigger (hold)",
    DefaultModifiers = {},
})
-- Blantant Tab
local BlantantTab = TabBox:AddTab("Blantant")
BlantantTab:AddToggle("SilentAim", { Text = "Silent Aim", Default = false })
BlantantTab:AddDropdown("SilentMethod", {
    Values = { "Raycast", "FindPartOnRay", "FindPartOnRayWithWhitelist", "FindPartOnRayWithIgnoreList", "Mouse.Hit/Target" },
    Default = "Raycast",
    Text = "Silent Method",
})
BlantantTab:AddSlider("SilentHitChance", {
    Text = "Hit Chance",
    Default = 100,
    Min = 0,
    Max = 100,
    Rounding = 0,
})
-- User Tab
local UserGroup = Tabs.User:AddLeftGroupbox("User Information")
UserGroup:AddLabel("Player executor: " .. (identifyexecutor() or "Unknown"))
UserGroup:AddLabel("Username: " .. LocalPlayer.Name)
UserGroup:AddLabel("Profile Name: " .. LocalPlayer.DisplayName)
local creationTime = os.time() - (LocalPlayer.AccountAge * 86400)
local creationDate = os.date("%Y-%m-%d", creationTime)
UserGroup:AddLabel("Account created: " .. creationDate)
LocalPlayer.CharacterAdded:Connect(function(char)
    LocalCharacter = char
    LocalHumanoidRootPart = char:WaitForChild("HumanoidRootPart")
end)
-- Initialize mouse behavior
UserInputService.MouseBehavior = Enum.MouseBehavior.Default
UserInputService.MouseIconEnabled = true
-- Mouse Lock Fix
local function updateMouseLock()
    local character = LocalPlayer.Character
    if not character then return end
    local head = character:FindFirstChild("Head")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not head or not humanoid then return end
  
    local isFirstPerson = (Camera.CFrame.Position - head.Position).Magnitude < 1
    local isRagdolled = humanoid:GetState() == Enum.HumanoidStateType.Physics
    local isShiftLock = not isRagdolled and humanoid.AutoRotate == false
    local rightClickPressed = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
  
    if isRagdolled then
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
    elseif isFirstPerson then
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        UserInputService.MouseIconEnabled = true
    elseif isShiftLock then
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        UserInputService.MouseIconEnabled = false
    else
        if not rightClickPressed then
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
            UserInputService.MouseIconEnabled = true
        end
    end
end
-- Helper: extremely robust check for dropdown/multi selection values
local function selectionContains(selection, value)
    if selection == nil then return false end
    if selection == value then return true end
    local targetName = nil
    local targetUserId = nil
    local targetTeamName = nil
    local targetIsPlayer = false
    local targetIsTeam = false
    if typeof(value) == "Instance" then
        if value:IsA("Player") then
            targetIsPlayer = true
            targetName = value.Name
            targetUserId = value.UserId
        elseif value:IsA("Team") then
            targetIsTeam = true
            targetTeamName = value.Name
        else
            targetName = value.Name
        end
    else
        targetName = tostring(value)
        local n = tonumber(value)
        if n then targetUserId = n end
    end
    local tsel = typeof(selection)
    if tsel == "string" or tsel == "number" then
        if tostring(selection) == tostring(value) then return true end
    end
    if typeof(selection) == "Instance" then
        if selection:IsA("Player") and targetIsPlayer then
            if selection.UserId == targetUserId or selection.Name == targetName then return true end
        end
        if selection:IsA("Team") and targetIsTeam then
            if selection.Name == targetTeamName then return true end
        end
    end
    local hasNumericKey = false
    if type(selection) == "table" then
        for k,_ in pairs(selection) do
            if type(k) == "number" then
                hasNumericKey = true
                break
            end
        end
    end
    if hasNumericKey then
        for _, entry in ipairs(selection) do
            if typeof(entry) == "Instance" then
                if entry:IsA("Player") and targetIsPlayer then
                    if entry.UserId == targetUserId or entry.Name == targetName then return true end
                elseif entry:IsA("Team") and targetIsTeam then
                    if entry.Name == targetTeamName then return true end
                else
                    if tostring(entry) == tostring(value) then return true end
                end
            elseif type(entry) == "table" then
                for k,v in pairs(entry) do
                    if type(k) == "string" and k == targetName then return true end
                    if tostring(v) == targetName then return true end
                    local num = tonumber(v)
                    if num and targetUserId and num == targetUserId then return true end
                end
            else
                if tostring(entry) == targetName then return true end
                local n = tonumber(entry)
                if n and targetUserId and n == targetUserId then return true end
            end
        end
        return false
    end
    if type(selection) == "table" then
        for k,v in pairs(selection) do
            if typeof(k) == "Instance" and k:IsA("Player") then
                if targetIsPlayer and (k.UserId == targetUserId or k.Name == targetName) then return true end
            end
            if typeof(k) == "Instance" and k:IsA("Team") then
                if targetIsTeam and k.Name == targetTeamName then return true end
            end
            if type(k) == "string" then
                if targetIsPlayer and k == targetName then return true end
                if targetIsTeam and k == targetTeamName then return true end
            end
            if typeof(v) == "Instance" then
                if v:IsA("Player") and targetIsPlayer then
                    if v.UserId == targetUserId or v.Name == targetName then return true end
                elseif v:IsA("Team") and targetIsTeam then
                    if v.Name == targetTeamName then return true end
                end
            else
                if tostring(v) == targetName then return true end
                local num = tonumber(v)
                if num and targetUserId and num == targetUserId then return true end
            end
        end
    end
    return false
end
-- ============================================
-- HELPER: GET AIM PART (HANDLES R6/R15 NPC/PLAYER)
-- ============================================
local function getAimPart(character)
    if not character then return nil end
    local partName = Options.AimPart.Value
    local part = character:FindFirstChild(partName)
   
    -- Fallback for R6 NPCs/Players who don't have UpperTorso
    if not part then
        if partName == "UpperTorso" then
            part = character:FindFirstChild("Torso")
        elseif partName == "LowerTorso" then
            part = character:FindFirstChild("Torso")
        end
    end
    return part
end
local function isVisible(part)
    if not Toggles.WallCheck.Value or not part then return true end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = {LocalPlayer.Character}
    local origin = Camera.CFrame.Position
    local direction = (part.Position - origin).Unit * (part.Position - origin).Magnitude
    local result = workspace:Raycast(origin, direction, params)
    if not result then return true end
    return result.Instance:IsDescendantOf(part.Parent)
end
-- ============================================
-- UNIVERSAL SILENT AIM TARGET SELECTOR (Modified for V1)
-- ============================================
local function getClosestTarget()
    local closest, closestDist = nil, Options.FOVRadius.Value -- Use GUI FOV Radius
    local mousePos = UserInputService:GetMouseLocation()
   
    local function checkTarget(v)
         local part = getAimPart(v.Character or v)
         if not part then return end
         local pos, onScreen = Camera:WorldToScreenPoint(part.Position)
         if onScreen then
            local diff = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
            if diff < closestDist then
                closestDist = diff
                closest = part -- Return the PART, not the player, for easier use
            end
         end
    end
    -- Check Players
    for _, v in ipairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and v.Character then
            if Toggles.ForceFieldCheck.Value and v.Character:FindFirstChildOfClass("ForceField") then continue end
            if Toggles.TeamCheck.Value and LocalPlayer.Team and v.Team == LocalPlayer.Team then continue end
            local playerWL = (Options.PlayerWhitelist and Options.PlayerWhitelist.Value) or {}
            local teamWL = (Options.TeamWhitelist and Options.TeamWhitelist.Value) or {}
            if selectionContains(playerWL, v) then continue end
            if v.Team and selectionContains(teamWL, v.Team) then continue end
            if Toggles.HealthCheck.Value then
                local humanoid = v.Character:FindFirstChildOfClass("Humanoid")
                if not humanoid or humanoid.Health <= 0 then continue end
                if humanoid.Health < Options.MinHealth.Value then continue end
            end
            checkTarget(v)
        end
    end
   
    -- Check NPCs
    if Toggles.AimNPCs.Value then
        for _, npc in pairs(workspace:GetDescendants()) do
            if npc:IsA("Model") and npc:FindFirstChild("Humanoid") and npc:FindFirstChild("HumanoidRootPart") then
                 if npc == LocalCharacter then continue end
                 local player = Players:GetPlayerFromCharacter(npc)
                 if player then continue end
                
                 if Toggles.ForceFieldCheck.Value and npc:FindFirstChildOfClass("ForceField") then continue end
                 if Toggles.HealthCheck.Value then
                    local humanoid = npc:FindFirstChildOfClass("Humanoid")
                    if not humanoid or humanoid.Health <= 0 then continue end
                    if humanoid.Health < Options.MinHealth.Value then continue end
                 end
                 checkTarget(npc)
            end
        end
    end
   
    return closest
end
-- ============================================
-- UNIVERSAL SILENT AIM HOOKS
-- ============================================
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(...)
    local Method = getnamecallmethod()
    local Arguments = {...}
    local self = Arguments[1]
   
    if Toggles.SilentAim.Value and self == workspace and not checkcaller() then
        if CalculateChance(Options.SilentHitChance.Value) then
            local HitPart = getClosestTarget()
           
            if HitPart then
                if Method == "FindPartOnRayWithIgnoreList" and Options.SilentMethod.Value == Method then
                    if ValidateArguments(Arguments, ExpectedArguments.FindPartOnRayWithIgnoreList) then
                        local A_Ray = Arguments[2]
                        local Origin = A_Ray.Origin
                        local Direction = getDirection(Origin, HitPart.Position)
                        Arguments[2] = Ray.new(Origin, Direction)
                        return oldNamecall(unpack(Arguments))
                    end
                elseif Method == "FindPartOnRayWithWhitelist" and Options.SilentMethod.Value == Method then
                    if ValidateArguments(Arguments, ExpectedArguments.FindPartOnRayWithWhitelist) then
                        local A_Ray = Arguments[2]
                        local Origin = A_Ray.Origin
                        local Direction = getDirection(Origin, HitPart.Position)
                        Arguments[2] = Ray.new(Origin, Direction)
                        return oldNamecall(unpack(Arguments))
                    end
                elseif (Method == "FindPartOnRay" or Method == "findPartOnRay") and Options.SilentMethod.Value:lower() == Method:lower() then
                    if ValidateArguments(Arguments, ExpectedArguments.FindPartOnRay) then
                        local A_Ray = Arguments[2]
                        local Origin = A_Ray.Origin
                        local Direction = getDirection(Origin, HitPart.Position)
                        Arguments[2] = Ray.new(Origin, Direction)
                        return oldNamecall(unpack(Arguments))
                    end
                elseif Method == "Raycast" and Options.SilentMethod.Value == Method then
                    if ValidateArguments(Arguments, ExpectedArguments.Raycast) then
                        local A_Origin = Arguments[2]
                        Arguments[3] = getDirection(A_Origin, HitPart.Position)
                        return oldNamecall(unpack(Arguments))
                    end
                end
            end
        end
    end
    return oldNamecall(...)
end))
local oldIndex = nil
oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, Index)
    if self == mouse and not checkcaller() and Toggles.SilentAim.Value and Options.SilentMethod.Value == "Mouse.Hit/Target" then
        if CalculateChance(Options.SilentHitChance.Value) then
            local HitPart = getClosestTarget()
            if HitPart then
                if Index == "Target" or Index == "target" then
                    return HitPart
                elseif Index == "Hit" or Index == "hit" then
                    local velocity = HitPart.AssemblyLinearVelocity or Vector3.new(0,0,0)
                    return HitPart.CFrame + (velocity * Options.Prediction.Value)
                elseif Index == "X" or Index == "x" then
                    return self.X
                elseif Index == "Y" or Index == "y" then
                    return self.Y
                elseif Index == "UnitRay" then
                    return Ray.new(self.Origin, (self.Hit.Position - self.Origin).Unit)
                end
            end
        end
    end
    return oldIndex(self, Index)
end))
-- FOV Circle - THINNER
local FOVCircle
pcall(function()
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Thickness = 1 -- Thinner FOV circle
    FOVCircle.Filled = false
    FOVCircle.Transparency = 1
    FOVCircle.Color = Color3.new(1,1,1)
    FOVCircle.Visible = false
end)
-- ESP System
local ESP = {}
ESP.__index = ESP
function ESP.new()
    local self = setmetatable({}, ESP)
    self.espCache = {}
    return self
end
function ESP:createDrawing(type, props)
    local drawing = Drawing.new(type)
    for prop, val in pairs(props) do
        drawing[prop] = val
    end
    return drawing
end
function ESP:createComponents()
    return {
        BoxOutline = self:createDrawing("Square", {Thickness = 1, Transparency = 1, Color = Color3.fromRGB(0,0,0), Filled = false}),
        Box = self:createDrawing("Square", {Thickness = 1, Transparency = 1, Color = Color3.fromRGB(255,255,255), Filled = false}),
        Fill = self:createDrawing("Square", {Thickness = 1, Transparency = 1, Color = Color3.new(0,0,0), Filled = false}),
        Tracer = self:createDrawing("Line", {Thickness = 1, Transparency = 1, Color = Color3.fromRGB(255,255,255)}),
        DistanceLabel = self:createDrawing("Text", {Size = 18, Center = true, Outline = true, Color = Color3.fromRGB(255,255,255), OutlineColor = Color3.fromRGB(0,0,0)}),
        NameLabel = self:createDrawing("Text", {Size = 18, Center = true, Outline = true, Color = Color3.fromRGB(255,255,255), OutlineColor = Color3.fromRGB(0,0,0)}),
        HealthBar = {
            Outline = self:createDrawing("Square", {Thickness = 1, Transparency = 1, Color = Color3.fromRGB(0,0,0), Filled = false}),
            Health = self:createDrawing("Square", {Thickness = 1, Transparency = 1, Color = Color3.fromRGB(0,255,0), Filled = true}),
            Text = self:createDrawing("Text", {Size = 14, Center = true, Outline = true, Color = Color3.fromRGB(255,255,255), OutlineColor = Color3.fromRGB(0,0,0)})
        },
        ItemLabel = self:createDrawing("Text", {Size = 18, Center = true, Outline = true, Color = Color3.fromRGB(255,255,255), OutlineColor = Color3.fromRGB(0,0,0)}),
        SkeletonLines = {}
    }
end
local bodyConnections = {
    R15 = {
        {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
        {"LowerTorso","LeftUpperLeg"},{"LowerTorso","RightUpperLeg"},
        {"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
        {"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
        {"UpperTorso","LeftUpperArm"},{"UpperTorso","RightUpperArm"},
        {"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
        {"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"}
    },
    R6 = {
        {"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},{"Torso","Left Leg"},{"Torso","Right Leg"}
    }
}
function ESP:updateComponents(components, character, player, hue)
    local hrp = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local head = character:FindFirstChild("Head")
    if not hrp or not humanoid or not head then
        self:hideComponents(components)
        return
    end
    local espPlayerWL = (Options.ESPPlayerWhitelist and Options.ESPPlayerWhitelist.Value) or {}
    local espTeamWL = (Options.ESPTeamWhitelist and Options.ESPTeamWhitelist.Value) or {}
    if selectionContains(espPlayerWL, player) then
        self:hideComponents(components)
        return
    end
    if player.Team and selectionContains(espTeamWL, player.Team) then
        self:hideComponents(components)
        return
    end
    if Toggles.ESPHideTeam.Value and LocalPlayer.Team and player.Team == LocalPlayer.Team then
        self:hideComponents(components)
        return
    end
    local rigType = humanoid.RigType.Name
    local validParts = {}
    if rigType == "R15" then
        validParts = {"Head","UpperTorso","LowerTorso","LeftUpperArm","RightUpperArm","LeftLowerArm","RightLowerArm","LeftHand","RightHand","LeftUpperLeg","RightUpperLeg","LeftLowerLeg","RightLowerLeg","LeftFoot","RightFoot"}
    else
        validParts = {"Head","Torso","Left Arm","Right Arm","Left Leg","Right Leg"}
    end
    local corners = {}
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") and table.find(validParts, part.Name) then
            local pos = part.Position
            local size = part.Size
            for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
                table.insert(corners, pos + Vector3.new(size.X/2*x, size.Y/2*y, size.Z/2*z))
            end end end
        end
    end
    if #corners == 0 then self:hideComponents(components) return end
    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge
    local allOnScreen = true
    for _, corner in ipairs(corners) do
        local screenPos, onScreen = Camera:WorldToViewportPoint(corner)
        if onScreen then
            minX = math.min(minX, screenPos.X)
            minY = math.min(minY, screenPos.Y)
            maxX = math.max(maxX, screenPos.X)
            maxY = math.max(maxY, screenPos.Y)
        else
            allOnScreen = false
        end
    end
    if not allOnScreen or minX == math.huge then self:hideComponents(components) return end
    local hrpPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
    if not onScreen then self:hideComponents(components) return end
    local distance = (LocalHumanoidRootPart.Position - hrp.Position).Magnitude
    local width = maxX - minX
    local height = maxY - minY
    local espColor = Toggles.RainbowESP.Value and Color3.fromHSV(hue, 1, 1) or Options.ESPColor.Value
    local boxColor = Toggles.RainbowESP.Value and Color3.fromHSV(hue, 1, 1) or Options.ESPBoxColor.Value
    local fillColor = Toggles.RainbowESP.Value and Color3.fromHSV(hue, 1, 1) or Options.ESPBoxFillColor.Value
    components.BoxOutline.Visible = Toggles.ESPBox.Value
    if components.BoxOutline.Visible then
        components.BoxOutline.Size = Vector2.new(width + 4, height + 4)
        components.BoxOutline.Position = Vector2.new(minX - 2, minY - 2)
        components.BoxOutline.Color = Color3.fromRGB(0,0,0)
        components.BoxOutline.Transparency = 1
        components.BoxOutline.Thickness = 1
        components.BoxOutline.Filled = false
    end
    components.Fill.Visible = Toggles.ESPBox.Value and Toggles.ESPBoxFilled.Value
    if components.Fill.Visible then
        components.Fill.Size = Vector2.new(width, height)
        components.Fill.Position = Vector2.new(minX, minY)
        local darkFactor = 0.4
        components.Fill.Color = Color3.new(
            fillColor.R * darkFactor,
            fillColor.G * darkFactor,
            fillColor.B * darkFactor
        )
        components.Fill.Transparency = Options.ESPBoxFillTransparency.Value
        components.Fill.Thickness = 1
        components.Fill.Filled = true
    end
    components.Box.Visible = Toggles.ESPBox.Value
    if components.Box.Visible then
        components.Box.Size = Vector2.new(width, height)
        components.Box.Position = Vector2.new(minX, minY)
        components.Box.Filled = false
        components.Box.Color = boxColor
        components.Box.Transparency = 1
        components.Box.Thickness = 1
    end
    components.Tracer.Visible = Toggles.ESPTracer.Value
    if components.Tracer.Visible then
        components.Tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
        components.Tracer.To = Vector2.new(hrpPos.X, maxY)
        components.Tracer.Color = espColor
    end
    components.NameLabel.Visible = Toggles.ESPName.Value
    if components.NameLabel.Visible then
        components.NameLabel.Text = player.DisplayName or player.Name
        components.NameLabel.Position = Vector2.new(hrpPos.X, minY - 15)
        components.NameLabel.Color = espColor
    end
    components.DistanceLabel.Visible = Toggles.ESPDistance.Value
    if components.DistanceLabel.Visible then
        components.DistanceLabel.Text = string.format("[%dm]", math.floor(distance))
        components.DistanceLabel.Position = Vector2.new(hrpPos.X, maxY + 15)
        components.DistanceLabel.Color = espColor
    end
    components.HealthBar.Outline.Visible = Toggles.ESPHealth.Value
    components.HealthBar.Health.Visible = Toggles.ESPHealth.Value
    components.HealthBar.Text.Visible = Toggles.ESPHealth.Value
    if Toggles.ESPHealth.Value then
        local frac = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
        local outlineW = 6
        local healthW = 4
        components.HealthBar.Outline.Size = Vector2.new(outlineW, height)
        components.HealthBar.Outline.Position = Vector2.new(minX - (outlineW + 2), minY)
        components.HealthBar.Outline.Color = Color3.fromRGB(0,0,0)
        components.HealthBar.Outline.Thickness = 1
        components.HealthBar.Outline.Filled = false
        local healthH = math.max(1, math.floor(height * frac))
        local healthX = components.HealthBar.Outline.Position.X + 1
        local healthY = components.HealthBar.Outline.Position.Y + (height - healthH)
        components.HealthBar.Health.Size = Vector2.new(healthW, healthH)
        components.HealthBar.Health.Position = Vector2.new(healthX, healthY)
        local r = math.min(255, 510 * (1 - frac))
        local g = math.min(255, 510 * frac)
        components.HealthBar.Health.Color = Color3.fromRGB(r, g, 0)
        components.HealthBar.Health.Transparency = 1
        components.HealthBar.Health.Thickness = 1
        components.HealthBar.Health.Filled = true
        local healthText = tostring(math.floor(humanoid.Health))
        components.HealthBar.Text.Text = healthText
        components.HealthBar.Text.Position = Vector2.new(
            healthX + (components.HealthBar.Health.Size.X / 2),
            healthY + (components.HealthBar.Health.Size.Y / 2)
        )
        components.HealthBar.Text.Color = Color3.fromRGB(255,255,255)
    end
    components.ItemLabel.Visible = Toggles.ESPTool.Value
    if Toggles.ESPTool.Value then
        local tool = character:FindFirstChildOfClass("Tool") or (player.Backpack and player.Backpack:FindFirstChildOfClass("Tool"))
        components.ItemLabel.Text = tool and ("[Holding: "..tool.Name.."]") or "[No tool]"
        components.ItemLabel.Position = Vector2.new(hrpPos.X, maxY + 35)
        components.ItemLabel.Color = espColor
    end
    if Toggles.ESPSkeleton.Value then
        local connections = bodyConnections[humanoid.RigType.Name] or {}
        for _, conn in ipairs(connections) do
            local partA, partB = character:FindFirstChild(conn[1]), character:FindFirstChild(conn[2])
            if partA and partB then
                local posA, onA = Camera:WorldToViewportPoint(partA.Position)
                local posB, onB = Camera:WorldToViewportPoint(partB.Position)
                local key = conn[1].."-"..conn[2]
                local line = components.SkeletonLines[key]
                if not line then
                    line = self:createDrawing("Line", {Thickness = 1, Color = espColor})
                    components.SkeletonLines[key] = line
                end
                if onA and onB then
                    line.From = Vector2.new(posA.X, posA.Y)
                    line.To = Vector2.new(posB.X, posB.Y)
                    line.Color = espColor
                    line.Visible = true
                else
                    line.Visible = false
                end
            end
        end
    else
        for _, line in pairs(components.SkeletonLines) do line.Visible = false end
    end
end
function ESP:hideComponents(components)
    components.Box.Visible = false
    components.BoxOutline.Visible = false
    components.Fill.Visible = false
    components.Tracer.Visible = false
    components.DistanceLabel.Visible = false
    components.NameLabel.Visible = false
    components.HealthBar.Outline.Visible = false
    components.HealthBar.Health.Visible = false
    components.HealthBar.Text.Visible = false
    components.ItemLabel.Visible = false
    for _, line in pairs(components.SkeletonLines) do line.Visible = false end
end
function ESP:removeEsp(player)
    local comp = self.espCache[player]
    if not comp then return end
    comp.Box:Remove()
    comp.BoxOutline:Remove()
    comp.Fill:Remove()
    comp.Tracer:Remove()
    comp.DistanceLabel:Remove()
    comp.NameLabel:Remove()
    comp.ItemLabel:Remove()
    comp.HealthBar.Outline:Remove()
    comp.HealthBar.Health:Remove()
    comp.HealthBar.Text:Remove()
    for _, line in pairs(comp.SkeletonLines) do line:Remove() end
    self.espCache[player] = nil
end
local espInstance = ESP.new()
-- Chams System
local ChamHighlights = {}
local function updateChams(hue)
    local espPlayerWL = (Options.ESPPlayerWhitelist and Options.ESPPlayerWhitelist.Value) or {}
    local espTeamWL = (Options.ESPTeamWhitelist and Options.ESPTeamWhitelist.Value) or {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local character = player.Character
        if not character then
            if ChamHighlights[player] then
                ChamHighlights[player]:Destroy()
                ChamHighlights[player] = nil
            end
            continue
        end
        if selectionContains(espPlayerWL, player) then
            if ChamHighlights[player] then ChamHighlights[player].Enabled = false end
            continue
        end
        if player.Team and selectionContains(espTeamWL, player.Team) then
            if ChamHighlights[player] then ChamHighlights[player].Enabled = false end
            continue
        end
        if Toggles.ESPHideTeam.Value and LocalPlayer.Team and player.Team == LocalPlayer.Team then
            if ChamHighlights[player] then ChamHighlights[player].Enabled = false end
            continue
        end
        local highlight = ChamHighlights[player]
        if not highlight then
            highlight = Instance.new("Highlight")
            highlight.Parent = character
            ChamHighlights[player] = highlight
        end
        highlight.Adornee = character
        highlight.Enabled = true
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0
        local chamColor = Toggles.RainbowESP.Value and Color3.fromHSV(hue, 1, 1) or Options.ESPColor.Value
        highlight.FillColor = chamColor
        highlight.OutlineColor = chamColor
    end
end
Toggles.ChamsEnabled:OnChanged(function(value)
    if not value then
        for _, highlight in pairs(ChamHighlights) do
            if highlight then highlight:Destroy() end
        end
        ChamHighlights = {}
    end
end)
-- ==============================================================
-- PREDICTION FORESHADOW (GHOST CLONE) SYSTEM (OPTIMIZED)
-- ==============================================================
local GhostCharacter = nil
local GhostPartsCache = {}
local function ClearGhost()
    if GhostCharacter then
        GhostCharacter:Destroy()
        GhostCharacter = nil
    end
    GhostPartsCache = {}
end
local function UpdateGhost(target, predictedPos)
    if not target or not target:FindFirstChild("HumanoidRootPart") then
        ClearGhost()
        return
    end
    -- 1. Create Ghost if missing or target changed
    if not GhostCharacter or GhostCharacter.Name ~= target.Name .. "_Ghost" then
        ClearGhost()
        GhostCharacter = Instance.new("Model")
        GhostCharacter.Name = target.Name .. "_Ghost"
        GhostCharacter.Parent = workspace.CurrentCamera -- Client side only
        -- Clone visual parts only
        for _, v in pairs(target:GetChildren()) do
            if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
                local clone = v:Clone()
                clone:ClearAllChildren() -- Remove scripts/welds to prevent lag/interactions
                clone.Parent = GhostCharacter
                clone.Anchored = true
                clone.CanCollide = false
                clone.CanTouch = false
                clone.CanQuery = false
                clone.Material = Enum.Material.Plastic -- Plastic material
                clone.Color = Options.GhostColor.Value
                clone.Transparency = Options.GhostTransparency.Value
                clone.CastShadow = false
               
                -- Cache the mapping of original name -> clone part
                GhostPartsCache[v.Name] = clone
               
                if v:IsA("MeshPart") then
                    clone.TextureID = ""
                end
            end
        end
    end
    -- 2. Move Ghost to Predicted Position
    local currentHRP = target:FindFirstChild("HumanoidRootPart")
    if currentHRP then
        local currentPos = currentHRP.Position
        -- The offset from current player to predicted position
        local offset = predictedPos - currentPos
       
        -- Get Visual Settings
        local gColor = Options.GhostColor.Value
        local gTrans = Options.GhostTransparency.Value
        for origName, clonePart in pairs(GhostPartsCache) do
            local originalPart = target:FindFirstChild(origName)
            if originalPart then
                -- Apply the offset to every part's CFrame to maintain animation pose
                clonePart.CFrame = originalPart.CFrame + offset
                -- Update visuals live
                clonePart.Color = gColor
                clonePart.Transparency = gTrans
            end
        end
    end
end
-- Aimbot functions
-- EXPANDED BODY PARTS LIST TO INCLUDE R6 PARTS (Torso, Arms, Legs)
local bodyParts = {
    "Head", "UpperTorso", "LowerTorso", "HumanoidRootPart",
    "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm", "LeftHand", "RightHand",
    "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg", "LeftFoot", "RightFoot",
    "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg" -- R6 Parts
}
local function getClosestTarget()
    local closest, closestDist = nil, math.huge
    local mousePos = UserInputService:GetMouseLocation()
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local character = player.Character
        if not character then continue end
        if Toggles.ForceFieldCheck.Value and character:FindFirstChildOfClass("ForceField") then continue end
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end
        if Toggles.TeamCheck.Value and LocalPlayer.Team and player.Team == LocalPlayer.Team then continue end
        local playerWL = (Options.PlayerWhitelist and Options.PlayerWhitelist.Value) or {}
        local teamWL = (Options.TeamWhitelist and Options.TeamWhitelist.Value) or {}
        if selectionContains(playerWL, player) then continue end
        if player.Team and selectionContains(teamWL, player.Team) then continue end
        if Toggles.HealthCheck.Value then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if not humanoid or humanoid.Health <= 0 then continue end
            if humanoid.Health < Options.MinHealth.Value then continue end
        end
        local distance = (Camera.CFrame.Position - hrp.Position).Magnitude
        if not Toggles.InfDistance.Value and distance > Options.MaxDistance.Value then continue end
        local charBestDist = math.huge
        if Toggles.AimVisibleParts.Value then
            for _, partName in ipairs(bodyParts) do
                local part = character:FindFirstChild(partName)
                if part and isVisible(part) then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                    if onScreen then
                        local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                        if dist < charBestDist then
                            charBestDist = dist
                        end
                    end
                end
            end
        else
            local part = getAimPart(character)
            if part and isVisible(part) then
                local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    charBestDist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                end
            end
        end
        if charBestDist <= Options.FOVRadius.Value and charBestDist < closestDist then
            closest = character
            closestDist = charBestDist
        end
    end
    if Toggles.AimNPCs.Value then
        for _, npc in pairs(workspace:GetDescendants()) do
            if npc:IsA("Model") and npc:FindFirstChild("Humanoid") and npc:FindFirstChild("HumanoidRootPart") then
                if npc == LocalCharacter then continue end
                local playerFromChar = Players:GetPlayerFromCharacter(npc)
                if playerFromChar then continue end
               
                if Toggles.ForceFieldCheck.Value and npc:FindFirstChildOfClass("ForceField") then continue end
                if Toggles.HealthCheck.Value then
                    local humanoid = npc:FindFirstChildOfClass("Humanoid")
                    if not humanoid or humanoid.Health <= 0 then continue end
                    if humanoid.Health < Options.MinHealth.Value then continue end
                end
                local hrp = npc.HumanoidRootPart
                local distance = (Camera.CFrame.Position - hrp.Position).Magnitude
                if not Toggles.InfDistance.Value and distance > Options.MaxDistance.Value then continue end
                local charBestDist = math.huge
                if Toggles.AimVisibleParts.Value then
                    for _, partName in ipairs(bodyParts) do
                        local part = npc:FindFirstChild(partName)
                        if part and isVisible(part) then
                            local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                            if onScreen then
                                local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                                if dist < charBestDist then
                                    charBestDist = dist
                                end
                            end
                        end
                    end
                else
                    local part = getAimPart(npc)
                    if part and isVisible(part) then
                        local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                        if onScreen then
                            charBestDist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                        end
                    end
                end
                if charBestDist <= Options.FOVRadius.Value and charBestDist < closestDist then
                    closest = npc
                    closestDist = charBestDist
                end
            end
        end
    end
    return closest
end
local function isValidLockedTarget(targetChar)
    if not targetChar or not targetChar.Parent then return false end
    if Toggles.ForceFieldCheck.Value and targetChar:FindFirstChildOfClass("ForceField") then return false end
    local hrp = targetChar:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local humanoid = targetChar:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    if Toggles.HealthCheck.Value and humanoid.Health < Options.MinHealth.Value then return false end
    local distance = (Camera.CFrame.Position - hrp.Position).Magnitude
    if not Toggles.InfDistance.Value and distance > Options.MaxDistance.Value then return false end
    local player = Players:GetPlayerFromCharacter(targetChar)
    if player then
        if Toggles.TeamCheck.Value and LocalPlayer.Team and player.Team == LocalPlayer.Team then return false end
        local playerWL = (Options.PlayerWhitelist and Options.PlayerWhitelist.Value) or {}
        local teamWL = (Options.TeamWhitelist and Options.TeamWhitelist.Value) or {}
        if selectionContains(playerWL, player) then return false end
        if player.Team and selectionContains(teamWL, player.Team) then return false end
    end
    return true
end
-- Aimbot & Triggerbot toggle states
local lockedTarget = nil
local stickyTarget = nil
local Clicked = false
local Target = nil
-- Main RenderStepped loop
local hue = 0
RunService.RenderStepped:Connect(function(dt)
    hue = (hue + dt * 0.25) % 1
    updateMouseLock()
  
    local mousePos = UserInputService:GetMouseLocation()
  
    if FOVCircle then
        FOVCircle.Position = mousePos
        FOVCircle.Radius = Options.FOVRadius.Value
        FOVCircle.Visible = Toggles.AimbotEnabled.Value and Toggles.FovVisible.Value
        if Toggles.RainbowFov.Value then
            FOVCircle.Color = Color3.fromHSV(hue,1,1)
        else
            FOVCircle.Color = Options.FovColor.Value
        end
    end
    if Toggles.ESPEnabled.Value then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local character = player.Character
                if character then
                    if not espInstance.espCache[player] then
                        espInstance.espCache[player] = espInstance:createComponents()
                    end
                    espInstance:updateComponents(espInstance.espCache[player], character, player, hue)
                end
            end
        end
    else
        for _, comp in pairs(espInstance.espCache) do espInstance:hideComponents(comp) end
    end
    if Toggles.ChamsEnabled.Value then
        updateChams(hue)
    end
    local triggerActive = Toggles.TriggerbotEnabled.Value
    if triggerActive then
        local targetPart = mouse.Target
        if targetPart then
            local char = targetPart.Parent
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if not humanoid then
                char = targetPart.Parent.Parent
                humanoid = char:FindFirstChildOfClass("Humanoid")
            end
            if humanoid and humanoid.Health > 0 and char.Name ~= LocalPlayer.Name then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if not hrp then
                    if Clicked then
                        mouse1release()
                        Clicked = false
                    end
                else
                    local playerFromChar = Players:GetPlayerFromCharacter(char)
                    local shouldShoot = true
                    if Toggles.ForceFieldCheck.Value and char:FindFirstChildOfClass("ForceField") then
                        shouldShoot = false
                    end
                    if playerFromChar then
                        if Toggles.TeamCheck.Value and LocalPlayer.Team and playerFromChar.Team == LocalPlayer.Team then
                            shouldShoot = false
                        end
                        local playerWL = (Options.PlayerWhitelist and Options.PlayerWhitelist.Value) or {}
                        local teamWL = (Options.TeamWhitelist and Options.TeamWhitelist.Value) or {}
                        if selectionContains(playerWL, playerFromChar) then
                            shouldShoot = false
                        end
                        if playerFromChar.Team and selectionContains(teamWL, playerFromChar.Team) then
                            shouldShoot = false
                        end
                    end
                    local dist = (LocalHumanoidRootPart.Position - hrp.Position).Magnitude
                    if Toggles.TriggerDistanceCheck.Value and dist > Options.TriggerMaxDistance.Value then
                        shouldShoot = false
                    end
                    local visible = not Toggles.TriggerbotWallCheck.Value or isVisible(targetPart)
                    if not visible then
                        shouldShoot = false
                    end
                    if shouldShoot then
                        if not Clicked then
                            mouse1press()
                            Clicked = true
                        end
                    else
                        if Clicked then
                            mouse1release()
                            Clicked = false
                        end
                    end
                end
            else
                if Clicked then
                    mouse1release()
                    Clicked = false
                end
            end
        else
            if Clicked then
                mouse1release()
                Clicked = false
            end
        end
    else
        if Clicked then
            mouse1release()
            Clicked = false
        end
    end
    if not Toggles.AimbotEnabled.Value then
        Target = nil
        lockedTarget = nil
        stickyTarget = nil
        CurrentLockedTarget = nil
        PerceivedPos = nil
        PerceivedVel = Vector3.new()
        JustLocked = true
        ClearGhost() -- Cleanup ghost
        -- END OF RENDERSTEPPED FOR AIMBOT DISABLED
        if Camera.CameraType == Enum.CameraType.Scriptable then
            Camera.CameraType = Enum.CameraType.Custom -- Always reset camera if Aimbot is off
        end
        return
    end
    local aimbotActive = false
    if Options.AimbotKeybind and type(Options.AimbotKeybind.GetState) == "function" then
        aimbotActive = Options.AimbotKeybind:GetState()
    end
    if not aimbotActive then
        Target = nil
        lockedTarget = nil
        stickyTarget = nil
        CurrentLockedTarget = nil
        PerceivedPos = nil
        PerceivedVel = Vector3.new()
        JustLocked = true
        ClearGhost() -- Cleanup ghost
        -- END OF RENDERSTEPPED FOR AIMBOT INACTIVE
        if Camera.CameraType == Enum.CameraType.Scriptable then
            Camera.CameraType = Enum.CameraType.Custom -- Reset camera if keybind released
        end
        return
    end
   
    local currentTarget = nil
   
    -- --- TARGET SELECTION LOGIC ---
    if Toggles.OutwallAim.Value then
         if not lockedTarget or not isValidLockedTarget(lockedTarget) then
             lockedTarget = getClosestTarget()
         end
         currentTarget = lockedTarget
    elseif Toggles.StickyAim.Value then
         -- STICKY AIM FIXED LOGIC
        
         -- 1. Validate existing target
         if stickyTarget and not isValidLockedTarget(stickyTarget) then
             stickyTarget = nil
         end
        
         -- 2. Check strict conditions for holding target
         if stickyTarget then
             local part = stickyTarget:FindFirstChild("HumanoidRootPart")
             if part then
                 local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                 local distFromMouse = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                
                 -- Rule: If not on screen or outside FOV, drop it
                 if not onScreen or distFromMouse > Options.FOVRadius.Value then
                     stickyTarget = nil
                 end
                
                 -- Rule: If WallCheck enabled, drop if hidden
                 if stickyTarget and Toggles.StickyWallCheck.Value then
                    local aimP = getAimPart(stickyTarget)
                    if aimP and not isVisible(aimP) then
                        stickyTarget = nil
                    end
                 end
             else
                 stickyTarget = nil
             end
         end
        
         -- 3. If we don't have a target, find one
         if not stickyTarget then
             stickyTarget = getClosestTarget()
         end
        
         currentTarget = stickyTarget
    else
        -- REACTION TIME LOGIC FIX
        local newClosest = getClosestTarget()
       
        -- If we have a valid target currently locked...
        if CurrentLockedTarget and isValidLockedTarget(CurrentLockedTarget) then
            -- And a DIFFERENT target is now closer (e.g. someone jumped in front)
            if newClosest ~= CurrentLockedTarget then
               
                -- Check if this is a "new" pending target
                if PendingTarget ~= newClosest then
                    PendingTarget = newClosest
                    TargetSwitchTimer = tick() -- Start the timer
                end
               
                -- Have we waited long enough to switch?
                if tick() - TargetSwitchTimer >= TargetReactionDelay then
                     -- Yes, reaction time passed. Switch target.
                     currentTarget = newClosest
                     CurrentLockedTarget = currentTarget
                else
                     -- No, keep aiming at the old target (ignore distraction)
                     currentTarget = CurrentLockedTarget
                end
            else
                -- New closest IS the current target, reset timers
                currentTarget = CurrentLockedTarget
                PendingTarget = nil
            end
        else
            -- We don't have a valid target, snap instantly to the closest one
            currentTarget = newClosest
            CurrentLockedTarget = currentTarget
            PendingTarget = nil
        end
    end
   
    if not currentTarget then
        Target = nil
        PerceivedPos = nil
        PerceivedVel = Vector3.new()
        JustLocked = true
        ClearGhost() -- Cleanup ghost
        -- Always reset camera if target is lost
        if Camera.CameraType == Enum.CameraType.Scriptable then
            Camera.CameraType = Enum.CameraType.Custom
        end
        return
    end
   
    -- FIXED PART RETRIEVAL (HANDLES R6/R15 NPC/PLAYER)
    local aimPart = nil
    local useWallCheck = Toggles.WallCheck.Value and not (Toggles.StickyAim.Value and Toggles.StickyWallCheck.Value and currentTarget == stickyTarget)
   
    if Toggles.AimVisibleParts.Value then
        local bestDist = math.huge
        local bestPart = nil
        for _, partName in ipairs(bodyParts) do
            local part = currentTarget:FindFirstChild(partName)
            if part and (not useWallCheck or isVisible(part)) then
                local scr, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local dist = (Vector2.new(scr.X, scr.Y) - mousePos).Magnitude
                    if dist < bestDist then
                        bestDist = dist
                        bestPart = part
                    end
                end
            end
        end
        aimPart = bestPart
    else
        aimPart = getAimPart(currentTarget)
        if aimPart and (not useWallCheck or isVisible(aimPart)) then
            -- part is good
        else
            aimPart = nil
        end
    end
    if not aimPart then
        Target = nil
        PerceivedPos = nil
        PerceivedVel = Vector3.new()
        JustLocked = true
        ClearGhost() -- Cleanup ghost
        -- Always reset camera if aimPart is lost
        if Camera.CameraType == Enum.CameraType.Scriptable then
            Camera.CameraType = Enum.CameraType.Custom
        end
        return
    end
    local currentVelocity = aimPart.AssemblyLinearVelocity or Vector3.new()
    local currentWorldPos = aimPart.Position
    local now = tick()
    -- First lock or target change = instant
    if JustLocked then
        PerceivedPos = currentWorldPos
        PerceivedVel = currentVelocity
        LastUpdateTimeX = now
        LastUpdateTimeY = now
        JustLocked = false
    end
    -- Update perception for X/Z (horizontal) and Y (vertical) independently
    if now - LastUpdateTimeX >= ReactionDelayX then
        PerceivedPos = Vector3.new(currentWorldPos.X, PerceivedPos.Y, currentWorldPos.Z)
        PerceivedVel = Vector3.new(currentVelocity.X, PerceivedVel.Y, currentVelocity.Z)
        LastUpdateTimeX = now
    end
    if now - LastUpdateTimeY >= ReactionDelayY then
        PerceivedPos = Vector3.new(PerceivedPos.X, currentWorldPos.Y, PerceivedPos.Z)
        PerceivedVel = Vector3.new(PerceivedVel.X, currentVelocity.Y, PerceivedPos.Z) -- FIX: PerceivedVel.Z was wrong
        LastUpdateTimeY = now
    end
    local timeSinceX = now - LastUpdateTimeX
    local timeSinceY = now - LastUpdateTimeY
    -- Extrapolate X/Z and Y with independent times
    local perceivedX = PerceivedPos.X + PerceivedVel.X * timeSinceX
    local perceivedY = PerceivedPos.Y + PerceivedVel.Y * timeSinceY
    local perceivedZ = PerceivedPos.Z + PerceivedVel.Z * timeSinceX -- FIX: used timeSinceX for Z
    local perceivedWorldPos = Vector3.new(perceivedX, perceivedY, perceivedZ)
    -- THIS IS WHERE THE TARGET WILL BE
    local predictedWorldPos = perceivedWorldPos + PerceivedVel * Options.Prediction.Value
    
    -- START OF THIRD-PERSON LOCK INTEGRATION (LOGIC)
    local thirdPersonActive = Toggles.ThirdPersonLock.Value and aimbotActive
    if thirdPersonActive then
        -- Переключаем камеру в Scriptable mode для third-person
        if Camera.CameraType ~= Enum.CameraType.Scriptable then
            Camera.CameraType = Enum.CameraType.Scriptable
        end
        
        -- Позиция цели (с предикшном)
        local targetPos = predictedWorldPos + Vector3.new(0, Options.LockHeight.Value, 0)
        
        -- Вычисляем CFrame камеры для LookAt(targetPos)
        local targetCFrame = CFrame.lookAt(Camera.CFrame.Position, targetPos)
        
        -- Позиция камеры: за спиной цели, на расстоянии
        -- Используем -targetCFrame.LookVector, чтобы быть ЗА targetPos
        local lookDir = targetCFrame.LookVector
        local cameraOffset = lookDir * -Options.LockDistance.Value
        local behindTarget = targetPos + cameraOffset
        
        -- Окончательная CFrame для камеры
        local finalCFrame = CFrame.lookAt(behindTarget, targetPos)
        
        -- Плавный lerp к новой CFrame
        local alpha = Options.LockSmooth.Value
        Camera.CFrame = Camera.CFrame:Lerp(finalCFrame, alpha)
        
        -- Обновление Ghost Foreshadow (опционально, но логично)
        if Toggles.PredictionForeshadow.Value and currentTarget then
            local hrp = currentTarget:FindFirstChild("HumanoidRootPart")
            if hrp then
                local predHrpPos = hrp.Position + (hrp.AssemblyLinearVelocity * Options.Prediction.Value)
                UpdateGhost(currentTarget, predHrpPos)
            end
        else
            ClearGhost()
        end
        
        if Target ~= currentTarget then
            JustLocked = true
        end
        Target = currentTarget
        
        return  -- Пропускаем стандартный aim-lock, т.к. камера уже лочится
    end
    -- END OF THIRD-PERSON LOCK INTEGRATION (LOGIC)
    
    -- ==============================================================
    -- UPDATE GHOST FORESHADOW
    -- ==============================================================
    if Toggles.PredictionForeshadow.Value and currentTarget then
        -- Calculate where the HumanoidRootPart is predicted to be
        -- We can assume predictedWorldPos is roughly where the AimPart is going
        -- To be safe, we offset the whole body based on HRP prediction
        local hrp = currentTarget:FindFirstChild("HumanoidRootPart")
        if hrp then
            local predHrpPos = hrp.Position + (hrp.AssemblyLinearVelocity * Options.Prediction.Value)
            UpdateGhost(currentTarget, predHrpPos)
        end
    else
        ClearGhost()
    end
    -- ==============================================================
    local screenPos, onScreen = Camera:WorldToViewportPoint(predictedWorldPos)
    if not onScreen then
        Target = nil
        JustLocked = true
        ClearGhost() -- Cleanup ghost
        return
    end
    local mousePos = UserInputService:GetMouseLocation()
    if Options.AimMethod.Value == "Mouse" then
        -- Use SNAP BACK SPEED if the aim delta is large (catching up), else use standard Smoothness
        local currentSmoothnessX = Options.XSmoothness.Value
        local currentSmoothnessY = Options.YSmoothness.Value
       
        local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
       
        -- Logic: If we are far off (due to reaction lag or switching), use SnapBackSpeed
        -- Threshold is arbitrary, 20px is a decent "off target" check
        if dist > 20 then
            currentSmoothnessX = Options.SnapBackSpeed.Value
            currentSmoothnessY = Options.SnapBackSpeed.Value
        end
        local deltaX = (screenPos.X - mousePos.X) / math.max(1, currentSmoothnessX)
        local deltaY = (screenPos.Y - mousePos.Y) / math.max(1, currentSmoothnessY)
        deltaX = deltaX + math.random(-1, 1) * 0.15
        deltaY = deltaY + math.random(-1, 1) * 0.15
        if mousemoverel then
            mousemoverel(deltaX, deltaY)
        end
    elseif Options.AimMethod.Value == "Camera" then
        local targetCFrame = CFrame.lookAt(Camera.CFrame.Position, predictedWorldPos)
        local avgSmoothness = (Options.XSmoothness.Value + Options.YSmoothness.Value) / 2
        local alpha = 1 / math.max(1, avgSmoothness)
        Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, alpha)
    end
    if Target ~= currentTarget then
        JustLocked = true
    end
    Target = currentTarget
    
    -- END OF RENDERSTEPPED LOOP, CHECK CAMERA RESET
    -- В конце RenderStepped, если thirdPersonActive=false, верни камеру:
    if not thirdPersonActive and Camera.CameraType == Enum.CameraType.Scriptable then
        Camera.CameraType = Enum.CameraType.Custom  -- Стандартный third-person/first-person
    end
end)
Players.PlayerRemoving:Connect(function(p)
    if ChamHighlights[p] then
        ChamHighlights[p]:Destroy()
        ChamHighlights[p] = nil
    end
    espInstance:removeEsp(p)
    if Target and Target == p.Character then
        ClearGhost()
    end
end)
-- UI Settings
local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu")
MenuGroup:AddToggle("KeybindMenuOpen", {
    Default = Library.KeybindFrame.Visible,
    Text = "Keybind Menu",
    Callback = function(Value) Library.KeybindFrame.Visible = Value end
})
MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })
MenuGroup:AddButton({ Text = "Unload", Func = function()
    ClearGhost()
    -- Reset camera type on unload for safety
    if Camera.CameraType == Enum.CameraType.Scriptable then
        Camera.CameraType = Enum.CameraType.Custom
    end
    Library:Unload()
end })
Library.ToggleKeybind = Options.MenuKeybind
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind", "AimbotKeybind", "TriggerbotKeybind" })
ThemeManager:ApplyToTab(Tabs["UI Settings"])
SaveManager:BuildConfigSection(Tabs["UI Settings"])
SaveManager:LoadAutoloadConfig()
Library:Notify("Obsidian GUI Loaded!", 5)
