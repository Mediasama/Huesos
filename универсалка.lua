local players = game:GetService("Players")
local player = players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

getgenv().SignalDelay = 0
local cache = {}
local hi = false
local hi1 = false
local Id, productInfo

_G.TP7 = false
_G.HideAll = false
_G.SignalTrue7 = false

-- [ TELEPORT BY CLICK ] --
local mouse = player:GetMouse()
mouse.Button1Down:Connect(function()
    if not _G.TP7 then return end
    if not player or not player.Character then return end
    if not mouse.Target then return end
    player.Character:PivotTo(CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0)))
end)

-- [ HIDE PLAYERS LOOP ] --
local HidePlayers = {}
task.spawn(function()
    while task.wait(0.5) do
        for _, v in pairs(players:GetPlayers()) do
            if v ~= player and v.Character then
                if _G.HideAll then
                    if not HidePlayers[v] then
                        HidePlayers[v] = v.Character.Parent
                    end
                    v.Character.Parent = nil
                else
                    if HidePlayers[v] and v.Character.Parent == nil then
                        v.Character.Parent = HidePlayers[v]
                    end
                end
            end
        end
    end
end)

-- [ UI LIBRARY ] --
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/wizard"))()
local Window = Library:NewWindow("Just script v2.1")

-- ==============================================================================
-- [ НОВАЯ ВКЛАДКА ROBIT (Специально для mediasama) ]
-- ==============================================================================
local RobitSection = Window:NewSection("robit")

-- 1. Визуальное увеличение стекол
RobitSection:CreateButton("Big Breakable Glass", function()
    pcall(function()
        if workspace.Map:FindFirstChild("BreakableGlass") then
            for _, v in pairs(workspace.Map.BreakableGlass:GetDescendants()) do
                if v:IsA("MeshPart") or v:IsA("BasePart") then
                    v.Size = Vector3.new(99.99, 99.99, 99.99)
                    v.Transparency = 0.5
                    v.CanCollide = false
                end
            end
        end
    end)
end)

-- Инструмент разрушения (Client-side)
RobitSection:CreateButton("Get Destroyer Tool", function()
    local tool = Instance.new("Tool")
    tool.Name = "mediasama Destroyer"
    tool.RequiresHandle = false
    tool.Parent = player.Backpack
    
    local mouse = player:GetMouse()
    tool.Activated:Connect(function()
        if mouse.Target then
            mouse.Target:Destroy()
        end
    end)
    
    StarterGui:SetCore("SendNotification", {
        Title = "System",
        Text = "Инструмент выдан!",
        Duration = 2
    })
end)

-- Телепорт к щитку
RobitSection:CreateButton("TP to Electric Box", function()
    pcall(function()
        local box = workspace:FindFirstChild("ElectricBox")
        local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        
        if box and hrp then
            -- Телепортируемся чуть перед дверцей, чтобы не застрять внутри
            hrp.CFrame = box:GetPivot() * CFrame.new(0, 0, 3) 
        else
            StarterGui:SetCore("SendNotification", {
                Title = "Error",
                Text = "ElectricBoxDoor не найден!",
                Duration = 3
            })
        end
    end)
end)

-- Настройка множителя спама
_G.SpamMultiplier = 50 

-- 1. Кнопка ULTRA HACK (с жестким спамом)
RobitSection:CreateButton("ULTRA HACK: PowerBox (SPAM)", function()
    local remote = game.ReplicatedStorage.Remotes.Utilities.HackPowerBox
    
    if remote then
        -- Тот самый пизда жесткий мультиплеер
        for i = 1, _G.SpamMultiplier do
            task.spawn(function()
                remote:FireServer(true)
            end)
        end
        
        -- Снимаем фиксацию экрана (если игра её наложила)
        task.wait(0.1)
        local camera = workspace.CurrentCamera
        camera.CameraType = Enum.CameraType.Custom
        player.Character.Humanoid.PlatformStand = false -- На случай, если персонаж замер
        
        warn("mediasama, щиток взломан с множителем x" .. _G.SpamMultiplier)
    end
end)

