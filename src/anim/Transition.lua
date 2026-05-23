-- Transicion: fade-out simple tras cargar la nueva pantalla
local SM = require("src.screens.ScreenManager")
local T  = {}

T.active     = false
T.alpha      = 0
T.nextName   = nil
T.nextParams = nil
T.speed      = 4.5  -- fade-out rapido (~0.22s)

function T.to(screenName, params, _)
    if T.active then return end
    -- Carga inmediata + fade desde negro a transparente
    SM.load(screenName, params)
    T.active = true
    T.alpha  = 1
end

function T.update(dt)
    if not T.active then return end
    T.alpha = T.alpha - T.speed * dt
    if T.alpha <= 0 then
        T.alpha  = 0
        T.active = false
    end
end

function T.draw(W, H)
    if T.alpha <= 0 then return end
    W = W or love.graphics.getWidth()
    H = H or love.graphics.getHeight()
    -- easing: desvanece con curva suave
    local a = T.alpha * T.alpha
    love.graphics.setColor(0.10, 0.08, 0.16, a)
    love.graphics.rectangle("fill", 0, 0, W, H)
end

function T.offsetX() return 0 end

return T
