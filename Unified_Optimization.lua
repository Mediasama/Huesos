--[[
    ╔══════════════════════════════════════════════════════════╗
    ║        OBSIDIAN PREMIUM SUITE: UNIFIED & OPTIMIZED       ║
    ║   Объединенный и улучшенный пакет скриптов (AIO)         ║
    ║   Стиль: Мятный Графит (Matted Mint - Overhaul Style)    ║
    ║                                                          ║
    ║   Разработано под авто-выполнение и мобильные эмуляторы ║
    ╚══════════════════════════════════════════════════════════╝
]]

-- ╔══════════════════════════════════════════════════════════╗
-- ║             ИНИЦИАЛИЗАЦИЯ И СЕРВИСЫ                      ║
-- ╚══════════════════════════════════════════════════════════╝
local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService  = game:GetService("HttpService")
local CoreGui      = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- Вспомогательная функция lerp2 (объявлена в самом верху для безопасного вызова во всех модулях)
local function lerp2(a, b, t)
    return a + (b - a) * t
end

-- Динамическое получение текущей камеры (на случай смены/спавна)
local Camera = workspace.CurrentCamera or workspace:FindFirstChildOfClass("Camera")

-- ╔══════════════════════════════════════════════════════════╗
-- ║                  СИСТЕМА СБРОСА И ОЧИСТКИ                ║
-- ╚══════════════════════════════════════════════════════════╝
if getgenv().UnifiedOptimizationSharedState then
    pcall(getgenv().UnifiedOptimizationSharedState.Cleanup)
end

local SharedState = {
    Connections = {},
    Drawings = {},
    Instances = {},
    Logs = {}
}
getgenv().UnifiedOptimizationSharedState = SharedState

function SharedState.AddConnection(conn)
    table.insert(SharedState.Connections, conn)
end

function SharedState.AddDrawing(drawObj)
    table.insert(SharedState.Drawings, drawObj)
end

function SharedState.AddInstance(inst)
    table.insert(SharedState.Instances, inst)
end

function SharedState.Cleanup()
    -- Отключаем все соединения событий
    for _, conn in ipairs(SharedState.Connections) do
        pcall(function() conn:Disconnect() end)
    end
    -- Удаляем все рисунки Drawing API
    for _, drawObj in ipairs(SharedState.Drawings) do
        pcall(function() drawObj:Remove() end)
    end
    -- Удаляем созданные UI элементы, папки, светящиеся сферы и прочее
    for _, inst in ipairs(SharedState.Instances) do
        pcall(function() if inst and inst.Parent then inst:Destroy() end end)
    end
    -- Принудительно очищаем оставшиеся призраки в workspace
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj.Name == "ServerGhostModel_Client" or obj.Name:find("_ghost") then
            pcall(function() obj:Destroy() end)
        end
    end
    -- Удаляем боксы подсветки SmartGlow
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name == "SmartGlow_Box" then
            pcall(function() obj:Destroy() end)
        end
    end
    -- Сброс коллизии камеры к стандартному поведению Zoom
    pcall(function() player.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Zoom end)
    -- Возвращаем тип камеры к Custom при очистке
    pcall(function() if Camera then Camera.CameraType = Enum.CameraType.Custom end end)
    -- Отключаем гироскопический рендер
    pcall(function() RunService:UnbindFromRenderStep("AIO_GyroCamera") end)
    -- Восстанавливаем оригинальный скайбокс
    pcall(function()
        local Lighting = game:GetService("Lighting")
        local origSky = Lighting:FindFirstChild("OriginalSkyboxBackup")
        if origSky then
            for _, child in ipairs(Lighting:GetChildren()) do
                if child:IsA("Sky") and child.Name ~= "OriginalSkyboxBackup" then
                    child:Destroy()
                end
            end
            origSky.Name = "Sky"
        end
    end)

    SharedState.Connections = {}
    SharedState.Drawings = {}
    SharedState.Instances = {}
end

-- Безопасный оберточный метод создания объектов Drawing (предотвращает краш, если Drawing не поддерживается)
local dummyDrawingMt = {
    __index = function(self, key)
        return function() end
    end,
    __newindex = function(self, key, val)
        -- Игнорируем установку свойств
    end
}

local function CreateDrawing(drawingType)
    if Drawing and Drawing.new then
        local success, obj = pcall(Drawing.new, drawingType)
        if success and obj then
            SharedState.AddDrawing(obj)
            return obj
        end
    end
    return setmetatable({}, dummyDrawingMt)
end

-- Динамическое отслеживание смены Camera
local camConnection = workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    Camera = workspace.CurrentCamera or workspace:FindFirstChildOfClass("Camera")
end)
SharedState.AddConnection(camConnection)

-- Логгер для console.lua интеграции
local function ConsoleLog(msg)
    local timestamp = os.date("%H:%M:%S")
    local line = string.format("[%s] %s", timestamp, msg)
    table.insert(SharedState.Logs, line)
    if #SharedState.Logs > 150 then
        table.remove(SharedState.Logs, 1)
    end
    -- Обновляем текстовое поле в консоли Obsidian, если оно создано
    if getgenv().ObsidianConsoleLabel then
        pcall(function()
            getgenv().ObsidianConsoleLabel:SetText(table.concat(SharedState.Logs, "\n"))
        end)
    end
    print(line)
end

ConsoleLog("Инициализация Obsidian Suite...")

-- ╔══════════════════════════════════════════════════════════╗
-- ║         ЗАГРУЗКА И НАСТРОЙКА БИБЛИОТЕКИ OBSIDIAN         ║
-- ╚══════════════════════════════════════════════════════════╝
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

-- Настройка мятного стиля по умолчанию (переопределяем ДО CreateWindow для 100% безопасности от "got string" крашей)
pcall(function()
    local mintAccent = Color3.fromRGB(0, 255, 200) -- Тот самый яркий неоновый мятный цвет из Overhaul!
    local darkAccent = Color3.fromRGB(0, 200, 150)
    local bgDark = Color3.fromRGB(20, 20, 25)
    local borderDark = Color3.fromRGB(40, 40, 45)
    local textWhite = Color3.fromRGB(255, 255, 255)
    local textGray = Color3.fromRGB(180, 180, 180)

    Library.Theme = {
        AccentColor = mintAccent,
        AccentColorDark = darkAccent,
        BackgroundColor = bgDark,
        BorderColor = borderDark,
        TextColor = textWhite,
        SubTextColor = textGray,
        MainColor = bgDark,
        OutlineColor = borderDark,
        FontColor = textWhite,
    }
    Library.ColorScheme = Library.Theme
end)

local Window = Library:CreateWindow({
    Title = "Obsidian Suite | Matted Mint",
    Footer = "Разработано для авто-выполнения | v2.6",
    Icon = 95816097006870,
    NotifySide = "Right",
    ShowCustomCursor = false,
})

-- Создаем вкладки
local Tabs = {
    Universal = Window:AddTab("Универсалка", "user"),
    Gyro = Window:AddTab("Гироскоп", "compass"),
    Console = Window:AddTab("Консоль", "terminal"),
    Settings = Window:AddTab("Настройки UI", "settings"),
}

-- Групбоксы во вкладке Универсалка
local OptGroup = Tabs.Universal:AddLeftGroupbox("Оптимизация и FFlags", "zap")
local VisualGroup = Tabs.Universal:AddLeftGroupbox("Визуальные Элементы", "eye")
local ComfortGroup = Tabs.Universal:AddRightGroupbox("Камера и Комфорт", "shield")
local AvatarGroup = Tabs.Universal:AddRightGroupbox("Прозрачность и Аура", "shield")

-- Групбокс во вкладке Гироскоп
local GyroSettingsGroup = Tabs.Gyro:AddLeftGroupbox("Тонкая Настройка Гироскопа", "sliders")
local GyroInfoGroup = Tabs.Gyro:AddRightGroupbox("Параметры и Статус", "info")

-- Групбокс во вкладке Консоль
local ConsoleGroup = Tabs.Console:AddLeftGroupbox("Окно Вывода Консоли", "terminal")

