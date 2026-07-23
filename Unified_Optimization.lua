--[[
    ╔══════════════════════════════════════════════════════════╗
    ║       UNIFIED OPTIMIZATION & INFO SUITE (AIO)            ║
    ║   Объединенный и улучшенный скрипт для авто-выполнения   ║
    ║                                                          ║
    ║   Особенности:                                           ║
    ║   1. Модульная структура с полной изоляцией переменных    ║
    ║   2. Полная защита от повторного запуска (без утечек)    ║
    ║   3. Единое и красивое меню настроек в начале файла     ║
    ║   4. Интегрированные уведомления для всех событий         ║
    ║   5. Оптимальный рендеринг и совместимость с Drawing     ║
    ╚══════════════════════════════════════════════════════════╝
]]

-- ╔══════════════════════════════════════════════════════════╗
-- ║                  ГЛОБАЛЬНЫЕ НАСТРОЙКИ                    ║
-- ╚══════════════════════════════════════════════════════════╝
local Settings = {
    Notifications = {
        Enabled = true,
        Duration = 5,
        ThemeColor = Color3.fromRGB(0, 255, 200),
        BgColor = Color3.fromRGB(20, 20, 25),
    },
    Performance = {
        EnableFFlags = true,      -- Включить тонкую настройку FFlags для максимального FPS
        OptimizeMap = true,       -- Удалить тяжелые текстуры и упростить материалы карты
        DisableParticles = true,  -- Выключить тяжелые эффекты частиц и следы (Trails)
    },
    Screen = {
        StretchedResolution = 0.65, -- "Растянутый экран" (камера-трюк). 0.65 = шире/больше FPS, 1.0 = выключено
    },
    Prediction = {
        Enabled = true,
        PreJumpEnabled = false,   -- Показ траектории до прыжка по умолчанию (Клавиша 'H' для вкл/выкл)
        PredictDotColor = Color3.fromRGB(0, 255, 255),
        LandDotColor = Color3.fromRGB(255, 100, 100),
        LandOutlineColor = Color3.fromRGB(255, 150, 150),
        VelocityColor = Color3.fromRGB(0, 255, 0),
        TrajectoryColor = Color3.fromRGB(255, 240, 140),
        PreJumpColor = Color3.fromRGB(100, 200, 255),
    },
    SmartGlow = {
        Enabled = true,
        Keywords = {"prompt", "proximity", "touch", "interact", "trigger"},
        FolderColor = Color3.fromRGB(255, 170, 0), -- Цвет свечения для папок/групп
        SingleColor = Color3.fromRGB(0, 255, 255), -- Цвет свечения для одиночных объектов
        Transparency = 0.8,                        -- Прозрачность линий
        PulseSpeed = 1.5,                          -- Период пульсации в секундах
    },
    ServerGhost = {
        Enabled = true,
        UseRGB = false,                            -- Использовать RGB радугу для призрака пинга
        Color = Color3.fromRGB(150, 255, 200),     -- Мягкий мятный цвет призрака
        Strength = 1.0,                            -- Множитель силы предсказания пинга
        MaxLimbDistance = 6,                       -- Максимальный разброс конечностей призрака
    }
}

-- ╔══════════════════════════════════════════════════════════╗
-- ║             ИНИЦИАЛИЗАЦИЯ И СИСТЕМА ОЧИСТКИ              ║
-- ╚══════════════════════════════════════════════════════════╝
local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService  = game:GetService("HttpService")
local CoreGui      = game:GetService("CoreGui")

local player = Players.LocalPlayer

-- Защита от повторного запуска (Предотвращает дублирование хуков, отрисовок и лагов)
if getgenv().UnifiedOptimizationSharedState then
    pcall(getgenv().UnifiedOptimizationSharedState.Cleanup)
end

local SharedState = {
    Connections = {},
    Drawings = {},
    Instances = {},
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
    -- Удаляем созданные UI, Part-объекты и призраков
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

-- Динамическое получение текущей камеры (на случай смены/спавна)
local Camera = workspace.CurrentCamera or workspace:FindFirstChildOfClass("Camera")
local camConnection = workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    Camera = workspace.CurrentCamera or workspace:FindFirstChildOfClass("Camera")
end)
SharedState.AddConnection(camConnection)

