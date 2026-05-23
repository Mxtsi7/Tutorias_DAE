-- Transicion fade suave sin slide
local SM = require("src.screens.ScreenManager")
local T  = {}

T.active     = false
T.alpha      = 0
T.dir        = 1
T.speed      = 3.0
T.nextName   = nil
T.nextParams = nil

function T.to(screenName, params, slideDir)
    if T.active then return end
    T.active     = true
    T.alpha      = 0
    T.dir        = 1
    T.nextName   = screenName
    T.nextParams = params
end

function T.update(dt)
    if not T.active then return end
    T.alpha = T.alpha + T.dir * T.speed * dt
    if T.dir == 1 and T.alpha >= 1 then
        T.alpha = 1
        T.dir   = -1
        SM.load(T.nextName, T.nextParams)
    elseif T.dir == -1 and T.alpha <= 0 then
        T.alpha  = 0
        T.active = false
    end
end

function T.draw(W, H)
    if T.alpha <= 0 then return end
    W = W or love.graphics.getWidth()
    H = H or love.graphics.getHeight()
    -- easing cuadratico: suaviza entrada y salida
    local a = T.dir == 1
        and T.alpha * T.alpha
        or  1 - (1 - T.alpha) * (1 - T.alpha)
    love.graphics.setColor(0.10, 0.08, 0.16, math.min(a, 1))
    love.graphics.rectangle("fill", 0, 0, W, H)
end

-- Sin slide, offsetX siempre 0
function T.offsetX() return 0 end

return T
