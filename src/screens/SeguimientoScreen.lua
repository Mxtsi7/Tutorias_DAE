-- SeguimientoScreen: seguimiento semanal del Coordinador
local SM = require("src.screens.ScreenManager")
local tutorias = require("src.data.tutorias")
local tutores  = require("src.data.tutores")
local estud    = require("src.data.estudiantes")

local SeguimientoScreen = {}
local hover = {}
local params = {}

function SeguimientoScreen.load(p)
    params = p or {}
    hover = {}
end

function SeguimientoScreen.update(dt)
    local mx, my = love.mouse.getPosition()
    for i, t in ipairs(tutorias) do
        local ry = 180 + (i-1)*80
        hover[i] = mx >= 40 and mx <= 1060 and my >= ry and my <= ry+68
    end
end

local function estadoColor(estado)
    if estado == "activa" then return Colors.green
    elseif estado == "activa_con_alerta" then return Colors.orange
    elseif estado == "suspendida" then return Colors.red
    else return Colors.textSub end
end

function SeguimientoScreen.draw()
    love.graphics.setColor(Colors.bg)
    love.graphics.rectangle("fill", 0, 0, 1100, 720)

    -- Header barra
    love.graphics.setColor(Colors.accent)
    love.graphics.rectangle("fill", 0, 0, 1100, 64)
    love.graphics.setColor(1,1,1)
    love.graphics.setFont(Fonts.title)
    love.graphics.printf("Seguimiento Semanal — Coordinador", 0, 18, 1100, "center")

    -- KPIs
    local kpis = {
        { label = "Tutorías Activas", value = #tutorias,   color = Colors.green  },
        { label = "Con Alertas",      value = 1,            color = Colors.orange },
        { label = "En Espera",        value = 0,            color = Colors.textSub},
    }
    for i, k in ipairs(kpis) do
        local kx = 40 + (i-1)*340
        love.graphics.setColor(Colors.card)
        love.graphics.rectangle("fill", kx, 76, 310, 72, 12)
        love.graphics.setColor(k.color)
        love.graphics.rectangle("fill", kx, 76, 6, 72, 4)
        love.graphics.setColor(Colors.text)
        love.graphics.setFont(Fonts.big)
        love.graphics.print(tostring(k.value), kx+24, 84)
        love.graphics.setColor(Colors.textSub)
        love.graphics.setFont(Fonts.small)
        love.graphics.print(k.label, kx+24, 122)
    end

    -- Encabezado tabla
    love.graphics.setColor(Colors.text)
    love.graphics.setFont(Fonts.small)
    local cols = {40, 220, 430, 600, 740, 870, 980}
    local headers = {"Estudiante","Área","Tutor","Sesiones","Avance","Estado","Acción"}
    for i, h in ipairs(headers) do
        love.graphics.print(h, cols[i], 162)
    end
    love.graphics.setColor(Colors.border)
    love.graphics.rectangle("fill", 40, 176, 1020, 1)

    -- Filas
    for i, t in ipairs(tutorias) do
        local ry = 182 + (i-1)*80
        -- fondo fila
        love.graphics.setColor(hover[i] and {0.95,0.95,1} or (i%2==0 and Colors.bg or Colors.card))
        love.graphics.rectangle("fill", 40, ry, 1020, 68, 8)
        -- datos
        local e = estud[t.estudiante_id] or {nombre="—"}
        local tu = tutores[t.tutor_id]  or {nombre="—"}
        love.graphics.setColor(Colors.text)
        love.graphics.setFont(Fonts.body)
        love.graphics.print(e.nombre,  cols[1], ry+12)
        love.graphics.setFont(Fonts.small)
        love.graphics.setColor(Colors.textSub)
        love.graphics.print(e.area_necesidad or "—", cols[1], ry+34)
        love.graphics.setColor(Colors.text)
        love.graphics.setFont(Fonts.body)
        love.graphics.print(t.area or "—",    cols[2], ry+22)
        love.graphics.print(tu.nombre,         cols[3], ry+22)
        love.graphics.print(t.sesiones_realizadas .. " / 8", cols[4], ry+22)
        -- avance barra mini
        local ac = t.nivel_avance_actual == "alto" and Colors.green
                or t.nivel_avance_actual == "medio" and Colors.orange or Colors.red
        love.graphics.setColor(ac)
        love.graphics.print(t.nivel_avance_actual or "bajo", cols[5], ry+22)
        -- estado badge
        local sc = estadoColor(t.estado)
        love.graphics.setColor(sc[1],sc[2],sc[3],0.15)
        love.graphics.rectangle("fill", cols[6], ry+14, 90, 24, 8)
        love.graphics.setColor(sc)
        love.graphics.setFont(Fonts.small)
        love.graphics.printf(t.estado or "activa", cols[6], ry+19, 90, "center")
        -- botón intervenir
        love.graphics.setColor(Colors.accentSoft)
        love.graphics.rectangle("fill", cols[7], ry+14, 80, 28, 8)
        love.graphics.setColor(Colors.accent)
        love.graphics.setFont(Fonts.small)
        love.graphics.printf("Detalle", cols[7], ry+20, 80, "center")
    end

    -- Botón volver
    love.graphics.setColor(Colors.accent)
    love.graphics.rectangle("fill", 40, 672, 140, 40, 10)
    love.graphics.setColor(1,1,1)
    love.graphics.setFont(Fonts.body)
    love.graphics.printf("Volver", 40, 683, 140, "center")
end

function SeguimientoScreen.mousepressed(x, y, button)
    if x >= 40 and x <= 180 and y >= 672 and y <= 712 then
        SM.load("dashboard", { rol = params.rol })
    end
end

return SeguimientoScreen
