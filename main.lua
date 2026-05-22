local EventBus      = require("src.events.EventBus")
local EventTypes    = require("src.events.EventTypes")
local ScreenManager = require("src.screens.ScreenManager")
local Transition    = require("src.anim.Transition")
local SolicitudHandler  = require("src.handlers.SolicitudHandler")
local AsignacionHandler = require("src.handlers.AsignacionHandler")
local SesionHandler     = require("src.handlers.SesionHandler")
local AusenciaHandler   = require("src.handlers.AusenciaHandler")
local CierreHandler     = require("src.handlers.CierreHandler")

-- Paleta global (estilo TutorMate)
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

-- Módulo de transición global
Nav = require("src.anim.Transition")

function love.load()
    love.graphics.setBackgroundColor(Colors.bg)
    Fonts = {
        title  = love.graphics.newFont(26),
        body   = love.graphics.newFont(16),
        small  = love.graphics.newFont(13),
        big    = love.graphics.newFont(36),
        huge   = love.graphics.newFont(52),
    }
    SolicitudHandler.register(EventBus)
    AsignacionHandler.register(EventBus)
    SesionHandler.register(EventBus)
    AusenciaHandler.register(EventBus)
    CierreHandler.register(EventBus)
    ScreenManager.load("login")
end

function love.update(dt)
    Nav.update(dt)
    ScreenManager.update(dt)
end

function love.draw()
    -- Offset de slide para toda la pantalla
    local ox = Nav.offsetX()
    if ox ~= 0 then
        love.graphics.push()
        love.graphics.translate(ox, 0)
    end
    ScreenManager.draw()
    if ox ~= 0 then love.graphics.pop() end
    -- Capa de fade encima de todo
    Nav.draw()
end

function love.keypressed(key)
    if key == "escape" then
        if ScreenManager.currentName ~= "login" then
            Nav.to("login", nil, -1)
        else
            love.event.quit()
        end
        return
    end
    ScreenManager.keypressed(key)
end

function love.mousepressed(x, y, button)
    if Nav.active then return end   -- bloquear clicks durante transición
    ScreenManager.mousepressed(x, y, button)
end

function love.textinput(text)
    ScreenManager.textinput(text)
end
