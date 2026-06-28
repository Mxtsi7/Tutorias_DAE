local EventBus      = require("src.events.EventBus")
local EventTypes    = require("src.events.EventTypes")
local ScreenManager = require("src.screens.ScreenManager")
local SolicitudHandler  = require("src.handlers.SolicitudHandler")
local AsignacionHandler = require("src.handlers.AsignacionHandler")
local SesionHandler     = require("src.handlers.SesionHandler")
local AusenciaHandler   = require("src.handlers.AusenciaHandler")
local CierreHandler     = require("src.handlers.CierreHandler")
local DB                = require("src.db.DB")

Colors = {
    bg         = {0.941, 0.945, 0.961},
    sidebar    = {1, 1, 1},
    accent     = {0.494, 0.165, 1},
    accentSoft = {0.914, 0.859, 1},
    green      = {0.133, 0.773, 0.525},
    greenSoft  = {0.859, 0.969, 0.925},
    orange     = {1, 0.596, 0.196},
    card       = {1, 1, 1},
    text       = {0.133, 0.133, 0.2},
    textSub    = {0.553, 0.553, 0.620},
    red        = {0.898, 0.224, 0.224},
    border     = {0.878, 0.878, 0.910},
}

Nav        = require("src.anim.Transition")
Fullscreen = false

local _tacitoTimer    = 0
local TACITO_INTERVAL = 60

function love.load()
    love.graphics.setBackgroundColor(Colors.bg)
    love.graphics.setDefaultFilter("linear", "linear")

    Fonts = {
        title = love.graphics.newFont(20),
        body  = love.graphics.newFont(14),
        small = love.graphics.newFont(11),
        big   = love.graphics.newFont(30),
        huge  = love.graphics.newFont(44),
    }

    DB.open()

    print("Cargando SolicitudHandler...")
    SolicitudHandler.register(EventBus)
    print("Cargando AsignacionHandler...")
    AsignacionHandler.register(EventBus)
    print("Cargando SesionHandler...")
    SesionHandler.register(EventBus)
    print("Cargando AusenciaHandler...")
    AusenciaHandler.register(EventBus)
    print("Cargando CierreHandler...")
    CierreHandler.register(EventBus)

    NotificationManager = require("src.components.NotificationManager")

    EventBus.subscribe(EventTypes.TUTOR_ACEPTO, function(data)
        local nombre = (data.tutor and data.tutor.nombre) or "Tutor"
        local area   = data.area or "la tutoria"
        NotificationManager.push(nombre .. " acepto la tutoria de " .. area, "success")
    end)

    EventBus.subscribe(EventTypes.TUTOR_RECHAZO, function(data)
        local tipo = data.tacito
            and "Rechazo tacito (48h sin respuesta)"
            or  "Rechazo explicito"
        NotificationManager.push(tipo .. " - solicitud devuelta a pendiente", "warning")
    end)

    EventBus.subscribe(EventTypes.ALERTA_COORDINADOR, function(data)
        local msg  = data.mensaje or "Alerta del sistema"
        local tipo = (data.tipo == "advertencia_formal" or data.tipo == "abandono_potencial")
            and "error" or "warning"
        NotificationManager.push(msg, tipo)
    end)

    EventBus.subscribe(EventTypes.NOTIFICACION_MOSTRAR, function(data)
        local msg  = data.mensaje or data.message or "Notificacion"
        local tipo = data.tipo    or data.type    or "info"
        NotificationManager.push(msg, tipo)
    end)

    EventBus.subscribe(EventTypes.TUTORIA_CERRADA, function(data)
        local estudiante = data.estudiante_nombre or "Estudiante"
        NotificationManager.push("Tutoria de " .. estudiante .. " cerrada exitosamente", "success")
    end)

    EventBus.subscribe(EventTypes.SOLICITUD_VALIDADA, function(data)
        local area = data.area or "area no especificada"
        NotificationManager.push("Solicitud registrada: " .. area .. " - pendiente de revision", "info")
    end)

    EventBus.subscribe(EventTypes.SOLICITUD_RECHAZADA, function(data)
        NotificationManager.push("Solicitud incompleta: " .. (data.motivo or "complete todos los campos"), "error")
    end)

    EventBus.subscribe(EventTypes.TUTOR_DADO_DE_BAJA, function(data)
        NotificationManager.push("Tutor dado de baja - tutorias afectadas pasan a reasignacion", "error")
    end)

    ScreenManager.load("login")
end

function love.quit()
    DB.close()
end

function love.update(dt)
    Nav.update(dt)
    ScreenManager.update(dt)
    NotificationManager.update(dt)
    _tacitoTimer = _tacitoTimer + dt
    if _tacitoTimer >= TACITO_INTERVAL then
        _tacitoTimer = 0
        EventBus.publish(EventTypes.VERIFICAR_TACITOS, {})
    end
end

function love.draw()
    local W, H = love.graphics.getDimensions()
    ScreenManager.draw()
    Nav.draw(W, H)
    NotificationManager.draw()
    local bx = W - 44
    local mx, my = love.mouse.getPosition()
    local hovFS = mx>=bx and mx<=bx+34 and my>=6 and my<=40
    love.graphics.setColor(0,0,0, hovFS and 0.12 or 0.06)
    love.graphics.rectangle("fill",bx,6,34,34,6)
    love.graphics.setColor(Colors.text)
    love.graphics.setFont(Fonts.small)
    love.graphics.printf(Fullscreen and "[o]" or "[ ]",bx,15,34,"center")
end

function love.keypressed(key)
    if key=="f11" then
        Fullscreen = not Fullscreen
        love.window.setFullscreen(Fullscreen,"desktop")
        return
    end
    if key=="escape" then
        if Fullscreen then Fullscreen=false love.window.setFullscreen(false) return end
        if ScreenManager.currentName~="login" then
            Nav.to("login",nil,-1)
        else love.event.quit() end
        return
    end
    ScreenManager.keypressed(key)
end

function love.mousepressed(x,y,button)
    if Nav.active then return end
    local W2 = love.graphics.getWidth()
    local bx = W2 - 44
    if x>=bx and x<=bx+34 and y>=6 and y<=40 then
        Fullscreen = not Fullscreen
        love.window.setFullscreen(Fullscreen,"desktop")
        return
    end
    ScreenManager.mousepressed(x,y,button)
end

-- CORRECCION: wheelmoved delegado al ScreenManager
function love.wheelmoved(x, y)
    if Nav.active then return end
    ScreenManager.wheelmoved(x, y)
end

function love.textinput(text)
    ScreenManager.textinput(text)
end
