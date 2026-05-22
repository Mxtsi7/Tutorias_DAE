-- SolicitudScreen: formulario de solicitud de tutoría (4 campos obligatorios)
local SM = require("src.screens.ScreenManager")
local EventBus = require("src.events.EventBus")
local EventTypes = require("src.events.EventTypes")

local SolicitudScreen = {}
local campos = {
    { label = "Área Temática",       placeholder = "Ej: Estadística Aplicada", value = "", error = false },
    { label = "Nivel de Urgencia",   placeholder = "alta / media / baja",       value = "", error = false },
    { label = "Disponibilidad Horaria", placeholder = "Ej: Martes y Jueves tarde", value = "", error = false },
    { label = "Modalidad Preferida", placeholder = "remota / presencial",       value = "", error = false },
}
local campoActivo = 1
local enviado = false
local errorMsg = ""
local params = {}

function SolicitudScreen.load(p)
    params = p or {}
    for _, c in ipairs(campos) do c.value = "" c.error = false end
    campoActivo = 1
    enviado = false
    errorMsg = ""
end

function SolicitudScreen.update(dt) end

function SolicitudScreen.draw()
    love.graphics.setColor(Colors.bg)
    love.graphics.rectangle("fill", 0, 0, 1100, 720)

    -- Panel central
    local px, py, pw, ph = 300, 60, 500, 590
    love.graphics.setColor(0,0,0,0.05)
    love.graphics.rectangle("fill", px+4, py+4, pw, ph, 18)
    love.graphics.setColor(Colors.card)
    love.graphics.rectangle("fill", px, py, pw, ph, 18)

    -- Header
    love.graphics.setColor(Colors.accent)
    love.graphics.rectangle("fill", px, py, pw, 60, 18)
    love.graphics.setColor(Colors.accent)
    love.graphics.rectangle("fill", px, py+40, pw, 20)
    love.graphics.setColor(1,1,1)
    love.graphics.setFont(Fonts.title)
    love.graphics.printf("Nueva Solicitud de Tutoría", px, py+16, pw, "center")

    -- Campos
    for i, c in ipairs(campos) do
        local fy = py + 80 + (i-1)*108
        -- label
        love.graphics.setColor(Colors.text)
        love.graphics.setFont(Fonts.body)
        love.graphics.print(c.label, px+24, fy)
        -- input box
        local bc = (i == campoActivo) and Colors.accent or (c.error and Colors.red or Colors.border)
        love.graphics.setColor(bc)
        love.graphics.rectangle("line", px+24, fy+24, pw-48, 42, 10)
        love.graphics.setColor(Colors.bg)
        love.graphics.rectangle("fill", px+25, fy+25, pw-50, 40, 9)
        -- valor o placeholder
        love.graphics.setFont(Fonts.body)
        if c.value ~= "" then
            love.graphics.setColor(Colors.text)
            love.graphics.print(c.value .. (i == campoActivo and "_" or ""), px+36, fy+36)
        else
            love.graphics.setColor(Colors.textSub)
            love.graphics.print(c.placeholder, px+36, fy+36)
        end
        -- error inline
        if c.error then
            love.graphics.setColor(Colors.red)
            love.graphics.setFont(Fonts.small)
            love.graphics.print("Campo obligatorio", px+36, fy+70)
        end
    end

    -- Mensaje de éxito
    if enviado then
        love.graphics.setColor(Colors.greenSoft)
        love.graphics.rectangle("fill", px+24, py+500, pw-48, 44, 10)
        love.graphics.setColor(Colors.green)
        love.graphics.setFont(Fonts.body)
        love.graphics.printf("✓ Solicitud enviada correctamente", px+24, py+514, pw-48, "center")
    end

    -- Error general
    if errorMsg ~= "" then
        love.graphics.setColor(0.98,0.92,0.92)
        love.graphics.rectangle("fill", px+24, py+500, pw-48, 44, 10)
        love.graphics.setColor(Colors.red)
        love.graphics.setFont(Fonts.small)
        love.graphics.printf(errorMsg, px+24, py+514, pw-48, "center")
    end

    -- Botones
    -- Cancelar
    love.graphics.setColor(Colors.border)
    love.graphics.rectangle("fill", px+24, py+555, 110, 40, 10)
    love.graphics.setColor(Colors.text)
    love.graphics.setFont(Fonts.body)
    love.graphics.printf("Cancelar", px+24, py+566, 110, "center")
    -- Enviar
    love.graphics.setColor(Colors.accent)
    love.graphics.rectangle("fill", px+pw-134, py+555, 110, 40, 10)
    love.graphics.setColor(1,1,1)
    love.graphics.printf("Enviar", px+pw-134, py+566, 110, "center")
end

function SolicitudScreen.mousepressed(x, y, button)
    local px, py, pw = 300, 60, 500
    -- seleccionar campo
    for i, c in ipairs(campos) do
        local fy = py + 80 + (i-1)*108
        if x >= px+24 and x <= px+pw-24 and y >= fy+24 and y <= fy+66 then
            campoActivo = i
            return
        end
    end
    -- Cancelar
    if x >= px+24 and x <= px+134 and y >= py+615 and y <= py+655 then
        SM.load("dashboard", { rol = params.rol })
        return
    end
    -- Enviar
    if x >= px+pw-134 and x <= px+pw-24 and y >= py+615 and y <= py+655 then
        errorMsg = ""
        local valid = true
        for _, c in ipairs(campos) do
            c.error = (c.value == "")
            if c.error then valid = false end
        end
        if valid then
            EventBus.publish(EventTypes.SOLICITUD_ENVIADA, { campos = campos })
            enviado = true
            errorMsg = ""
        else
            errorMsg = "Completa todos los campos obligatorios"
            enviado = false
        end
    end
end

function SolicitudScreen.keypressed(key)
    if key == "tab" then
        campoActivo = (campoActivo % #campos) + 1
    elseif key == "backspace" then
        local c = campos[campoActivo]
        if c then c.value = string.sub(c.value, 1, -2) end
    end
end

function SolicitudScreen.textinput(text)
    local c = campos[campoActivo]
    if c then c.value = c.value .. text end
end

return SolicitudScreen
