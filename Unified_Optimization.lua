--[[
    ╔══════════════════════════════════════════════════════════╗
    ║        OBSIDIAN PREMIUM SUITE: UNIFIED & OPTIMIZED       ║
    ║   Объединенный и улучшенный пакет скриптов (AIO)         ║
    ║   Стиль: Мятный Графит (Matted Mint)                     ║
    ║                                                          ║
    ║   Особенности:                                           ║
    ║   - Полная интеграция с Obsidian UI Library              ║
    ║   - Перенесены универсалка.lua и console.lua             ║
    ║   - 100% прозрачность персонажа + neon аура-сфера        ║
    ║   - 5-столпный высокочувствительный мобильный гироскоп   ║
    ║   - Текстурный прицел img_0_pk.png с fallback            ║
    ║   - Полная защита от повторного запуска (без утечек)    ║
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
        if obj:IsA("Part") and obj.Name:find("_ghost$") then
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

-- Настройка мятного стиля по умолчанию
Library.Scheme = {
    AccentColor = Color3.fromRGB(150, 255, 200), -- Тот самый мягкий мятный цвет
    AccentColorDark = Color3.fromRGB(100, 200, 150),
    BackgroundColor = Color3.fromRGB(20, 20, 25),
    BorderColor = Color3.fromRGB(40, 40, 45),
    TextColor = Color3.fromRGB(255, 255, 255),
    SubTextColor = Color3.fromRGB(180, 180, 180),
}

local Window = Library:CreateWindow({
    Title = "Obsidian Suite | Matted Mint",
    Footer = "Разработано для авто-выполнения | v2.5",
    Icon = "rbxassetid://95816097006870",
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
    },
    Comfort = {
        ZeroCamShake = true,
        ShiftLock = false,
        ShiftLockKey = "L",
    },
    Crosshair = {
        Enabled = true,
        VerticalOffset = -20,
    },
    JumpRadius = {
        Enabled = true,
        Color = Color3.fromRGB(255, 170, 0),
    },
    Character = {
        Transparent = true,
        Aura = true,
        AuraColor = Color3.fromRGB(0, 255, 255),
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
    Gyroscope = {
        Enabled = true,
        PitchSensitivity = 1.2,
        YawSensitivity = 1.5,
        Deadzone = 0.005,
        AlphaMin = 0.1,
        AlphaMax = 0.9,
        AlphaSpeedCoeff = 8.0,
        AccelFactor = 1.5,
        AccelLimit = 2.5,
    }
}

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

    -- Настройки света (Fullbright + Сохранение Контраста)
    local function ApplyLighting()
        pcall(function()
            local Lighting = game:GetService("Lighting")
            if Settings.Lighting.Fullbright then
                Lighting.Brightness = 2
                Lighting.ClockTime = 14
                Lighting.GlobalShadows = not Settings.Lighting.ContrastPreserve

                if Settings.Lighting.ContrastPreserve then
                    -- Сохранение глубины: стены не будут абсолютно одинаково плоскими
                    Lighting.Ambient = Color3.fromRGB(135, 135, 145)
                    Lighting.OutdoorAmbient = Color3.fromRGB(155, 155, 165)
                else
                    Lighting.Ambient = Color3.fromRGB(255, 255, 255)
                    Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
                end
            end
            if Settings.Lighting.RemoveAtmosphere then
                for _, obj in ipairs(Lighting:GetChildren()) do
                    if obj:IsA("Atmosphere") or obj:IsA("Sky") or obj:IsA("Clouds") then
                        obj:Destroy()
                    end
                end
                Lighting.FogEnd = 999999
            end
        end)
    end

    ApplyLighting()
    local connL = game:GetService("Lighting").ChildAdded:Connect(function()
        task.wait(0.1)
        ApplyLighting()
    end)
    SharedState.AddConnection(connL)
    ConsoleLog("Оптимизация освещения и карты применена.")
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
-- ║         2. МОДУЛЬ КАМЕРЫ (SHIFT LOCK, ZERO SHAKE)        ║
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

    -- Custom ShiftLock / Shoulder Shift
    local shiftLockActive = false
    local shiftOffset = Vector3.new(2, 0.5, 0)

    local inputConn = UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if Settings.Comfort.ShiftLock and input.KeyCode == Enum.KeyCode[Settings.Comfort.ShiftLockKey] then
            shiftLockActive = not shiftLockActive
            UserInputService.MouseBehavior = shiftLockActive and Enum.MouseBehavior.LockCenter or Enum.MouseBehavior.Default
            Library:Notify({
                Title = "ShiftLock",
                Description = "Кастомный ShiftLock: " .. (shiftLockActive and "АКТИВЕН" or "ВЫКЛЮЧЕН"),
                Time = 2,
            })
        end
    end)
    SharedState.AddConnection(inputConn)

    local renderConn = RunService.RenderStepped:Connect(function()
        if Settings.Comfort.ShiftLock and shiftLockActive then
            UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local camLook = Camera.CFrame.LookVector
                local flatLook = Vector3.new(camLook.X, 0, camLook.Z).Unit
                pcall(function()
                    hrp.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + flatLook)
                end)
            end
            Camera.CFrame = Camera.CFrame * CFrame.new(shiftOffset)
        end
    end)
    SharedState.AddConnection(renderConn)
    ConsoleLog("Модули комфорта и кастомного ShiftLock подключены.")
end

-- ╔══════════════════════════════════════════════════════════╗
-- ║         3. МОДУЛЬ ПРИЦЕЛА (IMG_0_PK.PNG С FALLBACK)      ║
-- ╚══════════════════════════════════════════════════════════╗
local function InitRaisedCrosshair()
    if not Settings.Crosshair.Enabled then return end

    -- Попытка создать прицел на основе текстуры img_0_pk.png
    local crosshairImg
    local isCustom = false

    pcall(function()
        crosshairImg = CreateDrawing("Image")
        if isfile and isfile("img_0_pk.png") and readfile then
            crosshairImg.Data = readfile("img_0_pk.png")
            isCustom = true
        else
            -- Загружаем резервный онлайн-прицел напрямую
            crosshairImg.Data = game:HttpGet("https://raw.githubusercontent.com/Mediasama/Huesos/main/img_0_pk.png")
            isCustom = true
        end
        crosshairImg.Size = Vector2.new(32, 32)
        crosshairImg.Visible = true
    end)

    -- Fallback на векторный прицел в мятном стиле, если рисование изображения не поддерживается
    local vectorLines = {}
    if not isCustom then
        ConsoleLog("Текстура img_0_pk.png не поддерживается. Переключение на векторный fallback.")
        for i = 1, 4 do
            local line = CreateDrawing("Line")
            line.Color = Color3.fromRGB(150, 255, 200)
            line.Thickness = 1.5
            line.Visible = true
            table.insert(vectorLines, line)
        end
    end

    local conn = RunService.RenderStepped:Connect(function()
        local vpSize = Camera.ViewportSize
        local center = Vector2.new(vpSize.X / 2, vpSize.Y / 2)
        local targetCenter = center + Vector2.new(0, Settings.Crosshair.VerticalOffset)

        if isCustom and crosshairImg then
            crosshairImg.Position = targetCenter - Vector2.new(16, 16)
        elseif #vectorLines == 4 then
            local size, gap = 8, 4
            vectorLines[1].From = targetCenter - Vector2.new(0, gap)
            vectorLines[1].To = targetCenter - Vector2.new(0, gap + size)
            vectorLines[2].From = targetCenter + Vector2.new(0, gap)
            vectorLines[2].To = targetCenter + Vector2.new(0, gap + size)
            vectorLines[3].From = targetCenter - Vector2.new(gap, 0)
            vectorLines[3].To = targetCenter - Vector2.new(gap + size, 0)
            vectorLines[4].From = targetCenter + Vector2.new(gap, 0)
            vectorLines[4].To = targetCenter + Vector2.new(gap + size, 0)
        end
    end)
    SharedState.AddConnection(conn)
end

-- ╔══════════════════════════════════════════════════════════╗
-- ║         4. МОДУЛЬ КРУГА ДИСТАНЦИИ ПРЫЖКА (JUMP RADIUS)   ║
-- ╚══════════════════════════════════════════════════════════╝
local function InitJumpDistanceRadius()
    if not Settings.JumpRadius.Enabled then return end

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

        -- Камера без коллизии стен
        pcall(function() player.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam end)

        -- Делаем ВСЕ части персонажа полностью прозрачными
        for _, obj in ipairs(char:GetDescendants()) do
            if obj:IsA("BasePart") or obj:IsA("Decal") then
                obj.Transparency = Settings.Character.Transparent and 1.0 or 0.0
            end
        end

        if not Settings.Character.Aura then return end

        local hrp = char:WaitForChild("HumanoidRootPart", 5)
        if hrp then
            local aura = Instance.new("Part")
            aura.Name = "AuraSphere_Client"
            aura.Shape = Enum.PartType.Ball
            aura.Size = Vector3.new(3, 3, 3)
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

            -- Тонкая обводка, видимая через стены
            local sBox = Instance.new("SelectionBox")
            sBox.Name = "AuraGlowBox"
            sBox.Adornee = aura
            sBox.Color3 = Settings.Character.AuraColor
            sBox.LineThickness = 0.05
            sBox.Parent = aura
            SharedState.AddInstance(sBox)
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
    if not Settings.Prediction.Enabled then return end

    local lastlanding = nil
    local isairborne = false
    local lastmoveinput = Vector3.new(0, 0, 1)
    local cameraturnspeed = 0
    local lastcameracf = Camera.CFrame
    local pulsetime = 0

    local preddot = CreateDrawing("Circle")
    preddot.Radius = 6
    preddot.Filled = true
    preddot.Color = Settings.Prediction.PredictDotColor or Color3.fromRGB(0, 255, 255)
    preddot.Visible = false
    preddot.NumSides = 32

    local landdot = CreateDrawing("Circle")
    landdot.Radius = 12
    landdot.Filled = true
    landdot.Color = Settings.Prediction.LandDotColor or Color3.fromRGB(255, 100, 100)
    landdot.Visible = false
    landdot.NumSides = 32

    local landoutline = CreateDrawing("Circle")
    landoutline.Radius = 18
    landoutline.Filled = false
    landoutline.Color = Settings.Prediction.LandOutlineColor or Color3.fromRGB(255, 150, 150)
    landoutline.Visible = false
    landoutline.Thickness = 2
    landoutline.NumSides = 32

    local velcurve = {}
    for i = 1, 8 do
        local line = CreateDrawing("Line")
        line.Color = Settings.Prediction.VelocityColor or Color3.fromRGB(0, 255, 0)
        line.Thickness = 3
        line.Visible = false
        velcurve[i] = line
    end

    local arclines = {}
    for i = 1, 29 do
        local line = CreateDrawing("Line")
        line.Color = Settings.Prediction.TrajectoryColor or Color3.fromRGB(255, 240, 140)
        line.Thickness = 2
        line.Visible = false
        arclines[i] = line
    end

    local prejumplines = {}
    for i = 1, 29 do
        local line = CreateDrawing("Line")
        line.Color = Settings.Prediction.PreJumpColor or Color3.fromRGB(100, 200, 255)
        line.Thickness = 2
        line.Visible = false
        line.Transparency = 0.7
        prejumplines[i] = line
    end

    local prejumplanddot = CreateDrawing("Circle")
    prejumplanddot.Radius = 10
    prejumplanddot.Filled = true
    prejumplanddot.Color = Settings.Prediction.PreJumpColor or Color3.fromRGB(100, 200, 255)
    prejumplanddot.Visible = false
    prejumplanddot.NumSides = 32

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

        if Settings.Prediction.PreJumpEnabled and not isairborne then
            local walkspeed = hum.WalkSpeed or 16
            local futurevel = lastmoveinput * walkspeed
            local jumpvel = futurevel + Vector3.new(0, 50, 0)
            local prejumppositions, prejumplanding = simulate(p0, jumpvel)

            if #prejumppositions > 1 then
                for i = 1, 29 do
                    local idx1 = math.floor((i - 1) * (#prejumppositions - 1) / 29) + 1
                    local idx2 = math.floor(i * (#prejumppositions - 1) / 29) + 1
                    local s1, on1 = toscreen(prejumppositions[idx1])
                    local s2, on2 = toscreen(prejumppositions[idx2])
                    prejumplines[i].From = s1
                    prejumplines[i].To = s2
                    prejumplines[i].Visible = on1 and on2 and isvisible((prejumppositions[idx1] + prejumppositions[idx2]) * 0.5)
                end
            else
                for i = 1, 29 do prejumplines[i].Visible = false end
            end

            if prejumplanding then
                local preland2, prelandon = toscreen(prejumplanding)
                prejumplanddot.Position = preland2
                prejumplanddot.Visible = prelandon and isvisible(prejumplanding)
            else
                prejumplanddot.Visible = false
            end
        else
            for i = 1, 29 do prejumplines[i].Visible = false end
            prejumplanddot.Visible = false
        end
    end)
    SharedState.AddConnection(conn)
    ConsoleLog("Модуль прогнозирования траектории запущен.")
end

-- ╔══════════════════════════════════════════════════════════╗
-- ║         7. МОДУЛЬ ПОДСВЕТКИ SMART GLOW (ESP)             ║
-- ╚══════════════════════════════════════════════════════════╝
local function InitSmartGlow()
    if not Settings.SmartGlow.Enabled then return end
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
    end

    local function Analyze(obj)
        if not obj then return end
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
-- ║         8. МОДУЛЬ СЕРВЕРНОГО ПРИЗРАКА ПИНГА (GHOST)      ║
-- ╚══════════════════════════════════════════════════════════╝
local function InitServerGhost()
    if not Settings.ServerGhost.Enabled then return end

    local part_names = {
        "HumanoidRootPart","Head","Left Arm","Right Arm","Left Leg","Right Leg",
        "LeftUpperArm","RightUpperArm","LeftLowerArm","RightLowerArm",
        "LeftHand","RightHand","LeftUpperLeg","RightUpperLeg",
        "LeftLowerLeg","RightLowerLeg","LeftFoot","RightFoot"
    }

    local function make_ghost(real)
        local g = Instance.new("Part")
        g.Name = real.Name .. "_ghost"
        g.Size = real.Size
        g.Anchored = true
        g.CanCollide = false
        g.Transparency = 1
        g.CFrame = real.CFrame
        g.Parent = workspace
        SharedState.AddInstance(g)

        local b = Instance.new("SelectionBox")
        b.Adornee = g
        b.LineThickness = 0.02
        b.Color3 = Color3.fromRGB(150, 255, 200)
        b.Parent = g
        SharedState.AddInstance(b)

        return {real = real, ghost = g, box = b}
    end

    local function setup()
        local char = player.Character
        if not char then return end

        local hum = char:FindFirstChildWhichIsA("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp then return end

        local ghosts = {}
        for _, n in ipairs(part_names) do
            local p = char:FindFirstChild(n)
            if p and p:IsA("BasePart") then
                ghosts[n] = make_ghost(p)
            end
        end

        local server_cf = hrp.CFrame
        local lin_vel = Vector3.new(0, 0, 0)
        local last = os.clock()
        local acc = 0
        local frames = {}

        local hb = RunService.Heartbeat:Connect(function(dt)
            if not hrp or not hrp.Parent then
                for _, g in pairs(ghosts) do if g.ghost then g.ghost:Destroy() end end
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
            for n, g in pairs(ghosts) do
                if g.real and g.real.Parent then
                    rel[n] = hrp_cf:ToObjectSpace(g.real.CFrame)
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

            for n, g in pairs(ghosts) do
                local ghost = g.ghost
                local box = g.box
                local r = f.rel[n]
                local tgt = r and pred_cf * r or (g.real and g.real.CFrame or ghost.CFrame)
                ghost.CFrame = ghost.CFrame:Lerp(tgt, math.min(delta * 18, 1))
            end
        end)
        SharedState.AddConnection(hb)
    end

    if player.Character then setup() end
    local conn = player.CharacterAdded:Connect(setup)
    SharedState.AddConnection(conn)
    ConsoleLog("Серверный призрак пинга инициализирован.")
end

-- ╔══════════════════════════════════════════════════════════╗
-- ║         9. ВЫСОКОКЛАССНЫЙ ГИРОСКОП С FALLBACK (SENSOR)   ║
-- ╚══════════════════════════════════════════════════════════╝
local function InitAdvancedGyroscope()
    if not Settings.Gyroscope.Enabled then return end

    pcall(function() UserInputService.GyroscopeEnabled = true end)

    local sPrevPitch = 0
    local sPrevYaw = 0

    local conn = RunService.RenderStepped:Connect(function(dt)
        if not Settings.Gyroscope.Enabled then return end

        -- Многоуровневый алгоритм получения наклона (3 источника для 100% совместимости)
        local rawPitch, rawYaw = 0, 0
        local successRot, rotRate = pcall(function() return UserInputService:GetDeviceRotationRate() end)

        if successRot and rotRate and (math.abs(rotRate.X) > 0.01 or math.abs(rotRate.Y) > 0.01) then
            rawPitch = rotRate.X
            rawYaw = rotRate.Y
        else
            -- Источник 2: DeviceRotation CFrame
            local successCFrame, devRot = pcall(function() return UserInputService.DeviceRotation end)
            if successCFrame and devRot then
                local rx, ry, rz = devRot:ToEulerAnglesXYZ()
                rawPitch = rx
                rawYaw = ry
            else
                -- Источник 3: Попытка аппроксимировать по гравитационному наклону (акселерометр)
                local successGrav, devGrav = pcall(function() return UserInputService.DeviceGravity end)
                if successGrav and devGrav then
                    rawPitch = devGrav.Y * 2
                    rawYaw = devGrav.X * 2
                end
            end
        end

        -- Смягчение мертвой зоны
        if math.abs(rawPitch) < Settings.Gyroscope.Deadzone then rawPitch = 0 end
        if math.abs(rawYaw) < Settings.Gyroscope.Deadzone then rawYaw = 0 end

        -- Фильтрация низких частот + адаптивное сглаживание микротремора
        local magP = math.abs(rawPitch)
        local alphaP = Settings.Gyroscope.AlphaMin + (Settings.Gyroscope.AlphaMax - Settings.Gyroscope.AlphaMin) * (1 - math.exp(-Settings.Gyroscope.AlphaSpeedCoeff * magP * magP))
        local sFilteredPitch = alphaP * rawPitch + (1 - alphaP) * sPrevPitch
        sPrevPitch = sFilteredPitch

        local magY = math.abs(rawYaw)
        local alphaY = Settings.Gyroscope.AlphaMin + (Settings.Gyroscope.AlphaMax - Settings.Gyroscope.AlphaMin) * (1 - math.exp(-Settings.Gyroscope.AlphaSpeedCoeff * magY * magY))
        local sFilteredYaw = alphaY * rawYaw + (1 - alphaY) * sPrevYaw
        sPrevYaw = sFilteredYaw

        -- Нелинейное прогрессивное ускорение вращения
        local speedP = math.abs(sFilteredPitch)
        local accelP = 1 + (Settings.Gyroscope.AccelFactor * speedP * speedP) / (1 + (speedP / Settings.Gyroscope.AccelLimit) * (speedP / Settings.Gyroscope.AccelLimit))

        local speedY = math.abs(sFilteredYaw)
        local accelY = 1 + (Settings.Gyroscope.AccelFactor * speedY * speedY) / (1 + (speedY / Settings.Gyroscope.AccelLimit) * (speedY / Settings.Gyroscope.AccelLimit))

        local finalPitch = sFilteredPitch * Settings.Gyroscope.PitchSensitivity * accelP * dt
        local finalYaw = sFilteredYaw * Settings.Gyroscope.YawSensitivity * accelY * dt

        -- Плавное и точное ориентирование камеры (без заваливания горизонта)
        if math.abs(finalPitch) > 0.0001 or math.abs(finalYaw) > 0.0001 then
            pcall(function()
                local curCF = Camera.CFrame
                local pitchRot = CFrame.Angles(-finalPitch, 0, 0)
                local yawRot = CFrame.Angles(0, -finalYaw, 0)
                Camera.CFrame = CFrame.new(curCF.Position) * yawRot * curCF.Rotation * pitchRot
            end)
        end
    end)
    SharedState.AddConnection(conn)
    ConsoleLog("Продвинутый 5-осевой гироскоп успешно запущен.")
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

OptGroup:AddSlider("StretchSlider", {
    Text = "Растяжение Камеры (Камера-трюк)",
    Default = Settings.Performance.StretchedResolution,
    Min = 0.4,
    Max = 1.0,
    Rounding = 2,
    Callback = function(v)
        Settings.Performance.StretchedResolution = v
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
    Text = "Серверный призрак пинга",
    Default = Settings.ServerGhost.Enabled,
    Callback = function(v)
        Settings.ServerGhost.Enabled = v
    end
})

-- Комфорт
ComfortGroup:AddToggle("ZeroCamShakeToggle", {
    Text = "Zero Cam Shake (Без тряски)",
    Default = Settings.Comfort.ZeroCamShake,
    Callback = function(v)
        Settings.Comfort.ZeroCamShake = v
    end
})

ComfortGroup:AddToggle("ShiftLockToggle", {
    Text = "Кастомный Shoulder ShiftLock",
    Default = Settings.Comfort.ShiftLock,
    Callback = function(v)
        Settings.Comfort.ShiftLock = v
    end
})

ComfortGroup:AddDropdown("ShiftLockKeyDropdown", {
    Values = { "L", "Q", "Z", "LeftControl", "LeftShift" },
    Default = "L",
    Text = "Клавиша ShiftLock",
    Callback = function(v)
        Settings.Comfort.ShiftLockKey = v
    end
})

-- Персонаж и аура
AvatarGroup:AddToggle("TransparentToggle", {
    Text = "100% Прозрачный персонаж",
    Default = Settings.Character.Transparent,
    Callback = function(v)
        Settings.Character.Transparent = v
        local char = player.Character
        if char then
            for _, obj in ipairs(char:GetDescendants()) do
                if obj:IsA("BasePart") or obj:IsA("Decal") then
                    obj.Transparency = v and 1.0 or 0.0
                end
            end
        end
    end
})

AvatarGroup:AddToggle("AuraToggle", {
    Text = "Светящаяся аура-сфера",
    Default = Settings.Character.Aura,
    Callback = function(v)
        Settings.Character.Aura = v
    end
})

-- Настройки гироскопа
GyroSettingsGroup:AddToggle("GyroToggle", {
    Text = "Включить Умный Гироскоп",
    Default = Settings.Gyroscope.Enabled,
    Callback = function(v)
        Settings.Gyroscope.Enabled = v
    end
})

GyroSettingsGroup:AddSlider("PitchSens", {
    Text = "Чувствительность по Вертикали (Pitch)",
    Default = Settings.Gyroscope.PitchSensitivity,
    Min = 0.1,
    Max = 3.0,
    Rounding = 1,
    Callback = function(v) Settings.Gyroscope.PitchSensitivity = v end
})

GyroSettingsGroup:AddSlider("YawSens", {
    Text = "Чувствительность по Горизонтали (Yaw)",
    Default = Settings.Gyroscope.YawSensitivity,
    Min = 0.1,
    Max = 3.0,
    Rounding = 1,
    Callback = function(v) Settings.Gyroscope.YawSensitivity = v end
})

GyroSettingsGroup:AddSlider("DeadzoneSlider", {
    Text = "Мертвая Зона (Компенсация дрейфа)",
    Default = Settings.Gyroscope.Deadzone,
    Min = 0.0,
    Max = 0.02,
    Rounding = 4,
    Callback = function(v) Settings.Gyroscope.Deadzone = v end
})

-- Информационные параметры гироскопа
GyroInfoGroup:AddLabel("Статус: Активен")
GyroInfoGroup:AddLabel("Фильтрация шума: EMA Low-Pass")
GyroInfoGroup:AddLabel("Ускорение: Динамическое нелинейное")

-- Консоль вывода логов (console.lua)
local ConsoleBox = ConsoleGroup:AddLabel("ConsoleOutput", {
    Text = "Ожидание запуска логов...\n",
    DoesWrap = true,
})
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