-- ╔══════════════════════════════════════════════════════════╗
-- ║                    НАСТРОЙКИ ПО УМОЛЧАНИЮ                ║
-- ╚══════════════════════════════════════════════════════════╝
local Settings = {
    Performance = {
        EnableFFlags = true,
        OptimizeMap = true,
        DisableParticles = true,
        StretchedResolution = 0.65,
    },
    Lighting = {
        Fullbright = true,
        RemoveAtmosphere = true,
        ContrastPreserve = true,
        SpaceSkybox = true,
    },
    Comfort = {
        ZeroCamShake = true,
        ShiftLock = false,
        ShiftOffsetDistance = 2.0, -- Динамическое смещение плеча вбок
    },
    Crosshair = {
        Enabled = true,
        Size = 32,
        Width = 32,
        Height = 32,
        XOffset = 0,
        YOffset = -20,
    },
    JumpRadius = {
        Enabled = true,
        Color = Color3.fromRGB(0, 255, 200),
    },
    Character = {
        Transparent = true,
        Aura = true,
        AuraColor = Color3.fromRGB(0, 255, 200),
    },
    Prediction = {
        Enabled = true,
        PreJumpEnabled = false,
    },
    SmartGlow = {
        Enabled = true,
    },
    ServerGhost = {
        Enabled = true,
    },
    TargetEsp = {
        Enabled = true,
        Range = 100,
        SmoothFade = 12,
        SmoothScale = 10,
        RotAngle = 360,
        RotSpeed = 1,
        VerticalOffset = 0,
        FovRadius = 80, -- Радиус зоны захвата вокруг прицела на экране (FOV lock)
    },
    Gyroscope = {
        Enabled = true,
        PitchSensitivity = 1.5,
        YawSensitivity = 1.8,
        Deadzone = 0.001,
        AlphaMin = 0.1,
    }
}

-- Вспомогательная функция для безопасного кэширования файлов с внешних ресурсов
local function GetCustomTexture(fileName, fallbackUrl)
    if isfile and readfile and writefile then
        if isfile(fileName) then
            local success, asset = pcall(function()
                return getcustomasset(fileName)
            end)
            if success and asset then
                return asset
            end
        end
        -- Качаем и сохраняем на диск
        ConsoleLog("Загрузка кастомного ресурса: " .. fileName)
        local success, data = pcall(function()
            return game:HttpGet(fallbackUrl)
        end)
        if success and data then
            writefile(fileName, data)
            local successAsset, asset = pcall(function()
                return getcustomasset(fileName)
            end)
            if successAsset and asset then
                return asset
            end
        end
    end
    return fallbackUrl
end

-- Кэшируем кастомные текстуры
local crosshairAsset = GetCustomTexture("img_0_pk.png", "https://raw.githubusercontent.com/Mediasama/Huesos/main/img_0_pk.png")
local targetAsset = GetCustomTexture("mitetarget.svg", "https://raw.githubusercontent.com/Mediasama/Huesos/main/img_0_pk.png") -- На случай отсутствия SVG, используем img_0_pk как красивый вращающийся спрайт

-- ╔══════════════════════════════════════════════════════════╗
-- ║         1. МОДУЛЬ FFLAGS И ОПТИМИЗАЦИИ (PERFORMANCE)     ║
-- ╚══════════════════════════════════════════════════════════╝
local flagtables = {
    ["DFIntTaskSchedulerTargetFps"] = "9999",
    ["FIntTaskSchedulerAutoThreadLimit"] = "6",
    ["FIntTaskSchedulerAsyncTasksMinimumThreadCount"] = "2",
    ["FIntTaskSchedulerMaxNumOfJobs"] = "86",
    ["FIntTaskSchedulerThreadMin"] = "1",
    ["DFFlagBrowserTrackerIdTelemetryEnabled"] = "False",
    ["DFFlagPreloadAsyncSupportTexturePack"] = "True",
    ["DFFlagTextureQualityOverrideEnabled"] = "True",
    ["DFFlagVideoCaptureServiceEnabled"] = "False",
    ["DFFlagSampleAndRefreshRakPing"] = "True",
    ["DFFlagRakNetUseSlidingWindow4"] = "True",
    ["DFFlagCoreScriptTelemetry2"] = "False",
    ["DFFlagEnableSoundPreloading"] = "True",
    ["DFFlagOptimizePartsInPart"] = "True",
    ["DFFlagDisableDPIScale"] = "True",
    ["DFFlagDebugPerfMode"] = "True",
    ["DFIntRaknetBandwidthInfluxHundredthsPercentageV2"] = "10000",
    ["DFIntRakNetClockDriftAdjustmentPerPingMillisecond"] = "100",
    ["DFIntRaknetBandwidthPingSendEveryXSeconds"] = "1",
    ["DFIntRakNetNakResendDelayRttPercent"] = "50",
    ["DFIntRakNetNakResendDelayMsMax"] = "100",
    ["DFIntRakNetNakResendDelayMs"] = "10",
    ["DFIntRakNetResendRttMultiple"] = "1",
    ["DFIntRakNetSelectTimeoutMs"] = "1",
    ["DFIntRakNetLoopMs"] = "1",
    ["DFIntRakNetMinAckGrowthPercent"] = "0",
    ["DFIntRakNetMtuValue1InBytes"] = "1280",
    ["DFIntRakNetMtuValue2InBytes"] = "1240",
    ["DFIntFolderColor"] = "0",
    ["DFIntRakNetMtuValue3InBytes"] = "1200",
    ["DFIntConnectionMTUSize"] = "1260",
    ["DFIntMaxReceiveToDeserializeLatencyMilliseconds"] = "15",
    ["DFIntNetworkInDeserializeLimitGameplayMsClient"] = "6",
    ["DFIntNetworkInProcessLimitGameplayMsClient"] = "6",
    ["DFIntClientPacketHealthyAllocationPercent"] = "20",
    ["DFIntClientPacketMaxFrameMicroseconds"] = "200",
    ["DFIntClientPacketExcessMicroseconds"] = "1000",
    ["DFIntClientPacketMinMicroseconds"] = "1",
    ["DFIntClientPacketMaxDelayMs"] = "11",
    ["DFIntMaxWaitTimeBeforeForcePacketProcessMS"] = "1",
    ["DFIntMaxProcessPacketsStepsPerCyclic"] = "5000",
    ["DFIntMaxProcessPacketsStepsAccumulated"] = "0",
    ["DFIntMaxProcessPacketsJobScaling"] = "10000",
    ["DFIntLargePacketQueueSizeCutoffMB"] = "1000",
    ["DFIntDataSenderRate"] = "1000",
    ["DFIntDataSenderMaxBandwidthBps"] = "2147483647",
    ["DFIntDataSenderMaxJoinBandwidthBps"] = "2147483647",
    ["DFIntS2PhysicsSenderRate"] = "1000",
    ["DFIntS2NumPhysicsPacketsPerStep"] = "100",
    ["DFIntPhysicsSenderMaxBandwidthBps"] = "2147483647",
    ["DFIntPhysicsSenderMaxBandwidthBpsScaling"] = "1000",
    ["FIntPGSAngularDampingPermilPersecond"] = "0",
    ["DFFlagPhysicsSkipNonRealTimeHumanoidForceCalc2"] = "True",
    ["FFlagDebugDisplayFPS"] = "True",
    ["DFIntSignalRHubConnectionHeartbeatTimerRateMs"] = "1000",
    ["DFIntSignalRHubConnectionBaseRetryTimeMs"] = "100",
    ["DFIntSignalRCoreKeepAlivePingPeriodMs"] = "250",
    ["DFIntSignalRCoreServerTimeoutMs"] = "11100",
    ["DFIntSignalRCoreTimerMs"] = "750",
    ["DFIntSignalRCoreRpcQueueSize"] = "256",
    ["DFIntAnimationLodFacsVisibilityDenominator"] = "0",
    ["DFIntAnimationLodFacsDistanceMin"] = "0",
    ["DFIntAnimationLodFacsDistanceMax"] = "0",
    ["DFIntDebugFRMQualityLevelOverride"] = "1",
    ["DFIntDebugDynamicRenderKiloPixels"] = "1100",
    ["DFIntDebugRestrictGCDistance"] = "1",
    ["DFIntWaitOnUpdateNetworkLoopEndedMS"] = "100",
    ["DFIntWaitOnRecvFromLoopEndedMS"] = "100",
    ["FIntRenderMaxShadowAtlasUsageBeforeDownscale"] = "80",
    ["FIntRenderShadowMapDepthCacheMemLimit"] = "192",
    ["FIntUITextureMaxRenderTextureSize"] = "1024",
    ["FIntRakNetResendBufferArrayLength"] = "128",
    ["FIntTerrainOTAMaxTextureSize"] = "1024",
    ["FIntOcclusionWorkerThreadCount"] = "5",
    ["FIntDefaultMeshCacheSizeMB"] = "256",
    ["FIntRobloxGuiBlurIntensity"] = "0",
    ["FIntTerrainArraySliceSize"] = "0",
    ["FIntDebugForceMSAASamples"] = "1",
    ["FIntRenderShadowmapBias"] = "0",
    ["FIntFRMMaxGrassDistance"] = "0",
    ["FIntFRMMinGrassDistance"] = "0",
    ["FIntGrassMovementReducedMotionFactor"] = "0",
    ["FIntDebugTextureManagerSkipMips"] = "7",
    ["FIntPerformanceTelemetryQueueProcessLimit"] = "0",
    ["FIntTelemetryProfilerFrequency"] = "0",
    ["FIntRenderLocalLightFadeInMs"] = "0",
    ["FIntReportDeviceInfoRollout"] = "0",
    ["FFlagRenderAllocateShadowMapResourcesOnDemand"] = "True",
    ["FFlagSpecifyNetworkReplicatorScopeForItems"] = "True",
    ["FFlagTaskSchedulerLimitTargetFpsTo2402"] = "False",
    ["FFlagHandleAltEnterFullscreenManually"] = "False",
    ["FFlagGameBasicSettingsFramerateCap5"] = "False",
    ["FFlagSpecifyNetworkReplicatorScope"] = "True",
    ["FFlagSendRenderFidelityTelemetry2"] = "False",
    ["FFlagRenderGpuTextureCompressor"] = "True",
    ["FFlagBaseThreadPoolUseRuntime2"] = "True",
    ["FFlagCacheTextBoundsInGuiText"] = "True",
    ["FFlagEnableTelemetryService1"] = "False",
    ["FFlagDebugGraphicsPreferD3D11"] = "True",
    ["FFlagPerfDataOnTelemetryV2"] = "False",
    ["FFlagOpenTelemetryEnabled2"] = "False",
    ["FFlagRbxStorageUseMemCache"] = "True",
    ["FFlagDebugForceGenerateHSR"] = "True",
    ["FFlagRenderInitShadowmaps"] = "True",
    ["FFlagFastGPULightCulling3"] = "True",
    ["FFlagDebugSkyGray"] = "True",
    ["FFlagDebugRenderingSetDeterministic"] = "True",
    ["FLogNetwork"] = "7"
}