-- 2. Текстбокс для настройки множителя (если захочешь еще жестче)
RobitSection:CreateTextbox("Spam Multiplier", function(val)
    local num = tonumber(val)
    if num then
        _G.SpamMultiplier = num
    end
end)

-- 3. Отдельная кнопка Fix Camera (на всякий случай)
RobitSection:CreateButton("Unlock Camera / Movement", function()
    local camera = workspace.CurrentCamera
    camera.CameraType = Enum.CameraType.Custom
    player.Character.Humanoid.WalkSpeed = 16
    player.Character.Humanoid.JumpPower = 50
    player.Character.Humanoid.PlatformStand = false
end)

-- Функция мгновенного суицида через бездну
RobitSection:CreateButton("INSTANT VOID (Self-Kill)", function()
    pcall(function()
        local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            -- Телепортируем глубоко вниз под карту
            hrp.CFrame = hrp.CFrame * CFrame.new(0, -500, 0)
            warn("mediasama, отправляемся в бездну для дюпа...")
        end
    end)
end)

-- 2. Ломаем двери и окна через Remote (Серверное разрушение)
RobitSection:CreateButton("DESTROY Doors & Glass", function()
    pcall(function()
        local utils = ReplicatedStorage.Remotes.Utilities
        local breakWindow = utils:FindFirstChild("BreakWindow")
        local breakDoor = utils:FindFirstChild("BreakDoor")

        print("Начинаю уничтожение карты...")

        -- Ломаем стекла
        if workspace.Map:FindFirstChild("BreakableGlass") then
            for _, v in pairs(workspace.Map.BreakableGlass:GetDescendants()) do
                if v:IsA("BasePart") or v:IsA("MeshPart") then
                    breakWindow:FireServer(v)
                end
            end
        end

        -- Ломаем двери
        if workspace.Map:FindFirstChild("Doors") then
            for _, v in pairs(workspace.Map.Doors:GetDescendants()) do
                if v:IsA("Model") then
                    breakDoor:FireServer(v)
                elseif v:IsA("BasePart") and v.Parent:IsA("Model") then
                    breakDoor:FireServer(v.Parent)
                end
                
                -- Если внутри двери есть стекло
                if v.Name == "Glass" or v.Name == "Window" then
                    breakWindow:FireServer(v)
                end
            end
        end
        print("Всё разрушено!")
    end)
end)

-- Авто-удар по Боссу (SuperGuard)
RobitSection:CreateToggle("KILL SuperGuard (Loop)", function(state)
    _G.KillBoss = state
    task.spawn(function()
        while _G.KillBoss do
            local boss = workspace.Map.NPCS:FindFirstChild("SuperGuard")
            -- Проверяем, жив ли босс
            if boss and boss:FindFirstChild("Humanoid") and boss.Humanoid.Health > 0 then
                local args = {
                    [1] = boss,
                    [2] = "Crowbar"
                }
                game.ReplicatedStorage.Remotes.Tools.HitNPC:FireServer(unpack(args))
            else
                -- Если босс умер или его нет, ждем немного, чтобы не спамить в пустоту
                task.wait(1)
            end
            task.wait(0.1) -- Задержка ударов (можно уменьшить для супер-скорости)
        end
    end)
end)

