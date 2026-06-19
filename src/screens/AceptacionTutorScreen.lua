-- AceptacionTutorScreen.lua
-- Pantalla del TUTOR: muestra la propuesta pendiente y permite Aceptar o Rechazar.
-- Si el tutor no responde en 48h, AsignacionHandler detecta el rechazo tácito
-- automáticamente via VERIFICAR_TACITOS (publicado cada 60s desde main.lua).

local EventBus   = require("src.events.EventBus")
local EventTypes = require("src.events.EventTypes")
local DB         = require("src.db.DB")
local Anim       = require("src.anim.Anim")

local AT = {}
local params    = {}
local propuesta = nil   -- solicitud en estado 'asignacion_propuesta' para este tutor
local tutor_db  = nil
local estudiante_nombre = ""
local msg       = ""
local msgColor  = nil
local stag      = {}
local hover     = {}

local function W() return love.graphics.getWidth() end
local function H() return love.graphics.getHeight() end
local MARGIN = 60

-- Convierte segundos a texto legible "Xh Ym restantes" o "VENCIDO"
local function formatCountdown(segundos_restantes)
    if segundos_restantes <= 0 then
        return "PLAZO VENCIDO (rechazo t\xc3\xa1cito pendiente)"
    end
    local horas   = math.floor(segundos_restantes / 3600)
    local minutos = math.floor((segundos_restantes % 3600) / 60)
    return string.format("%dh %02dm restantes para responder", horas, minutos)
end

local function cargarPropuesta()
    propuesta = nil
    estudiante_nombre = ""
    if not tutor_db then return end

    -- Buscar solicitud en 'asignacion_propuesta' asignada a este tutor
    propuesta = DB.find("solicitudes", function(s)
        return s.estado == "asignacion_propuesta"
               and s.tutor_propuesto == tutor_db.id
    end)

    if propuesta then
        -- Resolver nombre del estudiante
        local est = DB.find("estudiantes", function(e)
            return e.id == propuesta.estudiante_id
        end)
        if est then
            local usr = DB.find("usuarios", function(u) return u.id == est.usuario_id end)
            estudiante_nombre = usr and usr.nombre or "Estudiante"
        end
    end
end

function AT.load(p)
    params   = p or {}
    msg      = ""
    msgColor = nil
    hover    = {}

    -- Resolver entidad tutor a partir del usuario en sesión
    tutor_db = DB.find("tutores", function(t)
        return t.usuario_id == params.usuario_id
    end)

    cargarPropuesta()
    stag = Anim.staggerList(3, 0.08, 0.35)
end

function AT.update(dt)
    Anim.staggerUpdate(stag, dt)
    local mx, my = love.mouse.getPosition()
    local WW, HH = W(), H()
    hover.aceptar  = mx >= MARGIN         and mx <= MARGIN+180         and my >= HH-90 and my <= HH-44
    hover.rechazar = mx >= MARGIN+200     and mx <= MARGIN+380         and my >= HH-90 and my <= HH-44
    hover.volver   = mx >= WW-MARGIN-160  and mx <= WW-MARGIN          and my >= HH-90 and my <= HH-44
end