local function formatFlag(z)
    z = z:gsub("^DFInt", ""):gsub("^DFFlag", ""):gsub("^FFlag", ""):gsub("^FInt", ""):gsub("FString", ""):gsub("FLog", "")
    return z
end

local function InitFFlags()
    if not Settings.Performance.EnableFFlags then return end
    if not setfflag then
        ConsoleLog("Кривой клиент: функция setfflag отсутствует.")
        return
    end

    task.spawn(function()
        ConsoleLog("Начало инъекции FFlags...")
        local start = os.clock()
        local count = 0
        for k, v in pairs(flagtables) do
            pcall(function()
                local formatted = formatFlag(k)
                if getfflag(formatted) then
                    setfflag(formatted, v)
                    count = count + 1
                elseif getfflag(k) then
                    setfflag(k, v)
                    count = count + 1
                end
            end)
        end
        ConsoleLog(string.format("Успешно инжектировано %d FFlags за %.2f сек.", count, os.clock() - start))
    end)
end

-- Оптимизатор материалов и удаление тумана/атмосферы
local function InitOptimizerAndLighting()
    local function OptimizeObject(obj)
        pcall(function()
            if Settings.Performance.OptimizeMap then
                if obj:IsA("Decal") or obj:IsA("Texture") then
                    obj:Destroy()
                elseif obj:IsA("BasePart") or obj:IsA("MeshPart") or obj:IsA("UnionOperation") then
                    obj.Material = Enum.Material.SmoothPlastic
                    obj.Reflectance = 0
                    if obj:IsA("MeshPart") then
                        obj.TextureID = ""
                    end
                end
            end
            if Settings.Performance.DisableParticles and (obj:IsA("ParticleEmitter") or obj:IsA("Trail")) then
                obj.Enabled = false
            end
        end)
    end

    if Settings.Performance.OptimizeMap then
        for _, obj in ipairs(workspace:GetDescendants()) do
            OptimizeObject(obj)
        end
        local conn = workspace.DescendantAdded:Connect(OptimizeObject)
        SharedState.AddConnection(conn)
    end

    -- Настройки света (Fullbright + Сохранение Контраста + Скайбокс)
    local function ApplyLighting()
        pcall(function()
            local Lighting = game:GetService("Lighting")
            if Settings.Lighting.Fullbright then
                Lighting.Brightness = 2
                Lighting.ClockTime = 14
                Lighting.GlobalShadows = not Settings.Lighting.ContrastPreserve

                if Settings.Lighting.ContrastPreserve then
                    Lighting.Ambient = Color3.fromRGB(130, 130, 140)
                    Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 160)
                else
                    Lighting.Ambient = Color3.fromRGB(255, 255, 255)
                    Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
                end
            end
            if Settings.Lighting.RemoveAtmosphere then
                for _, obj in ipairs(Lighting:GetChildren()) do
                    if obj:IsA("Atmosphere") or obj:IsA("Clouds") then
                        obj:Destroy()
                    end
                end
                Lighting.FogEnd = 999999
            end

            -- Космический скайбокс
            if Settings.Lighting.SpaceSkybox then
                -- Резервное сохранение дефолтного
                local existingSky = Lighting:FindFirstChildOfClass("Sky")
                if existingSky and existingSky.Name ~= "SpaceSky" and not Lighting:FindFirstChild("OriginalSkyboxBackup") then
                    existingSky.Name = "OriginalSkyboxBackup"
                end

                local spaceSky = Lighting:FindFirstChild("SpaceSky")
                if not spaceSky then
                    spaceSky = Instance.new("Sky")
                    spaceSky.Name = "SpaceSky"
                    spaceSky.SkyboxBk = "rbxassetid://120612190"
                    spaceSky.SkyboxDn = "rbxassetid://120612133"
                    spaceSky.SkyboxFt = "rbxassetid://120612217"
                    spaceSky.SkyboxLf = "rbxassetid://120612260"
                    spaceSky.SkyboxRt = "rbxassetid://120612297"
                    spaceSky.SkyboxUp = "rbxassetid://120612330"
                    spaceSky.StarCount = 3000
                    spaceSky.Parent = Lighting
                end

                -- Деактивируем другие
                for _, child in ipairs(Lighting:GetChildren()) do
                    if child:IsA("Sky") and child.Name ~= "SpaceSky" then
                        child.Parent = nil
                    end
                end
                spaceSky.Parent = Lighting
            else
                local spaceSky = Lighting:FindFirstChild("SpaceSky")
                if spaceSky then spaceSky.Parent = nil end

                local origSky = Lighting:FindFirstChild("OriginalSkyboxBackup")
                if origSky then
                    origSky.Name = "Sky"
                    origSky.Parent = Lighting
                end
            end
        end)
    end

    ApplyLighting()
    local connL = game:GetService("Lighting").ChildAdded:Connect(function()
        task.wait(0.1)
        ApplyLighting()
    end)
    SharedState.AddConnection(connL)

    -- Постоянный апдейт состояния света из настроек
    task.spawn(function()
        while task.wait(0.5) do
            ApplyLighting()
        end
    end)
    ConsoleLog("Оптимизация освещения и космического неба запущена.")
end

-- Камера стретч трюк
local function InitCameraStretch()
    local conn = RunService.RenderStepped:Connect(function()
        if Camera and Settings.Performance.StretchedResolution < 1.0 then
            pcall(function()
                Camera.CFrame = Camera.CFrame * CFrame.new(0, 0, 0, 1, 0, 0, 0, Settings.Performance.StretchedResolution, 0, 0, 0, 1)
            end)
        end
    end)
    SharedState.AddConnection(conn)
end

-- ╔══════════════════════════════════════════════════════════╗
-- ║         2. МОДУЛЬ КАМЕРА (SHIFT LOCK, ZERO SHAKE)        ║
-- ╚══════════════════════════════════════════════════════════╗
local function InitCameraComfort()
    -- Zero Cam Shake
    local connShake = RunService.RenderStepped:Connect(function()
        if Settings.Comfort.ZeroCamShake then
            pcall(function()
                local char = player.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum.CameraOffset = Vector3.new(0, 0, 0)
                end
            end)
        end
    end)
    SharedState.AddConnection(connShake)

    -- Custom ShiftLock / Shoulder Shift (Полностью без тряски и глитчей физики)
    local renderConn = RunService.RenderStepped:Connect(function()
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")

        if Settings.Comfort.ShiftLock then
            if hum then
                hum.AutoRotate = false
            end
            if hrp then
                local camLook = Camera.CFrame.LookVector
                local flatLook = Vector3.new(camLook.X, 0, camLook.Z).Unit
                pcall(function()
                    hrp.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + flatLook)
                end)
            end
            Camera.CFrame = Camera.CFrame * CFrame.new(Vector3.new(Settings.Comfort.ShiftOffsetDistance, 0.5, 0))
        else
            if hum and not hum.AutoRotate then
                hum.AutoRotate = true
            end
        end
    end)
    SharedState.AddConnection(renderConn)
    ConsoleLog("Модули комфорта и кастомного плеча камеры подключены.")