-- 3. Выполнение квеста Get Noticed (Быстрый телепорт + Спам пакетов)
RobitSection:CreateButton("NPC Noticed (STORM)", function()
    pcall(function()
        local npcFolder = workspace.Map.NPCS
        local remoteFully = ReplicatedStorage.Remotes.NPCRemotes.NPCFullyNoticed
        local remoteStarted = ReplicatedStorage.Remotes.NPCRemotes.NPCStartedNoticing
        
        local root = player.Character.HumanoidRootPart
        local oldPos = root.CFrame
        
        print("Запуск шторма NPC...")

        for _, npc in pairs(npcFolder:GetChildren()) do
            local npcRoot = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChild("Head")
            if npcRoot then
                -- Телепортируемся перед лицом NPC (5 студов)
                root.CFrame = npcRoot.CFrame * CFrame.new(0, 0, -5)
                
                -- Спамим пакеты 5 раз подряд без задержки
                for i = 1, 5 do
                    remoteStarted:FireServer(npc)
                    remoteFully:FireServer(npc)
                end
                
                -- Минимальная задержка для регистрации позиции сервером
                RunService.Heartbeat:Wait()
            end
        end

        -- Возврат
        root.CFrame = oldPos
        print("Обход завершен!")
    end)
end)

-- ==============================================================================
-- [ Вкладка Scripts ]
-- ==============================================================================
local Section = Window:NewSection("Scripts")

Section:CreateButton("Infinite Yield", function()
    loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
end)

Section:CreateButton("Dex explorer", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/dex.lua"))()
end)

Section:CreateButton("Wyborn", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/ckw69/Wyborn/main/wyborn",true))()
end)

Section:CreateButton("Remote spy", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/FryzerHub/Biggestscript/refs/heads/main/SilentSpy"))()
end)

Section:CreateButton("RemoteBrowser", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Games1799/Scripts/refs/heads/main/RemoteBrowser"))()
end)

Section:CreateButton("Dev Products Purchaser", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/ckw69/Wyborn/refs/heads/main/Dev%20Product%20Purchase"))()
end)

Section:CreateButton("Adonis bypass", function()
    for i, v in pairs(game:GetDescendants()) do
        if v.Name == "__FUNCTION" then
            loadstring(game:HttpGet('https://raw.githubusercontent.com/Pixeluted/adoniscries/main/Source.lua'))()
            hi = true
            break
        end
    end

    if not hi then
        StarterGui:SetCore("SendNotification", {
            Title = "Not found!",
            Text = "Adonis anti cheat not found",
            Duration = 5,
        })
    end
end)

Section:CreateButton("RemoteBrowser v3 (Beta)", function()
    loadstring(Game:HttpGet("https://raw.githubusercontent.com/Games1799/Scripts/refs/heads/main/RemoteBrowserV3_Beta"))()
end)

-- ==============================================================================
-- [ Вкладка Moving ]
-- ==============================================================================
local MoveSection = Window:NewSection("Moving")

MoveSection:CreateToggle("Teleport By Tapping", function(state)
    _G.TP7 = state
end)

MoveSection:CreateButton("Copy position", function()
    local pos
    local char = player.Character
    local hum = char and player.Character:FindFirstChild("HumanoidRootPart")
    if hum then
        pos = hum.position
        local copy  = string.format("%f, %f, %f", pos.X, pos.Y, pos.Z)
        setclipboard(tostring(copy))
    else
        local camera = workspace.Camera
        if not camera then return end
        pos = camera.Focus.Position
        local copy  = string.format("%f, %f, %f", pos.X, pos.Y - 1.5, pos.Z)
        setclipboard(tostring(copy))
    end
end)

MoveSection:CreateButton("Copy Teleport", function()
    local pos
    local char = player.Character
    local hum = char and player.Character:FindFirstChild("HumanoidRootPart")
    if char and hum then
        pos = hum.position
        local copy = string.format("game.Players.LocalPlayer.Character:PivotTo(CFrame.new(Vector3.new(%f, %f, %f)))", pos.X, pos.Y, pos.Z)
        setclipboard(tostring(copy))
    else
        local camera = workspace.Camera
        if not camera then return end
        pos = camera.Focus.Position
        local copy = string.format("game.Players.LocalPlayer.Character:PivotTo(CFrame.new(Vector3.new(%f, %f, %f)))", pos.X, pos.Y - 1.5, pos.Z)
        setclipboard(tostring(copy))
    end
end)