-- ╔══════════════════════════════════════════════════════════╗
-- ║                     СИСТЕМА УВЕДОМЛЕНИЙ                  ║
-- ╚══════════════════════════════════════════════════════════╝
local guiParent
pcall(function()
    if gethui then
        guiParent = gethui()
    elseif cloneref then
        guiParent = cloneref(CoreGui)
    else
        guiParent = player:WaitForChild("PlayerGui")
    end
end)

local notificationGui = Instance.new("ScreenGui")
notificationGui.Name = "SMVLL_Notif_" .. HttpService:GenerateGUID(false):sub(1, 8)
notificationGui.ResetOnSpawn = false
notificationGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() notificationGui.Parent = guiParent end)
SharedState.AddInstance(notificationGui)

local activeNotifications = {}
local CONSTANTS = {
    WIDTH = 280,
    HEIGHT = 90,
    PADDING = 15,
    ANIMATION_SPEED = 0.4
}

local function UpdateNotifications()
    for index, data in ipairs(activeNotifications) do
        local targetY = -CONSTANTS.PADDING - ((index - 1) * (CONSTANTS.HEIGHT + CONSTANTS.PADDING))
        TweenService:Create(data.Container, TweenInfo.new(CONSTANTS.ANIMATION_SPEED, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = UDim2.new(1, -CONSTANTS.PADDING, 1, targetY)
        }):Play()
    end
end

local function ShowNotification(titleText, messageText, duration)
    if not Settings.Notifications.Enabled then return end
    duration = duration or Settings.Notifications.Duration

    local container = Instance.new("Frame")
    container.Size = UDim2.new(0, CONSTANTS.WIDTH, 0, CONSTANTS.HEIGHT)
    container.Position = UDim2.new(1, 350, 1, -CONSTANTS.PADDING)
    container.AnchorPoint = Vector2.new(1, 1)
    container.BackgroundTransparency = 1
    container.Parent = notificationGui
    SharedState.AddInstance(container)

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.BackgroundColor3 = Settings.Notifications.BgColor
    frame.BorderSizePixel = 0
    frame.Parent = container

    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(40, 40, 45)
    stroke.Thickness = 1
    stroke.Parent = frame

    local topAccent = Instance.new("Frame")
    topAccent.Size = UDim2.new(1, 0, 0, 2)
    topAccent.BackgroundColor3 = Settings.Notifications.ThemeColor
    topAccent.BorderSizePixel = 0
    topAccent.Parent = frame

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -50, 0, 25)
    titleLabel.Position = UDim2.new(0, 15, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = titleText
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 16
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = frame

    local messageLabel = Instance.new("TextLabel")
    messageLabel.Size = UDim2.new(1, -30, 0, 40)
    messageLabel.Position = UDim2.new(0, 15, 0, 35)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Text = messageText
    messageLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    messageLabel.Font = Enum.Font.GothamMedium
    messageLabel.TextSize = 13
    messageLabel.TextWrapped = true
    messageLabel.TextXAlignment = Enum.TextXAlignment.Left
    messageLabel.TextYAlignment = Enum.TextYAlignment.Top
    messageLabel.Parent = frame

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 24, 0, 24)
    closeBtn.Position = UDim2.new(1, -10, 0, 10)
    closeBtn.AnchorPoint = Vector2.new(1, 0)
    closeBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 12
    closeBtn.AutoButtonColor = false
    closeBtn.Parent = frame

    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

    local dots = {}
    local closed = false

    for i = 1, 3 do
        local dot = Instance.new("Frame")
        dot.Size = UDim2.new(0, 6, 0, 6)
        dot.Position = UDim2.new(0, 15 + (i - 1) * 14, 1, -18)
        dot.AnchorPoint = Vector2.new(0.5, 0.5)
        dot.BackgroundColor3 = Settings.Notifications.ThemeColor
        dot.BorderSizePixel = 0
        dot.Parent = frame

        Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
        dots[i] = dot

        task.delay((i - 1) * 0.15, function()
            if not closed then
                TweenService:Create(dot, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
                    Position = UDim2.new(0, dot.Position.X.Offset, 1, -22)
                }):Play()
            end
        end)
    end

    local notifData = {Container = container}
    table.insert(activeNotifications, 1, notifData)
    UpdateNotifications()

    TweenService:Create(frame, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
        Rotation = 1.2,
        Position = UDim2.new(0.5, 0, 0.5, -3)
    }):Play()

    closeBtn.MouseEnter:Connect(function()
        TweenService:Create(closeBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(220, 50, 50), TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
    end)
    closeBtn.MouseLeave:Connect(function()
        TweenService:Create(closeBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30, 30, 35), TextColor3 = Color3.fromRGB(150, 150, 150)}):Play()
    end)

    local function CloseNotification()
        if closed then return end
        closed = true

        local targetIndex = table.find(activeNotifications, notifData)
        if targetIndex then
            table.remove(activeNotifications, targetIndex)
            UpdateNotifications()
        end

        local tweenOut = TweenService:Create(container, TweenInfo.new(CONSTANTS.ANIMATION_SPEED, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
            Position = UDim2.new(1, 350, container.Position.Y.Scale, container.Position.Y.Offset)
        })
        tweenOut:Play()
        tweenOut.Completed:Wait()
        container:Destroy()
    end

    closeBtn.MouseButton1Click:Connect(CloseNotification)

    local interval = duration / 3
    for i = 3, 1, -1 do
        task.delay(interval * (4 - i), function()
            if not closed and dots[i] then
                local popTween = TweenService:Create(dots[i], TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
                    Size = UDim2.new(0, 0, 0, 0),
                    BackgroundTransparency = 1
                })
                popTween:Play()
                if i == 1 then
                    popTween.Completed:Wait()
                    if not closed then CloseNotification() end
                end
            end
        end)
    end
