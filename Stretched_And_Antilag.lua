-- Configurações Globais
getgenv().Resolution = {
    [".gg/scripters"] = 0.65 -- Quanto menor, mais FPS (e imagem mais esticada/baixa)
}

local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")

-- 1. PARTE: REMOÇÃO DE TEXTURAS E OTIMIZAÇÃO DE MATERIAIS
local function limparMapa()
    for _, objeto in pairs(game.Workspace:GetDescendants()) do
        if objeto:IsA("Decal") or objeto:IsA("Texture") then
            objeto:Destroy()
        elseif objeto:IsA("BasePart") or objeto:IsA("MeshPart") or objeto:IsA("UnionOperation") then
            objeto.Material = Enum.Material.SmoothPlastic
            objeto.Reflectance = 0
            if objeto:IsA("MeshPart") then
                objeto.TextureID = ""
            end
        end
        if objeto:IsA("ParticleEmitter") or objeto:IsA("Trail") then
            objeto.Enabled = false
        end
    end
    warn("Mapa otimizado: Texturas removidas.")
end

-- 2. PARTE: RESOLUÇÃO DE TELA (CAMERA TRICK)
if getgenv().gg_scripters == nil then
    RunService.RenderStepped:Connect(function()
        -- Aplica a matriz de escala na CFrame da câmera
        Camera.CFrame = Camera.CFrame * CFrame.new(0, 0, 0, 1, 0, 0, 0, getgenv().Resolution[".gg/scripters"], 0, 0, 0, 1)
    end)
end

-- 3. EXECUÇÃO
limparMapa()
getgenv().gg_scripters = "Aori0001"