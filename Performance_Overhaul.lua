
--[[
    Hey
]]

-- ╔══════════════════╗
-- ║         SERVICES
-- ╚══════════════════╝
local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService  = game:GetService("HttpService")
local CoreGui      = game:GetService("CoreGui")

local player = Players.LocalPlayer

-- ╔════════════════════════╗
-- ║     GUI stuuf 
-- ╚════════════════════════╝
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

-- Configuration Constants
local activeNotifications = {}
local CONSTANTS = {
    WIDTH = 280,
    HEIGHT = 90,
    PADDING = 15,
    THEME_COLOR = Color3.fromRGB(0, 255, 200),
    BG_COLOR = Color3.fromRGB(20, 20, 25),
    TEXT_COLOR = Color3.fromRGB(255, 255, 255),
    SUBTEXT_COLOR = Color3.fromRGB(180, 180, 180),
    ANIMATION_SPEED = 0.4
}

-- ╔══════════════════════════╗
-- ║     notif.  
-- ╚══════════════════════════╝
local function UpdateNotifications()
    for index, data in ipairs(activeNotifications) do
        local targetY = -CONSTANTS.PADDING - ((index - 1) * (CONSTANTS.HEIGHT + CONSTANTS.PADDING))
        
        TweenService:Create(data.Container, TweenInfo.new(CONSTANTS.ANIMATION_SPEED, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = UDim2.new(1, -CONSTANTS.PADDING, 1, targetY)
        }):Play()
    end
end

local function ShowNotification(titleText, messageText, duration)
    duration = duration or 6

    local container = Instance.new("Frame")
    container.Size = UDim2.new(0, CONSTANTS.WIDTH, 0, CONSTANTS.HEIGHT)
    container.Position = UDim2.new(1, 350, 1, -CONSTANTS.PADDING)
    container.AnchorPoint = Vector2.new(1, 1)
    container.BackgroundTransparency = 1
    container.Parent = notificationGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.BackgroundColor3 = CONSTANTS.BG_COLOR
    frame.BorderSizePixel = 0
    frame.Parent = container

    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(40, 40, 45)
    stroke.Thickness = 1
    stroke.Parent = frame

    local topAccent = Instance.new("Frame")
    topAccent.Size = UDim2.new(1, 0, 0, 2)
    topAccent.BackgroundColor3 = CONSTANTS.THEME_COLOR
    topAccent.BorderSizePixel = 0
    topAccent.Parent = frame

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -50, 0, 25)
    titleLabel.Position = UDim2.new(0, 15, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = titleText
    titleLabel.TextColor3 = CONSTANTS.TEXT_COLOR
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 16
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = frame

    local messageLabel = Instance.new("TextLabel")
    messageLabel.Size = UDim2.new(1, -30, 0, 40)
    messageLabel.Position = UDim2.new(0, 15, 0, 35)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Text = messageText
    messageLabel.TextColor3 = CONSTANTS.SUBTEXT_COLOR
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
        dot.BackgroundColor3 = CONSTANTS.THEME_COLOR
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

-- ╔════════════════════╗
-- ║       FFLAGS.
-- ╚════════════════════╝
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

-- ╔══════════════════════════════════════╗
-- ║     4. INJECTION DES FFLAGS          ║
-- ╚══════════════════════════════════════╝
local function formatFlag(z)
    z = z:gsub("^DFInt", "")
    z = z:gsub("^DFFlag", "")
    z = z:gsub("^FFlag", "")
    z = z:gsub("^FInt", "")
    z = z:gsub("FString", "")
    z = z:gsub("FLog", "")
    return z
end

ShowNotification("Support or nah?", "Checking executor compatibility...", 4)
task.wait(1)

if not setfflag then
    ShowNotification("Unsupported", "Executor does not support setfflag. Aborting.", 6)
    return
end

ShowNotification("Supported", "Applying FFlag performance configuration...", 10)

task.spawn(function()
    local start = os.clock()
    local injectedCount = 0

    for k, v in pairs(flagtables) do
        -- Anti-crash: yeild léger
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
    ShowNotification("Overhaul Loaded", injectedCount .. " FFlags successfully injected in " .. elapsed .. "s.", 10)

    -- ╔═════════════════════════╗
    -- ║    CONFIRMATION CONSOLE
    -- ╚═════════════════════════╝
    print("╔════════════════════════════════════════╗")
    print("║    UR MOM OVERHAUL")
    print("║   UI System    → Initialized")
    print("║   Compatibility→ Verified")
    print("║   FFlags Set   → " .. string.format("%02d", injectedCount) .. " flags")
    print("║   Time Taken   → " .. elapsed .. "s")
    print("╚════════════════════════════════════════╝")
end)
