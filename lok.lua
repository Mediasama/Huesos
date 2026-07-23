local TweenService = game:GetService("TweenService")

-- [ НАСТРОЙКИ ] --
local Settings = {
    Keywords = {"prompt", "proximity", "touch", "interact", "trigger"}, 
    FolderColor = Color3.fromRGB(255, 170, 0),    -- Оранжевый для папок
    SingleColor = Color3.fromRGB(0, 255, 255),    -- Голубой для одиночек
    Transparency = 0.8,
    PulseSpeed = 1.5                              -- Скорость мигания (в секундах)
}

local processed = {}

-- [ ФУНКЦИЯ СОЗДАНИЯ КОРОБКИ ] --
local function CreateVisual(target, color)
    if not target or processed[target] then return end
    processed[target] = true

    -- SelectionBox обводит всю модель целиком, если указать её в Adornee
    local box = Instance.new("SelectionBox")
    box.Name = "SmartGlow_Box"
    box.Adornee = target
    box.LineThickness = 0.04
    box.Color3 = color
    box.SurfaceColor3 = color
    box.SurfaceTransparency = 0.92 
    box.Transparency = Settings.Transparency
    box.Parent = target

    -- Анимация пульсации
    local info = TweenInfo.new(Settings.PulseSpeed, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
    TweenService:Create(box, info, {Transparency = 0.4, SurfaceTransparency = 0.98}):Play()
end

-- [ ЛОГИКА АНАЛИЗА ] --
local function Analyze(obj)
    if not obj then return end
    
    local name = obj.Name:lower()
    local isSuspiciousName = false
    
    for _, key in ipairs(Settings.Keywords) do
        if name:find(key) then
            isSuspiciousName = true
            break
        end
    end

    -- Если папка/модель называется как промпт — красим её содержимое (модели/парты)
    if isSuspiciousName and (obj:IsA("Folder") or obj:IsA("Model")) then
        for _, child in ipairs(obj:GetChildren()) do
            if child:IsA("Model") or child:IsA("BasePart") then
                CreateVisual(child, Settings.FolderColor)
            end
        end
        return 
    end

    -- Если нашли сам триггер внутри обычной структуры
    if obj:IsA("ProximityPrompt") then
        CreateVisual(obj.Parent, Settings.SingleColor)
        obj.RequiresLineOfSight = false
        obj.MaxActivationDistance = math.max(obj.MaxActivationDistance, 20)
    elseif obj:IsA("TouchTransmitter") or obj:IsA("ClickDetector") then
        CreateVisual(obj.Parent, Settings.SingleColor)
    end
end

-- [ ЗАПУСК ] --
for _, v in ipairs(workspace:GetDescendants()) do
    task.spawn(function() pcall(Analyze, v) end)
end

workspace.DescendantAdded:Connect(function(v)
    task.wait(0.5)
    pcall(Analyze, v)
end)

game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "mediasama",
    Text = "Smart Glow Active (No Text)",
    Duration = 3
})
