-- main.lua: Punto de entrada. Carga fuentes, registra handlers y abre pantalla de login.

local EventBus     = require("src.events.EventBus")
local EventTypes   = require("src.events.EventTypes")
local ScreenManager = require("src.screens.ScreenManager")
local SolicitudHandler  = require("src.handlers.SolicitudHandler")
local AsignacionHandler = require("src.handlers.AsignacionHandler")
local SesionHandler     = require("src.handlers.SesionHandler")
local AusenciaHandler   = require("src.handlers.AusenciaHandler")
local CierreHandler     = require("src.handlers.CierreHandler")

-- Paleta global (estilo TutorMate)
Colors = {
    bg         = {0.941, 0.945, 0.961},   -- #F0F1F5 fondo general
    sidebar    = {1, 1, 1},               -- blanco sidebar
    accent     = {0.494, 0.165, 1},       -- #7E2AFF violeta principal
    accentSoft = {0.914, 0.859, 1},       -- #E9DBFF violeta suave
    green      = {0.133, 0.773, 0.525},   -- #22C586 verde activo
    greenSoft  = {0.859, 0.969, 0.925},   -- #DBFBEC verde suave
    orange     = {1, 0.596, 0.196},       -- #FF9832 medio
    card       = {1, 1, 1},
    text       = {0.133, 0.133, 0.2},     -- #222233
    textSub    = {0.553, 0.553, 0.620},   -- gris subtexto
    red        = {0.898, 0.224, 0.224},   -- alerta
    border     = {0.878, 0.878, 0.910},   -- bordes suaves
}

function love.load()
    love.graphics.setBackgroundColor(Colors.bg)

    -- Fuente base (LOVE usa la default; se puede cambiar por .ttf)
    Fonts = {
        title  = love.graphics.newFont(22),
        body   = love.graphics.newFont(14),
        small  = love.graphics.newFont(11),
        big    = love.graphics.newFont(28),
    }

    SolicitudHandler.register(EventBus)
    AsignacionHandler.register(EventBus)
    SesionHandler.register(EventBus)
    AusenciaHandler.register(EventBus)
    CierreHandler.register(EventBus)

    ScreenManager.load("login")
end

function love.update(dt)
    ScreenManager.update(dt)
end

function love.draw()
    ScreenManager.draw()
end

function love.keypressed(key)
    if key == "escape" then
        -- volver al login si no estamos ya ahí
        if ScreenManager.currentName ~= "login" then
            ScreenManager.load("login")
        else
            love.event.quit()
        end
    end
    ScreenManager.keypressed(key)
end

function love.mousepressed(x, y, button)
    ScreenManager.mousepressed(x, y, button)
end

function love.textinput(text)
    ScreenManager.textinput(text)
end
