-- Sin parpadeo: carga pantalla y cubre con negro desde el primer frame
local SM = require("src.screens.ScreenManager")
local T  = {}

T.active     = false
T.alpha      = 0
T.speed      = 5.0

function T.to(screenName, params, _)
    if T.active then return end
    SM.load(screenName, params)
    T.alpha  = 1.0
    T.active = true
end

function T.update(dt)
    if not T.active then return end
    T.alpha = math.max(0, T.alpha - T.speed * dt)
    if T.alpha == 0 then
        T.active = false
    end
end

function T.draw(W, H)
    -- Siempre dibuja si active, incluso en alpha=1 (primer frame)
    if not T.active and T.alpha <= 0 then return end
    W = W or love.graphics.getWidth()
    H = H or love.graphics.getHeight()
    love.graphics.setColor(0.10, 0.08, 0.16, T.alpha * T.alpha)
    love.graphics.rectangle("fill", 0, 0, W, H)
end

function T.offsetX() return 0 end

return T