function AT.draw()
    local WW, HH = W(), H()
    local RW = WW - MARGIN*2

    -- Fondo
    love.graphics.setColor(Colors.bg)
    love.graphics.rectangle("fill", 0, 0, WW, HH)

    -- Header
    love.graphics.setColor(Colors.accent)
    love.graphics.rectangle("fill", 0, 0, WW, 68)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(Fonts.title)
    love.graphics.printf("Aceptaci\xc3\xb3n de Tutor\xc3\xada", 0, 20, WW, "center")

    -- Subtítulo rol
    love.graphics.setColor(Colors.textSub)
    love.graphics.setFont(Fonts.small)
    love.graphics.printf("Bienvenido, " .. (params.nombre or "Tutor") ..
        "  |  Rol: Tutor", 0, 80, WW, "center")

    if not propuesta then
        -- Sin propuesta pendiente
        local _, alpha = Anim.staggerValue(stag, 1)
        love.graphics.setColor(Colors.greenSoft[1], Colors.greenSoft[2],
            Colors.greenSoft[3], alpha)
        love.graphics.rectangle("fill", MARGIN, 130, RW, 80, 14)
        love.graphics.setColor(Colors.green[1], Colors.green[2],
            Colors.green[3], alpha)
        love.graphics.setFont(Fonts.body)
        love.graphics.printf(
            "\xe2\x9c\x93  No tienes propuestas pendientes de aceptaci\xc3\xb3n.",
            MARGIN, 158, RW, "center")
    else
        -- Card de la propuesta
        local _, alpha = Anim.staggerValue(stag, 1)
        local ahora   = os.time()
        local LIMITE  = 48 * 3600
        local elapsed = ahora - (propuesta.fecha_propuesta or ahora)
        local restant = LIMITE - elapsed
        local vencido = restant <= 0

        -- Card principal
        love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.rectangle("fill", MARGIN, 120, RW, 260, 16)
        love.graphics.setColor(Colors.accent[1], Colors.accent[2],
            Colors.accent[3], 0.35 * alpha)
        love.graphics.rectangle("line", MARGIN+1, 121, RW-2, 258, 16)

        -- Título card
        love.graphics.setColor(Colors.text[1], Colors.text[2],
            Colors.text[3], alpha)
        love.graphics.setFont(Fonts.title)
        love.graphics.print("Nueva propuesta de tutor\xc3\xada",
            MARGIN + 24, 140)

        love.graphics.setFont(Fonts.body)
        love.graphics.setColor(Colors.text[1], Colors.text[2],
            Colors.text[3], alpha)
        love.graphics.print("Estudiante:  " .. estudiante_nombre,
            MARGIN + 24, 180)
        love.graphics.print("\xc3\x81rea:        " ..
            (propuesta.area or "\xe2\x80\x94"), MARGIN + 24, 206)
        love.graphics.print("Urgencia:    " ..
            (propuesta.urgencia or "\xe2\x80\x94"), MARGIN + 24, 232)
        love.graphics.print("Modalidad:   " ..
            (propuesta.modalidad or "\xe2\x80\x94"), MARGIN + 24, 258)

        -- Countdown timer
        local timerColor = vencido and Colors.red
            or (restant < 7200 and Colors.orange or Colors.green)
        love.graphics.setColor(timerColor[1], timerColor[2],
            timerColor[3], alpha)
        love.graphics.setFont(Fonts.small)
        love.graphics.print("\xe2\x8f\xb1  " .. formatCountdown(restant),
            MARGIN + 24, 292)

        -- Regla de negocio visible
        love.graphics.setColor(Colors.textSub[1], Colors.textSub[2],
            Colors.textSub[3], alpha * 0.85)
        love.graphics.print(
            "Regla: si no respondes en 48h, el sistema registra rechazo t\xc3\xa1cito autom\xc3\xa1ticamente.",
            MARGIN + 24, 312)
    end

    -- Mensaje resultado
    if msg ~= "" then
        local mc = msgColor or Colors.green
        local bgc = (mc == Colors.red)
            and {0.99, 0.94, 0.94} or Colors.greenSoft
        love.graphics.setColor(bgc)
        love.graphics.rectangle("fill", MARGIN, HH-130, RW, 36, 10)
        love.graphics.setColor(mc)
        love.graphics.setFont(Fonts.small)
        love.graphics.printf(msg, MARGIN, HH-120, RW, "center")
    end

    -- Botones
    local btnY = HH - 90

    -- Aceptar (solo si hay propuesta)
    if propuesta then
        local ba = hover.aceptar and Colors.green
            or {Colors.green[1]*0.85, Colors.green[2]*0.85,
                Colors.green[3]*0.85}
        love.graphics.setColor(ba)
        love.graphics.rectangle("fill", MARGIN, btnY, 180, 46, 12)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(Fonts.body)
        love.graphics.printf("\xe2\x9c\x93  Aceptar", MARGIN, btnY + 13, 180, "center")

        -- Rechazar
        local br = hover.rechazar and Colors.red
            or {Colors.red[1]*0.85, Colors.red[2]*0.85,
                Colors.red[3]*0.85}
        love.graphics.setColor(br)
        love.graphics.rectangle("fill", MARGIN + 200, btnY, 180, 46, 12)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("\xe2\x9c\x95  Rechazar", MARGIN + 200, btnY + 13, 180, "center")
    end

    -- Volver
    love.graphics.setColor(hover.volver and Colors.border
        or {Colors.border[1]*0.9, Colors.border[2]*0.9,
            Colors.border[3]*0.9})
    love.graphics.rectangle("fill", WW - MARGIN - 160, btnY, 160, 46, 12)
    love.graphics.setColor(Colors.text)
    love.graphics.setFont(Fonts.body)
    love.graphics.printf("Volver", WW - MARGIN - 160, btnY + 13, 160, "center")
end

function AT.mousepressed(x, y, btn)
    if btn ~= 1 then return end
    local WW, HH = W(), H()
    local btnY   = HH - 90

    -- Botón Volver
    if x >= WW-MARGIN-160 and x <= WW-MARGIN
        and y >= btnY and y <= btnY+46 then
        Nav.to("dashboard", {
            rol        = params.rol,
            usuario_id = params.usuario_id,
            nombre     = params.nombre,
        }, -1)
        return
    end

    if not propuesta then return end

    -- Botón Aceptar
    if x >= MARGIN and x <= MARGIN+180
        and y >= btnY and y <= btnY+46 then
        -- Publicar evento TUTOR_ACEPTO → AsignacionHandler crea la tutoría
        EventBus.publish(EventTypes.TUTOR_ACEPTO, {
            tutor            = tutor_db,
            estudiante_id    = propuesta.estudiante_id,
            estudiante_nombre = estudiante_nombre,
            area             = propuesta.area,
            solicitud_id     = propuesta.id,
        })
        -- Marcar solicitud como asignada
        propuesta.estado          = "asignada"
        propuesta.tutor_propuesto = nil
        propuesta.fecha_propuesta = nil
        DB.save()
        msg      = "\xe2\x9c\x93 Aceptaste la tutor\xc3\xada. Ahora est\xc3\xa1 activa."
        msgColor = Colors.green
        propuesta = nil
        return
    end

    -- Botón Rechazar (rechazo explícito)
    if x >= MARGIN+200 and x <= MARGIN+380
        and y >= btnY and y <= btnY+46 then
        EventBus.publish(EventTypes.TUTOR_RECHAZO, {
            tutor_id     = tutor_db.id,
            solicitud_id = propuesta.id,
            tacito       = false,   -- rechazo explícito
        })
        msg      = "Rechazaste la propuesta. La solicitud vuelve a pendiente."
        msgColor = Colors.red
        propuesta = nil
        return
    end
end

return AT