MoveSection:CreateButton("Copy TweenService", function()
    local pos
    local char = player.Character
    local hum = char and player.Character:FindFirstChild("HumanoidRootPart")
    if char and hum then
        pos = hum.position
        local copy = string.format([[local tweenInfo = TweenInfo.new(2)
local goal = {CFrame = CFrame.new(%f, %f, %f)}
local tween = game:GetService("TweenService"):Create(game.Players.LocalPlayer.Character.HumanoidRootPart, tweenInfo, goal)
tween:Play()]], pos.X, pos.Y, pos.Z)
        setclipboard(tostring(copy))
    end
end)

MoveSection:CreateButton("Copy MoveTo", function()
    local pos
    local char = player.Character
    local hum = char and player.Character:FindFirstChild("HumanoidRootPart")
    if char and hum then
        pos = hum.position
        local copy = string.format([[local hrp = game.Players.LocalPlayer.Character.HumanoidRootPart
local position = "%f, %f, %f"
local humanoid = game.Players.LocalPlayer.Character.Humanoid
humanoid.WalkSpeed = 16
humanoid.JumpPower = 19
humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
humanoid:MoveTo(position)]], pos.X, pos.Y, pos.Z)
        setclipboard(tostring(copy))
    end
end)

MoveSection:CreateButton("Copy Lerp", function()
    local pos
    local char = player.Character
    local hum = char and player.Character:FindFirstChild("HumanoidRootPart")
    if char and hum then
        pos = hum.position
        local copy  = string.format([[local hrp = game.Players.LocalPlayer.Character.HumanoidRootPart
local goal = CFrame.new(%f, %f, %f)
for i = 0, 1, 0.05 do
hrp.CFrame = hrp.CFrame:Lerp(goal, i)
task.wait()
end]], pos.X, pos.Y, pos.Z)
        setclipboard(tostring(copy))
    end
end)

-- ==============================================================================
-- [ Вкладка Tools ]
-- ==============================================================================
local ToolSection = Window:NewSection("Tools")

ToolSection:CreateToggle("Hide players", function(state)
    _G.HideAll = state
end)

ToolSection:CreateButton("FireProximityPrompt", function()
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            fireproximityprompt(v)
        end
    end
end)

ToolSection:CreateButton("HoldDuration 0", function()
    for _, v in next, workspace:GetDescendants() do
        if v:IsA("ProximityPrompt") then
            v.HoldDuration = 0
        end
    end
end)

ToolSection:CreateButton("FireAllClickDetectors", function()
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("ClickDetector") then
            fireclickdetector(v)
        end
    end
end)

ToolSection:CreateButton("KillAura", function()
    local range = 9e9
    RunService.RenderStepped:Connect(function()
        local players1 = players:GetPlayers()
        for i = 2, #players1 do
            local target = players1[i].Character
            if target and target:FindFirstChild("Humanoid") and target.Humanoid.Health > 0 and target:FindFirstChild("HumanoidRootPart") then
                if player:DistanceFromCharacter(target.HumanoidRootPart.Position) <= range then
                    local tool = player.Character and player.Character:FindFirstChildOfClass("Tool")
                    if tool and tool:FindFirstChild("Handle") then
                        tool:Activate()
                        for _, part in ipairs(target:GetChildren()) do
                            if part:IsA("BasePart") then
                                firetouchinterest(tool.Handle, part, 0)
                                firetouchinterest(tool.Handle, part, 1)
                            end
                        end
                    end
                end
            end
        end
    end)
end)

ToolSection:CreateButton("FireAllTouchinterest", function()
    local hum = player.Character.HumanoidRootPart
    if hum then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("TouchTransmitter") then
                local part = obj.Parent
                if part then
                    firetouchinterest(part, hum, 1)
                    task.wait()
                    firetouchinterest(part, hum, 0)
                    part.CFrame = hum.CFrame
                end
            end
        end
    end
end)

