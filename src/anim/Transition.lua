-- Transition.lua: fade + slide entre pantallas
-- Uso: Transition.to("nombre", params)  en lugar de ScreenManager.load directamente

local SM  = require("src.screens.ScreenManager")

local T = {}
T.active   = false
T.alpha    = 0       -- 0=transparente  1=negro total
T.dir      = 1       -- 1=fade-out  -1=fade-in
T.speed    = 2.8     -- unidades/seg
T.nextName = nil
T.nextParams = nil
T.slideX   = 0       -- desplazamiento horizontal del contenido
T.slideDir = 0       -- +1 desliza derecha→izq,  -1 izq→derecha

function T.to(screenName, params, slideDir)
    if T.active then return end
    T.active     = true
    T.alpha      = 0
    T.dir        = 1
    T.nextName   = screenName
    T.nextParams = params
    T.slideDir   = slideDir or 1
    T.slideX     = 0
end

function T.update(dt)
    if not T.active then return end
    T.alpha = T.alpha + T.dir * T.speed * dt
    T.slideX = T.slideX + T.dir * T.slideDir * 900 * dt

    if T.dir == 1 and T.alpha >= 1 then
        -- mitad del fade: cambiar pantalla
        T.alpha  = 1
        T.dir    = -1
        T.slideX = -T.slideDir * 60
        SM.load(T.nextName, T.nextParams)
    elseif T.dir == -1 and T.alpha <= 0 then
        T.alpha  = 0
        T.active = false
        T.slideX = 0
    end
end

function T.draw()
    if T.alpha <= 0 then return end
    love.graphics.setColor(0.08, 0.08, 0.14, math.min(T.alpha, 1))
    love.graphics.rectangle("fill", 0, 0, 1920, 1080)
end

-- Devuelve el offset X actual para que las pantallas lo usen
function T.offsetX()
    return T.active and T.slideX or 0
end

return T
