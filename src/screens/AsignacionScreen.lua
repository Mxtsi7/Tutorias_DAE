-- AsignacionScreen: vista del Coordinador para asignar tutores
local SM = require("src.screens.ScreenManager")
local EventBus = require("src.events.EventBus")
local EventTypes = require("src.events.EventTypes")
local tutores = require("src.data.tutores")

local AsignacionScreen = {}
local seleccionado = nil
local hover = {}
local params = {}
local asignado = false

function AsignacionScreen.load(p)
    params = p or {}
    seleccionado = nil
    asignado = false
    hover = {}
end

function AsignacionScreen.update(dt)
    local mx, my = love.mouse.getPosition()
    for i, t in ipairs(tutores) do
        local ry = 160 + (i-1)*90
        hover[i] = mx >= 60 and mx <= 1040 and my >= ry and my <= ry+76
    end
end

function AsignacionScreen.draw()
    love.graphics.setColor(Colors.bg)
    love.graphics.rectangle("fill", 0, 0, 1100, 720)

    -- Header
    love.graphics.setColor(Colors.accent)
    love.graphics.rectangle("fill", 0, 0, 1100, 70)
    love.graphics.setColor(1,1,1)
    love.graphics.setFont(Fonts.title)
    love.graphics.printf("Asignación de Tutor", 0, 22, 1100, "center")

    love.graphics.setColor(Colors.text)
    love.graphics.setFont(Fonts.body)
    love.graphics.print("Selecciona un tutor compatible para la solicitud pendiente:", 60, 90)
    love.graphics.setColor(Colors.textSub)
    love.graphics.setFont(Fonts.small)
    love.graphics.print("Solo se muestran tutores que cumplen las 4 condiciones de elegibilidad.", 60, 112)

    -- Lista de tutores
    for i, t in ipairs(tutores) do
        local ry = 160 + (i-1)*90
        local sel = seleccionado == i
        -- card
        love.graphics.setColor(sel and Colors.accentSoft or (hover[i] and {0.96,0.96,1} or Colors.card))
        love.graphics.rectangle("fill", 60, ry, 980, 76, 12)
        -- borde si seleccionado
        if sel then
            love.graphics.setColor(Colors.accent)
            love.graphics.rectangle("line", 60, ry, 980, 76, 12)
        end
        -- círculo inicial
        local ac = t.tutorados_activos < 3 and Colors.green or Colors.orange
        love.graphics.setColor(ac[1],ac[2],ac[3],0.2)
        love.graphics.circle("fill", 100, ry+38, 22)
        love.graphics.setColor(ac)
        love.graphics.setFont(Fonts.title)
        love.graphics.print(string.upper(string.sub(t.nombre,1,1)), 92, ry+24)
        -- nombre
        love.graphics.setColor(Colors.text)
        love.graphics.setFont(Fonts.body)
        love.graphics.print(t.nombre, 132, ry+14)
        -- áreas
        love.graphics.setColor(Colors.textSub)
        love.graphics.setFont(Fonts.small)
        love.graphics.print("Áreas: " .. table.concat(t.areas_competencia, ", "), 132, ry+36)
        love.graphics.print("Disponibilidad: " .. table.concat(t.disponibilidad, ", "), 132, ry+52)
        -- cupo
        love.graphics.setColor(ac)
        love.graphics.setFont(Fonts.small)
        love.graphics.print(t.tutorados_activos .. " / " .. t.limite .. " tutorados", 850, ry+30)
        -- incidentes
        love.graphics.setColor(t.incidentes_recientes == 0 and Colors.green or Colors.red)
        love.graphics.print(t.incidentes_recientes == 0 and "Sin incidentes" or t.incidentes_recientes .. " incidente(s)", 850, ry+48)
    end

    -- Botones
    -- Volver
    love.graphics.setColor(Colors.border)
    love.graphics.rectangle("fill", 60, 650, 120, 42, 10)
    love.graphics.setColor(Colors.text)
    love.graphics.setFont(Fonts.body)
    love.graphics.printf("Volver", 60, 662, 120, "center")
    -- Asignar
    local bColor = seleccionado and Colors.accent or {0.8,0.7,0.95}
    love.graphics.setColor(bColor)
    love.graphics.rectangle("fill", 920, 650, 120, 42, 10)
    love.graphics.setColor(1,1,1)
    love.graphics.printf("Asignar", 920, 662, 120, "center")

    -- Confirmación
    if asignado then
        love.graphics.setColor(Colors.greenSoft)
        love.graphics.rectangle("fill", 300, 640, 500, 44, 12)
        love.graphics.setColor(Colors.green)
        love.graphics.setFont(Fonts.body)
        love.graphics.printf("✓ Tutor asignado. Notificación enviada.", 300, 654, 500, "center")
    end
end

function AsignacionScreen.mousepressed(x, y, button)
    for i, t in ipairs(tutores) do
        local ry = 160 + (i-1)*90
        if x >= 60 and x <= 1040 and y >= ry and y <= ry+76 then
            seleccionado = i
            return
        end
    end
    -- Volver
    if x >= 60 and x <= 180 and y >= 650 and y <= 692 then
        SM.load("dashboard", { rol = params.rol })
    end
    -- Asignar
    if x >= 920 and x <= 1040 and y >= 650 and y <= 692 and seleccionado then
        EventBus.publish(EventTypes.TUTOR_ASIGNADO, { tutor = tutores[seleccionado] })
        asignado = true
    end
end

return AsignacionScreen
