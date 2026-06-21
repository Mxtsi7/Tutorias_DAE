-- NotificationManager.lua
-- Sistema global de notificaciones toast.
-- Se llama desde main.lua update() y draw(), por lo que funciona
-- sobre cualquier pantalla sin modificar cada Screen individualmente.
--
-- Uso:
--   NotificationManager.push("Mensaje", "success")  -- success|warning|error|info
--   NotificationManager.update(dt)
--   NotificationManager.draw()   -- llamar DESPUES de ScreenManager.draw()

local NM = {}
NM._queue = {}          -- lista de toasts activos

local MAX_VISIBLE = 5   -- maximo de toasts apilados en pantalla
local TOAST_H     = 54  -- altura de cada toast
local TOAST_W     = 380 -- ancho fijo
local PADDING     = 12  -- margen entre toasts
local MARGIN_R    = 24  -- margen derecha
local MARGIN_B    = 24  -- margen inferior
local DURACION    = 5.0 -- segundos visibles
local FADE_T      = 0.4 -- segundos de fade in/out

local COLORES = {
    success = {0.133, 0.773, 0.525},  -- verde
    warning = {1,     0.596, 0.196},  -- naranja
    error   = {0.898, 0.224, 0.224},  -- rojo
    info    = {0.494, 0.165, 1},      -- violeta
}
local ICONOS = {
    success = "\xe2\x9c\x93",  -- checkmark
    warning = "\xe2\x9a\xa0",  -- triangulo
    error   = "\xe2\x9c\x95",  -- X
    info    = "\xe2\x84\xb9",  -- i
}

-- Agrega un nuevo toast a la cola
function NM.push(mensaje, tipo)
    tipo = tipo or "info"
    local toast = {
        mensaje  = mensaje or "",
        tipo     = tipo,
        timer    = DURACION,
        alpha    = 0,
        targetY  = 0,   -- calculado en draw
        currentY = 0,
    }
    table.insert(NM._queue, 1, toast)  -- insertar al frente (mas reciente arriba)
    -- limitar cola
    while #NM._queue > MAX_VISIBLE do
        table.remove(NM._queue)
    end
end

function NM.update(dt)
    for i = #NM._queue, 1, -1 do
        local t = NM._queue[i]
        t.timer = t.timer - dt
        -- fade in
        if t.timer > DURACION - FADE_T then
            t.alpha = math.min(1, (DURACION - t.timer) / FADE_T)
        -- fade out
        elseif t.timer < FADE_T then
            t.alpha = math.max(0, t.timer / FADE_T)
        else
            t.alpha = 1
        end
        if t.timer <= 0 then
            table.remove(NM._queue, i)
        end
    end
end

function NM.draw()
    if #NM._queue == 0 then return end
    local W = love.graphics.getWidth()
    local H = love.graphics.getHeight()
    local baseX = W - TOAST_W - MARGIN_R

    for i, t in ipairs(NM._queue) do
        local baseY = H - MARGIN_B - i * (TOAST_H + PADDING)
        local c = COLORES[t.tipo] or COLORES.info
        local a = t.alpha

        -- Sombra
        love.graphics.setColor(0, 0, 0, 0.10 * a)
        love.graphics.rectangle("fill", baseX + 3, baseY + 4, TOAST_W, TOAST_H, 12)

        -- Fondo blanco
        love.graphics.setColor(1, 1, 1, 0.97 * a)
        love.graphics.rectangle("fill", baseX, baseY, TOAST_W, TOAST_H, 12)

        -- Barra de color lateral
        love.graphics.setColor(c[1], c[2], c[3], a)
        love.graphics.rectangle("fill", baseX, baseY, 5, TOAST_H, 5)

        -- Icono
        love.graphics.setColor(c[1], c[2], c[3], a)
        love.graphics.setFont(Fonts.body)
        love.graphics.print(ICONOS[t.tipo] or "\xe2\x84\xb9", baseX + 16, baseY + TOAST_H / 2 - 9)

        -- Mensaje
        love.graphics.setColor(0.133, 0.133, 0.2, a)  -- Colors.text
        love.graphics.setFont(Fonts.small)
        love.graphics.printf(
            t.mensaje,
            baseX + 36,
            baseY + TOAST_H / 2 - 9,
            TOAST_W - 50,
            "left"
        )

        -- Barra de progreso del tiempo restante
        local progreso = math.max(0, t.timer / DURACION)
        love.graphics.setColor(c[1], c[2], c[3], 0.25 * a)
        love.graphics.rectangle("fill", baseX + 5, baseY + TOAST_H - 4,
            TOAST_W - 5, 4, 3)
        love.graphics.setColor(c[1], c[2], c[3], 0.6 * a)
        love.graphics.rectangle("fill", baseX + 5, baseY + TOAST_H - 4,
            (TOAST_W - 5) * progreso, 4, 3)
    end
end

return NM
