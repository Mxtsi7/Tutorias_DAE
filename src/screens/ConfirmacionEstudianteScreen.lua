-- ConfirmacionEstudianteScreen.lua
-- Se muestra al estudiante luego de que el evento TUTOR_ACEPTO se dispara.
-- Muestra: nombre del tutor, área, horario, modalidad y estado "Tutoría activa".
-- Patrón visual basado en SesionScreen.lua (panel centrado con cabecera de color).

local Anim = require("src.anim.Anim")

local CS = {}
local fadeIn = nil
local params = {}

local PW = 520
local PY = 60
local function W() return love.graphics.getWidth() end
local function H() return love.graphics.getHeight() end
local function PX() return math.floor((W() - PW) / 2) end

function CS.load(p)
    params = p or {}
    fadeIn = Anim.new(0, 1, 0.45, "easeOut")
end

function CS.update(dt)
    if fadeIn then fadeIn:update(dt) end
end

function CS.draw()
    local a   = fadeIn and fadeIn:value() or 1
    local WW  = W()
    local HH  = H()
    local px  = PX()
    local ph  = 380

    -- Fondo oscurecido
    love.graphics.setColor(0.08, 0.08, 0.14, 0.50 * a)
    love.graphics.rectangle("fill", 0, 0, WW, HH)

    -- Sombra del panel
    love.graphics.setColor(0, 0, 0, 0.10 * a)
    love.graphics.rectangle("fill", px + 6, PY + 8, PW, ph, 20)

    -- Panel blanco
    love.graphics.setColor(1, 1, 1, a)
    love.graphics.rectangle("fill", px, PY, PW, ph, 20)

    -- Cabecera verde (mismo patrón que SesionScreen)
    love.graphics.setColor(Colors.green[1], Colors.green[2], Colors.green[3], a)
    love.graphics.rectangle("fill", px, PY, PW, 64, 20)
    love.graphics.rectangle("fill", px, PY + 44, PW, 20, 0)
    love.graphics.setColor(1, 1, 1, a)
    love.graphics.setFont(Fonts.title)
    love.graphics.printf("Tutor\xc3\xada Confirmada", px, PY + 18, PW, "center")

    -- Badge "Tutoría activa"
    local badgeLabel = "\xe2\x97\x8f  Tutor\xc3\xada activa"
    local bw = Fonts.small:getWidth(badgeLabel) + 24
    local bx = px + math.floor((PW - bw) / 2)
    local by = PY + 76
    love.graphics.setColor(Colors.green[1], Colors.green[2], Colors.green[3], 0.18 * a)
    love.graphics.rectangle("fill", bx, by, bw, 26, 8)
    love.graphics.setColor(Colors.green[1], Colors.green[2], Colors.green[3], a)
    love.graphics.setFont(Fonts.small)
    love.graphics.printf(badgeLabel, bx, by + 6, bw, "center")

    -- Filas de información
    local rows = {
        { label = "Tutor asignado",   value = params.tutor_nombre  or "\xe2\x80\x94" },
        { label = "\xc3\x81rea de tutor\xc3\xada", value = params.area         or "\xe2\x80\x94" },
        { label = "Horario",          value = params.horario        or "\xe2\x80\x94" },
        { label = "Modalidad",        value = params.modalidad      or "\xe2\x80\x94" },
    }

    local startY = PY + 118
    local rowH   = 52
    for idx, row in ipairs(rows) do
        local ry  = startY + (idx - 1) * rowH
        local alt = idx % 2 == 0

        -- Fondo alternado
        if alt then
            love.graphics.setColor(0.97, 0.97, 1.0, 0.60 * a)
            love.graphics.rectangle("fill", px + 20, ry, PW - 40, rowH - 4, 8)
        end

        -- Label
        love.graphics.setColor(Colors.textSub[1], Colors.textSub[2], Colors.textSub[3], a)
        love.graphics.setFont(Fonts.small)
        love.graphics.print(row.label, px + 32, ry + 8)

        -- Value: colorear modalidad con badge
        if row.label == "Modalidad" then
            local mc
            if row.value == "Online" then
                mc = Colors.accent
            elseif row.value == "H\xc3\xadbrido" then
                mc = Colors.orange
            else
                mc = Colors.green
            end
            local vw = Fonts.body:getWidth(row.value) + 18
            love.graphics.setColor(mc[1], mc[2], mc[3], 0.18 * a)
            love.graphics.rectangle("fill", px + 32, ry + 24, vw, 22, 6)
            love.graphics.setColor(mc[1], mc[2], mc[3], a)
            love.graphics.setFont(Fonts.body)
            love.graphics.print(row.value, px + 41, ry + 27)
        else
            love.graphics.setColor(Colors.text[1], Colors.text[2], Colors.text[3], a)
            love.graphics.setFont(Fonts.body)
            love.graphics.print(row.value, px + 32, ry + 26)
        end
    end

    -- Línea separadora
    local sepY = startY + #rows * rowH + 4
    love.graphics.setColor(Colors.border[1], Colors.border[2], Colors.border[3], 0.6 * a)
    love.graphics.rectangle("fill", px + 20, sepY, PW - 40, 1)

    -- Botón "Ir al Dashboard"
    local btnY = sepY + 16
    love.graphics.setColor(Colors.green[1], Colors.green[2], Colors.green[3], a)
    love.graphics.rectangle("fill", px + math.floor((PW - 200) / 2), btnY, 200, 44, 12)
    love.graphics.setColor(1, 1, 1, a)
    love.graphics.setFont(Fonts.body)
    love.graphics.printf("Ir al Dashboard", px, btnY + 12, PW, "center")
end

function CS.mousepressed(x, y, btn)
    if btn ~= 1 then return end
    local px   = PX()
    local ph   = 380
    local rows = 4
    local startY = PY + 118
    local rowH   = 52
    local sepY   = startY + rows * rowH + 4
    local btnY   = sepY + 16
    local btnX   = px + math.floor((PW - 200) / 2)

    if x >= btnX and x <= btnX + 200 and y >= btnY and y <= btnY + 44 then
        Nav.to("dashboard", {
            rol        = params.rol,
            usuario_id = params.usuario_id,
            nombre     = params.nombre,
        }, -1)
    end
end

return CS