end

-- ╔══════════════════════════════════════════════════════════╗
-- ║         1. МОДУЛЬ: ТАБЛИЦА И ИНЪЕКЦИЯ FFLAGS             ║
-- ╚══════════════════════════════════════════════════════════╝
local flagtables = {
    -- Performance & Task Scheduler
    ["DFIntTaskSchedulerTargetFps"] = "9999",
    ["FIntTaskSchedulerAutoThreadLimit"] = "6",
    ["FIntTaskSchedulerAsyncTasksMinimumThreadCount"] = "2",
    ["FIntTaskSchedulerMaxNumOfJobs"] = "86",
    ["FIntTaskSchedulerThreadMin"] = "1",

    -- DFFlags
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

    -- Network / RakNet
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

    -- Client Packet / Networking
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

    -- SignalR
    ["DFIntSignalRHubConnectionHeartbeatTimerRateMs"] = "1000",
    ["DFIntSignalRHubConnectionBaseRetryTimeMs"] = "100",
    ["DFIntSignalRCoreKeepAlivePingPeriodMs"] = "250",
    ["DFIntSignalRCoreServerTimeoutMs"] = "11100",
    ["DFIntSignalRCoreTimerMs"] = "750",
    ["DFIntSignalRCoreRpcQueueSize"] = "256",

    -- Animation / Rendering
    ["DFIntAnimationLodFacsVisibilityDenominator"] = "0",
    ["DFIntAnimationLodFacsDistanceMin"] = "0",
    ["DFIntAnimationLodFacsDistanceMax"] = "0",
    ["DFIntDebugFRMQualityLevelOverride"] = "1",
    ["DFIntDebugDynamicRenderKiloPixels"] = "1100",
    ["DFIntDebugRestrictGCDistance"] = "1",

    -- Wait Timers
    ["DFIntWaitOnUpdateNetworkLoopEndedMS"] = "100",
    ["DFIntWaitOnRecvFromLoopEndedMS"] = "100",

    -- FInt Rendering / Graphics
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

    -- FFlags
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
    z = z:gsub("^DFInt", "")
    z = z:gsub("^DFFlag", "")
    z = z:gsub("^FFlag", "")
    z = z:gsub("^FInt", "")
    z = z:gsub("FString", "")
    z = z:gsub("FLog", "")
    return z
end

local function InitFFlags()
    if not Settings.Performance.EnableFFlags then return end

    if not setfflag then
        ShowNotification("FFlags Optimizer", "Клиент не поддерживает setfflag. Оптимизация FFlags пропущена.", 5)
        return
    end

    ShowNotification("Совместимость", "Применение оптимизации FFlags в фоне...", 5)

    task.spawn(function()
        local start = os.clock()
        local injectedCount = 0

        for k, v in pairs(flagtables) do
            -- Безопасная задержка для предотвращения фризов и вылетов при инжекте
            for i = 1, 5 do RunService.RenderStepped:Wait() end

            pcall(function()
                local formatted = formatFlag(k)
                if getfflag(formatted) then
                    setfflag(formatted, v)
                    injectedCount = injectedCount + 1
                elseif getfflag(k) then
                    setfflag(k, v)
                    injectedCount = injectedCount + 1
                end
            end)
        end

        local elapsed = string.format("%.2f", os.clock() - start)
        ShowNotification("Успешно", "Загружено " .. injectedCount .. " оптимизаций FFlags за " .. elapsed .. "сек.", 5)

        print("╔════════════════════════════════════════╗")
        print("║          PERFORMANCE OVERHAUL          ║")
        print("║   FFlags Set   → " .. string.format("%02d", injectedCount) .. " flags")
        print("║   Time Taken   → " .. elapsed .. "s")
        print("╚════════════════════════════════════════╝")
    end)
end

-- ╔══════════════════════════════════════════════════════════╗
-- ║        2. МОДУЛЬ: СТРЕТЧ И АНТИЛАГ КАРТЫ (OPTIMIZER)     ║
-- ╚══════════════════════════════════════════════════════════╗
local function InitOptimizerAndStretch()
    -- Удаление и сброс материалов на карте
    if Settings.Performance.OptimizeMap then
        local function OptimizeObject(obj)
            pcall(function()
                if obj:IsA("Decal") or obj:IsA("Texture") then
                    obj:Destroy()
                elseif obj:IsA("BasePart") or obj:IsA("MeshPart") or obj:IsA("UnionOperation") then
                    obj.Material = Enum.Material.SmoothPlastic
                    obj.Reflectance = 0
                    if obj:IsA("MeshPart") then
                        obj.TextureID = ""
                    end
                end
                if Settings.Performance.DisableParticles and (obj:IsA("ParticleEmitter") or obj:IsA("Trail")) then
                    obj.Enabled = false
                end
            end)
        end

        for _, obj in ipairs(workspace:GetDescendants()) do
            OptimizeObject(obj)
        end

        local mapConnection = workspace.DescendantAdded:Connect(OptimizeObject)
        SharedState.AddConnection(mapConnection)

        ShowNotification("Оптимизация", "Тяжелые текстуры удалены, шейдеры заменены на SmoothPlastic.", 4)
    end

    -- Трюк растяжения разрешения (Stretched Camera Trick)
    if Settings.Screen.StretchedResolution and Settings.Screen.StretchedResolution < 1.0 then
        local stretchedConn = RunService.RenderStepped:Connect(function()
            if Camera then
                pcall(function()
                    Camera.CFrame = Camera.CFrame * CFrame.new(0, 0, 0, 1, 0, 0, 0, Settings.Screen.StretchedResolution, 0, 0, 0, 1)
                end)
            end
        end)
        SharedState.AddConnection(stretchedConn)

        ShowNotification("Экран", "Установлено кастомное растяжение экрана: " .. Settings.Screen.StretchedResolution, 4)
    end
end

-- ╔══════════════════════════════════════════════════════════╗
-- ║         3. МОДУЛЬ: ПРЕДСКАЗАНИЕ ДВИЖЕНИЯ (PREDICTION)    ║
-- ╚══════════════════════════════════════════════════════════╝
local function InitPrediction()
    if not Settings.Prediction.Enabled then return end

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

    local lastlanding = nil
    local isairborne = false
    local lastmoveinput = v3(0, 0, 1)
    local cameraturnspeed = 0
    local lastcameracf = Camera.CFrame
    local pulsetime = 0

    -- Создание элементов рисования
    local preddot = CreateDrawing("Circle")
    preddot.Radius = 6
    preddot.Filled = true
    preddot.Color = Settings.Prediction.PredictDotColor
    preddot.Visible = false
    preddot.Transparency = 1
    preddot.NumSides = 32

    local landdot = CreateDrawing("Circle")
    landdot.Radius = 12
    landdot.Filled = true
    landdot.Color = Settings.Prediction.LandDotColor
    landdot.Visible = false
    landdot.Transparency = 1
    landdot.NumSides = 32

    local landoutline = CreateDrawing("Circle")
    landoutline.Radius = 18
    landoutline.Filled = false
    landoutline.Color = Settings.Prediction.LandOutlineColor
    landoutline.Visible = false
    landoutline.Transparency = 1
    landoutline.Thickness = 2
    landoutline.NumSides = 32

    local velline = CreateDrawing("Line")
    velline.Color = Settings.Prediction.VelocityColor
    velline.Thickness = 3
    velline.Visible = false
    velline.Transparency = 1

    local velcurve = {}
    for i = 1, 8 do
        local line = CreateDrawing("Line")
        line.Color = Settings.Prediction.VelocityColor
        line.Thickness = 3
        line.Visible = false
        line.Transparency = 1
        velcurve[i] = line
    end

    local arclines = {}
    for i = 1, 29 do
        local line = CreateDrawing("Line")
        line.Color = Settings.Prediction.TrajectoryColor
        line.Thickness = 2
        line.Visible = false
        line.Transparency = 1
        arclines[i] = line
    end

    local prejumplines = {}
    for i = 1, 29 do
        local line = CreateDrawing("Line")
        line.Color = Settings.Prediction.PreJumpColor
        line.Thickness = 2
        line.Visible = false
        line.Transparency = 0.7
        prejumplines[i] = line
    end

    local prejumplanddot = CreateDrawing("Circle")
    prejumplanddot.Radius = 10
    prejumplanddot.Filled = true
    prejumplanddot.Color = Settings.Prediction.PreJumpColor
    prejumplanddot.Visible = false
    prejumplanddot.Transparency = 0.7
    prejumplanddot.NumSides = 32

    local function predictpos(p0, v0, t)
        local grav = workspace.Gravity
        return p0 + v0 * t + v3(0, -grav, 0) * 0.5 * t * t
    end

    local function toscreen(pos)
        if not Camera then return v2(0, 0), false end
        local screenpos, onscreen = Camera:WorldToViewportPoint(pos)
        return v2(screenpos.X, screenpos.Y), onscreen
    end

    local function isvisible(pos)
        local char = player.Character
        if not char then return true end
        local rayparams = RaycastParams.new()
        rayparams.FilterDescendantsInstances = {char}
        rayparams.FilterType = Enum.RaycastFilterType.Exclude

        local campos = Camera.CFrame.Position
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
        local char = player.Character
        if not char then return true end
        local rayparams = RaycastParams.new()
        rayparams.FilterDescendantsInstances = {char}
        rayparams.FilterType = Enum.RaycastFilterType.Exclude

        local ray = workspace:Raycast(hrp.Position, v3(0, -3, 0), rayparams)
        return ray ~= nil
    end

    local function simulate(p0, v0)
        local char = player.Character
        local positions = {}
        local prev = p0
        local landed = nil

        local rayparams = RaycastParams.new()
        if char then
            rayparams.FilterDescendantsInstances = {char}
        end
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

    -- Переключение траектории кнопкой 'H'
    local inputConnection = game:GetService("UserInputService").InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.H then
            Settings.Prediction.PreJumpEnabled = not Settings.Prediction.PreJumpEnabled
            ShowNotification("Траектория", "Показ арки прыжка: " .. (Settings.Prediction.PreJumpEnabled and "ВКЛЮЧЕН" or "ВЫКЛЮЧЕН"), 3)
        end
    end)
    SharedState.AddConnection(inputConnection)

    local renderConnection = RunService.RenderStepped:Connect(function(dt)
        pulsetime = pulsetime + dt

        local char = player.Character
        if not char or not char.Parent then return end

        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChild("Humanoid")
        if not hrp or not hum then return end

        local p0 = hrp.Position
        local v0 = hrp.AssemblyLinearVelocity
        local grounded = isgrounded(hrp)

        local currentcf = Camera.CFrame
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

        if Settings.Prediction.PreJumpEnabled and not isairborne then
            local camlook = Camera.CFrame.LookVector
            local camright = Camera.CFrame.RightVector

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
    SharedState.AddConnection(renderConnection)

    print("\n[PREDICTION] Запущено:")
    print("Голубой круг = прогнозируемая позиция")
    print("Желтый = траектория движения")
    print("Зеленый = вектор скорости")
    print("Красный = точка приземления")
    print("Нажмите клавишу 'H' для вывода симуляции прыжка")
end

-- ╔══════════════════════════════════════════════════════════╗
-- ║        4. МОДУЛЬ: ПОДСВЕТКА ИНТЕРАКТИВОВ (SMART GLOW)    ║
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
        box.Transparency = Settings.SmartGlow.Transparency
        box.Parent = target
        SharedState.AddInstance(box)

        -- Плавная бесконечная анимация пульсации
        local info = TweenInfo.new(Settings.SmartGlow.PulseSpeed, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
        local tween = TweenService:Create(box, info, {Transparency = 0.4, SurfaceTransparency = 0.98})
        tween:Play()
    end

    local function Analyze(obj)
        if not obj then return end

        local name = obj.Name:lower()
        local isSuspiciousName = false

        for _, key in ipairs(Settings.SmartGlow.Keywords) do
            if name:find(key) then
                isSuspiciousName = true
                break
            end
        end

        if isSuspiciousName and (obj:IsA("Folder") or obj:IsA("Model")) then
            for _, child in ipairs(obj:GetChildren()) do
                if child:IsA("Model") or child:IsA("BasePart") then
                    CreateVisual(child, Settings.SmartGlow.FolderColor)
                end
            end
            return
        end

        if obj:IsA("ProximityPrompt") then
            CreateVisual(obj.Parent, Settings.SmartGlow.SingleColor)
            pcall(function()
                obj.RequiresLineOfSight = false
                obj.MaxActivationDistance = math.max(obj.MaxActivationDistance, 20)
            end)
        elseif obj:IsA("TouchTransmitter") or obj:IsA("ClickDetector") then
            CreateVisual(obj.Parent, Settings.SmartGlow.SingleColor)
        end
    end

    for _, v in ipairs(workspace:GetDescendants()) do
        task.spawn(function() pcall(Analyze, v) end)
    end

    local connection = workspace.DescendantAdded:Connect(function(v)
        task.wait(0.5)
        pcall(Analyze, v)
    end)
    SharedState.AddConnection(connection)

    ShowNotification("Интерактивы", "Smart Glow ESP активен. Триггеры и промпты подсвечены.", 4)
end

-- ╔══════════════════════════════════════════════════════════╗
-- ║         5. МОДУЛЬ: СЕРВЕРНЫЙ ПРИЗРАК ПИНГА (SERVER POS)   ║
-- ╚══════════════════════════════════════════════════════════╝
local function InitServerGhost()
    if not Settings.ServerGhost.Enabled then return end

    local part_names = {
        "HumanoidRootPart","Head","Left Arm","Right Arm","Left Leg","Right Leg",
        "LeftUpperArm","RightUpperArm","LeftLowerArm","RightLowerArm",
        "LeftHand","RightHand","LeftUpperLeg","RightUpperLeg",
        "LeftLowerLeg","RightLowerLeg","LeftFoot","RightFoot"
    }

    local function rgb(t)
        return Color3.fromHSV((t % 5) / 5, 1, 1)
    end

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
        b.Parent = g
        SharedState.AddInstance(b)

        return {real = real, ghost = g, box = b}
    end

    local function is_replicate(p)
        return p and not p.Anchored
    end

    local function is_owner(p)
        return p and p.ReceiveAge == 0
    end

    local function setup()
        local char = player.Character
        if not char then return end

        -- Очистка старых призраков из Workspace
        for _, o in ipairs(workspace:GetChildren()) do
            if o:IsA("Part") and o.Name:find("_ghost$") then
                pcall(function() o:Destroy() end)
            end
        end

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
        local hb

        hb = RunService.Heartbeat:Connect(function(dt)
            if not hrp or not hrp.Parent or not player.Character or hrp.Parent ~= player.Character then
                for _, g in pairs(ghosts) do
                    if g.ghost then pcall(function() g.ghost:Destroy() end) end
                end
                hb:Disconnect()
                return
            end

            local now = os.clock()
            local delta = now - last
            last = now

            local ping = player.GetNetworkPing and player:GetNetworkPing() or 0.08

            if is_replicate(hrp) then
                if is_owner(hrp) then
                    lin_vel = hrp.AssemblyLinearVelocity
                else
                    lin_vel = -hrp.AssemblyLinearVelocity
                end
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
            if #frames > 240 then
                for i = 1, 60 do table.remove(frames, 1) end
            end

            local target_t = now - ping
            local f
            for i = #frames, 1, -1 do
                if frames[i].t <= target_t then
                    f = frames[i]
                    break
                end
            end
            if not f then f = frames[1] end
            if not f then return end

            local td = math.min(target_t - f.t, 0.06)
            local pred_pos = f.pos + f.vel * td * Settings.ServerGhost.Strength
            local pred_cf = CFrame.new(pred_pos) * (f.cf - f.cf.Position)

            for n, g in pairs(ghosts) do
                local ghost = g.ghost
                local box = g.box
                local r = f.rel[n]
                local tgt = r and pred_cf * r or (g.real and g.real.CFrame or ghost.CFrame)
                local d = (tgt.Position - pred_cf.Position).Magnitude
                if d > Settings.ServerGhost.MaxLimbDistance then
                    local dir = (tgt.Position - pred_cf.Position).Unit
                    local p = pred_cf.Position + dir * Settings.ServerGhost.MaxLimbDistance
                    local rx, ry, rz = tgt:ToEulerAnglesXYZ()
                    tgt = CFrame.new(p) * CFrame.Angles(rx, ry, rz)
                end
                ghost.CFrame = ghost.CFrame:Lerp(tgt, math.min(delta * 18, 1))

                if Settings.ServerGhost.UseRGB then
                    box.Color3 = rgb(now)
                else
                    box.Color3 = Settings.ServerGhost.Color
                end
            end
        end)
        SharedState.AddConnection(hb)
    end

    if player.Character then
        task.spawn(setup)
    end

    local charAddedConn = player.CharacterAdded:Connect(function(char)
        char:WaitForChild("HumanoidRootPart", 3)
        task.wait(0.2)
        setup()
    end)
    SharedState.AddConnection(charAddedConn)

    ShowNotification("Пинг-Призрак", "Визуализация серверной позиции на основе пинга активна.", 4)
end

-- ╔══════════════════════════════════════════════════════════╗
-- ║                      ЗАПУСК ВСЕХ МОДУЛЕЙ                 ║
-- ╚══════════════════════════════════════════════════════════╝
ShowNotification("AIO Suite", "Загрузка объединенного пака оптимизаций...", 4)
task.wait(0.5)

InitFFlags()
InitOptimizerAndStretch()
InitPrediction()
InitSmartGlow()
InitServerGhost()

ShowNotification("Готово", "Все модули успешно запущены и оптимизированы!", 6)