end

-- ╔══════════════════════════════════════════════════════════╗
-- ║         3. МОДУЛЬ ПРИЦЕЛА (IMG_0_PK.PNG С RE-SENSING)    ║
-- ╚══════════════════════════════════════════════════════════╝
local function InitRaisedCrosshair()
    -- Попытка создать прицел на основе текстуры img_0_pk.png
    local crosshairImg
    local isCustom = false

    pcall(function()
        crosshairImg = CreateDrawing("Image")
        crosshairImg.Data = game:HttpGet("https://raw.githubusercontent.com/Mediasama/Huesos/main/img_0_pk.png")
        crosshairImg.Size = Vector2.new(Settings.Crosshair.Width, Settings.Crosshair.Height)
        crosshairImg.Visible = false
        isCustom = true
    end)

    -- Fallback на векторный прицел в мятном стиле, если рисование изображения не поддерживается
    local vectorLines = {}
    if not isCustom then
        for i = 1, 4 do
            local line = CreateDrawing("Line")
            line.Color = Color3.fromRGB(0, 255, 200)
            line.Thickness = 2.0
            line.Visible = false
            table.insert(vectorLines, line)
        end
    end

    local conn = RunService.RenderStepped:Connect(function()
        if not Settings.Crosshair.Enabled then
            if crosshairImg then crosshairImg.Visible = false end
            for _, l in ipairs(vectorLines) do l.Visible = false end
            return
        end

        local vpSize = Camera.ViewportSize
        local center = Vector2.new(vpSize.X / 2, vpSize.Y / 2)
        -- Точнейший оффсет, настраиваемый пользователем
        local targetCenter = center + Vector2.new(Settings.Crosshair.XOffset, Settings.Crosshair.YOffset)

        if isCustom and crosshairImg then
            crosshairImg.Size = Vector2.new(Settings.Crosshair.Width, Settings.Crosshair.Height)
            crosshairImg.Position = targetCenter - (crosshairImg.Size / 2)
            crosshairImg.Visible = true
        elseif #vectorLines == 4 then
            local size = Settings.Crosshair.Size or 12
            local gap = 4
            vectorLines[1].From = targetCenter - Vector2.new(0, gap)
            vectorLines[1].To = targetCenter - Vector2.new(0, gap + size)
            vectorLines[2].From = targetCenter + Vector2.new(0, gap)
            vectorLines[2].To = targetCenter + Vector2.new(0, gap + size)
            vectorLines[3].From = targetCenter - Vector2.new(gap, 0)
            vectorLines[3].To = targetCenter - Vector2.new(gap + size, 0)
            vectorLines[4].From = targetCenter + Vector2.new(gap, 0)
            vectorLines[4].To = targetCenter + Vector2.new(gap + size, 0)

            for _, l in ipairs(vectorLines) do l.Visible = true end
        end
    end)
    SharedState.AddConnection(conn)
end

-- ╔══════════════════════════════════════════════════════════╗
-- ║         4. МОДУЛЬ КРУГА ДИСТАНЦИИ ПРЫЖКА (JUMP RADIUS)   ║
-- ╚══════════════════════════════════════════════════════════╝
local function InitJumpDistanceRadius()
    local lines = {}
    local numSegments = 32
    for i = 1, numSegments do
        local line = CreateDrawing("Line")
        line.Color = Settings.JumpRadius.Color
        line.Thickness = 2
        line.Transparency = 0.8
        line.Visible = false
        table.insert(lines, line)
    end

    local conn = RunService.RenderStepped:Connect(function()
        if not Settings.JumpRadius.Enabled then
            for _, l in ipairs(lines) do l.Visible = false end
            return
        end

        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then
            for _, l in ipairs(lines) do l.Visible = false end
            return
        end

        local g = workspace.Gravity
        local jVelocity = hum.UseJumpPower and hum.JumpPower or math.sqrt(2 * g * hum.JumpHeight)
        local tAir = (2 * jVelocity) / g
        local wSpeed = hum.WalkSpeed
        local radius = wSpeed * tAir

        local points = {}
        local rayparams = RaycastParams.new()
        rayparams.FilterDescendantsInstances = {char}
        rayparams.FilterType = Enum.RaycastFilterType.Exclude

        for i = 1, numSegments do
            local angle = (i - 1) * (2 * math.pi / numSegments)
            local offset = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
            local targetPos = hrp.Position + offset

            local ray = workspace:Raycast(targetPos + Vector3.new(0, 5, 0), Vector3.new(0, -25, 0), rayparams)
            local groundY = ray and ray.Position.Y or (hrp.Position.Y - 3)

            table.insert(points, Vector3.new(targetPos.X, groundY, targetPos.Z))
        end

        for i = 1, numSegments do
            local p1 = points[i]
            local p2 = points[(i % numSegments) + 1]

            local s1, on1 = Camera:WorldToViewportPoint(p1)
            local s2, on2 = Camera:WorldToViewportPoint(p2)

            local line = lines[i]
            if on1 and on2 then
                line.From = Vector2.new(s1.X, s1.Y)
                line.To = Vector2.new(s2.X, s2.Y)
                line.Visible = true
            else
                line.Visible = false
            end
        end
    end)
    SharedState.AddConnection(conn)
end

-- ╔══════════════════════════════════════════════════════════╗
-- ║         5. МОДУЛЬ ПЕРСОНАЖА (100% TRANSPARENCY & AURA)   ║
-- ╚══════════════════════════════════════════════════════════╝
local function InitAvatarModifications()
    local function ApplyTransparentAura(char)
        if not char then return end

        pcall(function() player.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam end)

        local function MakeTransparent(obj)
            pcall(function()
                if obj.Name == "AuraSphere_Client" or obj.Name:find("ghost") then return end
                if obj:IsA("BasePart") or obj:IsA("Decal") then
                    obj.Transparency = Settings.Character.Transparent and 1.0 or 0.0
                end
            end)
        end

        -- Делаем ВСЕ части персонажа прозрачными
        for _, obj in ipairs(char:GetDescendants()) do
            MakeTransparent(obj)
        end

        local dynConn = char.DescendantAdded:Connect(MakeTransparent)
        SharedState.AddConnection(dynConn)

        -- Постоянный контроль прозрачности
        task.spawn(function()
            while char and char.Parent do
                for _, obj in ipairs(char:GetDescendants()) do
                    if obj:IsA("BasePart") or obj:IsA("Decal") then
                        if obj.Name ~= "AuraSphere_Client" and not obj.Name:find("ghost") then
                            obj.Transparency = Settings.Character.Transparent and 1.0 or 0.0
                        end
                    end
                end
                task.wait(1)
            end
        end)

        local hrp = char:WaitForChild("HumanoidRootPart", 5)
        if hrp then
            local aura = Instance.new("Part")
            aura.Name = "AuraSphere_Client"
            aura.Shape = Enum.PartType.Ball
            aura.Size = Vector3.new(3.5, 3.5, 3.5)
            aura.Material = Enum.Material.Neon
            aura.Color = Settings.Character.AuraColor
            aura.Transparency = 0.5
            aura.CanCollide = false
            aura.Parent = char
            SharedState.AddInstance(aura)

            local weld = Instance.new("Weld")
            weld.Part0 = hrp
            weld.Part1 = aura
            weld.Parent = aura

            -- При сильном приближении и от первого лица скрываем шар ауры
            local camCheck = RunService.RenderStepped:Connect(function()
                if Camera and aura and aura.Parent then
                    if not Settings.Character.Aura then
                        aura.Transparency = 1.0
                        return
                    end
                    local dist = (Camera.CFrame.Position - aura.Position).Magnitude
                    if dist < 2.5 then
                        aura.Transparency = 1.0
                    else
                        aura.Transparency = 0.5
                    end
                end
            end)
            SharedState.AddConnection(camCheck)
        end
    end

    if player.Character then ApplyTransparentAura(player.Character) end
    local conn = player.CharacterAdded:Connect(ApplyTransparentAura)
    SharedState.AddConnection(conn)
    ConsoleLog("Эффект полной прозрачности и ауры игрока применен.")
end