-- ==============================================================================
-- [ Вкладка Purchase signals ]
-- ==============================================================================
local SignSection = Window:NewSection("Purchase signals")

SignSection:CreateToggle("Signal true", function(state7)
    _G.SignalTrue7 = state7
end)

getgenv().hi2 = {toggle = false}

SignSection:CreateToggle("Spam the Signals", function(state)
    hi2.toggle = state
    task.spawn(function()
        while hi2.toggle do
            task.wait(getgenv().SignalDelay)
            if Id and cache[Id] then
                pcall(function()
                    local signal = _G.SignalTrue7
                    local info = cache[Id]
                    if info.type == "GamePass" then
                        MarketplaceService:SignalPromptGamePassPurchaseFinished(player, Id, signal)
                    elseif info.type == "Product" then
                        MarketplaceService:SignalPromptProductPurchaseFinished(player.UserId, Id, signal)
                    elseif info.type == "Bundle" then
                        MarketplaceService:SignalPromptBundlePurchaseFinished(player, Id, signal)
                    elseif info.type == "Asset" then
                        MarketplaceService:SignalPromptPurchaseFinished(player, Id, signal)
                    end
                end)
            end
        end
    end)
end)

SignSection:CreateTextbox("Enter id", function(id)
    Id = tonumber(id)
    if not Id then return end
    
    if cache[Id] then
        _G.productInfo = cache[Id]
        return
    end

    local productInfo
    -- Пытаемся определить тип
    local success, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, Id, Enum.InfoType.GamePass)
    if success then productInfo = {type = "GamePass", info = info}
    else
        success, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, Id, Enum.InfoType.Product)
        if success then productInfo = {type = "Product", info = info}
        else
            success, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, Id, Enum.InfoType.Asset)
            if success then productInfo = {type = "Asset", info = info} end
        end
    end

    if productInfo then
        cache[Id] = productInfo
        _G.productInfo = productInfo
    else
        StarterGui:SetCore("SendNotification", {Title="Error", Text="ID not found", Duration=5})
    end
end)

SignSection:CreateTextbox("Spam interval", function(time)
    getgenv().SignalDelay = tonumber(time) or 0
end)

SignSection:CreateButton("Use Signal", function()
    pcall(function()
        local signal = _G.SignalTrue7
        if not Id or not cache[Id] then return end
        local info = cache[Id]
        
        if info.type == "GamePass" then
            MarketplaceService:SignalPromptGamePassPurchaseFinished(player, Id, signal)
        elseif info.type == "Product" then
            MarketplaceService:SignalPromptProductPurchaseFinished(player.UserId, Id, signal)
        elseif info.type == "Bundle" then
            MarketplaceService:SignalPromptBundlePurchaseFinished(player, Id, signal)
        elseif info.type == "Asset" then
            MarketplaceService:SignalPromptPurchaseFinished(player, Id, signal)
        end
    end)
end)

-- ==============================================================================
-- [ ФОНОВЫЕ ПРОВЕРКИ ]
-- ==============================================================================

-- Adonis Check
for i, v in pairs(game:GetDescendants()) do
    if v.Name == "__FUNCTION" then
        StarterGui:SetCore("SendNotification", {
            Title = "Adonis anti cheat found!",
            Text = "Check !Buyitem and !Buyasset",
            Button1 = "Ок",
            Duration = 5,
        })
        hi1 = true
        break
    end
end

-- Purchase Prompt Monitor
if not _G.Prompt_ICON1 then
    _G.Prompt_ICON1 = true
    task.spawn(function()
        while task.wait(1) do  
            local purchasePrompt = CoreGui:FindFirstChild("PurchasePromptApp")  
            if purchasePrompt then  
                local priceText, imageSrc  
                -- Логика поиска окна покупки (ProductPurchaseContainer или RobuxUpsellContainer)
                -- ... (оставлена базовая структура для сокращения, так как логика сложная и специфичная)
            end  
        end
    end)
end
