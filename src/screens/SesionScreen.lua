-- SesionScreen: registro de informe de sesión (vista del Tutor)
local SM = require("src.screens.ScreenManager")
local EventBus = require("src.events.EventBus")
local EventTypes = require("src.events.EventTypes")

local SesionScreen = {}
local opcAvance = {"bajo", "medio", "alto"}
local opcAsist  = {"Asistió", "Ausencia justificada", "Ausencia injustificada"}
local campos = {
    { label = "Fecha de sesión",  value = "", placeholder = "Ej: 2026-05-22" },
    { label = "Duración (min)",   value = "", placeholder = "Ej: 60" },
    { label = "Temas tratados",   value = "", placeholder = "Describe los temas" },
}
local avanceSel = 1
local asistSel  = 1
local campoActivo = 1
local guardado  = false
local params    = {}

function SesionScreen.load(p)
    params = p or {}
    for _, c in ipairs(campos) do c.value = "" end
    avanceSel = 1 asistSel = 1 campoActivo = 1 guardado = false
end

function SesionScreen.update(dt) end

function SesionScreen.draw()
    love.graphics.setColor(Colors.bg)
    love.graphics.rectangle("fill", 0, 0, 1100, 720)

    local px, py, pw, ph = 260, 30, 580, 650
    love.graphics.setColor(0,0,0,0.05)
    love.graphics.rectangle("fill", px+4, py+4, pw, ph, 18)
    love.graphics.setColor(Colors.card)
    love.graphics.rectangle("fill", px, py, pw, ph, 18)

    -- Header
    love.graphics.setColor(Colors.green)
    love.graphics.rectangle("fill", px, py, pw, 56, 18)
    love.graphics.setColor(Colors.green)
    love.graphics.rectangle("fill", px, py+36, pw, 20)
    love.graphics.setColor(1,1,1)
    love.graphics.setFont(Fonts.title)
    love.graphics.printf("Registrar Informe de Sesión", px, py+14, pw, "center")

    -- Campos de texto
    for i, c in ipairs(campos) do
        local fy = py + 70 + (i-1)*100
        love.graphics.setColor(Colors.text)
        love.graphics.setFont(Fonts.body)
        love.graphics.print(c.label, px+24, fy)
        local bc = (i == campoActivo) and Colors.green or Colors.border
        love.graphics.setColor(bc)
        love.graphics.rectangle("line", px+24, fy+24, pw-48, 40, 9)
        love.graphics.setColor(Colors.bg)
        love.graphics.rectangle("fill", px+25, fy+25, pw-50, 38, 8)
        love.graphics.setFont(Fonts.body)
        if c.value ~= "" then
            love.graphics.setColor(Colors.text)
            love.graphics.print(c.value .. (i == campoActivo and "_" or ""), px+36, fy+34)
        else
            love.graphics.setColor(Colors.textSub)
            love.graphics.print(c.placeholder, px+36, fy+34)
        end
    end

    -- Selector nivel de avance
    local sy = py + 370
    love.graphics.setColor(Colors.text)
    love.graphics.setFont(Fonts.body)
    love.graphics.print("Nivel de avance del estudiante", px+24, sy)
    for i, op in ipairs(opcAvance) do
        local bx = px + 24 + (i-1)*150
        local sel = avanceSel == i
        local c = i==1 and Colors.red or (i==2 and Colors.orange or Colors.green)
        love.graphics.setColor(sel and c or Colors.border)
        love.graphics.rectangle("fill", bx, sy+24, 136, 36, 9)
        love.graphics.setColor(sel and {1,1,1} or Colors.textSub)
        love.graphics.setFont(Fonts.body)
        love.graphics.printf(string.upper(op), bx, sy+33, 136, "center")
    end

    -- Selector asistencia
    local ay = py + 450
    love.graphics.setColor(Colors.text)
    love.graphics.setFont(Fonts.body)
    love.graphics.print("Asistencia", px+24, ay)
    for i, op in ipairs(opcAsist) do
        local bx = px + 24 + (i-1)*178
        local sel = asistSel == i
        love.graphics.setColor(sel and Colors.accent or Colors.border)
        love.graphics.rectangle("fill", bx, ay+24, 164, 34, 9)
        love.graphics.setColor(sel and {1,1,1} or Colors.textSub)
        love.graphics.setFont(Fonts.small)
        love.graphics.printf(op, bx, ay+34, 164, "center")
    end

    -- Confirmación
    if guardado then
        love.graphics.setColor(Colors.greenSoft)
        love.graphics.rectangle("fill", px+24, py+504, pw-48, 40, 10)
        love.graphics.setColor(Colors.green)
        love.graphics.setFont(Fonts.body)
        love.graphics.printf("✓ Sesión registrada correctamente", px+24, py+515, pw-48, "center")
    end

    -- Botones
    love.graphics.setColor(Colors.border)
    love.graphics.rectangle("fill", px+24, py+560, 110, 40, 10)
    love.graphics.setColor(Colors.text)
    love.graphics.setFont(Fonts.body)
    love.graphics.printf("Volver", px+24, py+571, 110, "center")
    love.graphics.setColor(Colors.green)
    love.graphics.rectangle("fill", px+pw-134, py+560, 110, 40, 10)
    love.graphics.setColor(1,1,1)
    love.graphics.printf("Guardar", px+pw-134, py+571, 110, "center")
end

function SesionScreen.mousepressed(x, y, button)
    local px, py, pw = 260, 30, 580
    -- campos
    for i, c in ipairs(campos) do
        local fy = py + 70 + (i-1)*100
        if x >= px+24 and x <= px+pw-24 and y >= fy+24 and y <= fy+64 then
            campoActivo = i return
        end
    end
    -- avance
    local sy = py + 370
    for i = 1,3 do
        local bx = px + 24 + (i-1)*150
        if x >= bx and x <= bx+136 and y >= sy+24 and y <= sy+60 then
            avanceSel = i return
        end
    end
    -- asistencia
    local ay = py + 450
    for i = 1,3 do
        local bx = px + 24 + (i-1)*178
        if x >= bx and x <= bx+164 and y >= ay+24 and y <= ay+58 then
            asistSel = i return
        end
    end
    -- Volver
    if x >= px+24 and x <= px+134 and y >= py+590 and y <= py+630 then
        SM.load("dashboard", { rol = params.rol })
    end
    -- Guardar
    if x >= px+pw-134 and x <= px+pw-24 and y >= py+590 and y <= py+630 then
        local ev = opcAsist[asistSel] == "Asistió" and EventTypes.SESION_REGISTRADA
                or opcAsist[asistSel] == "Ausencia justificada" and EventTypes.SESION_AUSENCIA_JUST
                or EventTypes.SESION_AUSENCIA_INJUST
        EventBus.publish(ev, { avance = opcAvance[avanceSel], campos = campos })
        guardado = true
    end
end

function SesionScreen.keypressed(key)
    if key == "tab" then campoActivo = (campoActivo % #campos) + 1
    elseif key == "backspace" then
        local c = campos[campoActivo]
        if c then c.value = string.sub(c.value,1,-2) end
    end
end

function SesionScreen.textinput(text)
    local c = campos[campoActivo]
    if c then c.value = c.value .. text end
end

return SesionScreen