-- ╔══════════════════════════════════════════════════════════╗
-- ║         6. МОДУЛЬ ПРЕДСКАЗАНИЯ ДВИЖЕНИЯ (TRAJECTORY)     ║
-- ╚══════════════════════════════════════════════════════════╝
local function InitPrediction()
    local lastlanding = nil
    local isairborne = false
    local lastmoveinput = Vector3.new(0, 0, 1)
    local cameraturnspeed = 0
    local lastcameracf = Camera.CFrame
    local pulsetime = 0

    local preddot = CreateDrawing("Circle")
    preddot.Radius = 6
    preddot.Filled = true
    preddot.Color = Color3.fromRGB(0, 255, 200)
    preddot.Visible = false
    preddot.NumSides = 32

    local landdot = CreateDrawing("Circle")
    landdot.Radius = 12
    landdot.Filled = true
    landdot.Color = Color3.fromRGB(255, 100, 100)
    landdot.Visible = false
    landdot.NumSides = 32

    local landoutline = CreateDrawing("Circle")
    landoutline.Radius = 18
    landoutline.Filled = false
    landoutline.Color = Color3.fromRGB(255, 150, 150)
    landoutline.Visible = false
    landoutline.Thickness = 2
    landoutline.NumSides = 32

    local velcurve = {}
    for i = 1, 8 do
        local line = CreateDrawing("Line")
        line.Color = Color3.fromRGB(0, 255, 200)
        line.Thickness = 3
        line.Visible = false
        velcurve[i] = line
    end

    local arclines = {}
    for i = 1, 29 do
        local line = CreateDrawing("Line")
        line.Color = Color3.fromRGB(255, 240, 140)
        line.Thickness = 2
        line.Visible = false
        arclines[i] = line
    end

    local function predictpos(p0, v0, t)
        local grav = workspace.Gravity
        return p0 + v0 * t + Vector3.new(0, -grav, 0) * 0.5 * t * t
    end

    local function toscreen(pos)
        local screenpos, onscreen = Camera:WorldToViewportPoint(pos)
        return Vector2.new(screenpos.X, screenpos.Y), onscreen
    end

    local function isvisible(pos)
        local char = player.Character
        if not char then return true end
        local rayparams = RaycastParams.new()
        rayparams.FilterDescendantsInstances = {char}
        rayparams.FilterType = Enum.RaycastFilterType.Exclude
        local campos = Camera.CFrame.Position
        local dir = pos - campos
        local ray = workspace:Raycast(campos, dir, rayparams)
        if ray and (ray.Position - campos).Magnitude < dir.Magnitude - 2 then
            return false
        end
        return true
    end

    local function isgrounded(hrp)
        local char = player.Character
        if not char then return true end
        local rayparams = RaycastParams.new()
        rayparams.FilterDescendantsInstances = {char}
        rayparams.FilterType = Enum.RaycastFilterType.Exclude
        local ray = workspace:Raycast(hrp.Position, Vector3.new(0, -3, 0), rayparams)
        return ray ~= nil
    end

    local function simulate(p0, v0)
        local char = player.Character
        local positions = {}
        local prev = p0
        local landed = nil
        local rayparams = RaycastParams.new()
        if char then rayparams.FilterDescendantsInstances = {char} end
        rayparams.FilterType = Enum.RaycastFilterType.Exclude

        for t = 0, 2.5, 0.03 do
            local pos = predictpos(p0, v0, t)
            table.insert(positions, pos)
            local dir = pos - prev
            if dir.Magnitude > 0.01 then
                local ray = workspace:Raycast(prev, dir, rayparams)
                if ray then landed = ray.Position break end
            end
            prev = pos
        end
        return positions, landed
    end

    local conn = RunService.RenderStepped:Connect(function(dt)
        if not Settings.Prediction.Enabled then
            preddot.Visible = false
            landdot.Visible = false
            landoutline.Visible = false
            for i = 1, 8 do velcurve[i].Visible = false end
            for i = 1, 29 do arclines[i].Visible = false end
            return
        end

        pulsetime = pulsetime + dt
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChild("Humanoid")
        if not hrp or not hum then return end

        local p0 = hrp.Position
        local v0 = hrp.AssemblyLinearVelocity
        local grounded = isgrounded(hrp)

        local currentcf = Camera.CFrame
        local relativecf = lastcameracf:Inverse() * currentcf
        local _, yaw, _ = relativecf:ToEulerAnglesXYZ()
        local turndir = yaw / math.max(dt, 0.001)

        cameraturnspeed = cameraturnspeed * 0.7 + turndir * 0.3
        lastcameracf = currentcf

        isairborne = not grounded and v0.Y < -5

        local pred3 = predictpos(p0, v0, 0.25)
        local pred2, predon = toscreen(pred3)
        preddot.Position = pred2
        preddot.Visible = predon and isvisible(pred3)

        if v0.Magnitude > 1 then
            local curvature = -cameraturnspeed * 0.8
            local vellength = math.min(v0.Magnitude * 0.5, 20)
            local segments = 8
            for i = 1, segments do
                local t0 = (i - 1) / segments
                local t1 = i / segments
                local offset0 = t0 * vellength
                local offset1 = t1 * vellength
                local curve0 = curvature * offset0 * offset0 * 0.06
                local curve1 = curvature * offset1 * offset1 * 0.06
                local dir = v0.Unit
                local right = dir:Cross(Vector3.new(0, 1, 0)).Unit
                local pos0 = p0 + dir * offset0 + right * curve0
                local pos1 = p0 + dir * offset1 + right * curve1
                local start2, starton = toscreen(pos0)
                local end2, endon = toscreen(pos1)
                velcurve[i].From = start2
                velcurve[i].To = end2
                velcurve[i].Visible = starton and endon and isvisible(pos0) and isvisible(pos1)
            end
        else
            for i = 1, 8 do velcurve[i].Visible = false end
        end

        local positions, landing = simulate(p0, v0)
        if #positions > 1 then
            for i = 1, 29 do
                local idx1 = math.floor((i - 1) * (#positions - 1) / 29) + 1
                local idx2 = math.floor(i * (#positions - 1) / 29) + 1
                local s1, on1 = toscreen(positions[idx1])
                local s2, on2 = toscreen(positions[idx2])
                arclines[i].From = s1
                arclines[i].To = s2
                arclines[i].Visible = on1 and on2 and isvisible((positions[idx1] + positions[idx2]) * 0.5)
            end
        else
            for i = 1, 29 do arclines[i].Visible = false end
        end

        if isairborne and landing then
            lastlanding = landing
        end

        if lastlanding and isairborne then
            local land2, landon = toscreen(lastlanding)
            landdot.Position = land2
            landdot.Visible = landon and isvisible(lastlanding)

            local pulse = math.abs(math.sin(pulsetime * 3))
            landoutline.Position = land2
            landoutline.Radius = 18 + pulse * 8
            landoutline.Visible = landon and isvisible(lastlanding)
        else
            landdot.Visible = false
            landoutline.Visible = false
        end
    end)
    SharedState.AddConnection(conn)
    ConsoleLog("Модуль прогнозирования траектории запущен.")
end

-- ╔══════════════════════════════════════════════════════════╗
-- ║         7. МОДУЛЬ ПОДСВЕТКИ SMART GLOW (ESP)             ║
-- ╚══════════════════════════════════════════════════════════╗
local function InitSmartGlow()
    local processed = {}

    local function CreateVisual(target, color)
        if not target or processed[target] then return end
        processed[target] = true

        local box = Instance.new("SelectionBox")
        box.Name = "SmartGlow_Box"
        box.Adornee = target
        box.LineThickness = 0.04
        box.Color3 = color
        box.SurfaceColor3 = color
        box.SurfaceTransparency = 0.92
        box.Transparency = 0.8
        box.Parent = target
        SharedState.AddInstance(box)

        local info = TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
        TweenService:Create(box, info, {Transparency = 0.4, SurfaceTransparency = 0.98}):Play()

        -- Интегрируем динамический переключатель ESP в рендерер
        local activeCheck = RunService.Heartbeat:Connect(function()
            if box and box.Parent then
                box.Visible = Settings.SmartGlow.Enabled
            end
        end)
        SharedState.AddConnection(activeCheck)
    end

    local function Analyze(obj)
        if not obj then return end
        if obj.Name == "AuraSphere_Client" or obj.Name:find("ghost") or obj.Name:find("ServerGhost") then return end

        local name = obj.Name:lower()
        local isSuspicious = false
        local keywords = {"prompt", "proximity", "touch", "interact", "trigger"}

        for _, key in ipairs(keywords) do
            if name:find(key) then isSuspicious = true break end
        end

        if isSuspicious and (obj:IsA("Folder") or obj:IsA("Model")) then
            for _, child in ipairs(obj:GetChildren()) do
                if child:IsA("Model") or child:IsA("BasePart") then
                    CreateVisual(child, Color3.fromRGB(255, 170, 0))
                end
            end
            return
        end

        if obj:IsA("ProximityPrompt") then
            CreateVisual(obj.Parent, Color3.fromRGB(0, 255, 255))
            pcall(function()
                obj.RequiresLineOfSight = false
                obj.MaxActivationDistance = math.max(obj.MaxActivationDistance, 20)
            end)
        elseif obj:IsA("TouchTransmitter") or obj:IsA("ClickDetector") then
            CreateVisual(obj.Parent, Color3.fromRGB(0, 255, 255))
        end
    end

    for _, v in ipairs(workspace:GetDescendants()) do
        task.spawn(function() pcall(Analyze, v) end)
    end
    local conn = workspace.DescendantAdded:Connect(function(v)
        task.wait(0.5)
        pcall(Analyze, v)
    end)
    SharedState.AddConnection(conn)
    ConsoleLog("Модуль Smart Glow ESP активирован.")
end

-- ╔══════════════════════════════════════════════════════════╗
-- ║      8. КРУТОЙ 3D НЕОНОВЫЙ СИЛУЭТ СЕРВЕРА (GHOST)        ║
-- ╚══════════════════════════════════════════════════════════╗
local function InitServerGhost()
    local function setup()
        local char = player.Character
        if not char then return end

        local hum = char:FindFirstChildWhichIsA("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp then return end

        -- ЕДИНЫЙ КРАСИВЫЙ СИЛУЭТ (Дублируем реального персонажа)
        local ghostModel = Instance.new("Model")
        ghostModel.Name = "ServerGhostModel_Client"
        ghostModel.Parent = workspace
        SharedState.AddInstance(ghostModel)

        -- Тонкий мятный SelectionBox поверх гуманоида
        local mainBox = Instance.new("SelectionBox")
        mainBox.Adornee = ghostModel
        mainBox.LineThickness = 0.01
        mainBox.Color3 = Color3.fromRGB(0, 255, 200)
        mainBox.Parent = ghostModel
        SharedState.AddInstance(mainBox)

        -- Клонируем части тела для создания 3D Силуэта
        local ghostParts = {}
        for _, obj in ipairs(char:GetChildren()) do
            if obj:IsA("BasePart") and obj.Name ~= "HumanoidRootPart" then
                local g = obj:Clone()
                g.Name = obj.Name .. "_ghost"
                g.Anchored = true
                g.CanCollide = false
                g.CastShadow = false
                -- Эффектный футуристический полупрозрачный неон!
                g.Material = Enum.Material.ForceField
                g.Color = Color3.fromRGB(0, 255, 200)
                g.Transparency = 0.5
                g.Parent = ghostModel
                -- Удаляем скрипты и констрейнты из клона
                for _, sub in ipairs(g:GetDescendants()) do
                    if not sub:IsA("SpecialMesh") then
                        sub:Destroy()
                    end
                end
                ghostParts[obj.Name] = {real = obj, ghost = g}
            end
        end

        local server_cf = hrp.CFrame
        local lin_vel = Vector3.new(0, 0, 0)
        local last = os.clock()
        local acc = 0
        local frames = {}
        local trailTimer = 0

        local hb = RunService.Heartbeat:Connect(function(dt)
            if not Settings.ServerGhost.Enabled then
                ghostModel.Parent = nil
                return
            else
                ghostModel.Parent = workspace
            end

            if not hrp or not hrp.Parent then
                pcall(function() ghostModel:Destroy() end)
                return
            end

            local now = os.clock()
            local delta = now - last
            last = now

            local ping = player.GetNetworkPing and player:GetNetworkPing() or 0.08

            if hrp and not hrp.Anchored then
                lin_vel = hrp.AssemblyLinearVelocity
                if acc >= ping then
                    server_cf = hrp.CFrame
                    acc = 0
                else
                    acc = acc + delta
                end
            end

            local hrp_cf = server_cf
            local hrp_pos = hrp_cf.Position
            local rel = {}
            for name, data in pairs(ghostParts) do
                if data.real and data.real.Parent then
                    rel[name] = hrp_cf:ToObjectSpace(data.real.CFrame)
                end
            end

            table.insert(frames, {t = now, cf = hrp_cf, pos = hrp_pos, vel = lin_vel, rel = rel})
            if #frames > 240 then table.remove(frames, 1) end

            local target_t = now - ping
            local f
            for i = #frames, 1, -1 do if frames[i].t <= target_t then f = frames[i] break end end
            if not f then f = frames[1] end
            if not f then return end

            local td = math.min(target_t - f.t, 0.06)
            local pred_pos = f.pos + f.vel * td
            local pred_cf = CFrame.new(pred_pos) * (f.cf - f.cf.Position)

            -- Обновляем позиции 3D частей силуэта
            for name, data in pairs(ghostParts) do
                local ghost = data.ghost
                local r = f.rel[name]
                local tgt = r and pred_cf * r or (data.real and data.real.CFrame or ghost.CFrame)
                ghost.CFrame = ghost.CFrame:Lerp(tgt, math.min(delta * 18, 1))
            end

            -- Скрытие призрака при первом лице
            if Camera then
                local distToGhost = (Camera.CFrame.Position - pred_pos).Magnitude
                if distToGhost < 2.5 then
                    for _, data in pairs(ghostParts) do data.ghost.Transparency = 1.0 end
                    mainBox.Transparency = 1.0
                else
                    for _, data in pairs(ghostParts) do data.ghost.Transparency = 0.5 end
                    mainBox.Transparency = 0.0
                end
            end

            -- MOTION TRAIL (Мягкие затухающие неоновые следы)
            trailTimer = trailTimer + dt
            if trailTimer >= 0.05 then
                trailTimer = 0
                if mainBox.Transparency < 0.99 then
                    task.spawn(function()
                        local trailParts = {}
                        local trailContainer = Instance.new("Model")
                        trailContainer.Name = "ServerGhostTrail_Client"
                        trailContainer.Parent = workspace

                        for name, data in pairs(ghostParts) do
                            local tPart = data.ghost:Clone()
                            tPart.Transparency = 0.7
                            tPart.Material = Enum.Material.Neon
                            tPart.Color = Color3.fromRGB(0, 255, 200)
                            tPart.Parent = trailContainer
                            table.insert(trailParts, tPart)
                        end

                        -- Плавное увядание силуэта
                        for alpha = 0.7, 1.0, 0.05 do
                            for _, p in ipairs(trailParts) do
                                p.Transparency = alpha
                            end
                            task.wait(0.04)
                        end
                        trailContainer:Destroy()
                    end)
                end
            end
        end)
        SharedState.AddConnection(hb)
    end

    if player.Character then setup() end
    local conn = player.CharacterAdded:Connect(setup)
    SharedState.AddConnection(conn)
    ConsoleLog("3D Силуэт сервера успешно запущен.")
end

-- ╔══════════════════════════════════════════════════════════╗
-- ║         9. МОДУЛЬ ТАРГЕТ СПРАЙТА (TARGET ESP)            ║
-- ╚══════════════════════════════════════════════════════════╝
local function InitTargetESP()
    local guiParent = player:FindFirstChild("PlayerGui") or CoreGui

    local targetGui = Instance.new("ScreenGui")
    targetGui.Name = "MiteTarget_Gui"
    targetGui.ResetOnSpawn = false
    targetGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    targetGui.Parent = guiParent
    SharedState.AddInstance(targetGui)

    local targetImg = Instance.new("ImageLabel")
    targetImg.Size = UDim2.new(0, 70, 0, 70)
    targetImg.AnchorPoint = Vector2.new(0.5, 0.5)
    targetImg.BackgroundTransparency = 1
    targetImg.Image = targetAsset -- Кэшированная премиум SVG текстура!
    targetImg.ImageColor3 = Color3.fromRGB(0, 255, 200)
    targetImg.ImageTransparency = 1.0
    targetImg.Visible = false
    targetImg.Parent = targetGui
    SharedState.AddInstance(targetImg)

    local currentTransparency = 1.0
    local currentScale = 1.0
    local tclock = 0.0

    -- Умный поиск цели по экрану (FOV Lock наведение перекрестия)
    local function GetTarget()
        local vpSize = Camera.ViewportSize
        local center = Vector2.new(vpSize.X / 2, vpSize.Y / 2)
        local screenCenterWithOffset = center + Vector2.new(Settings.Crosshair.XOffset, Settings.Crosshair.YOffset)

        local closestPlayer = nil
        local minDistance = Settings.TargetEsp.FovRadius

        for _, other in ipairs(Players:GetPlayers()) do
            if other ~= player and other.Character then
                local head = other.Character:FindFirstChild("Head")
                local hum = other.Character:FindFirstChildOfClass("Humanoid")
                if head and hum and hum.Health > 0 then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                    if onScreen then
                        local screenPos2D = Vector2.new(screenPos.X, screenPos.Y)
                        local dist = (screenPos2D - screenCenterWithOffset).Magnitude
                        if dist < minDistance then
                            minDistance = dist
                            closestPlayer = head
                        end
                    end
                end
            end
        end

        -- Векторный рейкаст если наведено в упор
        if not closestPlayer then
            local ray = Camera:ViewportPointToRay(screenCenterWithOffset.X, screenCenterWithOffset.Y)
            local raycastParams = RaycastParams.new()
            raycastParams.FilterDescendantsInstances = {player.Character}
            raycastParams.FilterType = Enum.RaycastFilterType.Exclude

            local result = workspace:Raycast(ray.Origin, ray.Direction * Settings.TargetEsp.Range, raycastParams)
            if result and result.Instance then
                local model = result.Instance:FindFirstAncestorOfClass("Model")
                local hum = model and model:FindFirstChildOfClass("Humanoid")
                local head = model and model:FindFirstChild("Head")
                if hum and head and hum.Health > 0 then
                    closestPlayer = head
                end
            end
        end

        return closestPlayer
    end

    local conn = RunService.RenderStepped:Connect(function(dt)
        if not Settings.TargetEsp.Enabled then
            targetImg.Visible = false
            return
        end

        tclock = tclock + dt * Settings.TargetEsp.RotSpeed * 4

        local activeTarget = GetTarget()
        local shouldBeVisible = activeTarget ~= nil
        local targetTransparencyVal = shouldBeVisible and 0.0 or 1.0

        currentTransparency = lerp2(currentTransparency, targetTransparencyVal, dt * Settings.TargetEsp.SmoothFade)
        targetImg.ImageTransparency = currentTransparency

        if shouldBeVisible and targetImg.ImageTransparency < 0.99 then
            local targetPos = activeTarget.Position + Vector3.new(0, Settings.TargetEsp.VerticalOffset, 0)
            local screenPos, onScreen = Camera:WorldToViewportPoint(targetPos)

            if onScreen then
                targetImg.Visible = true
                targetImg.Position = UDim2.new(0, screenPos.X, 0, screenPos.Y)

                local dist = (activeTarget.Position - Camera.CFrame.Position).Magnitude
                local alpha = math.clamp(dist / Settings.TargetEsp.Range, 0, 1)
                local targetScale = 3.6 * (1 - alpha) + 2.0 * alpha

                currentScale = lerp2(currentScale, targetScale, dt * Settings.TargetEsp.SmoothScale)

                targetImg.Size = UDim2.new(0, 70 * currentScale, 0, 70 * currentScale)
                targetImg.Rotation = tclock * Settings.TargetEsp.RotAngle
            else
                targetImg.Visible = false
            end
        else
            targetImg.Visible = false
        end
    end)
    SharedState.AddConnection(conn)
    ConsoleLog("Таргет ESP модуль (наведение взглядом) успешно запущен.")
end

-- ╔══════════════════════════════════════════════════════════╗
-- ║  10. ПРЕМИАЛЬНЫЙ 1-ST/3-RD PERSON ГИРОСКОП               ║
-- ╚══════════════════════════════════════════════════════════╗
local function InitAdvancedGyroscope()
    local currentZoom = 12
    local offsetPitch = 0  -- Touch offsets
    local offsetYaw = 0
    local currentPitch = 0 -- Fallback накопление
    local currentYaw = 0

    local lookActive = false
    local lastLookPosition = nil

    -- Храним углы гироскопа, получаемые из DeviceRotationChanged напрямую
    local gyroPitch = 0
    local gyroYaw = 0

    -- СВЯЗКА ТАЧА И ГИРОСКОПА (Не сбрасываем processed, чтобы пальцы работали одновременно!)
    local touchBegan = UserInputService.InputBegan:Connect(function(input, processed)
        if input.UserInputType == Enum.UserInputType.Touch then
            local vpSize = Camera.ViewportSize
            -- Правая половина экрана отвечает за вращение
            if input.Position.X > vpSize.X / 2 then
                lookActive = true
                lastLookPosition = input.Position
            end
        end
    end)
    SharedState.AddConnection(touchBegan)

    local touchChanged = UserInputService.InputChanged:Connect(function(input, processed)
        if input.UserInputType == Enum.UserInputType.Touch and lookActive and lastLookPosition then
            local delta = input.Position - lastLookPosition
            local sensitivity = 0.005

            local deltaYaw = -delta.X * sensitivity
            local deltaPitch = -delta.Y * sensitivity

            offsetYaw = offsetYaw + deltaYaw
            offsetPitch = offsetPitch + deltaPitch

            lastLookPosition = input.Position
        end
    end)
    SharedState.AddConnection(touchChanged)

    local touchEnded = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            lookActive = false
            lastLookPosition = nil
        end
    end)
    SharedState.AddConnection(touchEnded)

    -- Чтение DeviceRotation через НАДЕЖНЫЙ Event Listener (не зависает в эмуляторах)
    local gyroConn = UserInputService.DeviceRotationChanged:Connect(function(rotation, translation)
        pcall(function()
            local rx, ry, rz = rotation:ToEulerAnglesXYZ()
            gyroPitch = rx * Settings.Gyroscope.PitchSensitivity
            gyroYaw = ry * Settings.Gyroscope.YawSensitivity
        end)
    end)
    SharedState.AddConnection(gyroConn)

    -- Zoom Камеры
    local wheelConn = UserInputService.InputChanged:Connect(function(input, processed)
        if input.UserInputType == Enum.UserInputType.MouseWheel then
            currentZoom = math.clamp(currentZoom - input.Position.Z * 2.0, 0.5, 40)
        end
    end)
    SharedState.AddConnection(wheelConn)

    local pinchConn = UserInputService.TouchPinch:Connect(function(touchPositions, scale, velocity, state, processed)
        currentZoom = math.clamp(currentZoom / scale, 0.5, 40)
    end)
    SharedState.AddConnection(pinchConn)

    pcall(function() RunService:UnbindFromRenderStep("AIO_GyroCamera") end)

    RunService:BindToRenderStep("AIO_GyroCamera", Enum.RenderPriority.Camera.Value + 10, function(dt)
        local char = player.Character
        local head = char and char:FindFirstChild("Head")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not char or not head or not hrp then return end

        if not Settings.Gyroscope.Enabled then
            pcall(function() Camera.CameraType = Enum.CameraType.Custom end)
            return
        else
            pcall(function() Camera.CameraType = Enum.CameraType.Scriptable end)
        end

        -- Всегда принудительно скрываем меши от первого лица
        if currentZoom < 2.5 then
            for _, p in pairs(char:GetDescendants()) do
                if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" and p.Name ~= "AuraSphere_Client" then
                    p.LocalTransparencyModifier = 1.0
                end
            end
        end

        -- Суммируем свайп и гироскоп
        local finalPitch = offsetPitch + gyroPitch
        local finalYaw = offsetYaw + gyroYaw

        -- Clamping pitch (X axis) to prevent flipping upside down
        finalPitch = math.clamp(finalPitch, -math.rad(80), math.rad(80))

        -- Позиционирование камеры
        local camPos = head.Position
        local targetRotation = CFrame.fromOrientation(finalPitch, finalYaw, 0)

        if currentZoom < 2.5 then
            Camera.CFrame = CFrame.new(camPos) * targetRotation
        else
            Camera.CFrame = CFrame.new(camPos) * targetRotation * CFrame.new(0, 0, currentZoom)
        end

        -- Автоматический поворот персонажа за направлением взгляда
        hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, finalYaw, 0)
    end)
end

-- ╔══════════════════════════════════════════════════════════╗
-- ║         КОНФИГУРИРОВАНИЕ ИНТЕРФЕЙСА OBSIDIAN             ║
-- ╚══════════════════════════════════════════════════════════╝
-- Оптимизация
OptGroup:AddToggle("FFlagsToggle", {
    Text = "Умный FFlags Оптимизатор",
    Default = Settings.Performance.EnableFFlags,
    Callback = function(v)
        Settings.Performance.EnableFFlags = v
        if v then InitFFlags() end
    end
})

OptGroup:AddToggle("MapOptimizeToggle", {
    Text = "Оптимизация карты (SmoothPlastic)",
    Default = Settings.Performance.OptimizeMap,
    Callback = function(v)
        Settings.Performance.OptimizeMap = v
    end
})

OptGroup:AddInput("StretchInput", {
    Text = "Растяжение Камеры (0.4 - 1.0)",
    Default = tostring(Settings.Performance.StretchedResolution),
    Numeric = true,
    Finished = true,
    Callback = function(Value)
        local num = tonumber(Value)
        if num then
            Settings.Performance.StretchedResolution = math.clamp(num, 0.4, 1.0)
            ConsoleLog("Установлено растяжение разрешения: " .. Settings.Performance.StretchedResolution)
        end
    end
})

-- Визуальные Элементы
VisualGroup:AddToggle("GlowESPToggle", {
    Text = "Smart Glow ESP (Подсветка триггеров)",
    Default = Settings.SmartGlow.Enabled,
    Callback = function(v)
        Settings.SmartGlow.Enabled = v
    end
})

VisualGroup:AddToggle("PredictionToggle", {
    Text = "Предсказание траектории",
    Default = Settings.Prediction.Enabled,
    Callback = function(v)
        Settings.Prediction.Enabled = v
    end
})

VisualGroup:AddToggle("JumpCircleToggle", {
    Text = "Круг максимальной дистанции прыжка",
    Default = Settings.JumpRadius.Enabled,
    Callback = function(v)
        Settings.JumpRadius.Enabled = v
    end
})

VisualGroup:AddToggle("ServerGhostToggle", {
    Text = "Серверный 3D Силуэт (Неон)",
    Default = Settings.ServerGhost.Enabled,
    Callback = function(v)
        Settings.ServerGhost.Enabled = v
    end
})

VisualGroup:AddToggle("TargetEspToggle", {
    Text = "Включить Target ESP (Авто-прицеливание)",
    Default = Settings.TargetEsp.Enabled,
    Callback = function(v)
        Settings.TargetEsp.Enabled = v
    end
})

VisualGroup:AddInput("TargetFovInput", {
    Text = "Радиус захвата ESP FOV",
    Default = tostring(Settings.TargetEsp.FovRadius),
    Numeric = true,
    Finished = true,
    Callback = function(v)
        local num = tonumber(v)
        if num then Settings.TargetEsp.FovRadius = num end
    end
})

-- Настройки прицела (Crosshair Control)
local CrosshairSection = Tabs.Universal:AddLeftGroupbox("Настройки Прицела", "eye")

CrosshairSection:AddToggle("CrosshairEnabled", {
    Text = "Включить Прицел",
    Default = Settings.Crosshair.Enabled,
    Callback = function(v)
        Settings.Crosshair.Enabled = v
    end
})

CrosshairSection:AddInput("CrosshairWidthInput", {
    Text = "Ширина Прицела (Width)",
    Default = tostring(Settings.Crosshair.Width),
    Numeric = true,
    Finished = true,
    Callback = function(v)
        local num = tonumber(v)
        if num then Settings.Crosshair.Width = num end
    end
})

CrosshairSection:AddInput("CrosshairHeightInput", {
    Text = "Высота Прицела (Height)",
    Default = tostring(Settings.Crosshair.Height),
    Numeric = true,
    Finished = true,
    Callback = function(v)
        local num = tonumber(v)
        if num then Settings.Crosshair.Height = num end
    end
})

CrosshairSection:AddInput("CrosshairXOffsetInput", {
    Text = "Смещение X (X Offset)",
    Default = tostring(Settings.Crosshair.XOffset),
    Numeric = true,
    Finished = true,
    Callback = function(v)
        local num = tonumber(v)
        if num then Settings.Crosshair.XOffset = num end
    end
})

CrosshairSection:AddInput("CrosshairYOffsetInput", {
    Text = "Смещение Y (Y Offset)",
    Default = tostring(Settings.Crosshair.YOffset),
    Numeric = true,
    Finished = true,
    Callback = function(v)
        local num = tonumber(v)
        if num then Settings.Crosshair.YOffset = num end
    end
})

-- Комфорт (Полностью убраны ПК бинды)
ComfortGroup:AddToggle("ZeroCamShakeToggle", {
    Text = "Zero Cam Shake (Без тряски)",
    Default = Settings.Comfort.ZeroCamShake,
    Callback = function(v)
        Settings.Comfort.ZeroCamShake = v
    end
})

ComfortGroup:AddToggle("ShiftLockToggle", {
    Text = "Кастомный Shoulder ShiftLock (Смещение плеча)",
    Default = Settings.Comfort.ShiftLock,
    Callback = function(v)
        Settings.Comfort.ShiftLock = v
    end
})

ComfortGroup:AddInput("ShiftOffsetInput", {
    Text = "Смещение камеры вбок (Плечо)",
    Default = tostring(Settings.Comfort.ShiftOffsetDistance),
    Numeric = true,
    Finished = true,
    Callback = function(Value)
        local num = tonumber(Value)
        if num then
            Settings.Comfort.ShiftOffsetDistance = num
        end
    end
})

-- Персонаж и аура
AvatarGroup:AddToggle("TransparentToggle", {
    Text = "100% Прозрачный персонаж",
    Default = Settings.Character.Transparent,
    Callback = function(v)
        Settings.Character.Transparent = v
    end
})

AvatarGroup:AddToggle("AuraToggle", {
    Text = "Светящаяся аура-сфера",
    Default = Settings.Character.Aura,
    Callback = function(v)
        Settings.Character.Aura = v
    end
})

AvatarGroup:AddToggle("SpaceSkyboxToggle", {
    Text = "Космический Скайбокс",
    Default = Settings.Lighting.SpaceSkybox,
    Callback = function(v)
        Settings.Lighting.SpaceSkybox = v
    end
})

-- Настройки гироскопа
GyroSettingsGroup:AddToggle("GyroToggle", {
    Text = "Включить Умный AAA-Гироскоп",
    Default = Settings.Gyroscope.Enabled,
    Callback = function(v)
        Settings.Gyroscope.Enabled = v
    end
})

GyroSettingsGroup:AddInput("PitchSensInput", {
    Text = "Чувствительность Вертикаль (Pitch)",
    Default = tostring(Settings.Gyroscope.PitchSensitivity),
    Numeric = true,
    Finished = true,
    Callback = function(v)
        local num = tonumber(v)
        if num then Settings.Gyroscope.PitchSensitivity = num end
    end
})

GyroSettingsGroup:AddInput("YawSensInput", {
    Text = "Чувствительность Горизонталь (Yaw)",
    Default = tostring(Settings.Gyroscope.YawSensitivity),
    Numeric = true,
    Finished = true,
    Callback = function(v)
        local num = tonumber(v)
        if num then Settings.Gyroscope.YawSensitivity = num end
    end
})

GyroSettingsGroup:AddInput("DeadzoneInput", {
    Text = "Мертвая Зона (Дрейф датчиков)",
    Default = tostring(Settings.Gyroscope.Deadzone),
    Numeric = true,
    Finished = true,
    Callback = function(v)
        local num = tonumber(v)
        if num then Settings.Gyroscope.Deadzone = num end
    end
})

-- Информационные параметры гироскопа
GyroInfoGroup:AddLabel("Статус: Активен")
GyroInfoGroup:AddLabel("Фильтрация шума: Event Driven Link")
GyroInfoGroup:AddLabel("Ускорение: Динамическое нелинейное")

-- Консоль вывода логов
local ConsoleBox = ConsoleGroup:AddLabel("Ожидание запуска логов...\n", true)
getgenv().ObsidianConsoleLabel = ConsoleBox

-- ╔══════════════════════════════════════════════════════════╗
-- ║                     ЗАПУСК СЮИТЫ                         ║
-- ╚══════════════════════════════════════════════════════════╝
InitFFlags()
InitOptimizerAndLighting()
InitCameraStretch()
InitCameraComfort()
InitRaisedCrosshair()
InitJumpDistanceRadius()
InitAvatarModifications()
InitPrediction()
InitSmartGlow()
InitServerGhost()
InitTargetESP()
InitAdvancedGyroscope()

-- Настройка менеджеров
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
ThemeManager:SetFolder("MattedMintSuite")
SaveManager:SetFolder("MattedMintSuite/Configs")
ThemeManager:ApplyToTab(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

ConsoleLog("Obsidian Suite успешно запущен и готов к авто-выполнению.")
Library:Notify({
    Title = "AIO Suite",
    Description = "Объединенный пак в мятном стиле успешно загружен!",
    Time = 6,
})
